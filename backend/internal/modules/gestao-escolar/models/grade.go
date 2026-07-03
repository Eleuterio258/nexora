package models

import "time"

// GradeItem representa uma avaliação (teste, exame, etc.).
type GradeItem struct {
	ID           int64     `json:"id"`
	TenantID     int64     `json:"tenant_id"`
	ClassID      int64     `json:"class_id"`
	SubjectID    int64     `json:"subject_id"`
	TermID       int64     `json:"term_id"`
	Nome         string    `json:"nome"`
	Tipo         string    `json:"tipo"`
	DataAvaliacao time.Time `json:"data_avaliacao"`
	NotaMaxima   float64   `json:"nota_maxima"`
	Peso         float64   `json:"peso"`
	Publicado    bool      `json:"publicado"`
	CreatedBy    *int64    `json:"created_by,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// Grade representa uma nota atribuída a um aluno.
type Grade struct {
	ID           int64     `json:"id"`
	TenantID     int64     `json:"tenant_id"`
	GradeItemID  int64     `json:"grade_item_id"`
	StudentID    int64     `json:"student_id"`
	EnrollmentID *int64    `json:"enrollment_id,omitempty"`
	Nota         float64   `json:"nota"`
	Observacoes  string    `json:"observacoes,omitempty"`
	LancadoPor   *int64    `json:"lancado_por,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// GradeScale representa uma escala de avaliação.
type GradeScale struct {
	Sistema    string  `json:"sistema"`
	Maxima     float64 `json:"maxima"`
	Minima     float64 `json:"minima"`
	Aprovacao  float64 `json:"aprovacao"`
}
