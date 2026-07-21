// Package models contém as structs de domínio do módulo de Recursos Humanos
// específicas para o sistema flexível de controlo de assiduidade.
package models

import (
	"time"

	"github.com/jackc/pgx/v5/pgtype"
)

// ═══════════════════════════════════════════════════════════════════
// Catálogos configuráveis
// ═══════════════════════════════════════════════════════════════════

// TipoEvento representa um tipo de evento de assiduidade configurável.
type TipoEvento struct {
	ID            int64     `json:"id"`
	TenantID      int64     `json:"tenant_id"`
	Codigo        string    `json:"codigo"`
	Nome          string    `json:"nome"`
	Categoria     string    `json:"categoria"`
	Sentido       *string   `json:"sentido,omitempty"`
	TipoPar       *string   `json:"tipo_par,omitempty"`
	AfetaCalculo  string    `json:"afeta_calculo"`
	Cor           *string   `json:"cor,omitempty"`
	Ativo         bool      `json:"ativo"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// MetodoMarcacao representa um método de marcação (biometria, app, manual, etc.).
type MetodoMarcacao struct {
	ID                int64     `json:"id"`
	TenantID          int64     `json:"tenant_id"`
	Codigo            string    `json:"codigo"`
	Nome              string    `json:"nome"`
	RequerDispositivo bool      `json:"requer_dispositivo"`
	RequerLocalizacao bool      `json:"requer_localizacao"`
	RequerSelfie      bool      `json:"requer_selfie"`
	Ativo             bool      `json:"ativo"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// TipoRegra representa um tipo de regra configurável (tolerância, máximo extra, etc.).
type TipoRegra struct {
	ID          int64  `json:"id"`
	Codigo      string `json:"codigo"`
	Nome        string `json:"nome"`
	Descricao   string `json:"descricao"`
	Parametros  []byte `json:"parametros"`
	TipoValor   string `json:"tipo_valor"`
}

// ═══════════════════════════════════════════════════════════════════
// Horários
// ═══════════════════════════════════════════════════════════════════

// HorarioTrabalho representa um horário de trabalho (fixo, flexível, turno, etc.).
type HorarioTrabalho struct {
	ID                   int64          `json:"id"`
	TenantID             int64          `json:"tenant_id"`
	Codigo               string         `json:"codigo"`
	Nome                 string         `json:"nome"`
	Descricao            *string        `json:"descricao,omitempty"`
	Tipo                 string         `json:"tipo"`
	Contagem             string         `json:"contagem"`
	CargaDiariaMinima    *time.Duration `json:"carga_diaria_minima,omitempty"`
	CargaDiariaMaxima    *time.Duration `json:"carga_diaria_maxima,omitempty"`
	CargaSemanal         *time.Duration `json:"carga_semanal,omitempty"`
	JanelaEntradaInicio  *time.Duration `json:"janela_entrada_inicio,omitempty"`
	JanelaEntradaFim     *time.Duration `json:"janela_entrada_fim,omitempty"`
	HoraEntrada          string         `json:"hora_entrada,omitempty"`       // legado
	HoraSaida            string         `json:"hora_saida,omitempty"`         // legado
	IntervaloInicio      *string        `json:"intervalo_inicio,omitempty"`     // legado
	IntervaloFim         *string        `json:"intervalo_fim,omitempty"`      // legado
	DiasSemana           string         `json:"dias_semana,omitempty"`        // legado
	CargaSemanalHoras    *float64       `json:"carga_semanal_horas,omitempty"` // legado
	Ativo                bool           `json:"ativo"`
	CreatedAt            time.Time      `json:"created_at"`
	UpdatedAt            time.Time      `json:"updated_at"`
}

// HorarioDia representa a configuração de um dia específico dentro de um horário.
type HorarioDia struct {
	ID                       int64         `json:"id"`
	HorarioID                int64         `json:"horario_id"`
	DiaSemana                *int16        `json:"dia_semana,omitempty"`
	DataEspecifica           *time.Time    `json:"data_especifica,omitempty"`
	Ordem                    int16         `json:"ordem"`
	HoraEntrada              time.Duration `json:"hora_entrada"`
	HoraSaida                time.Duration `json:"hora_saida"`
	IntervaloInicio          *time.Duration `json:"intervalo_inicio,omitempty"`
	IntervaloFim             *time.Duration `json:"intervalo_fim,omitempty"`
	ToleranciaAtraso         time.Duration `json:"tolerancia_atraso"`
	ToleranciaSaidaAntecipada time.Duration `json:"tolerancia_saida_antecipada"`
	EhNocturno               bool          `json:"eh_nocturno"`
	CreatedAt                time.Time     `json:"created_at"`
	UpdatedAt                time.Time     `json:"updated_at"`
}

// FuncionarioHorario representa a associação de um funcionário a um horário com vigência.
type FuncionarioHorario struct {
	ID            int64      `json:"id"`
	TenantID      int64      `json:"tenant_id"`
	FuncionarioID int64      `json:"funcionario_id"`
	HorarioID     int64      `json:"horario_id"`
	DataInicio    time.Time  `json:"data_inicio"`
	DataFim       *time.Time `json:"data_fim,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`
}

// ═══════════════════════════════════════════════════════════════════
// Eventos de assiduidade
// ═══════════════════════════════════════════════════════════════════

// EventoAssiduidade representa uma marcação/occurrence individual.
type EventoAssiduidade struct {
	ID               int64        `json:"id"`
	TenantID         int64        `json:"tenant_id"`
	FuncionarioID    int64        `json:"funcionario_id"`
	TipoEventoID     int64        `json:"tipo_evento_id"`
	TipoEventoCodigo *string      `json:"tipo_evento_codigo,omitempty"`
	TipoEventoNome   *string      `json:"tipo_evento_nome,omitempty"`
	MetodoID         *int64       `json:"metodo_id,omitempty"`
	MetodoCodigo     *string      `json:"metodo_codigo,omitempty"`
	OcorridoEm       time.Time    `json:"ocorrido_em"`
	DataReferencia   time.Time    `json:"data_referencia"`
	Origem           string       `json:"origem"`
	DispositivoID    *int64       `json:"dispositivo_id,omitempty"`
	QRTokenID        *int64       `json:"qr_token_id,omitempty"`
	NFCTagID         *int64       `json:"nfc_tag_id,omitempty"`
	Latitude         *float64     `json:"latitude,omitempty"`
	Longitude        *float64     `json:"longitude,omitempty"`
	LocalidadeID     *int64       `json:"localidade_id,omitempty"`
	DentroGeofence   *bool        `json:"dentro_geofence,omitempty"`
	FotoURL          *string      `json:"foto_url,omitempty"`
	DocumentoURL     *string      `json:"documento_url,omitempty"`
	Estado           string       `json:"estado"`
	RegistadoPor     *int64       `json:"registado_por,omitempty"`
	Motivo           *string      `json:"motivo,omitempty"`
	Observacoes      *string      `json:"observacoes,omitempty"`
	EventoPaiID      *int64       `json:"evento_pai_id,omitempty"`
	DuplicadoDeID    *int64       `json:"duplicado_de_id,omitempty"`
	IPOrigem         *string      `json:"ip_origem,omitempty"`
	UserAgent        *string      `json:"user_agent,omitempty"`
	HashDigital      *string      `json:"hash_digital,omitempty"`
	CreatedAt        time.Time    `json:"created_at"`
	UpdatedAt        time.Time    `json:"updated_at"`
}

// ═══════════════════════════════════════════════════════════════════
// Resultados calculados
// ═══════════════════════════════════════════════════════════════════

// ResultadoDiario representa o resultado calculado de um dia de trabalho.
type ResultadoDiario struct {
	ID                     int64          `json:"id"`
	TenantID               int64          `json:"tenant_id"`
	FuncionarioID          int64          `json:"funcionario_id"`
	DataReferencia         time.Time      `json:"data_referencia"`
	HorarioID              *int64         `json:"horario_id,omitempty"`
	HorasTrabalhadas       *time.Duration `json:"horas_trabalhadas,omitempty"`
	HorasNormais           *time.Duration `json:"horas_normais,omitempty"`
	HorasExtra             *time.Duration `json:"horas_extra,omitempty"`
	HorasNocturnas         *time.Duration `json:"horas_nocturnas,omitempty"`
	HorasRemoto            *time.Duration `json:"horas_remoto,omitempty"`
	HorasMissao            *time.Duration `json:"horas_missao,omitempty"`
	HorasFormacao          *time.Duration `json:"horas_formacao,omitempty"`
	HorasIntervalo         *time.Duration `json:"horas_intervalo,omitempty"`
	HorasNaoContabilizadas *time.Duration `json:"horas_nao_contabilizadas,omitempty"`
	AtrasoMinutos          int32          `json:"atraso_minutos"`
	SaidaAntecipadaMinutos int32          `json:"saida_antecipada_minutos"`
	Ausencia               bool           `json:"ausencia"`
	FaltaJustificada       bool           `json:"falta_justificada"`
	FaltaInjustificada     bool           `json:"falta_injustificada"`
	SaldoDiario            *time.Duration `json:"saldo_diario,omitempty"`
	SaldoSemanal           *time.Duration `json:"saldo_semanal,omitempty"`
	SaldoMensal            *time.Duration `json:"saldo_mensal,omitempty"`
	BancoHoras             *time.Duration `json:"banco_horas,omitempty"`
	VersaoRegra            int32          `json:"versao_regra"`
	RecalculadoEm          *time.Time     `json:"recalculado_em,omitempty"`
	CreatedAt              time.Time      `json:"created_at"`
	UpdatedAt              time.Time      `json:"updated_at"`
}

// ResultadoPeriodo representa o resultado acumulado de uma semana ou mês.
type ResultadoPeriodo struct {
	ID            int64          `json:"id"`
	TenantID      int64          `json:"tenant_id"`
	FuncionarioID int64          `json:"funcionario_id"`
	TipoPeriodo   string         `json:"tipo_periodo"`
	Ano           int16          `json:"ano"`
	Numero        int16          `json:"numero"`
	HorasNormais  *time.Duration `json:"horas_normais,omitempty"`
	HorasExtra    *time.Duration `json:"horas_extra,omitempty"`
	HorasNocturnas *time.Duration `json:"horas_nocturnas,omitempty"`
	HorasRemoto   *time.Duration `json:"horas_remoto,omitempty"`
	HorasMissao   *time.Duration `json:"horas_missao,omitempty"`
	AtrasosMinutos int32          `json:"atrasos_minutos"`
	Faltas         int32          `json:"faltas"`
	Saldo          *time.Duration `json:"saldo,omitempty"`
	RecalculadoEm  *time.Time     `json:"recalculado_em,omitempty"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
}

// ═══════════════════════════════════════════════════════════════════
// Regras configuráveis
// ═══════════════════════════════════════════════════════════════════

// RegraAssiduidade representa uma regra aplicável a um âmbito específico.
type RegraAssiduidade struct {
	ID          int64          `json:"id"`
	TenantID    int64          `json:"tenant_id"`
	TipoRegraID int64          `json:"tipo_regra_id"`
	TipoRegraCodigo *string    `json:"tipo_regra_codigo,omitempty"`
	Ambito      string         `json:"ambito"`
	EntidadeID  *int64         `json:"entidade_id,omitempty"`
	DataInicio  time.Time      `json:"data_inicio"`
	DataFim     *time.Time     `json:"data_fim,omitempty"`
	Valor       []byte         `json:"valor"`
	Prioridade  int16          `json:"prioridade"`
	Ativo       bool           `json:"ativo"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
}

// RegraResolvida é uma regra já resolvida com o seu valor interpretado.
type RegraResolvida struct {
	Codigo     string
	Parametros map[string]any
	Ambito     string
	Prioridade int16
}

// ═══════════════════════════════════════════════════════════════════
// Correcções
// ═══════════════════════════════════════════════════════════════════

// CorrecaoEvento representa um pedido de correcção de um evento.
type CorrecaoEvento struct {
	ID                     int64      `json:"id"`
	TenantID               int64      `json:"tenant_id"`
	FuncionarioID          int64      `json:"funcionario_id"`
	EventoID               *int64     `json:"evento_id,omitempty"`
	DataReferencia         time.Time  `json:"data_referencia"`
	Tipo                   string     `json:"tipo"`
	TipoEventoID           *int64     `json:"tipo_evento_id,omitempty"`
	OcorridoEmSolicitado   *time.Time `json:"ocorrido_em_solicitado,omitempty"`
	LocalidadeIDSolicitada *int64     `json:"localidade_id_solicitada,omitempty"`
	Motivo                 string     `json:"motivo"`
	DocumentoURL           *string    `json:"documento_url,omitempty"`
	Estado                 string     `json:"estado"`
	SolicitadoPor          int64      `json:"solicitado_por"`
	SolicitadoEm           time.Time  `json:"solicitado_em"`
	DecididoPor            *int64     `json:"decidido_por,omitempty"`
	DecididoEm             *time.Time `json:"decidido_em,omitempty"`
	JustificacaoDecisao    *string    `json:"justificacao_decisao,omitempty"`
	EventoGeradoID         *int64     `json:"evento_gerado_id,omitempty"`
	CreatedAt              time.Time  `json:"created_at"`
	UpdatedAt              time.Time  `json:"updated_at"`
}

// ═══════════════════════════════════════════════════════════════════
// Auditoria
// ═══════════════════════════════════════════════════════════════════

// AuditoriaAssiduidade representa um registo de auditoria.
type AuditoriaAssiduidade struct {
	ID            int64          `json:"id"`
	TenantID      int64          `json:"tenant_id"`
	Tabela        string         `json:"tabela"`
	RegistoID     int64          `json:"registo_id"`
	Operacao      string         `json:"operacao"`
	Campo         *string        `json:"campo,omitempty"`
	ValorAnterior []byte         `json:"valor_anterior,omitempty"`
	ValorNovo     []byte         `json:"valor_novo,omitempty"`
	AlteradoPor   *int64         `json:"alterado_por,omitempty"`
	Motivo        *string        `json:"motivo,omitempty"`
	IPOrigem      *string        `json:"ip_origem,omitempty"`
	Dispositivo   *string        `json:"dispositivo,omitempty"`
	Localizacao   *string        `json:"localizacao,omitempty"`
	EstadoAnterior *string       `json:"estado_anterior,omitempty"`
	EstadoNovo    *string        `json:"estado_novo,omitempty"`
	CreatedAt     time.Time      `json:"created_at"`
}

// ═══════════════════════════════════════════════════════════════════
// DTOs de entrada
// ═══════════════════════════════════════════════════════════════════

// CriarEventoRequest representa o payload para criar um evento.
type CriarEventoRequest struct {
	FuncionarioID  int64    `json:"funcionario_id"`
	TipoEventoCodigo string `json:"tipo_evento_codigo"`
	MetodoCodigo   *string  `json:"metodo_codigo,omitempty"`
	OcorridoEm     *time.Time `json:"ocorrido_em,omitempty"`
	DataReferencia *string    `json:"data_referencia,omitempty"`
	Origem         string     `json:"origem"`
	Latitude       *float64   `json:"latitude,omitempty"`
	Longitude      *float64   `json:"longitude,omitempty"`
	LocalidadeID   *int64     `json:"localidade_id,omitempty"`
	DentroGeofence *bool      `json:"dentro_geofence,omitempty"`
	FotoURL        *string    `json:"foto_url,omitempty"`
	DocumentoURL   *string    `json:"documento_url,omitempty"`
	Motivo         *string    `json:"motivo,omitempty"`
	Observacoes    *string    `json:"observacoes,omitempty"`
}

// CriarCorrecaoRequest representa o payload para submeter uma correcção.
type CriarCorrecaoRequest struct {
	FuncionarioID          int64      `json:"funcionario_id"`
	EventoID               *int64     `json:"evento_id,omitempty"`
	DataReferencia         string     `json:"data_referencia"`
	Tipo                   string     `json:"tipo"`
	TipoEventoCodigo       *string    `json:"tipo_evento_codigo,omitempty"`
	OcorridoEmSolicitado   *time.Time `json:"ocorrido_em_solicitado,omitempty"`
	LocalidadeIDSolicitada *int64     `json:"localidade_id_solicitada,omitempty"`
	Motivo                 string     `json:"motivo"`
	DocumentoURL           *string    `json:"documento_url,omitempty"`
}

// CriarRegraRequest representa o payload para criar uma regra.
type CriarRegraRequest struct {
	TipoRegraCodigo string         `json:"tipo_regra_codigo"`
	Ambito          string         `json:"ambito"`
	EntidadeID      *int64         `json:"entidade_id,omitempty"`
	DataInicio      string         `json:"data_inicio"`
	DataFim         *string        `json:"data_fim,omitempty"`
	Valor           map[string]any `json:"valor"`
	Prioridade      int16          `json:"prioridade"`
}

// ResultadoDiarioRequest representa os parâmetros para consultar resultados.
type ResultadoDiarioRequest struct {
	FuncionarioID int64  `json:"funcionario_id"`
	DataInicio    string `json:"data_inicio"`
	DataFim       string `json:"data_fim"`
}

// pgtype.Duration é um helper para mapear INTERVAL do PostgreSQL.
// pgx/v5 já mapeia INTERVAL para time.Duration, mas mantemos a referência para clareza.
var _ = pgtype.Interval{}

// StringPtr devolve um ponteiro para string.
func StringPtr(s string) *string { return &s }

// Int64Ptr devolve um ponteiro para int64.
func Int64Ptr(i int64) *int64 { return &i }

// BoolPtr devolve um ponteiro para bool.
func BoolPtr(b bool) *bool { return &b }

// Float64Ptr devolve um ponteiro para float64.
func Float64Ptr(f float64) *float64 { return &f }
