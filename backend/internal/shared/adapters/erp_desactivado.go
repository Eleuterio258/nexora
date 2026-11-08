package adapters

import (
	"context"

	"nexora/internal/shared/contracts"
)

// ERPDesactivado implementa os ports que pertencem ao ERP externo
// (tesouraria, financeiro, contabilidade, facturação, RH, clientes,
// aprovações e assinatura digital) enquanto a integração com o ERP Laravel
// não existe.
//
// As operações devolvem contracts.ErrIntegracaoERPDesactivada para que quem
// chama não registe a integração como feita. A única excepção é
// NeedsApproval: sem motor de aprovações, nenhuma operação fica pendente.
//
// Quando a API de integração do Laravel existir, substituir este tipo por
// adaptadores HTTP (idealmente alimentados por uma outbox) no router.
type ERPDesactivado struct{}

// NewERPDesactivado devolve o adaptador nulo dos ports do ERP.
func NewERPDesactivado() ERPDesactivado { return ERPDesactivado{} }

var (
	_ contracts.TreasuryPort   = ERPDesactivado{}
	_ contracts.FinancialPort  = ERPDesactivado{}
	_ contracts.AccountingPort = ERPDesactivado{}
	_ contracts.InvoicingPort  = ERPDesactivado{}
	_ contracts.HRPort         = ERPDesactivado{}
	_ contracts.ClientPort     = ERPDesactivado{}
	_ contracts.ApprovalPort   = ERPDesactivado{}
	_ contracts.SignaturePort  = ERPDesactivado{}
)

func (ERPDesactivado) RecordReceipt(context.Context, contracts.TreasuryReceipt) error {
	return contracts.ErrIntegracaoERPDesactivada
}

func (ERPDesactivado) RecordReceivable(context.Context, contracts.FinancialReceivable) error {
	return contracts.ErrIntegracaoERPDesactivada
}

func (ERPDesactivado) RecordJournalEntry(context.Context, contracts.JournalEntry) error {
	return contracts.ErrIntegracaoERPDesactivada
}

func (ERPDesactivado) CreateReceipt(context.Context, contracts.SchoolReceipt) (int64, error) {
	return 0, contracts.ErrIntegracaoERPDesactivada
}

func (ERPDesactivado) GetEmployeeID(context.Context, int64, int64) (int64, error) {
	return 0, contracts.ErrIntegracaoERPDesactivada
}

func (ERPDesactivado) CreateEmployee(context.Context, contracts.HREmployee) (int64, error) {
	return 0, contracts.ErrIntegracaoERPDesactivada
}

func (ERPDesactivado) GetClientID(context.Context, int64, string) (int64, error) {
	return 0, contracts.ErrIntegracaoERPDesactivada
}

func (ERPDesactivado) CreateClient(context.Context, contracts.ClientData) (int64, error) {
	return 0, contracts.ErrIntegracaoERPDesactivada
}

// NeedsApproval responde "não precisa de aprovação": sem motor de
// aprovações, devolver erro bloquearia os descontos para sempre.
func (ERPDesactivado) NeedsApproval(context.Context, int64, string, float64) (*contracts.ApprovalFlow, error) {
	return nil, nil
}

func (ERPDesactivado) CreateRequest(context.Context, int64, int64, int64, int64, string) error {
	return contracts.ErrIntegracaoERPDesactivada
}

func (ERPDesactivado) CreateForSigning(context.Context, contracts.SignatureDocumentRequest) (int64, error) {
	return 0, contracts.ErrIntegracaoERPDesactivada
}
