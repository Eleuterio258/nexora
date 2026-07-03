package repositories

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/gestao-escolar/models"
)

// AcademicStructureRepository encapsula CRUDs de níveis, ciclos, séries e cursos.
type AcademicStructureRepository struct {
	db DB
}

// NewAcademicStructureRepository cria um novo repositório.
func NewAcademicStructureRepository(db DB) *AcademicStructureRepository {
	return &AcademicStructureRepository{db: db}
}

// --- Levels ---

func scanLevel(row pgx.Row) (*models.Level, error) {
	var l models.Level
	err := row.Scan(
		&l.ID, &l.TenantID, &l.Codigo, &l.Nome, &l.Descricao, &l.Ordem,
		&l.NotaMinimaAprovacao, &l.EscalaMaxima, &l.SistemaAvaliacao,
		&l.NumeroPeriodosPadrao, &l.NomenclaturaPeriodo, &l.NomenclaturaSerie,
		&l.IdadeMinima, &l.IdadeMaxima, &l.Activo, &l.CreatedAt, &l.UpdatedAt,
	)
	return &l, err
}

// CreateLevel cria um nível de ensino.
func (r *AcademicStructureRepository) CreateLevel(ctx context.Context, l *models.Level) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_levels
		(tenant_id, codigo, nome, descricao, ordem, nota_minima_aprovacao, escala_maxima,
		 sistema_avaliacao, numero_periodos_padrao, nomenclatura_periodo, nomenclatura_serie,
		 idade_minima, idade_maxima)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
		RETURNING id, tenant_id, codigo, nome, descricao, ordem, nota_minima_aprovacao, escala_maxima,
		 sistema_avaliacao, numero_periodos_padrao, nomenclatura_periodo, nomenclatura_serie,
		 idade_minima, idade_maxima, activo, created_at, updated_at`,
		l.TenantID, l.Codigo, l.Nome, l.Descricao, l.Ordem, l.NotaMinimaAprovacao, l.EscalaMaxima,
		l.SistemaAvaliacao, l.NumeroPeriodosPadrao, l.NomenclaturaPeriodo, l.NomenclaturaSerie,
		l.IdadeMinima, l.IdadeMaxima,
	).Scan(
		&l.ID, &l.TenantID, &l.Codigo, &l.Nome, &l.Descricao, &l.Ordem,
		&l.NotaMinimaAprovacao, &l.EscalaMaxima, &l.SistemaAvaliacao,
		&l.NumeroPeriodosPadrao, &l.NomenclaturaPeriodo, &l.NomenclaturaSerie,
		&l.IdadeMinima, &l.IdadeMaxima, &l.Activo, &l.CreatedAt, &l.UpdatedAt,
	)
}

// GetLevelByID obtém um nível.
func (r *AcademicStructureRepository) GetLevelByID(ctx context.Context, id, tenantID int64) (*models.Level, error) {
	return scanLevel(r.db.QueryRow(ctx, `
		SELECT id, tenant_id, codigo, nome, descricao, ordem, nota_minima_aprovacao, escala_maxima,
		 sistema_avaliacao, numero_periodos_padrao, nomenclatura_periodo, nomenclatura_serie,
		 idade_minima, idade_maxima, activo, created_at, updated_at
		FROM gestao_escolar.school_levels WHERE id=$1 AND tenant_id=$2`, id, tenantID))
}

// ListLevels lista níveis de ensino.
func (r *AcademicStructureRepository) ListLevels(ctx context.Context, tenantID int64) ([]models.Level, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, tenant_id, codigo, nome, descricao, ordem, nota_minima_aprovacao, escala_maxima,
		 sistema_avaliacao, numero_periodos_padrao, nomenclatura_periodo, nomenclatura_serie,
		 idade_minima, idade_maxima, activo, created_at, updated_at
		FROM gestao_escolar.school_levels WHERE tenant_id=$1 ORDER BY ordem, nome`, tenantID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var levels []models.Level
	for rows.Next() {
		l, err := scanLevel(rows)
		if err != nil {
			return nil, err
		}
		levels = append(levels, *l)
	}
	return levels, rows.Err()
}

// UpdateLevel actualiza um nível.
func (r *AcademicStructureRepository) UpdateLevel(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	return updateByFields(ctx, r.db, "gestao_escolar.school_levels", id, tenantID, fields)
}

// DeleteLevel remove um nível (hard delete permitido apenas se não houver dependências).
func (r *AcademicStructureRepository) DeleteLevel(ctx context.Context, id, tenantID int64) error {
	return deleteByID(ctx, r.db, "gestao_escolar.school_levels", id, tenantID)
}

// --- Series ---

func scanSeries(row pgx.Row) (*models.Series, error) {
	var s models.Series
	err := row.Scan(&s.ID, &s.TenantID, &s.LevelID, &s.CycleID, &s.Codigo, &s.Nome, &s.Ordem, &s.Activo, &s.CreatedAt)
	return &s, err
}

