package repositories

import (
	"context"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/gestao-escolar/models"
)

// IncidentRepository acesso a dados de ocorrências.
type IncidentRepository struct {
	db DB
}

// NewIncidentRepository cria repositório.
func NewIncidentRepository(db DB) *IncidentRepository {
	return &IncidentRepository{db: db}
}

func scanIncident(row pgx.Row) (*models.StudentIncident, error) {
	var i models.StudentIncident
	var hora *string
	err := row.Scan(
		&i.ID, &i.TenantID, &i.SchoolYearID, &i.StudentID, &i.EnrollmentID, &i.IncidentTypeID,
		&i.ReportedBy, &i.DataOcorrencia, &hora, &i.Local, &i.Descricao, &i.Testemunhas,
		&i.Anexos, &i.Status, &i.CreatedAt, &i.UpdatedAt,
	)
	i.HoraOcorrencia = hora
	return &i, err
}

// CreateIncident cria ocorrência.
func (r *IncidentRepository) CreateIncident(ctx context.Context, i *models.StudentIncident) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_student_incidents
		(tenant_id, school_year_id, student_id, enrollment_id, incident_type_id, reported_by,
		 data_ocorrencia, hora_ocorrencia, local, descricao, testemunhas, anexos, status)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
		RETURNING id, tenant_id, school_year_id, student_id, enrollment_id, incident_type_id, reported_by,
		 data_ocorrencia, hora_ocorrencia, local, descricao, testemunhas, anexos, status, created_at, updated_at`,
		i.TenantID, i.SchoolYearID, i.StudentID, i.EnrollmentID, i.IncidentTypeID, i.ReportedBy,
		i.DataOcorrencia, i.HoraOcorrencia, i.Local, i.Descricao, i.Testemunhas, i.Anexos, i.Status,
	).Scan(
		&i.ID, &i.TenantID, &i.SchoolYearID, &i.StudentID, &i.EnrollmentID, &i.IncidentTypeID,
		&i.ReportedBy, &i.DataOcorrencia, &i.HoraOcorrencia, &i.Local, &i.Descricao, &i.Testemunhas,
		&i.Anexos, &i.Status, &i.CreatedAt, &i.UpdatedAt,
	)
}

// ListIncidents lista ocorrências de um aluno/ano.
func (r *IncidentRepository) ListIncidents(ctx context.Context, tenantID, studentID, schoolYearID int64) ([]models.StudentIncident, error) {
	where := "tenant_id=$1"
	args := []any{tenantID}
	if studentID > 0 {
		where += " AND student_id=$2"
		args = append(args, studentID)
	}
	if schoolYearID > 0 {
		where += " AND school_year_id=$" + string(rune('0'+len(args)+1))
		args = append(args, schoolYearID)
	}

	rows, err := r.db.Query(ctx, `
		SELECT id, tenant_id, school_year_id, student_id, enrollment_id, incident_type_id, reported_by,
		 data_ocorrencia, hora_ocorrencia, local, descricao, testemunhas, anexos, status, created_at, updated_at
		FROM gestao_escolar.school_student_incidents
		WHERE `+where+` ORDER BY data_ocorrencia DESC`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var incidents []models.StudentIncident
	for rows.Next() {
		i, err := scanIncident(rows)
		if err != nil {
			return nil, err
		}
		incidents = append(incidents, *i)
	}
	return incidents, rows.Err()
}

// GetIncidentByID obtém ocorrência.
func (r *IncidentRepository) GetIncidentByID(ctx context.Context, id, tenantID int64) (*models.StudentIncident, error) {
	return scanIncident(r.db.QueryRow(ctx, `
		SELECT id, tenant_id, school_year_id, student_id, enrollment_id, incident_type_id, reported_by,
		 data_ocorrencia, hora_ocorrencia, local, descricao, testemunhas, anexos, status, created_at, updated_at
		FROM gestao_escolar.school_student_incidents
		WHERE id=$1 AND tenant_id=$2`, id, tenantID))
}

var incidentUpdatableColumns = map[string]bool{
	"school_year_id": true, "student_id": true, "enrollment_id": true, "incident_type_id": true,
	"reported_by": true, "data_ocorrencia": true, "hora_ocorrencia": true, "local": true,
	"descricao": true, "testemunhas": true, "anexos": true, "status": true,
}

// UpdateIncident actualiza ocorrência.
func (r *IncidentRepository) UpdateIncident(ctx context.Context, id, tenantID int64, fields map[string]any) error {
	return updateByFields(ctx, r.db, "gestao_escolar.school_student_incidents", id, tenantID, fields, incidentUpdatableColumns, true)
}

// CreateIncidentType cria tipo.
func (r *IncidentRepository) CreateIncidentType(ctx context.Context, it *models.IncidentType) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_incident_types (tenant_id, codigo, nome, gravidade, requer_encarregado)
		VALUES ($1,$2,$3,$4,$5)
		RETURNING id, tenant_id, codigo, nome, gravidade, requer_encarregado, activo, created_at`,
		it.TenantID, it.Codigo, it.Nome, it.Gravidade, it.RequerEncarregado,
	).Scan(&it.ID, &it.TenantID, &it.Codigo, &it.Nome, &it.Gravidade, &it.RequerEncarregado, &it.Activo, &it.CreatedAt)
}

