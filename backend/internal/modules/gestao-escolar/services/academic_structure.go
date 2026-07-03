package services

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/repositories"
)

// AcademicStructureService contém a lógica de negócio da estrutura académica.
type AcademicStructureService struct {
	repo *repositories.AcademicStructureRepository
}

// NewAcademicStructureService cria um novo serviço.
func NewAcademicStructureService(repo *repositories.AcademicStructureRepository) *AcademicStructureService {
	return &AcademicStructureService{repo: repo}
}

var (
	ErrAcademicNotFound      = errors.New("registo academico nao encontrado")
	ErrAcademicDuplicateCode = errors.New("codigo ja existe")
	ErrAcademicInvalidData   = errors.New("dados invalidos")
	ErrAcademicHasChildren   = errors.New("registo possui dependentes")
)

func normalizeCodeName(code, name string) (string, string) {
	return strings.TrimSpace(code), strings.TrimSpace(name)
}

// --- Levels ---

// CreateLevel cria um nível de ensino.
func (s *AcademicStructureService) CreateLevel(ctx context.Context, l *models.Level) error {
	l.Codigo, l.Nome = normalizeCodeName(l.Codigo, l.Nome)
	if l.TenantID == 0 || l.Codigo == "" || l.Nome == "" {
		return ErrAcademicInvalidData
	}
	if l.SistemaAvaliacao == "" {
		l.SistemaAvaliacao = "0-20"
	}
	if l.NotaMinimaAprovacao <= 0 {
		l.NotaMinimaAprovacao = 10
	}
	if l.EscalaMaxima <= 0 {
		l.EscalaMaxima = 20
	}
	if l.NumeroPeriodosPadrao <= 0 {
		l.NumeroPeriodosPadrao = 3
	}
	if l.NomenclaturaPeriodo == "" {
		l.NomenclaturaPeriodo = "trimestre"
	}
	if l.NomenclaturaSerie == "" {
		l.NomenclaturaSerie = "classe"
	}
	return s.repo.CreateLevel(ctx, l)
}

// ListLevels lista níveis.
func (s *AcademicStructureService) ListLevels(ctx context.Context, tenantID int64) ([]models.Level, error) {
	return s.repo.ListLevels(ctx, tenantID)
}

// GetLevel obtém um nível.
func (s *AcademicStructureService) GetLevel(ctx context.Context, id, tenantID int64) (*models.Level, error) {
	l, err := s.repo.GetLevelByID(ctx, id, tenantID)
	if err == pgx.ErrNoRows {
		return nil, ErrAcademicNotFound
	}
	return l, err
}

// UpdateLevel actualiza um nível.
func (s *AcademicStructureService) UpdateLevel(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	if len(fields) == 0 {
		return ErrAcademicInvalidData
	}
	if code, ok := fields["codigo"]; ok {
		fields["codigo"] = strings.TrimSpace(code.(string))
	}
	if name, ok := fields["nome"]; ok {
		fields["nome"] = strings.TrimSpace(name.(string))
	}
	if err := s.repo.UpdateLevel(ctx, id, tenantID, fields); err != nil {
		if err == pgx.ErrNoRows {
			return ErrAcademicNotFound
		}
		return err
	}
	return nil
}

// DeleteLevel remove um nível.
func (s *AcademicStructureService) DeleteLevel(ctx context.Context, id, tenantID int64) error {
	if err := s.repo.DeleteLevel(ctx, id, tenantID); err != nil {
		if err == pgx.ErrNoRows {
			return ErrAcademicNotFound
		}
		if isFKViolation(err) {
			return ErrAcademicHasChildren
		}
		return err
	}
	return nil
}

// --- Series ---

