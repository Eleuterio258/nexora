package service

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/internal/modules/hardware/models"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
	"nexora/internal/modules/recursos-humanos/service/funcionario"
	"nexora/internal/pkg/tenantid"
)

// Processor contém a lógica de processamento de eventos normalizados.
type Processor struct {
	db          *pgxpool.Pool
	assiduidade *assiduidade.Service
	funcionario *funcionario.Service
}

// NewProcessor cria um novo processor.
func NewProcessor(db *pgxpool.Pool) *Processor {
	return &Processor{
		db:          db,
		assiduidade: assiduidade.NewService(db),
		funcionario: funcionario.NewService(db),
	}
}

// ProcessResult representa o resultado do processamento de um evento.
type ProcessResult struct {
	Processed    bool
	PresencaID   *int64
	AttendanceID *int64
	ErrorMessage string
}

// Process grava o evento bruto e processa-o de acordo com o mapeamento do dispositivo.
func (p *Processor) Process(ctx context.Context, deviceID, tenantID int64, event *models.NormalizedEvent) (int64, ProcessResult, error) {
	raw, _ := json.Marshal(event.RawPayload)
	eventHash := hashEvent(deviceID, event.EmployeeNo, event.EventTime, raw)

	// Insere de forma atómica: ON CONFLICT evita a janela entre "verificar
	// duplicado" e "inserir" (dois pedidos concorrentes com o mesmo
	// event_hash — ex.: retry do dispositivo a colidir com o pedido
	// original — já não fazem a segunda chamada falhar com erro de
	// constraint UNIQUE; devolve o evento já existente como processado).
	var eventID int64
	var inserted bool
	err := p.db.QueryRow(ctx, `
		INSERT INTO hardware.device_events
		  (tenant_id, device_id, event_type, employee_no, event_time, event_hash, raw_payload)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		ON CONFLICT (event_hash) DO NOTHING
		RETURNING id, TRUE`,
		tenantID, deviceID, event.EventType, event.EmployeeNo,
		event.EventTime, eventHash, raw,
	).Scan(&eventID, &inserted)
	if err != nil {
		if err == pgx.ErrNoRows {
			var existingID int64
			if scanErr := p.db.QueryRow(ctx, `
				SELECT id FROM hardware.device_events WHERE event_hash = $1`,
				eventHash,
			).Scan(&existingID); scanErr == nil {
				return existingID, ProcessResult{Processed: true}, nil
			}
		}
		return 0, ProcessResult{ErrorMessage: "erro ao registar evento"}, err
	}

	result := p.processEntity(ctx, tenantID, deviceID, event, eventID)

	// Atualiza evento com resultado.
	if result.Processed {
		_, _ = p.db.Exec(ctx, `
			UPDATE hardware.device_events
			   SET processed = TRUE, processed_at = NOW(),
			       presenca_id = $1, attendance_id = $2, error_message = $3
			 WHERE id = $4`,
			result.PresencaID, result.AttendanceID, result.ErrorMessage, eventID,
		)
	} else if result.ErrorMessage != "" {
		_, _ = p.db.Exec(ctx, `
			UPDATE hardware.device_events SET error_message = $1 WHERE id = $2`,
			result.ErrorMessage, eventID,
		)
	}

	return eventID, result, nil
}

func (p *Processor) processEntity(ctx context.Context, tenantID, deviceID int64, event *models.NormalizedEvent, eventID int64) ProcessResult {
	saasTenantID, err := tenantid.ResolveSaas(ctx, p.db, tenantID)
	if err != nil {
		return ProcessResult{ErrorMessage: "dispositivo sem empresa/tenant associado correctamente"}
	}

	if activo, metodo := p.metodoAssiduidadeActivo(ctx, saasTenantID, event.CredentialType); !activo {
		return ProcessResult{ErrorMessage: fmt.Sprintf("Método de assiduidade '%s' não permitido para este tenant.", metodo)}
	}

	var mapping struct {
		EntityType string
		EntityID   int64
	}
	err = p.db.QueryRow(ctx, `
		SELECT entity_type, entity_id
		  FROM hardware.device_users
		 WHERE device_id = $1 AND employee_no = $2 AND ativo = TRUE`,
		deviceID, event.EmployeeNo,
	).Scan(&mapping.EntityType, &mapping.EntityID)
	if err != nil {
		return ProcessResult{ErrorMessage: "employee_no não mapeado"}
	}

	switch mapping.EntityType {
	case "funcionario", "professor":
		// Uniformização: valida o funcionário através do resolver centralizado,
		// garantindo que o entity_id obtido do device_users corresponde a um
		// funcionário activo no tenant SaaS.
		funcionario, err := p.funcionario.PorID(ctx, saasTenantID, mapping.EntityID)
		if err != nil {
			return ProcessResult{ErrorMessage: "funcionário não encontrado"}
		}
		if err := funcionario.VerificarAtivo(); err != nil {
			return ProcessResult{ErrorMessage: "funcionário inativo"}
		}
		eventoID, err := p.registarEventoAssiduidade(ctx, saasTenantID, deviceID, funcionario.ID, event, eventID)
		if err != nil {
			return ProcessResult{ErrorMessage: "erro ao registar evento de assiduidade: " + err.Error()}
		}
		// Repurposed: PresencaID/hardware.device_events.presenca_id passam a
		// referenciar rh.eventos_assiduidade.id (sem FK na BD, coluna livre),
		// não rh.presencas.id — mantém o contrato JSON externo (FaceClock)
		// inalterado, só muda o que o ID identifica internamente.
		return ProcessResult{Processed: true, PresencaID: &eventoID}

	case "aluno":
		aid, err := p.registarFrequencia(ctx, saasTenantID, mapping.EntityID, event.EventTime, eventID)
		if err != nil {
			return ProcessResult{ErrorMessage: "erro ao registar frequência: " + err.Error()}
		}
		return ProcessResult{Processed: true, AttendanceID: &aid}

	default:
		return ProcessResult{ErrorMessage: "entity_type não suportado"}
	}
}

