package service

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"nexora/internal/modules/hardware/models"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
	"nexora/internal/modules/recursos-humanos/service/funcionario"
	"nexora/internal/pkg/tenantid"
)

// DBTX é a interface mínima de acesso à BD usada por este pacote — tanto
// *pgxpool.Pool (produção) como pgxmock (testes) a implementam (mesmo
// padrão de assiduidade.DBTX / push.DBTX / nexorapay.DBTX).
type DBTX interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
}

// Processor contém a lógica de processamento de eventos normalizados.
type Processor struct {
	db          DBTX
	assiduidade *assiduidade.Service
	funcionario *funcionario.Service
}

// NewProcessor cria um novo processor.
func NewProcessor(db DBTX) *Processor {
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
	// Permanent distingue uma falha de configuração (tenant sem empresa
	// associada, método de assiduidade desactivado, credential_type sem
	// mapeamento) — que não se resolve sozinha, não vale a pena o job de
	// retry (Fase 5, item 1) voltar a tentar — de uma falha que pode
	// legitimamente deixar de o ser com o tempo (employee_no ainda não
	// mapeado, funcionário inactivo, erro transitório a gravar o evento).
	Permanent bool
}

// deviceEventMaxAttempts e deviceEventBackoff espelham
// notificationMaxAttempts/notificationBackoff (internal/background/jobs.go)
// — mais curto: um evento de assiduidade por mapear vale a pena retomar em
// minutos, não horas.
const deviceEventMaxAttempts = 5

var deviceEventBackoff = []time.Duration{
	1 * time.Minute,
	5 * time.Minute,
	15 * time.Minute,
	30 * time.Minute,
	1 * time.Hour,
}

func deviceEventBackoffFor(attempts int) time.Duration {
	idx := min(max(attempts-1, 0), len(deviceEventBackoff)-1)
	return deviceEventBackoff[idx]
}

// Process grava o evento bruto e processa-o de acordo com o mapeamento do dispositivo.
func (p *Processor) Process(ctx context.Context, deviceID, tenantID int64, event *models.NormalizedEvent) (int64, ProcessResult, error) {
	raw, _ := json.Marshal(event.RawPayload)
	eventHash := hashEvent(deviceID, event.EmployeeNo, event.EventTime, raw)
	// normalized_payload guarda o NormalizedEvent já normalizado pelo
	// adapter (CredentialType, Direction, coordenadas, etc.) — ao contrário
	// de raw_payload (só os bytes brutos originais, para debug), é isto que
	// permite ao job de retry (Fase 5, item 1) e ao replay manual (item 4)
	// repetir processEntity mais tarde sem precisar do pedido original.
	normalizedPayload, _ := json.Marshal(event)

	// Insere de forma atómica: ON CONFLICT evita a janela entre "verificar
	// duplicado" e "inserir" (dois pedidos concorrentes com o mesmo
	// event_hash — ex.: retry do dispositivo a colidir com o pedido
	// original — já não fazem a segunda chamada falhar com erro de
	// constraint UNIQUE; devolve o estado real do evento já existente).
	var eventID int64
	var inserted bool
	err := p.db.QueryRow(ctx, `
		INSERT INTO hardware.device_events
		  (tenant_id, device_id, event_type, employee_no, event_time, event_hash, raw_payload, normalized_payload)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		ON CONFLICT (event_hash) DO NOTHING
		RETURNING id, TRUE`,
		tenantID, deviceID, event.EventType, event.EmployeeNo,
		event.EventTime, eventHash, raw, normalizedPayload,
	).Scan(&eventID, &inserted)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			var existingID int64
			var processed bool
			var errorMessage *string
			if scanErr := p.db.QueryRow(ctx, `
				SELECT id, processed, error_message FROM hardware.device_events WHERE event_hash = $1`,
				eventHash,
			).Scan(&existingID, &processed, &errorMessage); scanErr == nil {
				result := ProcessResult{Processed: processed}
				if errorMessage != nil {
					result.ErrorMessage = *errorMessage
				}
				return existingID, result, nil
			}
		}
		return 0, ProcessResult{ErrorMessage: "erro ao registar evento"}, err
	}

	result := p.processEntity(ctx, tenantID, deviceID, event, eventID)
	if err := p.finalizeEvent(ctx, eventID, 0, result); err != nil {
		log.Printf("[hardware] gravar resultado do evento %d: %v", eventID, err)
	}
	return eventID, result, nil
}

