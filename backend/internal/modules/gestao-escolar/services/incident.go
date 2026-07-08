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

// IncidentService lógica de ocorrências.
type IncidentService struct {
	repo *repositories.IncidentRepository
}

// NewIncidentService cria serviço.
func NewIncidentService(repo *repositories.IncidentRepository) *IncidentService {
	return &IncidentService{repo: repo}
}

var (
	ErrIncidentNotFound    = errors.New("ocorrencia nao encontrada")
	ErrIncidentInvalidData = errors.New("dados da ocorrencia invalidos")
)

func (s *IncidentService) normalizeIncident(i *models.StudentIncident) {
	i.Status = strings.ToLower(strings.TrimSpace(i.Status))
	if i.Status == "" {
		i.Status = "registada"
	}
	if i.DataOcorrencia.IsZero() {
		i.DataOcorrencia = time.Now()
	}
}

// CreateIncidentType cria tipo.
func (s *IncidentService) CreateIncidentType(ctx context.Context, it *models.IncidentType) error {
	it.Codigo = strings.TrimSpace(it.Codigo)
	it.Nome = strings.TrimSpace(it.Nome)
	if it.TenantID == 0 || it.Codigo == "" || it.Nome == "" {
		return ErrIncidentInvalidData
	}
	if it.Gravidade == "" {
		it.Gravidade = "media"
	}
	return s.repo.CreateIncidentType(ctx, it)
}

// ListIncidentTypes lista tipos.
func (s *IncidentService) ListIncidentTypes(ctx context.Context, tenantID int64) ([]models.IncidentType, error) {
	return s.repo.ListIncidentTypes(ctx, tenantID)
}

// CreateIncident cria ocorrência.
func (s *IncidentService) CreateIncident(ctx context.Context, i *models.StudentIncident) error {
	s.normalizeIncident(i)
	if i.TenantID == 0 || i.SchoolYearID == 0 || i.StudentID == 0 || i.ReportedBy == 0 || i.Descricao == "" {
		return ErrIncidentInvalidData
	}
	return s.repo.CreateIncident(ctx, i)
}

// ListIncidents lista ocorrências.
func (s *IncidentService) ListIncidents(ctx context.Context, tenantID, studentID, schoolYearID int64) ([]models.StudentIncident, error) {
	return s.repo.ListIncidents(ctx, tenantID, studentID, schoolYearID)
}

// GetIncident obtém ocorrência.
func (s *IncidentService) GetIncident(ctx context.Context, id, tenantID int64) (*models.StudentIncident, error) {
	i, err := s.repo.GetIncidentByID(ctx, id, tenantID)
	if err == pgx.ErrNoRows {
		return nil, ErrIncidentNotFound
	}
	return i, err
}

// UpdateIncident actualiza ocorrência.
func (s *IncidentService) UpdateIncident(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	if len(fields) == 0 {
		return ErrIncidentInvalidData
	}
	if err := s.repo.UpdateIncident(ctx, id, tenantID, fields); err != nil {
		if err == pgx.ErrNoRows {
			return ErrIncidentNotFound
		}
		if errors.Is(err, repositories.ErrInvalidColumn) {
			return ErrIncidentInvalidData
		}
		return err
	}
	return nil
}

// CreateSanction cria sanção.
func (s *IncidentService) CreateSanction(ctx context.Context, sanction *models.StudentSanction) error {
	if sanction.TenantID == 0 || sanction.IncidentID == 0 || sanction.AplicadoPor == 0 {
		return ErrIncidentInvalidData
	}
	if sanction.DataInicio.IsZero() {
		sanction.DataInicio = time.Now()
	}
	return s.repo.CreateSanction(ctx, sanction)
}

// CreateMerit cria mérito.
func (s *IncidentService) CreateMerit(ctx context.Context, m *models.StudentMerit) error {
	m.Titulo = strings.TrimSpace(m.Titulo)
	if m.TenantID == 0 || m.SchoolYearID == 0 || m.StudentID == 0 || m.Titulo == "" {
		return ErrIncidentInvalidData
	}
	if m.DataMerito.IsZero() {
		m.DataMerito = time.Now()
	}
	return s.repo.CreateMerit(ctx, m)
}
