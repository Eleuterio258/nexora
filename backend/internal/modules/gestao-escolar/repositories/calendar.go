package repositories

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/gestao-escolar/models"
)

// CalendarRepository acesso a dados do calendário.
type CalendarRepository struct {
	db DB
}

// NewCalendarRepository cria repositório.
func NewCalendarRepository(db DB) *CalendarRepository {
	return &CalendarRepository{db: db}
}

func scanCalendarEvent(row pgx.Row) (*models.CalendarEvent, error) {
	var e models.CalendarEvent
	var dataFim *time.Time
	var horaInicio, horaFim *string
	err := row.Scan(
		&e.ID, &e.TenantID, &e.SchoolYearID, &e.EventTypeID, &e.Titulo, &e.Descricao,
		&e.DataInicio, &dataFim, &horaInicio, &horaFim, &e.DiaTodo, &e.PublicoAlvo,
		&e.PublicoAlvoID, &e.CreatedBy, &e.CreatedAt, &e.UpdatedAt,
	)
	e.DataFim = dataFim
	e.HoraInicio = horaInicio
	e.HoraFim = horaFim
	return &e, err
}

// CreateEvent cria evento.
func (r *CalendarRepository) CreateEvent(ctx context.Context, e *models.CalendarEvent) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_calendar_events
		(tenant_id, school_year_id, event_type_id, titulo, descricao, data_inicio, data_fim, hora_inicio, hora_fim, dia_todo, publico_alvo, publico_alvo_id, created_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
		RETURNING id, tenant_id, school_year_id, event_type_id, titulo, descricao, data_inicio, data_fim, hora_inicio, hora_fim, dia_todo, publico_alvo, publico_alvo_id, created_by, created_at, updated_at`,
		e.TenantID, e.SchoolYearID, e.EventTypeID, e.Titulo, e.Descricao, e.DataInicio, e.DataFim, e.HoraInicio, e.HoraFim, e.DiaTodo, e.PublicoAlvo, e.PublicoAlvoID, e.CreatedBy,
	).Scan(
		&e.ID, &e.TenantID, &e.SchoolYearID, &e.EventTypeID, &e.Titulo, &e.Descricao,
		&e.DataInicio, &e.DataFim, &e.HoraInicio, &e.HoraFim, &e.DiaTodo, &e.PublicoAlvo,
		&e.PublicoAlvoID, &e.CreatedBy, &e.CreatedAt, &e.UpdatedAt,
	)
}

// ListEvents lista eventos de um ano lectivo.
func (r *CalendarRepository) ListEvents(ctx context.Context, tenantID, schoolYearID int64, start, end *time.Time) ([]models.CalendarEvent, error) {
	where := "tenant_id=$1 AND school_year_id=$2"
	args := []any{tenantID, schoolYearID}
	if start != nil {
		where += " AND data_inicio >= $3"
		args = append(args, *start)
	}
	if end != nil {
		where += " AND (data_fim IS NULL OR data_fim <= $" + string(rune('0'+len(args)+1)) + ")"
		args = append(args, *end)
	}

	rows, err := r.db.Query(ctx, `
		SELECT id, tenant_id, school_year_id, event_type_id, titulo, descricao, data_inicio, data_fim, hora_inicio, hora_fim, dia_todo, publico_alvo, publico_alvo_id, created_by, created_at, updated_at
		FROM gestao_escolar.school_calendar_events
		WHERE `+where+` ORDER BY data_inicio`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []models.CalendarEvent
	for rows.Next() {
		e, err := scanCalendarEvent(rows)
		if err != nil {
			return nil, err
		}
		events = append(events, *e)
	}
	return events, rows.Err()
}

// GetEventByID obtém evento.
func (r *CalendarRepository) GetEventByID(ctx context.Context, id, tenantID int64) (*models.CalendarEvent, error) {
	return scanCalendarEvent(r.db.QueryRow(ctx, `
		SELECT id, tenant_id, school_year_id, event_type_id, titulo, descricao, data_inicio, data_fim, hora_inicio, hora_fim, dia_todo, publico_alvo, publico_alvo_id, created_by, created_at, updated_at
		FROM gestao_escolar.school_calendar_events
		WHERE id=$1 AND tenant_id=$2`, id, tenantID))
}

var calendarEventUpdatableColumns = map[string]bool{
	"school_year_id": true, "event_type_id": true, "titulo": true, "descricao": true,
	"data_inicio": true, "data_fim": true, "hora_inicio": true, "hora_fim": true,
	"dia_todo": true, "publico_alvo": true, "publico_alvo_id": true,
}

// UpdateEvent actualiza evento.
func (r *CalendarRepository) UpdateEvent(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	return updateByFields(ctx, r.db, "gestao_escolar.school_calendar_events", id, tenantID, fields, calendarEventUpdatableColumns, true)
}

// DeleteEvent remove evento.
func (r *CalendarRepository) DeleteEvent(ctx context.Context, id, tenantID int64) error {
	return deleteByID(ctx, r.db, "gestao_escolar.school_calendar_events", id, tenantID)
}

// --- Event Types ---

// CreateEventType cria tipo.
func (r *CalendarRepository) CreateEventType(ctx context.Context, et *models.CalendarEventType) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_calendar_event_types (tenant_id, codigo, nome, cor, impacto_frequencia, dia_todo)
		VALUES ($1,$2,$3,$4,$5,$6)
		RETURNING id, tenant_id, codigo, nome, cor, impacto_frequencia, dia_todo, activo, created_at`,
		et.TenantID, et.Codigo, et.Nome, et.Cor, et.ImpactoFrequencia, et.DiaTodo,
	).Scan(&et.ID, &et.TenantID, &et.Codigo, &et.Nome, &et.Cor, &et.ImpactoFrequencia, &et.DiaTodo, &et.Activo, &et.CreatedAt)
}

// ListEventTypes lista tipos.
func (r *CalendarRepository) ListEventTypes(ctx context.Context, tenantID int64) ([]models.CalendarEventType, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, tenant_id, codigo, nome, cor, impacto_frequencia, dia_todo, activo, created_at
		FROM gestao_escolar.school_calendar_event_types
		WHERE tenant_id=$1 AND activo ORDER BY nome`, tenantID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var types []models.CalendarEventType
	for rows.Next() {
		var et models.CalendarEventType
		err := rows.Scan(&et.ID, &et.TenantID, &et.Codigo, &et.Nome, &et.Cor, &et.ImpactoFrequencia, &et.DiaTodo, &et.Activo, &et.CreatedAt)
		if err != nil {
			return nil, err
		}
		types = append(types, et)
	}
	return types, rows.Err()
}
