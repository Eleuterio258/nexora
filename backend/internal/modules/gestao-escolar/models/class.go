package models

import "time"

// Class representa uma turma.
type Class struct {
	ID                 int64     `json:"id"`
	TenantID           int64     `json:"tenant_id"`
	SchoolYearID       *int64    `json:"school_year_id,omitempty"`
	LevelID            *int64    `json:"level_id,omitempty"`
	SeriesID           *int64    `json:"series_id,omitempty"`
	CourseID           *int64    `json:"course_id,omitempty"`
	Codigo             string    `json:"codigo"`
	Nome               string    `json:"nome"`
	Nivel              string    `json:"nivel,omitempty"`
	Turma              string    `json:"turma,omitempty"`
	Turno              string    `json:"turno,omitempty"`
	Sala               string    `json:"sala,omitempty"`
	Capacidade         int       `json:"capacidade"`
	DirectorTeacherID  *int64    `json:"director_teacher_id,omitempty"`
	Horario            []any     `json:"horario,omitempty"`
	Activo             bool      `json:"activo"`
	CreatedAt          time.Time `json:"created_at"`
	UpdatedAt          time.Time `json:"updated_at"`
}

// ClassCreate payload.
type ClassCreate struct {
	SchoolYearID      *int64 `json:"school_year_id,omitempty"`
	LevelID           *int64 `json:"level_id,omitempty"`
	SeriesID          *int64 `json:"series_id,omitempty"`
	CourseID          *int64 `json:"course_id,omitempty"`
	Codigo            string `json:"codigo"`
	Nome              string `json:"nome"`
	Nivel             string `json:"nivel,omitempty"`
	Turma             string `json:"turma,omitempty"`
	Turno             string `json:"turno,omitempty"`
	Sala              string `json:"sala,omitempty"`
	Capacidade        int    `json:"capacidade"`
	DirectorTeacherID *int64 `json:"director_teacher_id,omitempty"`
}

// ClassUpdate payload.
type ClassUpdate struct {
	SchoolYearID      *int64  `json:"school_year_id,omitempty"`
	LevelID           *int64  `json:"level_id,omitempty"`
	SeriesID          *int64  `json:"series_id,omitempty"`
	CourseID          *int64  `json:"course_id,omitempty"`
	Codigo            *string `json:"codigo,omitempty"`
	Nome              *string `json:"nome,omitempty"`
	Nivel             *string `json:"nivel,omitempty"`
	Turma             *string `json:"turma,omitempty"`
	Turno             *string `json:"turno,omitempty"`
	Sala              *string `json:"sala,omitempty"`
	Capacidade        *int    `json:"capacidade,omitempty"`
	DirectorTeacherID *int64  `json:"director_teacher_id,omitempty"`
	Activo            *bool   `json:"activo,omitempty"`
}
