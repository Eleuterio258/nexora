package handlers

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"
)

// itemFaturaPOS espelha uma linha de pos_sale_items com os valores já
// calculados por CriarVenda (subtotal/desconto/imposto/total por item),
// reaproveitados aqui em vez de recalculados, para a fatura nunca poder
// divergir dos valores realmente cobrados na venda.
type itemFaturaPOS struct {
	ProductID        int64
	ProductVariantID *int64
	Descricao        *string
	Quantidade       float64
	PrecoUnitario    float64
	DescontoValor    float64
	ImpostoValor     float64
	Subtotal         float64
	Total            float64
}

type faturaVendaParams struct {
	tenantID   int64
	customerID int64
	userID     int64
	itens      []itemFaturaPOS
	subtotal   float64
	desconto   float64
	imposto    float64
	total      float64
	moeda      string
}

// consumidorFinalID resolve (criando se necessário) o cliente genérico
// "Consumidor Final" do tenant — usado como customer_id da fatura fiscal
// quando a venda POS não identificou um cliente. Todo o ERP exige
// customers.customer_id nas faturas (ver CriarFatura em modulo-faturacao);
// como o POS deliberadamente não obriga o operador a escolher um cliente
// por venda, este registo-placeholder é o que torna "fatura sempre
// automática" possível sem bloquear vendas de balcão.
func (h *Handler) consumidorFinalID(ctx context.Context, tx pgx.Tx, tenantID int64) (int64, error) {
	var id int64
	err := tx.QueryRow(ctx, `
		INSERT INTO clientes.customers (tenant_id, codigo, nome, estado)
		VALUES ($1, 'CONSUMIDOR-FINAL', 'Consumidor Final', 'ativo')
		ON CONFLICT (tenant_id, codigo) DO UPDATE SET codigo = EXCLUDED.codigo
		RETURNING id`, tenantID).Scan(&id)
	return id, err
}

// criarFaturaParaVenda emite (não rascunho — a venda POS já está paga e
// concluída quando isto é chamado) uma fatura fiscal (série "FT") dentro da
// MESMA transacção de CriarVenda: se a fatura falhar, a venda inteira é
// revertida, para nunca poder existir uma venda POS concluída sem o
// documento fiscal correspondente.
//
// Nota: isto consome uma série diferente da que pos_sales.numero já usa
// (série "VD", ver proximoNumeroSerie em pos.go) — o número interno da
// venda POS e o número da fatura fiscal são documentos distintos,
// deliberadamente, tal como acontece com outros tipos de série (ORC/ENC/GR/
// FT/NC/RB/VD) já suportados por faturacao.invoice_series.
func (h *Handler) criarFaturaParaVenda(ctx context.Context, tx pgx.Tx, p faturaVendaParams) (invoiceID int64, numero string, err error) {
	numero, serieID, err := proximoNumeroSerie(ctx, tx, p.tenantID, "FT")
	if err != nil {
		return 0, "", err
	}

	agora := time.Now()
	err = tx.QueryRow(ctx, `
		INSERT INTO faturacao.invoices (
		  tenant_id, serie_id, customer_id, numero, invoice_date, moeda,
		  subtotal, desconto_total, imposto_total, total, valor_pago,
		  status, tipo, emitida_em, criado_por)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$10,'paga','normal',$11,$12)
		RETURNING id`,
		p.tenantID, serieID, p.customerID, numero, agora, p.moeda,
		p.subtotal, p.desconto, p.imposto, p.total, agora, p.userID,
	).Scan(&invoiceID)
	if err != nil {
		return 0, "", err
	}

	for _, item := range p.itens {
		if _, err = tx.Exec(ctx, `
			INSERT INTO faturacao.invoice_items (
			  invoice_id, product_id, descricao, quantidade, preco_unitario,
			  desconto_valor, imposto_valor, subtotal, total)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
			invoiceID, item.ProductID, item.Descricao, item.Quantidade, item.PrecoUnitario,
			item.DescontoValor, item.ImpostoValor, item.Subtotal, item.Total,
		); err != nil {
			return 0, "", err
		}
	}

	return invoiceID, numero, nil
}
