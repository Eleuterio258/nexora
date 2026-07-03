package models

import "time"

// Teacher representa um professor no sistema.
type Teacher struct {
	ID                        int64      `json:"id"`
	TenantID                  int64      `json:"tenant_id"`
	UserID                    *int64     `json:"user_id,omitempty"`
	Codigo                    string     `json:"codigo"`
	NomeCompleto              string     `json:"nome_completo"`
	Genero                    string     `json:"genero,omitempty"`
	Telefone                  string     `json:"telefone,omitempty"`
	Email                     string     `json:"email,omitempty"`
	DocumentoIdentificacao    string     `json:"documento_identificacao,omitempty"`
	Especialidade             string     `json:"especialidade,omitempty"`
	CargaHorariaMaximaSemanal int        `json:"carga_horaria_maxima_semanal"`
	Status                    string     `json:"status"`
	CreatedAt                 time.Time  `json:"created_at"`
	UpdatedAt                 time.Time  `json:"updated_at"`
}

// TeacherCreate é o payload para criação de professor.
type TeacherCreate struct {
	UserID                    *int64 `json:"user_id,omitempty"`
	Codigo                    string `json:"codigo"`
	NomeCompleto              string `json:"nome_completo"`
	Genero                    string `json:"genero,omitempty"`
	Telefone                  string `json:"telefone,omitempty"`
	Email                     string `json:"email,omitempty"`
	DocumentoIdentificacao    string `json:"documento_identificacao,omitempty"`
	Especialidade             string `json:"especialidade,omitempty"`
	CargaHorariaMaximaSemanal int    `json:"carga_horaria_maxima_semanal"`
}

// TeacherUpdate é o payload para actualização parcial de professor.
type TeacherUpdate struct {
	UserID                    *int64  `json:"user_id,omitempty"`
	Codigo                    *string `json:"codigo,omitempty"`
	NomeCompleto              *string `json:"nome_completo,omitempty"`
	Genero                    *string `json:"genero,omitempty"`
	Telefone                  *string `json:"telefone,omitempty"`
	Email                     *string `json:"email,omitempty"`
	DocumentoIdentificacao    *string `json:"documento_identificacao,omitempty"`
	Especialidade             *string `json:"especialidade,omitempty"`
	CargaHorariaMaximaSemanal *int    `json:"carga_horaria_maxima_semanal,omitempty"`
	Status                    *string `json:"status,omitempty"`
}

// TeacherWorkload representa a carga horária semanal de um professor.
type TeacherWorkload struct {
	TeacherID             int64 `json:"teacher_id"`
	CargaHorariaAtribuida int   `json:"carga_horaria_atribuida"`
	CargaHorariaMaxima    int   `json:"carga_horaria_maxima"`
}
