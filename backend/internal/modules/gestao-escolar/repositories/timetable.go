package repositories

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/gestao-escolar/models"
)

// TimetableRepository acesso a dados de horários.
type TimetableRepository struct {
	db DB
}

// NewTimetableRepository cria repositório.
func NewTimetableRepository(db DB) *TimetableRepository {
	return &TimetableRepository{db: db}
}

func scanTimetableEntry(row pgx.Row) (*models.TimetableEntry, error) {
	var e models.TimetableEntry
	err := row.Scan(
		&e.ID, &e.TenantID, &e.SchoolYearID, &e.ClassID, &e.SubjectID, &e.TeacherID,
		&e.TimeSlotID, &e.DiaSemana, &e.Sala, &e.DataInicio, &e.DataFim, &e.Activo,
		&e.CreatedAt, &e.UpdatedAt,
	)
	return &e, err
}

// Create cria uma entrada de horário.
func (r *TimetableRepository) Create(ctx context.Context, e *models.TimetableEntry) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_timetable_entries
		(tenant_id, school_year_id, class_id, subject_id, teacher_id, time_slot_id, dia_semana, sala, data_inicio, data_fim)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
		RETURNING id, tenant_id, school_year_id, class_id, subject_id, teacher_id, time_slot_id, dia_semana, sala, data_inicio, data_fim, activo, created_at, updated_at`,
		e.TenantID, e.SchoolYearID, e.ClassID, e.SubjectID, e.TeacherID, e.TimeSlotID, e.DiaSemana, e.Sala, e.DataInicio, e.DataFim,
	).Scan(
		&e.ID, &e.TenantID, &e.SchoolYearID, &e.ClassID, &e.SubjectID, &e.TeacherID,
		&e.TimeSlotID, &e.DiaSemana, &e.Sala, &e.DataInicio, &e.DataFim, &e.Activo, &e.CreatedAt, &e.UpdatedAt,
	)
}

// GetByID obtém entrada.
func (r *TimetableRepository) GetByID(ctx context.Context, id, tenantID int64) (*models.TimetableEntry, error) {
	return scanTimetableEntry(r.db.QueryRow(ctx, `
		SELECT id, tenant_id, school_year_id, class_id, subject_id, teacher_id, time_slot_id, dia_semana, sala, data_inicio, data_fim, activo, created_at, updated_at
		FROM gestao_escolar.school_timetable_entries
		WHERE id=$1 AND tenant_id=$2`, id, tenantID))
}

// ListByClass lista horário de uma turma.
func (r *TimetableRepository) ListByClass(ctx context.Context, classID, tenantID int64) ([]models.TimetableEntry, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, tenant_id, school_year_id, class_id, subject_id, teacher_id, time_slot_id, dia_semana, sala, data_inicio, data_fim, activo, created_at, updated_at
		FROM gestao_escolar.school_timetable_entries
		WHERE class_id=$1 AND tenant_id=$2 AND activo
		ORDER BY dia_semana, time_slot_id`, classID, tenantID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var entries []models.TimetableEntry
	for rows.Next() {
		e, err := scanTimetableEntry(rows)
		if err != nil {
			return nil, err
		}
		entries = append(entries, *e)
	}
	return entries, rows.Err()
}

