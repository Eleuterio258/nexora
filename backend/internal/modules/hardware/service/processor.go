package service

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/internal/modules/hardware/models"
)

// Processor contém a lógica de processamento de eventos normalizados.
type Processor struct {
	db *pgxpool.Pool
}

// NewProcessor cria um novo processor.
func NewProcessor(db *pgxpool.Pool) *Processor {
	return &Processor{db: db}
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

	// Verifica duplicado.
	var existingID int64
	_ = p.db.QueryRow(ctx, `
		SELECT id FROM hardware.device_events
		 WHERE tenant_id = $1 AND event_hash = $2`,
		tenantID, eventHash,
	).Scan(&existingID)
	if existingID > 0 {
		return existingID, ProcessResult{Processed: true}, nil
	}

	// Insere evento bruto.
	var eventID int64
	err := p.db.QueryRow(ctx, `
		INSERT INTO hardware.device_events
		  (tenant_id, device_id, event_type, employee_no, event_time, event_hash, raw_payload)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id`,
		tenantID, deviceID, event.EventType, event.EmployeeNo,
		event.EventTime, eventHash, raw,
	).Scan(&eventID)
	if err != nil {
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

// resolveSaasTenantID traduz o tenant_id de hardware.devices (que é na
// verdade empresas.companies.id, por causa da FK devices_tenant_id_fkey ->
// companies) para o saas.tenants.id real usado por rh.presencas e
// gestao_escolar.school_attendance.
//
// Bug corrigido em 2026-07-11: antes desta função, processEntity gravava
// rh.presencas.tenant_id/gestao_escolar.school_attendance.tenant_id
// directamente com o tenantID recebido de Process() (= companies.id), que é
// um espaço de identificadores DIFERENTE de saas.tenants.id — confirmado com
// dados reais (Enigma School: companies.id=7, saas.tenants.id=5). Isto podia
// gravar presenças/frequências com o tenant_id errado sempre que essas duas
// IDs divergissem para a empresa do dispositivo. hardware.device_events
// continua a usar o tenantID original (companies.id), que é consistente
// dentro do próprio schema hardware.
func (p *Processor) resolveSaasTenantID(ctx context.Context, companyID int64) (int64, error) {
	var saasTenantID int64
	err := p.db.QueryRow(ctx,
		`SELECT tenant_id FROM empresas.companies WHERE id = $1`, companyID,
	).Scan(&saasTenantID)
	return saasTenantID, err
}

func (p *Processor) processEntity(ctx context.Context, tenantID, deviceID int64, event *models.NormalizedEvent, eventID int64) ProcessResult {
	var mapping struct {
		EntityType string
		EntityID   int64
	}
	err := p.db.QueryRow(ctx, `
		SELECT entity_type, entity_id
		  FROM hardware.device_users
		 WHERE device_id = $1 AND employee_no = $2 AND ativo = TRUE`,
		deviceID, event.EmployeeNo,
	).Scan(&mapping.EntityType, &mapping.EntityID)
	if err != nil {
		return ProcessResult{ErrorMessage: "employee_no não mapeado"}
	}

	saasTenantID, err := p.resolveSaasTenantID(ctx, tenantID)
	if err != nil {
		return ProcessResult{ErrorMessage: "dispositivo sem empresa/tenant associado correctamente"}
	}

	switch mapping.EntityType {
	case "funcionario", "professor":
		pid, err := p.registarPresenca(ctx, saasTenantID, mapping.EntityID, event.EventTime, eventID)
		if err != nil {
			return ProcessResult{ErrorMessage: "erro ao registar presença: " + err.Error()}
		}
		return ProcessResult{Processed: true, PresencaID: &pid}

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

// atrasoToleranciaMinutos é a margem antes de um evento de entrada ser
// considerado atraso, face à hora_entrada configurada em rh.horarios_trabalho.
const atrasoToleranciaMinutos = 10

// calcularTipoPresenca decide 'presente' ou 'atraso' comparando a hora do
// evento com rh.horarios_trabalho.hora_entrada do funcionário (via
// rh.funcionarios.horario_id). Sem horário configurado (ou fora do formato
// HH:MM), não há baseline para detectar atraso — assume-se 'presente'.
//
// Nota (Fase 4, 2026-07-11): não determina 'falta' — ausência só pode ser
// detectada pela FALTA de qualquer evento num dia útil esperado, o que exige
// uma rotina diária a comparar dias-de-trabalho vs rh.presencas, não algo que
// se calcule a partir de um único evento recebido. Fica como trabalho futuro.
func (p *Processor) calcularTipoPresenca(ctx context.Context, tenantID, funcionarioID int64, horaEvento string) string {
	var horaEntradaEsperada *string
	err := p.db.QueryRow(ctx, `
		SELECT h.hora_entrada
		  FROM rh.funcionarios f
		  JOIN rh.horarios_trabalho h ON h.id = f.horario_id
		 WHERE f.id = $1 AND f.tenant_id = $2 AND h.ativo = TRUE`,
		funcionarioID, tenantID,
	).Scan(&horaEntradaEsperada)
	if err != nil || horaEntradaEsperada == nil {
		return "presente"
	}

	esperado, err1 := time.Parse("15:04", *horaEntradaEsperada)
	real, err2 := time.Parse("15:04", horaEvento)
	if err1 != nil || err2 != nil {
		return "presente"
	}
	if real.Sub(esperado) > atrasoToleranciaMinutos*time.Minute {
		return "atraso"
	}
	return "presente"
}

func (p *Processor) registarPresenca(ctx context.Context, tenantID, funcionarioID int64, eventTime time.Time, eventID int64) (int64, error) {
	data := eventTime.Format("2006-01-02")
	hora := eventTime.Format("15:04")
	tipo := p.calcularTipoPresenca(ctx, tenantID, funcionarioID, hora)
	// eventID pré-formatado como string: um placeholder usado só dentro de uma
	// concatenação "|| $N::text" não dá ao pgx contexto suficiente para
	// inferir o tipo do parâmetro a partir de um int64 Go — falha em runtime
	// com "cannot find encode plan" (bug encontrado e corrigido em 2026-07-11,
	// nunca antes exercido: 0 eventos hardware tinham sido processados até então).
	eventIDStr := fmt.Sprintf("%d", eventID)

	var id int64
	err := p.db.QueryRow(ctx, `
		INSERT INTO rh.presencas (tenant_id, funcionario_id, data, hora_entrada, observacoes, tipo)
		VALUES ($1, $2, $3::date, $4, $5, $6)
		ON CONFLICT (funcionario_id, data)
		DO UPDATE SET
		  hora_saida = CASE
		    WHEN rh.presencas.hora_entrada IS NOT NULL AND rh.presencas.hora_entrada <> ''
		      AND (rh.presencas.hora_saida IS NULL OR rh.presencas.hora_saida = '')
		    THEN $4
		    ELSE rh.presencas.hora_saida
		  END,
		  observacoes = COALESCE(rh.presencas.observacoes, '') || ' | evento_id=' || $7
		RETURNING id`,
		tenantID, funcionarioID, data, hora, "Registo via hardware", tipo, eventIDStr,
	).Scan(&id)
	return id, err
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