// credentialTypeToMetodo traduz o credential_type normalizado por um adapter
// (ex.: generic_rest — ver HardwareEventMapper.kt no nexora_assiduidade) para
// a chave usada em rh.assiduidade.configuracao.metodos — mesmo vocabulário de
// _SOURCE_TO_METODO em
// assiduidade_system_backend/app/services/attendance_validation.py.
var credentialTypeToMetodo = map[string]string{
	"face":        "facial",
	"fingerprint": "fingerprint",
	"qr":          "qr_code",
	"nfc":         "nfc",
	"pin":         "pin",
	"geolocation": "geolocation",
	"manual":      "manual",
}

// metodoAssiduidadeActivo verifica se um método de assiduidade está permitido
// para o tenant, segundo a mesma configuração editada em
// PUT /api/system/configuracao/tenant/feature/rh.assiduidade
// (sistema-configuracao/handlers/assiduidade.go). Até esta função existir,
// esse ecrã só tinha efeito real sobre o método Facial — validado dentro do
// FaceClock, em /biometric/verify — porque os outros 6 métodos (Manual, PIN,
// QR, NFC, Impressão Digital, Selfie+GPS) falam directamente com este
// endpoint genérico e nunca passavam por essa validação.
//
// Falha aberta (permite) em qualquer caso ambíguo — credential_type sem
// mapeamento, feature rh.assiduidade inexistente/inactiva para o tenant, ou
// método sem entrada explícita na configuração — espelhando
// validar_metodo_assiduidade no FaceClock, para não bloquear
// dispositivos/tenants antes de existir configuração completa.
func (p *Processor) metodoAssiduidadeActivo(ctx context.Context, tenantID int64, credentialType string) (bool, string) {
	metodo, ok := credentialTypeToMetodo[credentialType]
	if !ok {
		return true, ""
	}

	var activo bool
	var configuracao []byte
	err := p.db.QueryRow(ctx, `
		SELECT COALESCE(tf.activo, fc.ativo_por_defeito), COALESCE(tf.configuracao, '{}'::jsonb)
		  FROM saas.feature_catalog fc
		  LEFT JOIN sistema_configuracao.tenant_feature_flags tf
		    ON tf.tenant_id = $1 AND tf.codigo = fc.key
		 WHERE fc.key = 'rh.assiduidade'`, tenantID).
		Scan(&activo, &configuracao)
	if err != nil || !activo {
		return true, ""
	}

	var cfg struct {
		Metodos map[string]struct {
			Ativo *bool `json:"ativo"`
		} `json:"metodos"`
	}
	if err := json.Unmarshal(configuracao, &cfg); err != nil {
		return true, ""
	}

	metodoCfg, ok := cfg.Metodos[metodo]
	if !ok || metodoCfg.Ativo == nil || *metodoCfg.Ativo {
		return true, ""
	}
	return false, metodo
}

