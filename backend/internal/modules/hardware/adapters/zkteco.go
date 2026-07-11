package adapters

import (
	"errors"
	"net/http"
	"time"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/hardware/models"
)

// ZKTecoAdapter normaliza eventos de terminais ZKTeco enviados via Push/ADMS
// (application/x-www-form-urlencoded), um evento por pedido.
//
// Não cobre o protocolo ADMS clássico em lote (GET /iclock/getrequest,
// POST /iclock/cdata com múltiplas linhas TSV) — apenas o modo Push simples
// de um evento por POST, tal como configurável no terminal.
type ZKTecoAdapter struct{}

func (a *ZKTecoAdapter) Name() string { return "zkteco" }

func (a *ZKTecoAdapter) ParseEvent(r *http.Request) (*models.NormalizedEvent, error) {
	if err := r.ParseForm(); err != nil {
		return nil, err
	}

	pin := r.FormValue("PIN")
	if pin == "" {
		return nil, errors.New("PIN é obrigatório")
	}

	attTime := r.FormValue("ATT_TIME")
	if attTime == "" {
		return nil, errors.New("ATT_TIME é obrigatório")
	}

	eventTime, err := time.Parse("2006-01-02 15:04:05", attTime)
	if err != nil {
		return nil, errors.New("ATT_TIME deve estar no formato YYYY-MM-DD HH:MM:SS")
	}

	eventType := "access_granted"
	if r.FormValue("RES") == "0" {
		eventType = "access_denied"
	}

	direction := "unknown"
	switch r.FormValue("STATE") {
	case "0", "4":
		direction = "entry"
	case "1", "5":
		direction = "exit"
	}

	credentialType := "unknown"
	switch r.FormValue("VERIFY_TYPE") {
	case "0":
		credentialType = "pin"
	case "1":
		credentialType = "fingerprint"
	case "2", "3":
		credentialType = "card"
	case "15":
		credentialType = "face"
	}

	return &models.NormalizedEvent{
		DeviceSerial:   r.FormValue("SN"),
		EmployeeNo:     pin,
		EventType:      eventType,
		EventTime:      eventTime,
		Direction:      direction,
		CredentialType: credentialType,
		RawPayload:     []byte(r.Form.Encode()),
	}, nil
}

func (a *ZKTecoAdapter) ValidateAuth(r *http.Request, device *mw.DeviceInfo, configs map[string]string) error {
	// A autenticação principal é feita por API Key no middleware (RequireDeviceAuth),
	// que hoje só lê o cabeçalho X-API-Key. Muitos terminais ZKTeco Push/ADMS não
	// suportam cabeçalhos HTTP personalizados na configuração de "Server URL" —
	// ver nota de viabilidade sobre RequireDeviceAuth precisar de aceitar a
	// chave também por query string para este driver funcionar em terminais reais.
	return nil
}
