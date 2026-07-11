// Package mqtt implementa um worker interno (goroutine no processo principal)
// que subscreve tópicos MQTT de dispositivos com driver "generic_mqtt" e
// processa os eventos recebidos através do Processor genérico do módulo hardware.
//
// Arranque é opcional: só liga ao broker se MQTT_BROKER_URL estiver definida
// (ver config.Config.MQTTBrokerURL). Sem essa variável, o worker não é criado
// e o resto do backend funciona normalmente.
package mqtt

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/jackc/pgx/v5/pgxpool"

	"nexora/internal/modules/hardware/models"
	"nexora/internal/modules/hardware/service"
)

// Config contém os parâmetros de ligação ao broker MQTT.
type Config struct {
	BrokerURL string // ex: ssl://broker.nexora.co.mz:8883 ou tcp://localhost:1883
	ClientID  string
	Username  string
	Password  string
}

// Worker mantém a ligação ao broker e as subscrições activas.
type Worker struct {
	db     *pgxpool.Pool
	client mqtt.Client
}

// NewWorker liga-se ao broker MQTT. Devolve erro se a ligação inicial falhar.
func NewWorker(db *pgxpool.Pool, cfg Config) (*Worker, error) {
	if cfg.BrokerURL == "" {
		return nil, errors.New("mqtt: BrokerURL em falta")
	}
	clientID := cfg.ClientID
	if clientID == "" {
		clientID = "nexora-hardware-worker"
	}

	opts := mqtt.NewClientOptions().
		AddBroker(cfg.BrokerURL).
		SetClientID(clientID).
		SetAutoReconnect(true).
		SetConnectRetry(true).
		SetConnectRetryInterval(5 * time.Second).
		SetOnConnectHandler(func(c mqtt.Client) {
			log.Printf("[hardware/mqtt] ligado ao broker %s", cfg.BrokerURL)
		})
	opts.OnConnectionLost = func(c mqtt.Client, err error) {
		log.Printf("[hardware/mqtt] ligação perdida ao broker: %v", err)
	}

	if cfg.Username != "" {
		opts.SetUsername(cfg.Username)
		opts.SetPassword(cfg.Password)
	}

	client := mqtt.NewClient(opts)
	token := client.Connect()
	if !token.WaitTimeout(10*time.Second) || token.Error() != nil {
		if err := token.Error(); err != nil {
			return nil, err
		}
		return nil, errors.New("mqtt: tempo limite ao ligar ao broker")
	}

	return &Worker{db: db, client: client}, nil
}

// deviceSub representa um dispositivo "generic_mqtt" activo a subscrever.
type deviceSub struct {
	DeviceID int64
	TenantID int64
	Topic    string
	QoS      byte
}

// Start carrega todos os dispositivos "generic_mqtt" activos (com mqtt.topic
// configurado em hardware.device_configs) e subscreve os seus tópicos.
//
// Dispositivos criados/alterados depois do arranque só são apanhados num
// próximo Start (reinício do processo) — não há recarga dinâmica.
func (w *Worker) Start(ctx context.Context) error {
	devices, err := w.loadDevices(ctx)
	if err != nil {
		return err
	}
	for _, d := range devices {
		w.subscribe(d)
	}
	log.Printf("[hardware/mqtt] %d dispositivo(s) subscrito(s)", len(devices))
	return nil
}

// Stop desliga do broker de forma limpa.
func (w *Worker) Stop() {
	w.client.Disconnect(250)
}

func (w *Worker) loadDevices(ctx context.Context) ([]deviceSub, error) {
	rows, err := w.db.Query(ctx, `
		SELECT d.id, d.tenant_id,
		       COALESCE(t.valor, ''),
		       COALESCE(q.valor, '1')
		  FROM hardware.devices d
		  LEFT JOIN hardware.device_configs t
		         ON t.device_id = d.id AND t.chave = 'mqtt.topic'
		  LEFT JOIN hardware.device_configs q
		         ON q.device_id = d.id AND q.chave = 'mqtt.qos'
		 WHERE d.driver = 'generic_mqtt' AND d.ativo = TRUE`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var devices []deviceSub
	for rows.Next() {
		var d deviceSub
		var topic, qosStr string
		if err := rows.Scan(&d.DeviceID, &d.TenantID, &topic, &qosStr); err != nil {
			continue
		}
		if topic == "" {
			log.Printf("[hardware/mqtt] dispositivo %d sem mqtt.topic configurado, ignorado", d.DeviceID)
			continue
		}
		d.Topic = topic
		d.QoS = 1
		if qosStr == "0" || qosStr == "2" {
			d.QoS = qosStr[0] - '0'
		}
		devices = append(devices, d)
	}
	return devices, rows.Err()
}

// mqttEventPayload é o formato do payload publicado no tópico de cada
// dispositivo (ver Anexo B da análise: JSON com chaves snake_case).
type mqttEventPayload struct {
	DeviceSerial   string    `json:"device_serial"`
	EmployeeNo     string    `json:"employee_no"`
	EventTime      time.Time `json:"event_time"`
	EventType      string    `json:"event_type"`
	Direction      string    `json:"direction"`
	CredentialType string    `json:"credential_type"`
}

func (w *Worker) subscribe(d deviceSub) {
	deviceID, tenantID := d.DeviceID, d.TenantID

	token := w.client.Subscribe(d.Topic, d.QoS, func(c mqtt.Client, msg mqtt.Message) {
		var payload mqttEventPayload
		if err := json.Unmarshal(msg.Payload(), &payload); err != nil {
			log.Printf("[hardware/mqtt] payload inválido no tópico %s: %v", msg.Topic(), err)
			return
		}
		if payload.EmployeeNo == "" || payload.EventTime.IsZero() {
			log.Printf("[hardware/mqtt] payload incompleto no tópico %s (employee_no/event_time em falta)", msg.Topic())
			return
		}

		eventType := payload.EventType
		if eventType == "" {
			eventType = "unknown"
		}
		direction := payload.Direction
		if direction == "" {
			direction = "unknown"
		}
		credentialType := payload.CredentialType
		if credentialType == "" {
			credentialType = "unknown"
		}

		event := models.NormalizedEvent{
			DeviceSerial:   payload.DeviceSerial,
			EmployeeNo:     payload.EmployeeNo,
			EventType:      eventType,
			EventTime:      payload.EventTime,
			Direction:      direction,
			CredentialType: credentialType,
			RawPayload:     msg.Payload(),
		}

		processor := service.NewProcessor(w.db)
		if _, _, err := processor.Process(context.Background(), deviceID, tenantID, &event); err != nil {
			log.Printf("[hardware/mqtt] erro ao processar evento do dispositivo %d: %v", deviceID, err)
		}
	})

	if !token.WaitTimeout(5*time.Second) || token.Error() != nil {
		log.Printf("[hardware/mqtt] falha ao subscrever tópico %s (dispositivo %d): %v", d.Topic, deviceID, token.Error())
		return
	}
	log.Printf("[hardware/mqtt] subscrito: %s (dispositivo %d, QoS %d)", d.Topic, deviceID, d.QoS)
}
