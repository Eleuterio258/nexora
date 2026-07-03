package models

import "time"

// FeePlan representa um plano de propina/taxa.
type FeePlan struct {
	ID           int64     `json:"id"`
	TenantID     int64     `json:"tenant_id"`
	SchoolYearID *int64    `json:"school_year_id,omitempty"`
	Codigo       string    `json:"codigo"`
	Nome         string    `json:"nome"`
	Tipo         string    `json:"tipo"`
	Valor        float64   `json:"valor"`
	Moeda        string    `json:"moeda"`
	Periodicidade string   `json:"periodicidade"`
	DiaVencimento *int     `json:"dia_vencimento,omitempty"`
	ClasseNivel  string    `json:"classe_nivel,omitempty"`
	Activo       bool      `json:"activo"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// SchoolFee representa uma cobrança escolar.
type SchoolFee struct {
	ID            int64      `json:"id"`
	TenantID      int64      `json:"tenant_id"`
	EnrollmentID  int64      `json:"enrollment_id"`
	FeePlanID     *int64     `json:"fee_plan_id,omitempty"`
	StudentID     *int64     `json:"student_id,omitempty"`
	Numero        string     `json:"numero"`
	Descricao     string     `json:"descricao"`
	MesReferencia string     `json:"mes_referencia,omitempty"`
	DataVencimento time.Time `json:"data_vencimento"`
	ValorTotal    float64    `json:"valor_total"`
	ValorPago     float64    `json:"valor_pago"`
	Desconto      float64    `json:"desconto"`
	DescontoMotivo string    `json:"desconto_motivo,omitempty"`
	Moeda         string     `json:"moeda"`
	Status        string     `json:"status"`
	Entidade      string     `json:"entidade,omitempty"`
	Referencia    string     `json:"referencia,omitempty"`
	EmitidaEm     *time.Time `json:"emitida_em,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`
}

// SchoolPayment representa um pagamento escolar.
type SchoolPayment struct {
	ID          int64      `json:"id"`
	TenantID    int64      `json:"tenant_id"`
	SchoolFeeID int64      `json:"school_fee_id"`
	StudentID   int64      `json:"student_id"`
	ExternalID  string     `json:"external_id,omitempty"`
	Metodo      string     `json:"metodo"`
	Referencia  string     `json:"referencia,omitempty"`
	Valor       float64    `json:"valor"`
	Moeda       string     `json:"moeda"`
	Status      string     `json:"status"`
	Conciliado  bool       `json:"conciliado"`
	PagoEm      time.Time  `json:"pago_em"`
	PayloadGateway map[string]any `json:"payload_gateway,omitempty"`
	CreatedBy   *int64     `json:"created_by,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
}
