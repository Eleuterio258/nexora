package services

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/repositories"
)

// TimetableService lógica de horários.
type TimetableService struct {
	repo *repositories.TimetableRepository
}

// NewTimetableService cria serviço.
func NewTimetableService(repo *repositories.TimetableRepository) *TimetableService {
	return &TimetableService{repo: repo}
}

var (
	ErrTimetableNotFound    = errors.New("entrada de horario nao encontrada")
	ErrTimetableInvalidData = errors.New("dados do horario invalidos")
	ErrTimetableConflict    = errors.New("conflito de horario detectado")
	ErrTimetableInvalidSlot = errors.New("horario invalido")
)

func parseTime(value string) (time.Time, error) {
	return time.Parse("15:04", value)
}

func (s *TimetableService) normalizeEntry(e *models.TimetableEntry) {
	if e.DataInicio.IsZero() {
		e.DataInicio = time.Now()
	}
	e.Sala = strings.TrimSpace(e.Sala)
}

// CreateTimeSlot cria slot.
func (s *TimetableService) CreateTimeSlot(ctx context.Context, ts *models.TimeSlot) error {
	ts.Codigo = strings.TrimSpace(ts.Codigo)
	ts.Nome = strings.TrimSpace(ts.Nome)
	ts.HoraInicio = strings.TrimSpace(ts.HoraInicio)
	ts.HoraFim = strings.TrimSpace(ts.HoraFim)

	if ts.TenantID == 0 || ts.Codigo == "" || ts.HoraInicio == "" || ts.HoraFim == "" {
		return ErrTimetableInvalidData
	}
	start, err := parseTime(ts.HoraInicio)
	if err != nil {
		return ErrTimetableInvalidSlot
	}
	end, err := parseTime(ts.HoraFim)
	if err != nil {
		return ErrTimetableInvalidSlot
	}
	if !end.After(start) {
		return ErrTimetableInvalidSlot
	}
	return s.repo.CreateTimeSlot(ctx, ts)
}

// ListTimeSlots lista slots.
func (s *TimetableService) ListTimeSlots(ctx context.Context, tenantID int64) ([]models.TimeSlot, error) {
	return s.repo.ListTimeSlots(ctx, tenantID)
}

// GetTimeSlot obtém slot.
func (s *TimetableService) GetTimeSlot(ctx context.Context, id, tenantID int64) (*models.TimeSlot, error) {
	ts, err := s.repo.GetTimeSlotByID(ctx, id, tenantID)
	if err == pgx.ErrNoRows {
		return nil, ErrTimetableNotFound
	}
	return ts, err
}

// CreateEntry cria entrada de horário com validação de conflitos.
func (s *TimetableService) CreateEntry(ctx context.Context, e *models.TimetableEntry) error {
	s.normalizeEntry(e)
	if e.TenantID == 0 || e.SchoolYearID == 0 || e.ClassID == 0 || e.SubjectID == 0 || e.TeacherID == 0 || e.TimeSlotID == 0 || e.DiaSemana < 1 || e.DiaSemana > 7 {
		return ErrTimetableInvalidData
	}
	if err := s.repo.CheckConflicts(ctx, e, 0); err != nil {
		return ErrTimetableConflict
	}
	return s.repo.Create(ctx, e)
}

// UpdateEntry actualiza entrada.
func (s *TimetableService) UpdateEntry(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	if len(fields) == 0 {
		return ErrTimetableInvalidData
	}
	if err := s.repo.Update(ctx, id, tenantID, fields); err != nil {
		if err == pgx.ErrNoRows {
			return ErrTimetableNotFound
		}
		if errors.Is(err, repositories.ErrInvalidColumn) {
			return ErrTimetableInvalidData
		}
		return err
	}
	return nil
}

// DeleteEntry remove entrada.
func (s *TimetableService) DeleteEntry(ctx context.Context, id, tenantID int64) error {
	if err := s.repo.Delete(ctx, id, tenantID); err != nil {
		if err == pgx.ErrNoRows {
			return ErrTimetableNotFound
		}
		return err
	}
	return nil
}

// ListByClass lista horário por turma.
func (s *TimetableService) ListByClass(ctx context.Context, classID, tenantID int64) ([]models.TimetableEntry, error) {
	return s.repo.ListByClass(ctx, classID, tenantID)
}

// ListByTeacher lista horário por professor.
func (s *TimetableService) ListByTeacher(ctx context.Context, teacherID, tenantID int64) ([]models.TimetableEntry, error) {
	return s.repo.ListByTeacher(ctx, teacherID, tenantID)
}
