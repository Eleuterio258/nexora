package services

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/repositories"
)

// ClassService lógica de negócio de turmas.
type ClassService struct {
	repo *repositories.ClassRepository
}

// NewClassService cria serviço de turmas.
func NewClassService(repo *repositories.ClassRepository) *ClassService {
	return &ClassService{repo: repo}
}

var (
	ErrClassNotFound      = errors.New("turma nao encontrada")
	ErrClassInvalidData   = errors.New("dados da turma invalidos")
	ErrClassDuplicateCode = errors.New("codigo da turma ja existe")
	ErrClassFull          = errors.New("turma atingiu a capacidade maxima")
)

func (s *ClassService) normalize(c *models.Class) {
	c.Codigo = strings.TrimSpace(c.Codigo)
	c.Nome = strings.TrimSpace(c.Nome)
	c.Turno = strings.ToLower(strings.TrimSpace(c.Turno))
	if c.Turno == "" {
		c.Turno = "manha"
	}
	if c.Capacidade < 0 {
		c.Capacidade = 0
	}
}

// Create cria uma turma.
func (s *ClassService) Create(ctx context.Context, c *models.Class) error {
	s.normalize(c)
	if c.TenantID == 0 || c.Codigo == "" || c.Nome == "" {
		return ErrClassInvalidData
	}
	return s.repo.Create(ctx, c)
}

// GetByID obtém uma turma.
func (s *ClassService) GetByID(ctx context.Context, id, tenantID int64) (*models.Class, error) {
	c, err := s.repo.GetByID(ctx, id, tenantID)
	if err == pgx.ErrNoRows {
		return nil, ErrClassNotFound
	}
	return c, err
}

// CheckCapacity verifica se a turma ainda tem vagas.
func (s *ClassService) CheckCapacity(ctx context.Context, classID, tenantID int64) error {
	c, err := s.GetByID(ctx, classID, tenantID)
	if err != nil {
		return err
	}
	if c.Capacidade <= 0 {
		return nil // sem limite definido
	}
	count, err := s.repo.CountActiveStudents(ctx, classID, tenantID)
	if err != nil {
		return err
	}
	if count >= c.Capacidade {
		return ErrClassFull
	}
	return nil
}

// Update actualiza uma turma.
func (s *ClassService) Update(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	if len(fields) == 0 {
		return ErrClassInvalidData
	}
	if err := s.repo.Update(ctx, id, tenantID, fields); err != nil {
		if err == pgx.ErrNoRows {
			return ErrClassNotFound
		}
		return err
	}
	return nil
}
