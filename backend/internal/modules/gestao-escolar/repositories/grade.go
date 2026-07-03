package repositories

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/gestao-escolar/models"
)

// GradeRepository acesso a dados de notas.
type GradeRepository struct {
	db DB
}

// NewGradeRepository cria repositório.
func NewGradeRepository(db DB) *GradeRepository {
	return &GradeRepository{db: db}
}

func scanGradeItem(row pgx.Row) (*models.GradeItem, error) {
	var g models.GradeItem
	err := row.Scan(&g.ID, &g.TenantID, &g.ClassID, &g.SubjectID, &g.TermID, &g.Nome, &g.Tipo,
		&g.DataAvaliacao, &g.NotaMaxima, &g.Peso, &g.Publicado, &g.CreatedBy, &g.CreatedAt, &g.UpdatedAt)
	return &g, err
}

// CreateItem cria avaliação.
func (r *GradeRepository) CreateItem(ctx context.Context, g *models.GradeItem) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_grade_items
		(tenant_id, class_id, subject_id, term_id, nome, tipo, data_avaliacao, nota_maxima, peso, created_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
		RETURNING id, tenant_id, class_id, subject_id, term_id, nome, tipo, data_avaliacao, nota_maxima, peso, publicado, created_by, created_at, updated_at`,
		g.TenantID, g.ClassID, g.SubjectID, g.TermID, g.Nome, g.Tipo, g.DataAvaliacao, g.NotaMaxima, g.Peso, g.CreatedBy,
	).Scan(&g.ID, &g.TenantID, &g.ClassID, &g.SubjectID, &g.TermID, &g.Nome, &g.Tipo,
		&g.DataAvaliacao, &g.NotaMaxima, &g.Peso, &g.Publicado, &g.CreatedBy, &g.CreatedAt, &g.UpdatedAt)
}

// GetItemByID obtém avaliação.
func (r *GradeRepository) GetItemByID(ctx context.Context, id, tenantID int64) (*models.GradeItem, error) {
	return scanGradeItem(r.db.QueryRow(ctx, `
		SELECT id, tenant_id, class_id, subject_id, term_id, nome, tipo, data_avaliacao, nota_maxima, peso, publicado, created_by, created_at, updated_at
		FROM gestao_escolar.school_grade_items WHERE id=$1 AND tenant_id=$2`, id, tenantID))
}

// ListItems lista avaliações.
func (r *GradeRepository) ListItems(ctx context.Context, tenantID, classID, subjectID, termID int64) ([]models.GradeItem, error) {
	where := "tenant_id=$1"
	args := []any{tenantID}
	if classID > 0 {
		where += " AND class_id=$2"
		args = append(args, classID)
	}
	if subjectID > 0 {
		where += " AND subject_id=$" + fmt.Sprintf("%d", len(args)+1)
		args = append(args, subjectID)
	}
	if termID > 0 {
		where += " AND term_id=$" + fmt.Sprintf("%d", len(args)+1)
		args = append(args, termID)
	}

	rows, err := r.db.Query(ctx, `
		SELECT id, tenant_id, class_id, subject_id, term_id, nome, tipo, data_avaliacao, nota_maxima, peso, publicado, created_by, created_at, updated_at
		FROM gestao_escolar.school_grade_items WHERE `+where+` ORDER BY data_avaliacao DESC`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.GradeItem
	for rows.Next() {
		g, err := scanGradeItem(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, *g)
	}
	return items, rows.Err()
}

// PublishItem publica/oculta notas.
func (r *GradeRepository) PublishItem(ctx context.Context, id, tenantID int64, published bool) error {
	tag, err := r.db.Exec(ctx, `
		UPDATE gestao_escolar.school_grade_items
		SET publicado=$1, updated_at=NOW()
		WHERE id=$2 AND tenant_id=$3`, published, id, tenantID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

// UpsertGrade insere ou actualiza nota.
func (r *GradeRepository) UpsertGrade(ctx context.Context, g *models.Grade) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_grades
		(tenant_id, grade_item_id, student_id, enrollment_id, nota, observacoes, lancado_por)
		VALUES ($1,$2,$3,$4,$5,$6,$7)
		ON CONFLICT(tenant_id, grade_item_id, student_id)
		DO UPDATE SET nota=EXCLUDED.nota, observacoes=EXCLUDED.observacoes, lancado_por=EXCLUDED.lancado_por, updated_at=NOW()
		RETURNING id, created_at, updated_at`,
		g.TenantID, g.GradeItemID, g.StudentID, g.EnrollmentID, g.Nota, g.Observacoes, g.LancadoPor,
	).Scan(&g.ID, &g.CreatedAt, &g.UpdatedAt)
}

// GetGradeByID obtém nota.
func (r *GradeRepository) GetGradeByID(ctx context.Context, id, tenantID int64) (*models.Grade, error) {
	var g models.Grade
	err := r.db.QueryRow(ctx, `
		SELECT id, tenant_id, grade_item_id, student_id, enrollment_id, nota, observacoes, lancado_por, created_at, updated_at
		FROM gestao_escolar.school_grades WHERE id=$1 AND tenant_id=$2`, id, tenantID).Scan(
		&g.ID, &g.TenantID, &g.GradeItemID, &g.StudentID, &g.EnrollmentID, &g.Nota, &g.Observacoes, &g.LancadoPor, &g.CreatedAt, &g.UpdatedAt)
	return &g, err
}

// StudentAverages calcula médias por disciplina para um aluno num período.
func (r *GradeRepository) StudentAverages(ctx context.Context, studentID, termID, tenantID int64) ([]map[string]any, error) {
	query := `
		SELECT sub.id, sub.nome, ROUND(SUM(g.nota*i.peso)/NULLIF(SUM(i.peso),0),2) media,
		 COUNT(g.id) avaliacoes
		FROM gestao_escolar.school_grades g
		JOIN gestao_escolar.school_grade_items i ON i.id=g.grade_item_id AND i.publicado=TRUE
		JOIN gestao_escolar.school_subjects sub ON sub.id=i.subject_id
		WHERE g.student_id=$1 AND g.tenant_id=$2`
	args := []any{studentID, tenantID}
	if termID > 0 {
		query += " AND i.term_id=$3"
		args = append(args, termID)
	}
	query += " GROUP BY sub.id, sub.nome ORDER BY sub.nome"

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []map[string]any
	for rows.Next() {
		var subjectID int64
		var nome string
		var media *float64
		var avaliacoes int64
		if err := rows.Scan(&subjectID, &nome, &media, &avaliacoes); err != nil {
			return nil, err
		}
		result = append(result, map[string]any{
			"subject_id":  subjectID,
			"disciplina":  nome,
			"media":       media,
			"avaliacoes":  avaliacoes,
		})
	}
	return result, rows.Err()
}
