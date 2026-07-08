package repositories

import (
	"context"
	"errors"
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

// ErrInvalidColumn é devolvido quando um campo de actualização não está na lista branca da tabela.
var ErrInvalidColumn = errors.New("campo nao permitido para actualizacao")

// Listas brancas de colunas actualizáveis por tabela, usadas por updateByFields
// para impedir que nomes de coluna vindos do corpo JSON do cliente sejam
// interpolados directamente na query SQL (protecção contra injecção de SQL).
var (
	levelUpdatableColumns = map[string]bool{
		"codigo": true, "nome": true, "descricao": true, "ordem": true,
		"nota_minima_aprovacao": true, "escala_maxima": true, "sistema_avaliacao": true,
		"numero_periodos_padrao": true, "nomenclatura_periodo": true, "nomenclatura_serie": true,
		"idade_minima": true, "idade_maxima": true, "activo": true,
	}
	seriesUpdatableColumns = map[string]bool{
		"level_id": true, "cycle_id": true, "codigo": true, "nome": true, "ordem": true, "activo": true,
	}
	courseUpdatableColumns = map[string]bool{
		"level_id": true, "codigo": true, "nome": true, "descricao": true,
		"duracao_anos": true, "modalidade": true, "grau": true, "activo": true,
	}
	cycleUpdatableColumns = map[string]bool{
		"level_id": true, "codigo": true, "nome": true, "ordem": true, "activo": true,
	}
	courseSubjectUpdatableColumns = map[string]bool{
		"course_id": true, "level_id": true, "series_id": true, "subject_id": true,
		"obrigatoria": true, "carga_horaria_semanal": true, "componente": true, "activo": true,
	}
	courseSubjectTermUpdatableColumns = map[string]bool{
		"term_id": true, "tem_exame": true, "peso_exame": true,
	}
)

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
	return updateByFields(ctx, r.db, "gestao_escolar.school_levels", id, tenantID, fields, levelUpdatableColumns, true)
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
	return updateByFields(ctx, r.db, "gestao_escolar.school_series", id, tenantID, fields, seriesUpdatableColumns, false)
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
	return updateByFields(ctx, r.db, "gestao_escolar.school_courses", id, tenantID, fields, courseUpdatableColumns, true)
}

// DeleteCourse remove um curso.
func (r *AcademicStructureRepository) DeleteCourse(ctx context.Context, id, tenantID int64) error {
	return deleteByID(ctx, r.db, "gestao_escolar.school_courses", id, tenantID)
}

// --- Cycles ---

func scanCycle(row pgx.Row) (*models.Cycle, error) {
	var c models.Cycle
	err := row.Scan(&c.ID, &c.TenantID, &c.LevelID, &c.Codigo, &c.Nome, &c.Ordem, &c.Activo, &c.CreatedAt)
	return &c, err
}

