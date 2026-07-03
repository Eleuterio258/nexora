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

// GradeService lógica de notas.
type GradeService struct {
	repo *repositories.GradeRepository
}

// NewGradeService cria serviço.
func NewGradeService(repo *repositories.GradeRepository) *GradeService {
	return &GradeService{repo: repo}
}

var (
	ErrGradeNotFound    = errors.New("avaliacao/nota nao encontrada")
	ErrGradeInvalidData = errors.New("dados invalidos")
	ErrGradeOutOfRange  = errors.New("nota fora do intervalo permitido")
	ErrGradeNotPublished = errors.New("notas ainda nao publicadas")
)

func (s *GradeService) normalizeItem(g *models.GradeItem) {
	g.Nome = strings.TrimSpace(g.Nome)
	g.Tipo = strings.ToLower(strings.TrimSpace(g.Tipo))
	if g.Tipo == "" {
		g.Tipo = "teste"
	}
	if g.NotaMaxima <= 0 {
		g.NotaMaxima = 20
	}
	if g.Peso <= 0 {
		g.Peso = 1
	}
	if g.DataAvaliacao.IsZero() {
		g.DataAvaliacao = time.Now()
	}
}

// CreateItem cria avaliação.
func (s *GradeService) CreateItem(ctx context.Context, g *models.GradeItem) error {
	s.normalizeItem(g)
	if g.TenantID == 0 || g.ClassID == 0 || g.SubjectID == 0 || g.TermID == 0 || g.Nome == "" {
		return ErrGradeInvalidData
	}
	return s.repo.CreateItem(ctx, g)
}

// GetItem obtém avaliação.
func (s *GradeService) GetItem(ctx context.Context, id, tenantID int64) (*models.GradeItem, error) {
	g, err := s.repo.GetItemByID(ctx, id, tenantID)
	if err == pgx.ErrNoRows {
		return nil, ErrGradeNotFound
	}
	return g, err
}

// ListItems lista avaliações.
func (s *GradeService) ListItems(ctx context.Context, tenantID, classID, subjectID, termID int64) ([]models.GradeItem, error) {
	return s.repo.ListItems(ctx, tenantID, classID, subjectID, termID)
}

// PublishItem publica/oculta notas.
func (s *GradeService) PublishItem(ctx context.Context, id, tenantID int64, published bool) error {
	if err := s.repo.PublishItem(ctx, id, tenantID, published); err != nil {
		if err == pgx.ErrNoRows {
			return ErrGradeNotFound
		}
		return err
	}
	return nil
}

// UpsertGrade lança ou corrige nota.
func (s *GradeService) UpsertGrade(ctx context.Context, g *models.Grade) error {
	if g.TenantID == 0 || g.GradeItemID == 0 || g.StudentID == 0 {
		return ErrGradeInvalidData
	}
	item, err := s.GetItem(ctx, g.GradeItemID, g.TenantID)
	if err != nil {
		return err
	}
	if g.Nota < 0 || g.Nota > item.NotaMaxima {
		return ErrGradeOutOfRange
	}
	return s.repo.UpsertGrade(ctx, g)
}

// GetGrade obtém nota.
func (s *GradeService) GetGrade(ctx context.Context, id, tenantID int64) (*models.Grade, error) {
	g, err := s.repo.GetGradeByID(ctx, id, tenantID)
	if err == pgx.ErrNoRows {
		return nil, ErrGradeNotFound
	}
	return g, err
}

// StudentReport devolve médias por disciplina (apenas itens publicados).
func (s *GradeService) StudentReport(ctx context.Context, studentID, termID, tenantID int64) (map[string]any, error) {
	averages, err := s.repo.StudentAverages(ctx, studentID, termID, tenantID)
	if err != nil {
		return nil, err
	}
	return map[string]any{
		"student_id":  studentID,
		"term_id":     termID,
		"disciplinas": averages,
	}, nil
}