// finalizeEvent grava o resultado de uma tentativa de processamento
// (Process ou Retry) — attemptsBefore é o valor de "attempts" já gravado na
// BD antes desta tentativa (0 na primeira chamada de Process, o valor
// devolvido por ClaimForRetry nas seguintes).
func (p *Processor) finalizeEvent(ctx context.Context, eventID int64, attemptsBefore int, result ProcessResult) error {
	if result.Processed {
		_, err := p.db.Exec(ctx, `
			UPDATE hardware.device_events
			   SET processed = TRUE, processed_at = NOW(),
			       presenca_id = $1, attendance_id = $2, error_message = $3,
			       locked_at = NULL, locked_by = NULL
			 WHERE id = $4`,
			result.PresencaID, result.AttendanceID, nullIfEmptyString(result.ErrorMessage), eventID,
		)
		return err
	}

	if result.Permanent {
		_, err := p.db.Exec(ctx, `
			UPDATE hardware.device_events
			   SET error_message = $1, permanent_failure = TRUE,
			       locked_at = NULL, locked_by = NULL
			 WHERE id = $2`,
			result.ErrorMessage, eventID,
		)
		return err
	}

	attempts := attemptsBefore + 1
	_, err := p.db.Exec(ctx, `
		UPDATE hardware.device_events
		   SET error_message = $1, attempts = $2,
		       available_at = NOW() + ($3 * INTERVAL '1 second'),
		       locked_at = NULL, locked_by = NULL
		 WHERE id = $4`,
		nullIfEmptyString(result.ErrorMessage), attempts, deviceEventBackoffFor(attempts).Seconds(), eventID,
	)
	return err
}

func nullIfEmptyString(s string) any {
	if s == "" {
		return nil
	}
	return s
}

// deviceEventLeaseTimeout é quanto tempo um evento pode ficar reservado
// (locked_at) antes de se considerar que o worker que o reservou morreu a
// meio da tentativa e a reserva ser recuperada.
const deviceEventLeaseTimeout = 5 * time.Minute

// DeviceEventRetry é uma linha de hardware.device_events reservada para
// nova tentativa de processamento — Fase 5, item 1, de
// docs/analise-transactional-outbox-backends.md.
type DeviceEventRetry struct {
	ID                int64
	TenantID          int64
	DeviceID          int64
	NormalizedPayload []byte
	Attempts          int
}

// RecoverExpiredLeases devolve à disponibilidade de retry os eventos cujo
// lease expirou (worker morto a meio da tentativa) — não mexe em
// processed/permanent_failure, só liberta a reserva.
func (p *Processor) RecoverExpiredLeases(ctx context.Context, leaseTimeout time.Duration) (int64, error) {
	tag, err := p.db.Exec(ctx, `
		UPDATE hardware.device_events
		   SET locked_at = NULL, locked_by = NULL
		 WHERE locked_at IS NOT NULL AND locked_at < NOW() - ($1 * INTERVAL '1 second')`,
		leaseTimeout.Seconds())
	if err != nil {
		return 0, err
	}
	return tag.RowsAffected(), nil
}