// CreateCycle cria um ciclo dentro de um nível.
func (r *AcademicStructureRepository) CreateCycle(ctx context.Context, c *models.Cycle) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_cycles (tenant_id, level_id, codigo, nome, ordem)
		VALUES ($1,$2,$3,$4,$5)
		RETURNING id, tenant_id, level_id, codigo, nome, ordem, activo, created_at`,
		c.TenantID, c.LevelID, c.Codigo, c.Nome, c.Ordem,
	).Scan(&c.ID, &c.TenantID, &c.LevelID, &c.Codigo, &c.Nome, &c.Ordem, &c.Activo, &c.CreatedAt)
}

// GetCycleByID obtém um ciclo.
func (r *AcademicStructureRepository) GetCycleByID(ctx context.Context, id, tenantID int64) (*models.Cycle, error) {
	return scanCycle(r.db.QueryRow(ctx, `
		SELECT id, tenant_id, level_id, codigo, nome, ordem, activo, created_at
		FROM gestao_escolar.school_cycles WHERE id=$1 AND tenant_id=$2`, id, tenantID))
}

// ListCycles lista ciclos, opcionalmente filtrados por nível.
func (r *AcademicStructureRepository) ListCycles(ctx context.Context, tenantID, levelID int64) ([]models.Cycle, error) {
	where := "tenant_id=$1"
	args := []any{tenantID}
	if levelID > 0 {
		where += " AND level_id=$2"
		args = append(args, levelID)
	}
	rows, err := r.db.Query(ctx, `
		SELECT id, tenant_id, level_id, codigo, nome, ordem, activo, created_at
		FROM gestao_escolar.school_cycles WHERE `+where+` ORDER BY ordem, nome`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cycles []models.Cycle
	for rows.Next() {
		c, err := scanCycle(rows)
		if err != nil {
			return nil, err
		}
		cycles = append(cycles, *c)
	}
	return cycles, rows.Err()
}

// UpdateCycle actualiza um ciclo.
func (r *AcademicStructureRepository) UpdateCycle(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	return updateByFields(ctx, r.db, "gestao_escolar.school_cycles", id, tenantID, fields, cycleUpdatableColumns, false)
}

// DeleteCycle remove um ciclo.
func (r *AcademicStructureRepository) DeleteCycle(ctx context.Context, id, tenantID int64) error {
	return deleteByID(ctx, r.db, "gestao_escolar.school_cycles", id, tenantID)
}

// --- CourseSubjects (currículo: disciplina associada a curso, nível ou série) ---

func scanCourseSubject(row pgx.Row) (*models.CourseSubject, error) {
	var cs models.CourseSubject
	err := row.Scan(&cs.ID, &cs.TenantID, &cs.CourseID, &cs.LevelID, &cs.SeriesID, &cs.SubjectID,
		&cs.Obrigatoria, &cs.CargaHorariaSemanal, &cs.Componente, &cs.Activo, &cs.CreatedAt)
	return &cs, err
}

// CreateCourseSubject associa uma disciplina a um curso, nível ou série.
func (r *AcademicStructureRepository) CreateCourseSubject(ctx context.Context, cs *models.CourseSubject) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_course_subjects
		(tenant_id, course_id, level_id, series_id, subject_id, obrigatoria, carga_horaria_semanal, componente)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
		RETURNING id, tenant_id, course_id, level_id, series_id, subject_id, obrigatoria, carga_horaria_semanal, componente, activo, created_at`,
		cs.TenantID, cs.CourseID, cs.LevelID, cs.SeriesID, cs.SubjectID, cs.Obrigatoria, cs.CargaHorariaSemanal, cs.Componente,
	).Scan(&cs.ID, &cs.TenantID, &cs.CourseID, &cs.LevelID, &cs.SeriesID, &cs.SubjectID,
		&cs.Obrigatoria, &cs.CargaHorariaSemanal, &cs.Componente, &cs.Activo, &cs.CreatedAt)
}

// GetCourseSubjectByID obtém um item do currículo.
func (r *AcademicStructureRepository) GetCourseSubjectByID(ctx context.Context, id, tenantID int64) (*models.CourseSubject, error) {
	return scanCourseSubject(r.db.QueryRow(ctx, `
		SELECT id, tenant_id, course_id, level_id, series_id, subject_id, obrigatoria, carga_horaria_semanal, componente, activo, created_at
		FROM gestao_escolar.school_course_subjects WHERE id=$1 AND tenant_id=$2`, id, tenantID))
}

// ListCourseSubjectsFilter define os filtros opcionais para listar o currículo.
type ListCourseSubjectsFilter struct {
	CourseID  int64
	LevelID   int64
	SeriesID  int64
	SubjectID int64
}

