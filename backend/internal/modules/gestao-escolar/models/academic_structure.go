package models

import "time"

// Level representa um nível de ensino (primário, secundário, técnico, superior).
type Level struct {
	ID                     int64     `json:"id"`
	TenantID               int64     `json:"tenant_id"`
	Codigo                 string    `json:"codigo"`
	Nome                   string    `json:"nome"`
	Descricao              string    `json:"descricao,omitempty"`
	Ordem                  int       `json:"ordem"`
	NotaMinimaAprovacao    float64   `json:"nota_minima_aprovacao"`
	EscalaMaxima           float64   `json:"escala_maxima"`
	SistemaAvaliacao       string    `json:"sistema_avaliacao"`
	NumeroPeriodosPadrao   int       `json:"numero_periodos_padrao"`
	NomenclaturaPeriodo    string    `json:"nomenclatura_periodo"`
	NomenclaturaSerie      string    `json:"nomenclatura_serie"`
	IdadeMinima            *int      `json:"idade_minima,omitempty"`
	IdadeMaxima            *int      `json:"idade_maxima,omitempty"`
	Activo                 bool      `json:"activo"`
	CreatedAt              time.Time `json:"created_at"`
	UpdatedAt              time.Time `json:"updated_at"`
}

// Cycle representa um ciclo dentro de um nível de ensino.
type Cycle struct {
	ID        int64     `json:"id"`
	TenantID  int64     `json:"tenant_id"`
	LevelID   int64     `json:"level_id"`
	Codigo    string    `json:"codigo"`
	Nome      string    `json:"nome"`
	Ordem     int       `json:"ordem"`
	Activo    bool      `json:"activo"`
	CreatedAt time.Time `json:"created_at"`
}

// Series representa uma série/ano/semestre dentro de um nível/ciclo.
type Series struct {
	ID        int64     `json:"id"`
	TenantID  int64     `json:"tenant_id"`
	LevelID   int64     `json:"level_id"`
	CycleID   *int64    `json:"cycle_id,omitempty"`
	Codigo    string    `json:"codigo"`
	Nome      string    `json:"nome"`
	Ordem     int       `json:"ordem"`
	Activo    bool      `json:"activo"`
	CreatedAt time.Time `json:"created_at"`
}

// Course representa um curso técnico ou universitário.
type Course struct {
	ID           int64     `json:"id"`
	TenantID     int64     `json:"tenant_id"`
	LevelID      int64     `json:"level_id"`
	Codigo       string    `json:"codigo"`
	Nome         string    `json:"nome"`
	Descricao    string    `json:"descricao,omitempty"`
	DuracaoAnos  int       `json:"duracao_anos"`
	Modalidade   string    `json:"modalidade"`
	Grau         string    `json:"grau,omitempty"`
	Activo       bool      `json:"activo"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// CourseSubject associa disciplinas a cursos/séries.
type CourseSubject struct {
	ID                   int64     `json:"id"`
	TenantID             int64     `json:"tenant_id"`
	CourseID             *int64    `json:"course_id,omitempty"`
	LevelID              *int64    `json:"level_id,omitempty"`
	SeriesID             *int64    `json:"series_id,omitempty"`
	SubjectID            int64     `json:"subject_id"`
	Obrigatoria          bool      `json:"obrigatoria"`
	CargaHorariaSemanal  *int      `json:"carga_horaria_semanal,omitempty"`
	Componente           string    `json:"componente"`
	Activo               bool      `json:"activo"`
	CreatedAt            time.Time `json:"created_at"`
}
