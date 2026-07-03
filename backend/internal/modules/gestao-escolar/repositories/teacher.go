package repositories

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/gestao-escolar/models"
)

// TeacherRepository encapsula o acesso a dados de professores.
type TeacherRepository struct {
	db DB
}

// NewTeacherRepository cria um novo repositório de professores.
func NewTeacherRepository(db DB) *TeacherRepository {
	return &TeacherRepository{db: db}
}

const teacherColumns = `
	id, tenant_id, user_id, codigo, nome_completo, COALESCE(genero,'') AS genero,
	COALESCE(telefone,'') AS telefone, COALESCE(email,'') AS email,
	COALESCE(documento_identificacao,'') AS documento_identificacao,
	COALESCE(especialidade,'') AS especialidade, carga_horaria_maxima_semanal,
	status, created_at, updated_at
`

func scanTeacher(row pgx.Row) (*models.Teacher, error) {
	var t models.Teacher
	err := row.Scan(
		&t.ID, &t.TenantID, &t.UserID, &t.Codigo, &t.NomeCompleto, &t.Genero,
		&t.Telefone, &t.Email, &t.DocumentoIdentificacao, &t.Especialidade,
		&t.CargaHorariaMaximaSemanal, &t.Status, &t.CreatedAt, &t.UpdatedAt,
	)
	return &t, err
}

// Create insere um novo professor.
func (r *TeacherRepository) Create(ctx context.Context, t *models.Teacher) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_teachers
		(tenant_id, user_id, codigo, nome_completo, genero, telefone, email,
		 documento_identificacao, especialidade, carga_horaria_maxima_semanal, status)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING `+teacherColumns,
		t.TenantID, t.UserID, t.Codigo, t.NomeCompleto, t.Genero, t.Telefone,
		t.Email, t.DocumentoIdentificacao, t.Especialidade, t.CargaHorariaMaximaSemanal, t.Status,
	).Scan(
		&t.ID, &t.TenantID, &t.UserID, &t.Codigo, &t.NomeCompleto, &t.Genero,
		&t.Telefone, &t.Email, &t.DocumentoIdentificacao, &t.Especialidade,
		&t.CargaHorariaMaximaSemanal, &t.Status, &t.CreatedAt, &t.UpdatedAt,
	)
}

// GetByID obtém um professor pelo ID e tenant.
func (r *TeacherRepository) GetByID(ctx context.Context, id, tenantID int64) (*models.Teacher, error) {
	return scanTeacher(r.db.QueryRow(ctx, `
		SELECT `+teacherColumns+`
		FROM gestao_escolar.school_teachers
		WHERE id = $1 AND tenant_id = $2`, id, tenantID))
}

// GetByCode obtém um professor pelo código e tenant.
func (r *TeacherRepository) GetByCode(ctx context.Context, code string, tenantID int64) (*models.Teacher, error) {
	return scanTeacher(r.db.QueryRow(ctx, `
		SELECT `+teacherColumns+`
		FROM gestao_escolar.school_teachers
		WHERE codigo = $1 AND tenant_id = $2`, code, tenantID))
}

// List lista professores com filtros opcionais e paginação.
func (r *TeacherRepository) List(ctx context.Context, tenantID int64, status, search string, page, limit int) ([]models.Teacher, int64, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 200 {
		limit = 20
	}
	offset := (page - 1) * limit

	where := "tenant_id = $1"
	args := []any{tenantID}
	argCount := 1

	if status != "" {
		argCount++
		where += fmt.Sprintf(" AND status = $%d", argCount)
		args = append(args, status)
	}
	if search != "" {
		argCount++
		where += fmt.Sprintf(" AND (nome_completo ILIKE $%d OR codigo ILIKE $%d OR email ILIKE $%d)", argCount, argCount, argCount)
		args = append(args, "%"+search+"%")
	}

	var total int64
	err := r.db.QueryRow(ctx, "SELECT COUNT(*) FROM gestao_escolar.school_teachers WHERE "+where, args...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	argCount++
	limitArg := argCount
	argCount++
	offsetArg := argCount

	query := fmt.Sprintf(`
		SELECT `+teacherColumns+`
		FROM gestao_escolar.school_teachers
		WHERE %s
		ORDER BY nome_completo
		LIMIT $%d OFFSET $%d`, where, limitArg, offsetArg)

	rows, err := r.db.Query(ctx, query, append(args, limit, offset)...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var teachers []models.Teacher
	for rows.Next() {
		var t models.Teacher
		err := rows.Scan(
			&t.ID, &t.TenantID, &t.UserID, &t.Codigo, &t.NomeCompleto, &t.Genero,
			&t.Telefone, &t.Email, &t.DocumentoIdentificacao, &t.Especialidade,
			&t.CargaHorariaMaximaSemanal, &t.Status, &t.CreatedAt, &t.UpdatedAt,
		)
		if err != nil {
			return nil, 0, err
		}
		teachers = append(teachers, t)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, err
	}

	return teachers, total, nil
}

// Update actualiza um professor existente.
func (r *TeacherRepository) Update(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	if len(fields) == 0 {
		return nil
	}

	query := "UPDATE gestao_escolar.school_teachers SET "
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

	tag, err := r.db.Exec(ctx, query, args...)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

// Delete remove um professor (soft delete: inactiva).
func (r *TeacherRepository) Delete(ctx context.Context, id, tenantID int64) error {
	tag, err := r.db.Exec(ctx, `
		UPDATE gestao_escolar.school_teachers
		SET status = 'inactivo', updated_at = NOW()
		WHERE id = $1 AND tenant_id = $2`, id, tenantID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

// ExistsByCode verifica se já existe professor com o código.
func (r *TeacherRepository) ExistsByCode(ctx context.Context, code string, tenantID, excludeID int64) (bool, error) {
	var where string
	args := []any{code, tenantID}
	if excludeID > 0 {
		where = " AND id <> $3"
		args = append(args, excludeID)
	}
	var exists bool
	err := r.db.QueryRow(ctx, `
		SELECT EXISTS(SELECT 1 FROM gestao_escolar.school_teachers
		WHERE codigo = $1 AND tenant_id = $2`+where+")", args...).Scan(&exists)
	return exists, err
}

// WeeklyWorkload retorna a carga horária semanal atribuída a um professor.
func (r *TeacherRepository) WeeklyWorkload(ctx context.Context, teacherID, tenantID int64) (int, error) {
	var workload int
	err := r.db.QueryRow(ctx, `
		SELECT COALESCE(SUM(Extract(EPOCH FROM (ts.hora_fim - ts.hora_inicio)) / 3600), 0)::int
		FROM gestao_escolar.school_timetable_entries te
		JOIN gestao_escolar.school_time_slots ts ON ts.id = te.time_slot_id
		WHERE te.teacher_id = $1 AND te.tenant_id = $2 AND te.activo`, teacherID, tenantID).Scan(&workload)
	return workload, err
}