// ListCourseSubjects lista o currículo, opcionalmente filtrado por curso/nível/série/disciplina.
func (r *AcademicStructureRepository) ListCourseSubjects(ctx context.Context, tenantID int64, f ListCourseSubjectsFilter) ([]models.CourseSubject, error) {
	where := "tenant_id=$1"
	args := []any{tenantID}
	if f.CourseID > 0 {
		args = append(args, f.CourseID)
		where += fmt.Sprintf(" AND course_id=$%d", len(args))
	}
	if f.LevelID > 0 {
		args = append(args, f.LevelID)
		where += fmt.Sprintf(" AND level_id=$%d", len(args))
	}
	if f.SeriesID > 0 {
		args = append(args, f.SeriesID)
		where += fmt.Sprintf(" AND series_id=$%d", len(args))
	}
	if f.SubjectID > 0 {
		args = append(args, f.SubjectID)
		where += fmt.Sprintf(" AND subject_id=$%d", len(args))
	}
	rows, err := r.db.Query(ctx, `
		SELECT id, tenant_id, course_id, level_id, series_id, subject_id, obrigatoria, carga_horaria_semanal, componente, activo, created_at
		FROM gestao_escolar.school_course_subjects WHERE `+where+` ORDER BY created_at`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []models.CourseSubject
	for rows.Next() {
		cs, err := scanCourseSubject(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, *cs)
	}
	return list, rows.Err()
}

// UpdateCourseSubject actualiza um item do currículo.
func (r *AcademicStructureRepository) UpdateCourseSubject(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	return updateByFields(ctx, r.db, "gestao_escolar.school_course_subjects", id, tenantID, fields, courseSubjectUpdatableColumns, false)
}

// DeleteCourseSubject remove um item do currículo.
func (r *AcademicStructureRepository) DeleteCourseSubject(ctx context.Context, id, tenantID int64) error {
	return deleteByID(ctx, r.db, "gestao_escolar.school_course_subjects", id, tenantID)
}

// --- CourseSubjectTerms (configuração da disciplina por período) ---

func scanCourseSubjectTerm(row pgx.Row) (*models.CourseSubjectTerm, error) {
	var t models.CourseSubjectTerm
	err := row.Scan(&t.ID, &t.TenantID, &t.CourseSubjectID, &t.TermID, &t.TemExame, &t.PesoExame)
	return &t, err
}

// CreateCourseSubjectTerm configura a presença/exame de uma disciplina num período.
func (r *AcademicStructureRepository) CreateCourseSubjectTerm(ctx context.Context, t *models.CourseSubjectTerm) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_course_subject_terms
		(tenant_id, course_subject_id, term_id, tem_exame, peso_exame)
		VALUES ($1,$2,$3,$4,$5)
		RETURNING id, tenant_id, course_subject_id, term_id, tem_exame, peso_exame`,
		t.TenantID, t.CourseSubjectID, t.TermID, t.TemExame, t.PesoExame,
	).Scan(&t.ID, &t.TenantID, &t.CourseSubjectID, &t.TermID, &t.TemExame, &t.PesoExame)
}

// ListCourseSubjectTerms lista a configuração por período de um item do currículo.
func (r *AcademicStructureRepository) ListCourseSubjectTerms(ctx context.Context, tenantID, courseSubjectID int64) ([]models.CourseSubjectTerm, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, tenant_id, course_subject_id, term_id, tem_exame, peso_exame
		FROM gestao_escolar.school_course_subject_terms
		WHERE tenant_id=$1 AND course_subject_id=$2 ORDER BY term_id`, tenantID, courseSubjectID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []models.CourseSubjectTerm
	for rows.Next() {
		t, err := scanCourseSubjectTerm(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, *t)
	}
	return list, rows.Err()
}

// UpdateCourseSubjectTerm actualiza a configuração de uma disciplina num período.
func (r *AcademicStructureRepository) UpdateCourseSubjectTerm(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	return updateByFields(ctx, r.db, "gestao_escolar.school_course_subject_terms", id, tenantID, fields, courseSubjectTermUpdatableColumns, true)
}

// DeleteCourseSubjectTerm remove a configuração de uma disciplina num período.
func (r *AcademicStructureRepository) DeleteCourseSubjectTerm(ctx context.Context, id, tenantID int64) error {
	return deleteByID(ctx, r.db, "gestao_escolar.school_course_subject_terms", id, tenantID)
}

// --- helpers ---

// updateByFields constrói um UPDATE dinâmico apenas com as colunas presentes em
// `allowed`; qualquer campo fora dessa lista branca é rejeitado com ErrInvalidColumn
// em vez de ser interpolado na query (os nomes de coluna nunca são passados como
// parâmetros SQL, por isso têm de ser validados antes de entrar na string da query).
func updateByFields(ctx context.Context, db DB, table string, id, tenantID int64, fields map[string]any, allowed map[string]bool, touchUpdatedAt bool) error {
	if len(fields) == 0 {
		return nil
	}
	query := "UPDATE " + table + " SET "
	args := []any{}
	i := 1
	for col, val := range fields {
		if !allowed[col] {
			return ErrInvalidColumn
		}
		if i > 1 {
			query += ", "
		}
		query += fmt.Sprintf("%s = $%d", col, i)
		args = append(args, val)
		i++
	}
	if touchUpdatedAt {
		query += ", updated_at = NOW()"
	}
	query += fmt.Sprintf(" WHERE id = $%d AND tenant_id = $%d", i, i+1)
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