// ClaimForRetry reserva até `limit` eventos não processados, não
// permanentemente falhados e vencidos, para workerID — mesmo padrão de
// claimPendingNotifications (internal/background/jobs.go) e
// PaymentService.ClaimForReconciliation
// (internal/pkg/nexorapay/service.go): UPDATE ... FROM (SELECT ... FOR
// UPDATE SKIP LOCKED) RETURNING, atómico, sem tocar em
// processed/permanent_failure — só locked_at/locked_by.
func (p *Processor) ClaimForRetry(ctx context.Context, workerID string, limit int) ([]DeviceEventRetry, error) {
	rows, err := p.db.Query(ctx, `
		WITH candidatos AS (
			SELECT id
			  FROM hardware.device_events
			 WHERE processed = FALSE AND permanent_failure = FALSE
			   AND available_at <= NOW()
			   AND locked_at IS NULL
			 ORDER BY available_at, created_at, id
			 LIMIT $1
			 FOR UPDATE SKIP LOCKED
		)
		UPDATE hardware.device_events e
		   SET locked_at = NOW(), locked_by = $2
		  FROM candidatos c
		 WHERE e.id = c.id
		RETURNING e.id, e.tenant_id, e.device_id, COALESCE(e.normalized_payload, '{}'::jsonb), e.attempts`,
		limit, workerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var retries []DeviceEventRetry
	for rows.Next() {
		var r DeviceEventRetry
		if err := rows.Scan(&r.ID, &r.TenantID, &r.DeviceID, &r.NormalizedPayload, &r.Attempts); err != nil {
			continue
		}
		retries = append(retries, r)
	}
	return retries, rows.Err()
}

// Retry desserializa o NormalizedEvent persistido em normalized_payload e
// chama processEntity outra vez, gravando o resultado com a mesma lógica
// de Process — usado pelo job de retry automático (internal/background/jobs.go)
// e disponível para o replay manual (item 4) reprocessar sem precisar do
// pedido HTTP/MQTT original.
func (p *Processor) Retry(ctx context.Context, ev DeviceEventRetry) error {
	var event models.NormalizedEvent
	if err := json.Unmarshal(ev.NormalizedPayload, &event); err != nil {
		return fmt.Errorf("desserializar normalized_payload do evento %d: %w", ev.ID, err)
	}
	result := p.processEntity(ctx, ev.TenantID, ev.DeviceID, &event, ev.ID)
	return p.finalizeEvent(ctx, ev.ID, ev.Attempts, result)
}

func (p *Processor) processEntity(ctx context.Context, tenantID, deviceID int64, event *models.NormalizedEvent, eventID int64) ProcessResult {
	saasTenantID, err := tenantid.ResolveSaas(ctx, p.db, tenantID)
	if err != nil {
		return ProcessResult{ErrorMessage: "dispositivo sem empresa/tenant associado correctamente", Permanent: true}
	}

	if activo, motivo := p.metodoAssiduidadeActivo(ctx, saasTenantID, event.CredentialType); !activo {
		return ProcessResult{ErrorMessage: motivo, Permanent: true}
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
		// Mapeamento existe mas com um entity_type que este processor não
		// sabe tratar — problema de dados/config em hardware.device_users,
		// não algo que se resolva sozinho com o tempo.
		return ProcessResult{ErrorMessage: "entity_type não suportado", Permanent: true}
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
// (sistema-configuracao/handlers/assiduidade.go). Até esta verificação
// existir, esse ecrã só tinha efeito real sobre o método Facial — validado
// dentro do FaceClock, em /biometric/verify — porque os outros 6 métodos
// (Manual, PIN, QR, NFC, Impressão Digital, Selfie+GPS) falam directamente com
// este endpoint genérico e nunca passavam por essa validação.
//
// A decisão em si vive em assiduidade.MetodoActivo (partilhada com o
// self-service, que marca ponto por JWT); aqui fica só a tradução do
// credential_type do dispositivo para a chave da configuração.
//
// Um credential_type sem mapeamento falha fechado (rejeita o evento) — os 7
// tipos suportados (facial/fingerprint/qr/nfc/pin/geolocation/manual) cobrem
// tudo o que os adapters actuais (generic_rest, zkteco, hikvision) produzem;
// um valor fora deste conjunto só pode vir de um adapter novo ainda sem
// mapeamento aqui ou de um pedido malformado, e nesse caso não há como saber
// se o método corresponde a algo que o tenant desactivou. O evento fica
// gravado em hardware.device_events (para auditoria/reprocessamento manual),
// só não vira marcação de assiduidade.
func (p *Processor) metodoAssiduidadeActivo(ctx context.Context, tenantID int64, credentialType string) (bool, string) {
	metodo, ok := credentialTypeToMetodo[credentialType]
	if !ok {
		log.Printf("[hardware] credential_type %q sem mapeamento em credentialTypeToMetodo (tenant %d) — "+
			"a rejeitar o evento (falha fechada)", credentialType, tenantID)
		return false, fmt.Sprintf("credential_type '%s' desconhecido", credentialType)
	}
	if p.assiduidade.MetodoActivo(ctx, tenantID, metodo) {
		return true, ""
	}
	return false, fmt.Sprintf("Método de assiduidade '%s' não permitido para este tenant.", metodo)
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
	tipoEventoCodigo := p.inferirTipoEventoCodigo(ctx, tenantID, funcionarioID, event)

	// metodo tem de ser um codigo existente em rh.metodos_marcacao para o
	// tenant: resolverMetodoID (assiduidade/eventos.go) devolve erro em
	// ErrNoRows e aborta o registo, portanto um codigo fora do catalogo perde
	// o evento em silencio no lado do dispositivo. origem é um campo mais
	// grosseiro (por que canal chegou) e está limitado pelo CHECK
	// eventos_assiduidade_origem_check — que não aceita "pin", daí o "app".
	metodo := "biometria"
	origem := "biometria"
	switch event.CredentialType {
	case "face":
		metodo = "reconhecimento_facial"
	case "fingerprint":
		metodo = "impressao_digital"
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
		metodo = "gps"
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

func (p *Processor) inferirTipoEventoCodigo(ctx context.Context, tenantID, funcionarioID int64, event *models.NormalizedEvent) string {
	switch event.Direction {
	case "entry":
		return "entrada"
	case "exit":
		return "saida"
	}
	return p.assiduidade.InferirEntradaOuSaida(ctx, tenantID, funcionarioID, event.EventTime)
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
