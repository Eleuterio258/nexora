package models

import "time"

// TimeSlot representa um bloco horário do dia.
type TimeSlot struct {
	ID         int64     `json:"id"`
	TenantID   int64     `json:"tenant_id"`
	Codigo     string    `json:"codigo"`
	Nome       string    `json:"nome,omitempty"`
	HoraInicio string    `json:"hora_inicio"`
	HoraFim    string    `json:"hora_fim"`
	Ordem      int       `json:"ordem"`
	Activo     bool      `json:"activo"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

// TimetableEntry representa uma aula no horário.
type TimetableEntry struct {
	ID           int64      `json:"id"`
	TenantID     int64      `json:"tenant_id"`
	SchoolYearID int64      `json:"school_year_id"`
	ClassID      int64      `json:"class_id"`
	SubjectID    int64      `json:"subject_id"`
	TeacherID    int64      `json:"teacher_id"`
	TimeSlotID   int64      `json:"time_slot_id"`
	DiaSemana    int        `json:"dia_semana"`
	Sala         string     `json:"sala,omitempty"`
	DataInicio   time.Time  `json:"data_inicio"`
	DataFim      *time.Time `json:"data_fim,omitempty"`
	Activo       bool       `json:"activo"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
}

// CalendarEventType representa os tipos de evento do calendário escolar.
type CalendarEventType struct {
	ID                  int64     `json:"id"`
	TenantID            int64     `json:"tenant_id"`
	Codigo              string    `json:"codigo"`
	Nome                string    `json:"nome"`
	Cor                 string    `json:"cor"`
	ImpactoFrequencia   string    `json:"impacto_frequencia"`
	DiaTodo             bool      `json:"dia_todo"`
	Activo              bool      `json:"activo"`
	CreatedAt           time.Time `json:"created_at"`
}

// CalendarEvent representa um evento no calendário escolar.
type CalendarEvent struct {
	ID             int64      `json:"id"`
	TenantID       int64      `json:"tenant_id"`
	SchoolYearID   int64      `json:"school_year_id"`
	EventTypeID    *int64     `json:"event_type_id,omitempty"`
	Titulo         string     `json:"titulo"`
	Descricao      string     `json:"descricao,omitempty"`
	DataInicio     time.Time  `json:"data_inicio"`
	DataFim        *time.Time `json:"data_fim,omitempty"`
	HoraInicio     *string    `json:"hora_inicio,omitempty"`
	HoraFim        *string    `json:"hora_fim,omitempty"`
	DiaTodo        bool       `json:"dia_todo"`
	PublicoAlvo    string     `json:"publico_alvo"`
	PublicoAlvoID  *int64     `json:"publico_alvo_id,omitempty"`
	CreatedBy      *int64     `json:"created_by,omitempty"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
}
