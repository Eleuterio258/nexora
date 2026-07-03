package models

import "time"

// IncidentType representa um tipo de ocorrência disciplinar.
type IncidentType struct {
	ID                  int64     `json:"id"`
	TenantID            int64     `json:"tenant_id"`
	Codigo              string    `json:"codigo"`
	Nome                string    `json:"nome"`
	Gravidade           string    `json:"gravidade"`
	RequerEncarregado   bool      `json:"requer_encarregado"`
	Activo              bool      `json:"activo"`
	CreatedAt           time.Time `json:"created_at"`
}

// SanctionType representa um tipo de sanção.
type SanctionType struct {
	ID        int64     `json:"id"`
	TenantID  int64     `json:"tenant_id"`
	Codigo    string    `json:"codigo"`
	Nome      string    `json:"nome"`
	Gravidade string    `json:"gravidade"`
	Activo    bool      `json:"activo"`
	CreatedAt time.Time `json:"created_at"`
}

// StudentIncident representa uma ocorrência disciplinar de um aluno.
type StudentIncident struct {
	ID               int64     `json:"id"`
	TenantID         int64     `json:"tenant_id"`
	SchoolYearID     int64     `json:"school_year_id"`
	StudentID        int64     `json:"student_id"`
	EnrollmentID     *int64    `json:"enrollment_id,omitempty"`
	IncidentTypeID   *int64    `json:"incident_type_id,omitempty"`
	ReportedBy       int64     `json:"reported_by"`
	DataOcorrencia   time.Time `json:"data_ocorrencia"`
	HoraOcorrencia   *string   `json:"hora_ocorrencia,omitempty"`
	Local            string    `json:"local,omitempty"`
	Descricao        string    `json:"descricao"`
	Testemunhas      string    `json:"testemunhas,omitempty"`
	Anexos           []string  `json:"anexos,omitempty"`
	Status           string    `json:"status"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

// StudentSanction representa uma sanção aplicada a um aluno.
type StudentSanction struct {
	ID             int64      `json:"id"`
	TenantID       int64      `json:"tenant_id"`
	IncidentID     int64      `json:"incident_id"`
	SanctionTypeID *int64     `json:"sanction_type_id,omitempty"`
	AplicadoPor    int64      `json:"aplicado_por"`
	DataInicio     time.Time  `json:"data_inicio"`
	DataFim        *time.Time `json:"data_fim,omitempty"`
	Descricao      string     `json:"descricao,omitempty"`
	Cumprida       bool       `json:"cumprida"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
}

// StudentMerit representa uma distinção ou mérito de um aluno.
type StudentMerit struct {
	ID           int64     `json:"id"`
	TenantID     int64     `json:"tenant_id"`
	SchoolYearID int64     `json:"school_year_id"`
	StudentID    int64     `json:"student_id"`
	EnrollmentID *int64    `json:"enrollment_id,omitempty"`
	Titulo       string    `json:"titulo"`
	Descricao    string    `json:"descricao,omitempty"`
	DataMerito   time.Time `json:"data_merito"`
	AtribuidoPor *int64    `json:"atribuido_por,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
}