// registarEventoAssiduidade grava o evento numa das duas famílias
// entrada/saída de rh.eventos_assiduidade, substituindo o antigo
// registarPresenca (que escrevia directamente em rh.presencas, um par
// entrada/saída por dia). A tolerância de atraso e o cálculo de
// presente/atraso/falta deixam de ser resolvidos aqui — passam a ser
// responsabilidade de assiduidade.RecalcularDia, aplicados a partir das
// regras configuráveis do tenant em vez de uma tolerância fixa de 10 min.
//
// event.Direction ("entry"/"exit"/"unknown", devolvido pelo adapter do
// dispositivo) decide o tipo de evento quando conhecido; no caso "unknown"
// (adapters mais simples que não distinguem direcção), infere-se pela
// paridade de eventos entrada/saída já registados nesse dia — a mesma marca
// alterna entrada/saída indefinidamente, já não se perde ao 3º evento como
// no modelo antigo (1ª marcação=entrada, 2ª=saída, 3ª+=perdida).
func (p *Processor) registarEventoAssiduidade(ctx context.Context, tenantID, deviceID, funcionarioID int64, event *models.NormalizedEvent, eventID int64) (int64, error) {
	tipoEventoCodigo, err := p.inferirTipoEventoCodigo(ctx, tenantID, funcionarioID, event)
	if err != nil {
		return 0, err
	}

	metodo := "biometria"
	origem := "biometria"
	switch event.CredentialType {
	case "qr":
		metodo = "qr"
		origem = "qr"
	case "nfc":
		metodo = "nfc"
		origem = "nfc"
	case "pin":
		metodo = "pin"
		origem = "app"
	case "geolocation":
		metodo = "geolocalizacao"
		origem = "gps"
	case "manual":
		metodo = "manual"
		origem = "manual"
	}

	eventIDStr := fmt.Sprintf("%d", eventID)
	observacoes := "Registo via hardware | evento_id=" + eventIDStr

	ev, err := p.assiduidade.RegistarEvento(ctx, tenantID, assiduidade.RegistarEventoInput{
		FuncionarioID:    funcionarioID,
		TipoEventoCodigo: tipoEventoCodigo,
		MetodoCodigo:     &metodo,
		OcorridoEm:       event.EventTime,
		Origem:           origem,
		DispositivoID:    &deviceID,
		QRTokenID:        event.QRTokenID,
		Latitude:         event.Latitude,
		Longitude:        event.Longitude,
		LocalidadeID:     event.LocalidadeID,
		FotoURL:          event.FotoURL,
		RegistadoPor:     event.RegisteredBy,
		Observacoes:      &observacoes,
	})
	if err != nil {
		return 0, err
	}
	return ev.ID, nil
}

func (p *Processor) inferirTipoEventoCodigo(ctx context.Context, tenantID, funcionarioID int64, event *models.NormalizedEvent) (string, error) {
	switch event.Direction {
	case "entry":
		return "entrada", nil
	case "exit":
		return "saida", nil
	}

	var count int
	err := p.db.QueryRow(ctx, `
		SELECT COUNT(*)
		  FROM rh.eventos_assiduidade e
		  JOIN rh.tipos_evento te ON te.id = e.tipo_evento_id
		 WHERE e.tenant_id = $1 AND e.funcionario_id = $2
		   AND e.data_referencia = $3::date AND te.codigo IN ('entrada', 'saida')`,
		tenantID, funcionarioID, event.EventTime.Format("2006-01-02"),
	).Scan(&count)
	if err != nil {
		return "entrada", nil
	}
	if count%2 == 0 {
		return "entrada", nil
	}
	return "saida", nil
}

func (p *Processor) registarFrequencia(ctx context.Context, tenantID, studentID int64, eventTime time.Time, eventID int64) (int64, error) {
	data := eventTime.Format("2006-01-02")

	estado := "presente"
	if eventTime.Hour() > 7 || (eventTime.Hour() == 7 && eventTime.Minute() > 30) {
		estado = "atrasado"
	}

	var classID int64
	err := p.db.QueryRow(ctx, `
		SELECT e.class_id
		  FROM gestao_escolar.school_enrollments e
		  JOIN gestao_escolar.school_years y ON y.id = e.school_year_id
		 WHERE e.tenant_id = $1
		   AND e.student_id = $2
		   AND e.status = 'activa'
		   AND y.status = 'activo'
		 ORDER BY e.created_at DESC
		 LIMIT 1`,
		tenantID, studentID,
	).Scan(&classID)
	if err != nil {
		return 0, fmt.Errorf("aluno sem matrícula activa no ano lectivo activo")
	}

	// Mesmo bug de inferência de tipo do pgx que em registarPresenca — eventID
	// pré-formatado como string antes de entrar na query.
	eventIDStr := fmt.Sprintf("%d", eventID)

	var id int64
	err = p.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_attendance
		  (tenant_id, class_id, student_id, attendance_date, estado, observacoes)
		VALUES ($1, $2, $3, $4::date, $5, $6)
		ON CONFLICT (tenant_id, class_id, student_id, attendance_date, COALESCE(subject_id, 0))
		DO UPDATE SET
		  estado = EXCLUDED.estado,
		  observacoes = COALESCE(gestao_escolar.school_attendance.observacoes, '') || ' | evento_id=' || $7,
		  updated_at = NOW()
		RETURNING id`,
		tenantID, classID, studentID, data, estado, "Registo via hardware", eventIDStr,
	).Scan(&id)
	return id, err
}

func hashEvent(deviceID int64, employeeNo string, eventTime time.Time, raw []byte) string {
	s := fmt.Sprintf("%d|%s|%s|%x", deviceID, employeeNo, eventTime.Format(time.RFC3339), sha256.Sum256(raw))
	return fmt.Sprintf("%x", sha256.Sum256([]byte(s)))
}
