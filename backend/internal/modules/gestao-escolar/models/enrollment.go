package models

import "time"

// Enrollment representa uma matrícula.
type Enrollment struct {
	ID           int64      `json:"id"`
	TenantID     int64      `json:"tenant_id"`
	SchoolYearID *int64     `json:"school_year_id,omitempty"`
	StudentID    int64      `json:"student_id"`
	ClassID      int64      `json:"class_id"`
	Numero       string     `json:"numero"`
	DataMatricula time.Time `json:"data_matricula"`
	Tipo         string     `json:"tipo"`
	Status       string     `json:"status"`
	Observacoes  string     `json:"observacoes,omitempty"`
	TransferredAt *time.Time `json:"transferred_at,omitempty"`
	CancelledAt  *time.Time `json:"cancelled_at,omitempty"`
	CreatedBy    *int64     `json:"created_by,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
}

// EnrollmentCreate payload.
type EnrollmentCreate struct {
	SchoolYearID *int64 `json:"school_year_id,omitempty"`
	StudentID    int64  `json:"student_id"`
	ClassID      int64  `json:"class_id"`
	Numero       string `json:"numero"`
	DataMatricula string `json:"data_matricula,omitempty"`
	Tipo         string `json:"tipo,omitempty"`
	Observacoes  string `json:"observacoes,omitempty"`
}

// EnrollmentTransfer payload.
type EnrollmentTransfer struct {
	ClassID int64  `json:"class_id"`
	Motivo  string `json:"motivo,omitempty"`
}
