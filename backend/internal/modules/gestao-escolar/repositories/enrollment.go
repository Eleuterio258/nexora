package repositories

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/gestao-escolar/models"
)

// EnrollmentRepository acesso a dados de matrículas.
type EnrollmentRepository struct {
	db DB
}

// NewEnrollmentRepository cria um repositório de matrículas.
func NewEnrollmentRepository(db DB) *EnrollmentRepository {
	return &EnrollmentRepository{db: db}
}

// Create insere uma matrícula.
func (r *EnrollmentRepository) Create(ctx context.Context, e *models.Enrollment) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_enrollments
		(tenant_id, school_year_id, student_id, class_id, numero, data_matricula, tipo, status, observacoes, created_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
		RETURNING id, created_at, updated_at`,
		e.TenantID, e.SchoolYearID, e.StudentID, e.ClassID, e.Numero, e.DataMatricula, e.Tipo, e.Status, e.Observacoes, e.CreatedBy,
	).Scan(&e.ID, &e.CreatedAt, &e.UpdatedAt)
}

// GetActiveByStudentAndYear verifica se aluno já tem matrícula activa no ano.
func (r *EnrollmentRepository) GetActiveByStudentAndYear(ctx context.Context, studentID, schoolYearID, tenantID int64) (*models.Enrollment, error) {
	var e models.Enrollment
	err := r.db.QueryRow(ctx, `
		SELECT id, tenant_id, school_year_id, student_id, class_id, numero, data_matricula, tipo, status, observacoes, transferred_at, cancelled_at, created_by, created_at, updated_at
		FROM gestao_escolar.school_enrollments
		WHERE student_id=$1 AND school_year_id=$2 AND tenant_id=$3 AND status='activa'`,
		studentID, schoolYearID, tenantID).Scan(
		&e.ID, &e.TenantID, &e.SchoolYearID, &e.StudentID, &e.ClassID, &e.Numero, &e.DataMatricula,
		&e.Tipo, &e.Status, &e.Observacoes, &e.TransferredAt, &e.CancelledAt, &e.CreatedBy, &e.CreatedAt, &e.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	return &e, err
}

// GetByID obtém uma matrícula.
func (r *EnrollmentRepository) GetByID(ctx context.Context, id, tenantID int64) (*models.Enrollment, error) {
	var e models.Enrollment
	err := r.db.QueryRow(ctx, `
		SELECT id, tenant_id, school_year_id, student_id, class_id, numero, data_matricula, tipo, status, observacoes, transferred_at, cancelled_at, created_by, created_at, updated_at
		FROM gestao_escolar.school_enrollments
		WHERE id=$1 AND tenant_id=$2`, id, tenantID).Scan(
		&e.ID, &e.TenantID, &e.SchoolYearID, &e.StudentID, &e.ClassID, &e.Numero, &e.DataMatricula,
		&e.Tipo, &e.Status, &e.Observacoes, &e.TransferredAt, &e.CancelledAt, &e.CreatedBy, &e.CreatedAt, &e.UpdatedAt,
	)
	return &e, err
}

// Transfer actualiza a turma de uma matrícula activa.
func (r *EnrollmentRepository) Transfer(ctx context.Context, id, tenantID, newClassID int64, motivo string) error {
	tag, err := r.db.Exec(ctx, `
		UPDATE gestao_escolar.school_enrollments
		SET class_id=$1, transferred_at=$2, observacoes=COALESCE(NULLIF($3,''), observacoes), updated_at=$2
		WHERE id=$4 AND tenant_id=$5 AND status='activa'`,
		newClassID, time.Now(), motivo, id, tenantID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

// Cancel cancela uma matrícula.
func (r *EnrollmentRepository) Cancel(ctx context.Context, id, tenantID int64) error {
	tag, err := r.db.Exec(ctx, `
		UPDATE gestao_escolar.school_enrollments
		SET status='cancelada', cancelled_at=$1, updated_at=$1
		WHERE id=$2 AND tenant_id=$3 AND status='activa'`, time.Now(), id, tenantID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

// ExistsByNumber verifica se já existe matrícula com o número.
func (r *EnrollmentRepository) ExistsByNumber(ctx context.Context, numero string, tenantID, excludeID int64) (bool, error) {
	args := []any{numero, tenantID}
	where := ""
	if excludeID > 0 {
		where = " AND id <> $3"
		args = append(args, excludeID)
	}
	var exists bool
	err := r.db.QueryRow(ctx, `
		SELECT EXISTS(SELECT 1 FROM gestao_escolar.school_enrollments
		WHERE numero=$1 AND tenant_id=$2`+where+")", args...).Scan(&exists)
	return exists, err
}