// CreateSeries cria uma série.
func (s *AcademicStructureService) CreateSeries(ctx context.Context, series *models.Series) error {
	series.Codigo, series.Nome = normalizeCodeName(series.Codigo, series.Nome)
	if series.TenantID == 0 || series.LevelID == 0 || series.Codigo == "" || series.Nome == "" {
		return ErrAcademicInvalidData
	}
	return s.repo.CreateSeries(ctx, series)
}

// ListSeries lista séries.
func (s *AcademicStructureService) ListSeries(ctx context.Context, tenantID, levelID int64) ([]models.Series, error) {
	return s.repo.ListSeries(ctx, tenantID, levelID)
}

// GetSeries obtém uma série.
func (s *AcademicStructureService) GetSeries(ctx context.Context, id, tenantID int64) (*models.Series, error) {
	series, err := s.repo.GetSeriesByID(ctx, id, tenantID)
	if err == pgx.ErrNoRows {
		return nil, ErrAcademicNotFound
	}
	return series, err
}

// UpdateSeries actualiza uma série.
func (s *AcademicStructureService) UpdateSeries(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	if len(fields) == 0 {
		return ErrAcademicInvalidData
	}
	if err := s.repo.UpdateSeries(ctx, id, tenantID, fields); err != nil {
		if err == pgx.ErrNoRows {
			return ErrAcademicNotFound
		}
		return err
	}
	return nil
}

// DeleteSeries remove uma série.
func (s *AcademicStructureService) DeleteSeries(ctx context.Context, id, tenantID int64) error {
	if err := s.repo.DeleteSeries(ctx, id, tenantID); err != nil {
		if err == pgx.ErrNoRows {
			return ErrAcademicNotFound
		}
		if isFKViolation(err) {
			return ErrAcademicHasChildren
		}
		return err
	}
	return nil
}

// --- Courses ---

// CreateCourse cria um curso.
func (s *AcademicStructureService) CreateCourse(ctx context.Context, c *models.Course) error {
	c.Codigo, c.Nome = normalizeCodeName(c.Codigo, c.Nome)
	if c.TenantID == 0 || c.LevelID == 0 || c.Codigo == "" || c.Nome == "" {
		return ErrAcademicInvalidData
	}
	if c.Modalidade == "" {
		c.Modalidade = "presencial"
	}
	if c.DuracaoAnos <= 0 {
		c.DuracaoAnos = 1
	}
	return s.repo.CreateCourse(ctx, c)
}

// ListCourses lista cursos.
func (s *AcademicStructureService) ListCourses(ctx context.Context, tenantID, levelID int64) ([]models.Course, error) {
	return s.repo.ListCourses(ctx, tenantID, levelID)
}

// GetCourse obtém um curso.
func (s *AcademicStructureService) GetCourse(ctx context.Context, id, tenantID int64) (*models.Course, error) {
	c, err := s.repo.GetCourseByID(ctx, id, tenantID)
	if err == pgx.ErrNoRows {
		return nil, ErrAcademicNotFound
	}
	return c, err
}

// UpdateCourse actualiza um curso.
func (s *AcademicStructureService) UpdateCourse(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	if len(fields) == 0 {
		return ErrAcademicInvalidData
	}
	if err := s.repo.UpdateCourse(ctx, id, tenantID, fields); err != nil {
		if err == pgx.ErrNoRows {
			return ErrAcademicNotFound
		}
		return err
	}
	return nil
}

// DeleteCourse remove um curso.
func (s *AcademicStructureService) DeleteCourse(ctx context.Context, id, tenantID int64) error {
	if err := s.repo.DeleteCourse(ctx, id, tenantID); err != nil {
		if err == pgx.ErrNoRows {
			return ErrAcademicNotFound
		}
		if isFKViolation(err) {
			return ErrAcademicHasChildren
		}
		return err
	}
	return nil
}

// isFKViolation detecta violações de chave estrangeira.
func isFKViolation(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()
	return strings.Contains(msg, "foreign key") || strings.Contains(msg, "FOREIGN KEY") ||
		strings.Contains(msg, "23503")
}
