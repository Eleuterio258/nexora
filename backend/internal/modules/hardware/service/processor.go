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

	switch mapping.EntityType {
	case "funcionario", "professor":
		pid, err := p.registarPresenca(ctx, tenantID, mapping.EntityID, event.EventTime, eventID)
		if err != nil {
			return ProcessResult{ErrorMessage: "erro ao registar presença: " + err.Error()}
		}
		return ProcessResult{Processed: true, PresencaID: &pid}

	case "aluno":
		aid, err := p.registarFrequencia(ctx, tenantID, mapping.EntityID, event.EventTime, eventID)
		if err != nil {
			return ProcessResult{ErrorMessage: "erro ao registar frequência: " + err.Error()}
		}
		return ProcessResult{Processed: true, AttendanceID: &aid}

	default:
		return ProcessResult{ErrorMessage: "entity_type não suportado"}
	}
}

func (p *Processor) registarPresenca(ctx context.Context, tenantID, funcionarioID int64, eventTime time.Time, eventID int64) (int64, error) {
	data := eventTime.Format("2006-01-02")
	hora := eventTime.Format("15:04")

	var id int64
	err := p.db.QueryRow(ctx, `
		INSERT INTO rh.presencas (tenant_id, funcionario_id, data, hora_entrada, observacoes)
		VALUES ($1, $2, $3::date, $4, $5)
		ON CONFLICT (funcionario_id, data)
		DO UPDATE SET
		  hora_saida = CASE
		    WHEN rh.presencas.hora_entrada IS NOT NULL AND rh.presencas.hora_entrada <> ''
		      AND (rh.presencas.hora_saida IS NULL OR rh.presencas.hora_saida = '')
		    THEN $4
		    ELSE rh.presencas.hora_saida
		  END,
		  observacoes = COALESCE(rh.presencas.observacoes, '') || ' | evento_id=' || $6::text
		RETURNING id`,
		tenantID, funcionarioID, data, hora, "Registo via hardware", eventID,
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

	var id int64
	err = p.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_attendance
		  (tenant_id, class_id, student_id, attendance_date, estado, observacoes)
		VALUES ($1, $2, $3, $4::date, $5, $6)
		ON CONFLICT (tenant_id, class_id, student_id, attendance_date, COALESCE(subject_id, 0))
		DO UPDATE SET
		  estado = EXCLUDED.estado,
		  observacoes = COALESCE(gestao_escolar.school_attendance.observacoes, '') || ' | evento_id=' || $7::text,
		  updated_at = NOW()
		RETURNING id`,
		tenantID, classID, studentID, data, estado, "Registo via hardware", eventID,
	).Scan(&id)
	return id, err
}

func hashEvent(deviceID int64, employeeNo string, eventTime time.Time, raw []byte) string {
	s := fmt.Sprintf("%d|%s|%s|%x", deviceID, employeeNo, eventTime.Format(time.RFC3339), sha256.Sum256(raw))
	return fmt.Sprintf("%x", sha256.Sum256([]byte(s)))
}