// ListIncidentTypes lista tipos.
func (r *IncidentRepository) ListIncidentTypes(ctx context.Context, tenantID int64) ([]models.IncidentType, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, tenant_id, codigo, nome, gravidade, requer_encarregado, activo, created_at
		FROM gestao_escolar.school_incident_types
		WHERE tenant_id=$1 AND activo ORDER BY nome`, tenantID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var types []models.IncidentType
	for rows.Next() {
		var it models.IncidentType
		err := rows.Scan(&it.ID, &it.TenantID, &it.Codigo, &it.Nome, &it.Gravidade, &it.RequerEncarregado, &it.Activo, &it.CreatedAt)
		if err != nil {
			return nil, err
		}
		types = append(types, it)
	}
	return types, rows.Err()
}

// CreateSanction cria sanção.
func (r *IncidentRepository) CreateSanction(ctx context.Context, s *models.StudentSanction) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_student_sanctions
		(tenant_id, incident_id, sanction_type_id, aplicado_por, data_inicio, data_fim, descricao)
		VALUES ($1,$2,$3,$4,$5,$6,$7)
		RETURNING id, tenant_id, incident_id, sanction_type_id, aplicado_por, data_inicio, data_fim, descricao, cumprida, created_at, updated_at`,
		s.TenantID, s.IncidentID, s.SanctionTypeID, s.AplicadoPor, s.DataInicio, s.DataFim, s.Descricao,
	).Scan(&s.ID, &s.TenantID, &s.IncidentID, &s.SanctionTypeID, &s.AplicadoPor, &s.DataInicio, &s.DataFim, &s.Descricao, &s.Cumprida, &s.CreatedAt, &s.UpdatedAt)
}

// CreateMerit cria mérito.
func (r *IncidentRepository) CreateMerit(ctx context.Context, m *models.StudentMerit) error {
	return r.db.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_student_merits
		(tenant_id, school_year_id, student_id, enrollment_id, titulo, descricao, data_merito, atribuido_por)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
		RETURNING id, tenant_id, school_year_id, student_id, enrollment_id, titulo, descricao, data_merito, atribuido_por, created_at`,
		m.TenantID, m.SchoolYearID, m.StudentID, m.EnrollmentID, m.Titulo, m.Descricao, m.DataMerito, m.AtribuidoPor,
	).Scan(&m.ID, &m.TenantID, &m.SchoolYearID, &m.StudentID, &m.EnrollmentID, &m.Titulo, &m.Descricao, &m.DataMerito, &m.AtribuidoPor, &m.CreatedAt)
}