// ListByTeacher lista horário de um professor.
func (r *TimetableRepository) ListByTeacher(ctx context.Context, teacherID, tenantID int64) ([]models.TimetableEntry, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, tenant_id, school_year_id, class_id, subject_id, teacher_id, time_slot_id, dia_semana, sala, data_inicio, data_fim, activo, created_at, updated_at
		FROM gestao_escolar.school_timetable_entries
		WHERE teacher_id=$1 AND tenant_id=$2 AND activo
		ORDER BY dia_semana, time_slot_id`, teacherID, tenantID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var entries []models.TimetableEntry
	for rows.Next() {
		e, err := scanTimetableEntry(rows)
		if err != nil {
			return nil, err
		}
		entries = append(entries, *e)
	}
	return entries, rows.Err()
}

var timetableUpdatableColumns = map[string]bool{
	"school_year_id": true, "class_id": true, "subject_id": true, "teacher_id": true,
	"time_slot_id": true, "dia_semana": true, "sala": true, "data_inicio": true,
	"data_fim": true, "activo": true,
}

// Update actualiza entrada.
func (r *TimetableRepository) Update(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	return updateByFields(ctx, r.db, "gestao_escolar.school_timetable_entries", id, tenantID, fields, timetableUpdatableColumns, true)
}

// Delete remove entrada.
func (r *TimetableRepository) Delete(ctx context.Context, id, tenantID int64) error {
	return deleteByID(ctx, r.db, "gestao_escolar.school_timetable_entries", id, tenantID)
}

// CheckConflicts verifica conflitos de professor ou sala no mesmo slot.
func (r *TimetableRepository) CheckConflicts(ctx context.Context, e *models.TimetableEntry, excludeID int64) error {
	args := []any{e.TenantID, e.SchoolYearID, e.DiaSemana, e.TimeSlotID, e.DataInicio}
	where := "tenant_id=$1 AND school_year_id=$2 AND dia_semana=$3 AND time_slot_id=$4 AND data_inicio<=$5 AND (data_fim IS NULL OR data_fim>=$5) AND activo"
	if excludeID > 0 {
		where += " AND id <> $6"
		args = append(args, excludeID)
	}

	// Professor em duas turmas ao mesmo tempo
	var teacherConflicts int
	err := r.db.QueryRow(ctx, fmt.Sprintf(`
		SELECT COUNT(*) FROM gestao_escolar.school_timetable_entries
		WHERE %s AND teacher_id=$%d`, where, len(args)+1), append(args, e.TeacherID)...).Scan(&teacherConflicts)
	if err != nil {
		return err
	}
	if teacherConflicts > 0 {
		return errors.New("professor ja tem aula neste horario")
	}

	// Sala duplicada
	if e.Sala != "" {
		var roomConflicts int
		err := r.db.QueryRow(ctx, fmt.Sprintf(`
			SELECT COUNT(*) FROM gestao_escolar.school_timetable_entries
			WHERE %s AND sala=$%d AND sala<>''`, where, len(args)+1), append(args, e.Sala)...).Scan(&roomConflicts)
		if err != nil {
			return err
		}
		if roomConflicts > 0 {
			return errors.New("sala ja ocupada neste horario")
		}
	}

	return nil
}

// TimeSlot methods

// CreateTimeSlot cria slot.
func (r *TimetableRepository) CreateTimeSlot(ctx context.Context, ts *models.TimeSlot) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_time_slots (tenant_id, codigo, nome, hora_inicio, hora_fim, ordem)
		VALUES ($1,$2,$3,$4,$5,$6)
		RETURNING id, tenant_id, codigo, nome, hora_inicio, hora_fim, ordem, activo, created_at, updated_at`,
		ts.TenantID, ts.Codigo, ts.Nome, ts.HoraInicio, ts.HoraFim, ts.Ordem,
	).Scan(&ts.ID, &ts.TenantID, &ts.Codigo, &ts.Nome, &ts.HoraInicio, &ts.HoraFim, &ts.Ordem, &ts.Activo, &ts.CreatedAt, &ts.UpdatedAt)
}

// ListTimeSlots lista slots.
func (r *TimetableRepository) ListTimeSlots(ctx context.Context, tenantID int64) ([]models.TimeSlot, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, tenant_id, codigo, nome, hora_inicio, hora_fim, ordem, activo, created_at, updated_at
		FROM gestao_escolar.school_time_slots
		WHERE tenant_id=$1 AND activo ORDER BY ordem, hora_inicio`, tenantID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var slots []models.TimeSlot
	for rows.Next() {
		var ts models.TimeSlot
		err := rows.Scan(&ts.ID, &ts.TenantID, &ts.Codigo, &ts.Nome, &ts.HoraInicio, &ts.HoraFim, &ts.Ordem, &ts.Activo, &ts.CreatedAt, &ts.UpdatedAt)
		if err != nil {
			return nil, err
		}
		slots = append(slots, ts)
	}
	return slots, rows.Err()
}

// GetTimeSlotByID obtém slot.
func (r *TimetableRepository) GetTimeSlotByID(ctx context.Context, id, tenantID int64) (*models.TimeSlot, error) {
	var ts models.TimeSlot
	err := r.db.QueryRow(ctx, `
		SELECT id, tenant_id, codigo, nome, hora_inicio, hora_fim, ordem, activo, created_at, updated_at
		FROM gestao_escolar.school_time_slots
		WHERE id=$1 AND tenant_id=$2`, id, tenantID).Scan(&ts.ID, &ts.TenantID, &ts.Codigo, &ts.Nome, &ts.HoraInicio, &ts.HoraFim, &ts.Ordem, &ts.Activo, &ts.CreatedAt, &ts.UpdatedAt)
	return &ts, err
}

// parseTime auxiliar para converter string HH:MM em time.Time.
func parseTime(value string) (time.Time, error) {
	return time.Parse("15:04", value)
}

// durationMinutes calcula duração em minutos entre duas strings HH:MM.
func durationMinutes(start, end string) (int, error) {
	s, err := parseTime(start)
	if err != nil {
		return 0, err
	}
	e, err := parseTime(end)
	if err != nil {
		return 0, err
	}
	return int(e.Sub(s).Minutes()), nil
}
