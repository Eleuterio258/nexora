package repositories

import (
	"context"

	"nexora/internal/modules/gestao-escolar/models"
)

// ClassRepository acesso a dados de turmas.
type ClassRepository struct {
	db DB
}

// NewClassRepository cria um repositório de turmas.
func NewClassRepository(db DB) *ClassRepository {
	return &ClassRepository{db: db}
}

// GetByID obtém uma turma pelo ID.
func (r *ClassRepository) GetByID(ctx context.Context, id, tenantID int64) (*models.Class, error) {
	var c models.Class
	var horarioRaw []byte
	err := r.db.QueryRow(ctx, `
		SELECT id, tenant_id, school_year_id, level_id, series_id, course_id,
		 codigo, nome, nivel, turma, turno, sala, capacidade,
		 director_teacher_id, horario, activo, created_at, updated_at
		FROM gestao_escolar.school_classes
		WHERE id=$1 AND tenant_id=$2`, id, tenantID).Scan(
		&c.ID, &c.TenantID, &c.SchoolYearID, &c.LevelID, &c.SeriesID, &c.CourseID,
		&c.Codigo, &c.Nome, &c.Nivel, &c.Turma, &c.Turno, &c.Sala, &c.Capacidade,
		&c.DirectorTeacherID, &horarioRaw, &c.Activo, &c.CreatedAt, &c.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	// horario JSONB -> []any omitido para simplicidade; pode ser preenchido se necessário
	return &c, nil
}

// CountActiveStudents retorna o número de alunos activos numa turma.
func (r *ClassRepository) CountActiveStudents(ctx context.Context, classID, tenantID int64) (int, error) {
	var count int
	err := r.db.QueryRow(ctx, `
		SELECT COUNT(*) FROM gestao_escolar.school_enrollments
		WHERE class_id=$1 AND tenant_id=$2 AND status='activa'`, classID, tenantID).Scan(&count)
	return count, err
}

// Create cria uma turma.
func (r *ClassRepository) Create(ctx context.Context, c *models.Class) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_classes
		(tenant_id, school_year_id, level_id, series_id, course_id, codigo, nome, nivel,
		 turma, turno, sala, capacidade, director_teacher_id, horario)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
		RETURNING id, created_at, updated_at`,
		c.TenantID, c.SchoolYearID, c.LevelID, c.SeriesID, c.CourseID, c.Codigo, c.Nome, c.Nivel,
		c.Turma, c.Turno, c.Sala, c.Capacidade, c.DirectorTeacherID, c.Horario,
	).Scan(&c.ID, &c.CreatedAt, &c.UpdatedAt)
}

// Update actualiza uma turma.
func (r *ClassRepository) Update(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	return updateByFields(ctx, r.db, "gestao_escolar.school_classes", id, tenantID, fields)
}