// CreateSeries cria uma série.
func (r *AcademicStructureRepository) CreateSeries(ctx context.Context, s *models.Series) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_series (tenant_id, level_id, cycle_id, codigo, nome, ordem)
		VALUES ($1,$2,$3,$4,$5,$6)
		RETURNING id, tenant_id, level_id, cycle_id, codigo, nome, ordem, activo, created_at`,
		s.TenantID, s.LevelID, s.CycleID, s.Codigo, s.Nome, s.Ordem,
	).Scan(&s.ID, &s.TenantID, &s.LevelID, &s.CycleID, &s.Codigo, &s.Nome, &s.Ordem, &s.Activo, &s.CreatedAt)
}

// GetSeriesByID obtém uma série.
func (r *AcademicStructureRepository) GetSeriesByID(ctx context.Context, id, tenantID int64) (*models.Series, error) {
	return scanSeries(r.db.QueryRow(ctx, `
		SELECT id, tenant_id, level_id, cycle_id, codigo, nome, ordem, activo, created_at
		FROM gestao_escolar.school_series WHERE id=$1 AND tenant_id=$2`, id, tenantID))
}

// ListSeries lista séries, opcionalmente filtradas por nível.
func (r *AcademicStructureRepository) ListSeries(ctx context.Context, tenantID, levelID int64) ([]models.Series, error) {
	where := "tenant_id=$1"
	args := []any{tenantID}
	if levelID > 0 {
		where += " AND level_id=$2"
		args = append(args, levelID)
	}
	rows, err := r.db.Query(ctx, `
		SELECT id, tenant_id, level_id, cycle_id, codigo, nome, ordem, activo, created_at
		FROM gestao_escolar.school_series WHERE `+where+` ORDER BY ordem, nome`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var series []models.Series
	for rows.Next() {
		s, err := scanSeries(rows)
		if err != nil {
			return nil, err
		}
		series = append(series, *s)
	}
	return series, rows.Err()
}

// UpdateSeries actualiza uma série.
func (r *AcademicStructureRepository) UpdateSeries(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	return updateByFields(ctx, r.db, "gestao_escolar.school_series", id, tenantID, fields)
}

// DeleteSeries remove uma série.
func (r *AcademicStructureRepository) DeleteSeries(ctx context.Context, id, tenantID int64) error {
	return deleteByID(ctx, r.db, "gestao_escolar.school_series", id, tenantID)
}

// --- Courses ---

func scanCourse(row pgx.Row) (*models.Course, error) {
	var c models.Course
	err := row.Scan(&c.ID, &c.TenantID, &c.LevelID, &c.Codigo, &c.Nome, &c.Descricao, &c.DuracaoAnos, &c.Modalidade, &c.Grau, &c.Activo, &c.CreatedAt, &c.UpdatedAt)
	return &c, err
}

// CreateCourse cria um curso.
func (r *AcademicStructureRepository) CreateCourse(ctx context.Context, c *models.Course) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_courses (tenant_id, level_id, codigo, nome, descricao, duracao_anos, modalidade, grau)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
		RETURNING id, tenant_id, level_id, codigo, nome, descricao, duracao_anos, modalidade, grau, activo, created_at, updated_at`,
		c.TenantID, c.LevelID, c.Codigo, c.Nome, c.Descricao, c.DuracaoAnos, c.Modalidade, c.Grau,
	).Scan(&c.ID, &c.TenantID, &c.LevelID, &c.Codigo, &c.Nome, &c.Descricao, &c.DuracaoAnos, &c.Modalidade, &c.Grau, &c.Activo, &c.CreatedAt, &c.UpdatedAt)
}

// GetCourseByID obtém um curso.
func (r *AcademicStructureRepository) GetCourseByID(ctx context.Context, id, tenantID int64) (*models.Course, error) {
	return scanCourse(r.db.QueryRow(ctx, `
		SELECT id, tenant_id, level_id, codigo, nome, descricao, duracao_anos, modalidade, grau, activo, created_at, updated_at
		FROM gestao_escolar.school_courses WHERE id=$1 AND tenant_id=$2`, id, tenantID))
}

// ListCourses lista cursos, opcionalmente filtrados por nível.
func (r *AcademicStructureRepository) ListCourses(ctx context.Context, tenantID, levelID int64) ([]models.Course, error) {
	where := "tenant_id=$1"
	args := []any{tenantID}
	if levelID > 0 {
		where += " AND level_id=$2"
		args = append(args, levelID)
	}
	rows, err := r.db.Query(ctx, `
		SELECT id, tenant_id, level_id, codigo, nome, descricao, duracao_anos, modalidade, grau, activo, created_at, updated_at
		FROM gestao_escolar.school_courses WHERE `+where+` ORDER BY nome`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var courses []models.Course
	for rows.Next() {
		c, err := scanCourse(rows)
		if err != nil {
			return nil, err
		}
		courses = append(courses, *c)
	}
	return courses, rows.Err()
}

// UpdateCourse actualiza um curso.
func (r *AcademicStructureRepository) UpdateCourse(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	return updateByFields(ctx, r.db, "gestao_escolar.school_courses", id, tenantID, fields)
}

// DeleteCourse remove um curso.
func (r *AcademicStructureRepository) DeleteCourse(ctx context.Context, id, tenantID int64) error {
	return deleteByID(ctx, r.db, "gestao_escolar.school_courses", id, tenantID)
}

// --- helpers ---

func updateByFields(ctx context.Context, db DB, table string, id, tenantID int64, fields map[string]any) error {
	if len(fields) == 0 {
		return nil
	}
	query := "UPDATE " + table + " SET "
	args := []any{}
	i := 1
	for col, val := range fields {
		if i > 1 {
			query += ", "
		}
		query += fmt.Sprintf("%s = $%d", col, i)
		args = append(args, val)
		i++
	}
	query += fmt.Sprintf(", updated_at = NOW() WHERE id = $%d AND tenant_id = $%d", i, i+1)
	args = append(args, id, tenantID)

	tag, err := db.Exec(ctx, query, args...)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

func deleteByID(ctx context.Context, db DB, table string, id, tenantID int64) error {
	tag, err := db.Exec(ctx, "DELETE FROM "+table+" WHERE id=$1 AND tenant_id=$2", id, tenantID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}
