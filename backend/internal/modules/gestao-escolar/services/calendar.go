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

// CalendarService lógica do calendário.
type CalendarService struct {
	repo *repositories.CalendarRepository
}

// NewCalendarService cria serviço.
func NewCalendarService(repo *repositories.CalendarRepository) *CalendarService {
	return &CalendarService{repo: repo}
}

var (
	ErrCalendarNotFound    = errors.New("evento nao encontrado")
	ErrCalendarInvalidData = errors.New("dados do evento invalidos")
)

func (s *CalendarService) normalizeEvent(e *models.CalendarEvent) {
	e.Titulo = strings.TrimSpace(e.Titulo)
	e.PublicoAlvo = strings.ToLower(strings.TrimSpace(e.PublicoAlvo))
	if e.PublicoAlvo == "" {
		e.PublicoAlvo = "todos"
	}
	if e.DataInicio.IsZero() {
		e.DataInicio = time.Now()
	}
}

// CreateEventType cria tipo.
func (s *CalendarService) CreateEventType(ctx context.Context, et *models.CalendarEventType) error {
	et.Codigo = strings.TrimSpace(et.Codigo)
	et.Nome = strings.TrimSpace(et.Nome)
	if et.TenantID == 0 || et.Codigo == "" || et.Nome == "" {
		return ErrCalendarInvalidData
	}
	if et.ImpactoFrequencia == "" {
		et.ImpactoFrequencia = "nenhum"
	}
	return s.repo.CreateEventType(ctx, et)
}

// ListEventTypes lista tipos.
func (s *CalendarService) ListEventTypes(ctx context.Context, tenantID int64) ([]models.CalendarEventType, error) {
	return s.repo.ListEventTypes(ctx, tenantID)
}

// CreateEvent cria evento.
func (s *CalendarService) CreateEvent(ctx context.Context, e *models.CalendarEvent) error {
	s.normalizeEvent(e)
	if e.TenantID == 0 || e.SchoolYearID == 0 || e.Titulo == "" {
		return ErrCalendarInvalidData
	}
	return s.repo.CreateEvent(ctx, e)
}

// ListEvents lista eventos.
func (s *CalendarService) ListEvents(ctx context.Context, tenantID, schoolYearID int64, start, end *time.Time) ([]models.CalendarEvent, error) {
	return s.repo.ListEvents(ctx, tenantID, schoolYearID, start, end)
}

// GetEvent obtém evento.
func (s *CalendarService) GetEvent(ctx context.Context, id, tenantID int64) (*models.CalendarEvent, error) {
	e, err := s.repo.GetEventByID(ctx, id, tenantID)
	if err == pgx.ErrNoRows {
		return nil, ErrCalendarNotFound
	}
	return e, err
}

// UpdateEvent actualiza evento.
func (s *CalendarService) UpdateEvent(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	if len(fields) == 0 {
		return ErrCalendarInvalidData
	}
	if err := s.repo.UpdateEvent(ctx, id, tenantID, fields); err != nil {
		if err == pgx.ErrNoRows {
			return ErrCalendarNotFound
		}
		return err
	}
	return nil
}

// DeleteEvent remove evento.
func (s *CalendarService) DeleteEvent(ctx context.Context, id, tenantID int64) error {
	if err := s.repo.DeleteEvent(ctx, id, tenantID); err != nil {
		if err == pgx.ErrNoRows {
			return ErrCalendarNotFound
		}
		return err
	}
	return nil
}
