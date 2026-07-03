// Package contracts define as interfaces (ports) que permitem ao módulo
// Gestão Escolar comunicar com outros módulos do ERP sem depender
// directamente dos seus schemas ou implementações internas.
//
// Padrão: Ports & Adapters (Hexagonal Architecture).
// O módulo escolar depende apenas destas interfaces; as implementações
// concretas vivem nos adaptadores e são injectadas em runtime.
package contracts

import (
	"context"
	"time"
)

// ── Tesouraria ──────────────────────────────────────────────────────────────

// TreasuryPort regista movimentos de recebimento no módulo Tesouraria.
type TreasuryPort interface {
	RecordReceipt(ctx context.Context, p TreasuryReceipt) error
}

// TreasuryReceipt dados de um movimento de recebimento.
type TreasuryReceipt struct {
	TenantID        int64
	ContaBancariaID *int64
	Valor           float64
	Moeda           string
	Referencia      string
	Descricao       string
	OrigemTipo      string
	OrigemID        *int64
	DataMovimento   time.Time
}

// ── Financeiro ──────────────────────────────────────────────────────────────

// FinancialPort regista recebimentos no módulo Financeiro.
type FinancialPort interface {
	RecordReceivable(ctx context.Context, p FinancialReceivable) error
}

// FinancialReceivable dados para criar conta a receber + pagamento.
type FinancialReceivable struct {
	TenantID       int64
	Numero         string
	OrigemTipo     string
	OrigemID       int64
	Descricao      string
	Valor          float64
	Moeda          string
	DataVencimento time.Time
	CreatedBy      *int64
}

// ── Contabilidade ───────────────────────────────────────────────────────────

// AccountingPort cria lançamentos contabilísticos no módulo Contabilidade.
type AccountingPort interface {
	RecordJournalEntry(ctx context.Context, e JournalEntry) error
}

// JournalEntry cabeçalho + linhas de um lançamento contabilístico.
type JournalEntry struct {
	TenantID    int64
	Numero      string
	Descricao   string
	Referencia  string
	DataEntrada time.Time
	CreatedBy   *int64
	Linhas      []JournalLine
}

// JournalLine linha de débito ou crédito.
type JournalLine struct {
	ContaID int64   // chart_of_accounts.id
	Debito  float64 // valor a débito (0 se crédito)
	Credito float64 // valor a crédito (0 se débito)
	Memo    string
}

// ── Faturação ───────────────────────────────────────────────────────────────

// InvoicingPort emite documentos fiscais (recibos, faturas) via módulo Faturação.
type InvoicingPort interface {
	// CreateReceipt emite um recibo (tipo RB) para um pagamento escolar.
	// Devolve o ID do documento criado.
	CreateReceipt(ctx context.Context, r SchoolReceipt) (int64, error)
}

// SchoolReceipt dados para criação de recibo de propina.
type SchoolReceipt struct {
	TenantID   int64
	CustomerID int64 // gestao_clientes.customers.id
	Numero     string
	Descricao  string
	Valor      float64
	Moeda      string
	DataEmissao time.Time
	CreatedBy  *int64
}

// ── Notificações ────────────────────────────────────────────────────────────

// NotificationPort envia notificações a utilizadores do ERP.
type NotificationPort interface {
	Send(ctx context.Context, n Notification)
}

// Notification dados de uma notificação.
type Notification struct {
	TenantID       int64
	CanalTipo      string
	Destinatario   string
	Assunto        string
	Corpo          string
	TemplateID     *int64
	ReferenciaTipo string  // origem: "escolar.notas", "escolar.pagamento", etc.
	ReferenciaID   *int64  // ID da entidade de origem
}

// ── Recursos Humanos ────────────────────────────────────────────────────────

// HRPort consulta e gere entidades no módulo Recursos Humanos.
type HRPort interface {
	// GetEmployeeID devolve o ID de rh.funcionarios para um user_id, ou 0 se não existir.
	GetEmployeeID(ctx context.Context, tenantID, userID int64) (int64, error)
	// CreateEmployee cria um funcionário em rh.funcionarios para um professor escolar.
	// Devolve o ID do funcionário criado.
	CreateEmployee(ctx context.Context, e HREmployee) (int64, error)
}

// HREmployee dados mínimos para criar um funcionário no módulo RH.
type HREmployee struct {
	TenantID    int64
	Nome        string
	Email       string
	Telefone    string
	NomeNumero  string // numero de funcionário, ex: "PROF-2026-001"
	DataAdmissao time.Time
	Cargo       string
}

// ── Clientes ────────────────────────────────────────────────────────────────

// ClientPort consulta e gere entidades no módulo Gestão de Clientes.
type ClientPort interface {
	// GetClientID devolve o ID de gestao_clientes.customers pelo email, ou 0 se não existir.
	GetClientID(ctx context.Context, tenantID int64, email string) (int64, error)
	// CreateClient cria um cliente em gestao_clientes.customers.
	// Devolve o ID do cliente criado.
	CreateClient(ctx context.Context, c ClientData) (int64, error)
}

// ClientData dados mínimos para criar um cliente.
type ClientData struct {
	TenantID int64
	Nome     string
	Email    string
	Telefone string
	Nuit     string
	Tipo     string // "encarregado", "aluno", etc. (customer_group_id será resolvido pelo adapter)
}

// ── Aprovações ──────────────────────────────────────────────────────────────

// ApprovalPort verifica e submete fluxos de aprovação do ERP.
type ApprovalPort interface {
	// NeedsApproval verifica se a feature requer aprovação para o valor dado.
	// Devolve nil se não necessitar de aprovação.
	NeedsApproval(ctx context.Context, tenantID int64, feature string, valor float64) (*ApprovalFlow, error)
	// CreateRequest cria um pedido de aprovação.
	CreateRequest(ctx context.Context, tenantID, flowID, entidadeID, criadoPor int64, entidade string) error
}

// ApprovalFlow resumo de um fluxo de aprovação activo.
type ApprovalFlow struct {
	ID     int64
	Nome   string
	Niveis int
}

// ── Sistema de Configuração ─────────────────────────────────────────────────

// SystemConfigPort lê e grava configurações do ERP por tenant.
type SystemConfigPort interface {
	// Get devolve o valor de uma configuração. Devolve "" se não existir.
	Get(ctx context.Context, tenantID int64, chave string) (string, error)
	// Set grava ou actualiza uma configuração por tenant.
	Set(ctx context.Context, tenantID int64, chave, valor string) error
}
