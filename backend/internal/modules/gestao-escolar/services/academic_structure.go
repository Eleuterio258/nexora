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
		if errors.Is(err, repositories.ErrInvalidColumn) {
			return ErrAcademicInvalidData
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
		if errors.Is(err, repositories.ErrInvalidColumn) {
			return ErrAcademicInvalidData
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
		if errors.Is(err, repositories.ErrInvalidColumn) {
			return ErrAcademicInvalidData
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

// --- Cycles ---

// CreateCycle cria um ciclo dentro de um nível.
func (s *AcademicStructureService) CreateCycle(ctx context.Context, c *models.Cycle) error {
	c.Codigo, c.Nome = normalizeCodeName(c.Codigo, c.Nome)
	if c.TenantID == 0 || c.LevelID == 0 || c.Codigo == "" || c.Nome == "" {
		return ErrAcademicInvalidData
	}
	return s.repo.CreateCycle(ctx, c)
}

// ListCycles lista ciclos, opcionalmente filtrados por nível.
func (s *AcademicStructureService) ListCycles(ctx context.Context, tenantID, levelID int64) ([]models.Cycle, error) {
	return s.repo.ListCycles(ctx, tenantID, levelID)
}

// GetCycle obtém um ciclo.
func (s *AcademicStructureService) GetCycle(ctx context.Context, id, tenantID int64) (*models.Cycle, error) {
	c, err := s.repo.GetCycleByID(ctx, id, tenantID)
	if err == pgx.ErrNoRows {
		return nil, ErrAcademicNotFound
	}
	return c, err
}

// UpdateCycle actualiza um ciclo.
func (s *AcademicStructureService) UpdateCycle(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	if len(fields) == 0 {
		return ErrAcademicInvalidData
	}
	if err := s.repo.UpdateCycle(ctx, id, tenantID, fields); err != nil {
		if err == pgx.ErrNoRows {
			return ErrAcademicNotFound
		}
		if errors.Is(err, repositories.ErrInvalidColumn) {
			return ErrAcademicInvalidData
		}
		return err
	}
	return nil
}

// DeleteCycle remove um ciclo.
func (s *AcademicStructureService) DeleteCycle(ctx context.Context, id, tenantID int64) error {
	if err := s.repo.DeleteCycle(ctx, id, tenantID); err != nil {
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

// --- CourseSubjects (currículo) ---

// CreateCourseSubject associa uma disciplina a um curso, nível ou série — é a
// operação que permite a cada escola (tenant) definir livremente o seu currículo.
func (s *AcademicStructureService) CreateCourseSubject(ctx context.Context, cs *models.CourseSubject) error {
	cs.Componente = strings.TrimSpace(cs.Componente)
	if cs.TenantID == 0 || cs.SubjectID == 0 {
		return ErrAcademicInvalidData
	}
	semAmbito := (cs.CourseID == nil || *cs.CourseID == 0) &&
		(cs.LevelID == nil || *cs.LevelID == 0) &&
		(cs.SeriesID == nil || *cs.SeriesID == 0)
	if semAmbito {
		return ErrAcademicInvalidData
	}
	if cs.Componente == "" {
		cs.Componente = "teorica"
	}
	if cs.Obrigatoria == nil {
		obrigatoria := true
		cs.Obrigatoria = &obrigatoria
	}
	return s.repo.CreateCourseSubject(ctx, cs)
}

// ListCourseSubjects lista o currículo, opcionalmente filtrado.
func (s *AcademicStructureService) ListCourseSubjects(ctx context.Context, tenantID int64, f repositories.ListCourseSubjectsFilter) ([]models.CourseSubject, error) {
	return s.repo.ListCourseSubjects(ctx, tenantID, f)
}

// GetCourseSubject obtém um item do currículo.
func (s *AcademicStructureService) GetCourseSubject(ctx context.Context, id, tenantID int64) (*models.CourseSubject, error) {
	cs, err := s.repo.GetCourseSubjectByID(ctx, id, tenantID)
	if err == pgx.ErrNoRows {
		return nil, ErrAcademicNotFound
	}
	return cs, err
}

// UpdateCourseSubject actualiza um item do currículo.
func (s *AcademicStructureService) UpdateCourseSubject(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	if len(fields) == 0 {
		return ErrAcademicInvalidData
	}
	if err := s.repo.UpdateCourseSubject(ctx, id, tenantID, fields); err != nil {
		if err == pgx.ErrNoRows {
			return ErrAcademicNotFound
		}
		if errors.Is(err, repositories.ErrInvalidColumn) {
			return ErrAcademicInvalidData
		}
		return err
	}
	return nil
}

// DeleteCourseSubject remove um item do currículo.
func (s *AcademicStructureService) DeleteCourseSubject(ctx context.Context, id, tenantID int64) error {
	if err := s.repo.DeleteCourseSubject(ctx, id, tenantID); err != nil {
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

// --- CourseSubjectTerms ---

// CreateCourseSubjectTerm configura a presença/exame de uma disciplina num período.
// Ausência de configuração para um período significa que a disciplina não é leccionada nesse período.
func (s *AcademicStructureService) CreateCourseSubjectTerm(ctx context.Context, t *models.CourseSubjectTerm) error {
	if t.TenantID == 0 || t.CourseSubjectID == 0 || t.TermID == 0 {
		return ErrAcademicInvalidData
	}
	return s.repo.CreateCourseSubjectTerm(ctx, t)
}

// ListCourseSubjectTerms lista a configuração por período de um item do currículo.
func (s *AcademicStructureService) ListCourseSubjectTerms(ctx context.Context, tenantID, courseSubjectID int64) ([]models.CourseSubjectTerm, error) {
	return s.repo.ListCourseSubjectTerms(ctx, tenantID, courseSubjectID)
}

// UpdateCourseSubjectTerm actualiza a configuração de uma disciplina num período.
func (s *AcademicStructureService) UpdateCourseSubjectTerm(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	if len(fields) == 0 {
		return ErrAcademicInvalidData
	}
	if err := s.repo.UpdateCourseSubjectTerm(ctx, id, tenantID, fields); err != nil {
		if err == pgx.ErrNoRows {
			return ErrAcademicNotFound
		}
		if errors.Is(err, repositories.ErrInvalidColumn) {
			return ErrAcademicInvalidData
		}
		return err
	}
	return nil
}

// DeleteCourseSubjectTerm remove a configuração de uma disciplina num período.
func (s *AcademicStructureService) DeleteCourseSubjectTerm(ctx context.Context, id, tenantID int64) error {
	if err := s.repo.DeleteCourseSubjectTerm(ctx, id, tenantID); err != nil {
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
