package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) customerExists(r *http.Request, id string) bool {
	var ok bool
	user := mw.GetUser(r)
	_ = h.db.QueryRow(r.Context(),
		`SELECT EXISTS(SELECT 1 FROM clientes.customers WHERE id=$1 AND tenant_id=$2)`,
		id, user.TenantID).Scan(&ok)
	return ok
}

func (h *Handler) requireCustomer(w http.ResponseWriter, r *http.Request) bool {
	if h.customerExists(r, chi.URLParam(r, "id")) {
		return true
	}
	jsonErr(w, "Cliente nao encontrado", http.StatusNotFound)
	return false
}

func (h *Handler) ObterGrupo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var row struct {
		ID        int64      `json:"id"`
		Codigo    string     `json:"codigo"`
		Nome      string     `json:"nome"`
		Descricao *string    `json:"descricao"`
		Ativo     bool       `json:"ativo"`
		CreatedAt time.Time  `json:"created_at"`
		UpdatedAt *time.Time `json:"updated_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id,codigo,nome,descricao,ativo,created_at,updated_at
		FROM clientes.customer_groups WHERE id=$1 AND tenant_id=$2`,
		chi.URLParam(r, "id"), user.TenantID).
		Scan(&row.ID, &row.Codigo, &row.Nome, &row.Descricao, &row.Ativo, &row.CreatedAt, &row.UpdatedAt)
	if err != nil {
		jsonErr(w, "Grupo nao encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, row, http.StatusOK)
}

func (h *Handler) alterarEstadoCliente(w http.ResponseWriter, r *http.Request, action string) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	estado := "ativo"
	var motivo *string
	if action == "bloquear" {
		estado = "bloqueado"
		var body struct {
			Motivo string `json:"motivo"`
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		if strings.TrimSpace(body.Motivo) == "" {
			body.Motivo = "Bloqueio manual"
		}
		motivo = &body.Motivo
	}
	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())
	tag, err := tx.Exec(r.Context(), `
		UPDATE clientes.customers
		SET estado=$1, bloqueio_motivo=$2,
		    bloqueado_em=CASE WHEN $1='bloqueado' THEN NOW() ELSE NULL END,
		    updated_at=NOW()
		WHERE id=$3 AND tenant_id=$4`, estado, motivo, id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Cliente nao encontrado", http.StatusNotFound)
		return
	}
	descricao := "Cliente activado"
	if action == "desbloquear" {
		descricao = "Cliente desbloqueado"
	} else if action == "bloquear" {
		descricao = *motivo
	}
	_, _ = tx.Exec(r.Context(), `
		INSERT INTO clientes.customer_history(customer_id,evento,descricao,created_by)
		VALUES($1,$2,$3,$4)`, id, action, descricao, user.ID)
	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ActivarClienteSeguro(w http.ResponseWriter, r *http.Request) {
	h.alterarEstadoCliente(w, r, "activar")
}

func (h *Handler) BloquearClienteSeguro(w http.ResponseWriter, r *http.Request) {
	h.alterarEstadoCliente(w, r, "bloquear")
}

func (h *Handler) DesbloquearClienteSeguro(w http.ResponseWriter, r *http.Request) {
	h.alterarEstadoCliente(w, r, "desbloquear")
}

func (h *Handler) ListarDocumentos(w http.ResponseWriter, r *http.Request) {
	if !h.requireCustomer(w, r) {
		return
	}
	rows, err := h.db.Query(r.Context(), `
		SELECT id,tipo,numero,ficheiro_url,emitido_em,expira_em,created_at
		FROM clientes.customer_documents WHERE customer_id=$1 ORDER BY created_at DESC`,
		chi.URLParam(r, "id"))
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data, err := pgx.CollectRows(rows, pgx.RowToMap)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarDocumento(w http.ResponseWriter, r *http.Request) {
	if !h.requireCustomer(w, r) {
		return
	}
	var body struct {
		Tipo        string  `json:"tipo"`
		Numero      *string `json:"numero"`
		FicheiroURL *string `json:"ficheiro_url"`
		EmitidoEm   *string `json:"emitido_em"`
		ExpiraEm    *string `json:"expira_em"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Tipo == "" {
		jsonErr(w, "tipo e obrigatorio", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO clientes.customer_documents(customer_id,tipo,numero,ficheiro_url,emitido_em,expira_em)
		VALUES($1,$2,$3,$4,$5,$6) RETURNING id`,
		chi.URLParam(r, "id"), body.Tipo, body.Numero, body.FicheiroURL, body.EmitidoEm, body.ExpiraEm).Scan(&id)
	if err != nil {
		jsonErr(w, "Dados do documento invalidos", http.StatusBadRequest)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RemoverDocumento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tag, _ := h.db.Exec(r.Context(), `
		DELETE FROM clientes.customer_documents d USING clientes.customers c
		WHERE d.id=$1 AND d.customer_id=$2 AND c.id=d.customer_id AND c.tenant_id=$3`,
		chi.URLParam(r, "doc_id"), chi.URLParam(r, "id"), user.TenantID)
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Documento nao encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ObterLimiteCreditoSeguro(w http.ResponseWriter, r *http.Request) {
	if !h.requireCustomer(w, r) {
		return
	}
	var row struct {
		LimiteCredito float64    `json:"limite_credito"`
		Moeda         string     `json:"moeda"`
		InicioEm      *time.Time `json:"inicio_em"`
		FimEm         *time.Time `json:"fim_em"`
		Ativo         bool       `json:"ativo"`
		Motivo        *string    `json:"motivo"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT limite_credito,moeda,inicio_em,fim_em,ativo,motivo
		FROM clientes.customer_credit_limits WHERE customer_id=$1`,
		chi.URLParam(r, "id")).
		Scan(&row.LimiteCredito, &row.Moeda, &row.InicioEm, &row.FimEm, &row.Ativo, &row.Motivo)
	if err == pgx.ErrNoRows {
		row.Moeda, row.Ativo = "MZN", true
	} else if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, row, http.StatusOK)
}

func (h *Handler) DefinirLimiteCredito(w http.ResponseWriter, r *http.Request) {
	if !h.requireCustomer(w, r) {
		return
	}
	user := mw.GetUser(r)
	var body struct {
		LimiteCredito *float64 `json:"limite_credito"`
		Limite        *float64 `json:"limite"`
		Moeda         string   `json:"moeda"`
		InicioEm      *string  `json:"inicio_em"`
		FimEm         *string  `json:"fim_em"`
		Ativo         *bool    `json:"ativo"`
		Motivo        *string  `json:"motivo"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	limite := body.LimiteCredito
	if limite == nil {
		limite = body.Limite
	}
	if limite == nil || *limite < 0 {
		jsonErr(w, "limite_credito deve ser maior ou igual a zero", http.StatusBadRequest)
		return
	}
	if body.Moeda == "" {
		body.Moeda = "MZN"
	}
	ativo := true
	if body.Ativo != nil {
		ativo = *body.Ativo
	}
	_, err := h.db.Exec(r.Context(), `
		INSERT INTO clientes.customer_credit_limits
		    (customer_id,limite_credito,moeda,inicio_em,fim_em,ativo,motivo,updated_by)
		VALUES($1,$2,$3,$4,$5,$6,$7,$8)
		ON CONFLICT(customer_id) DO UPDATE SET
		    limite_credito=EXCLUDED.limite_credito, moeda=EXCLUDED.moeda,
		    inicio_em=EXCLUDED.inicio_em, fim_em=EXCLUDED.fim_em,
		    ativo=EXCLUDED.ativo, motivo=EXCLUDED.motivo,
		    updated_by=EXCLUDED.updated_by, updated_at=NOW()`,
		chi.URLParam(r, "id"), *limite, body.Moeda, body.InicioEm, body.FimEm,
		ativo, body.Motivo, user.ID)
	if err != nil {
		jsonErr(w, "Dados do limite de credito invalidos", http.StatusBadRequest)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ObterSaldoSeguro(w http.ResponseWriter, r *http.Request) {
	if !h.requireCustomer(w, r) {
		return
	}
	user := mw.GetUser(r)
	var row struct {
		SaldoDevedor      float64    `json:"saldo_devedor"`
		TotalCompras      float64    `json:"total_compras"`
		TotalPago         float64    `json:"total_pago"`
		LimiteCredito     float64    `json:"limite_credito"`
		CreditoDisponivel float64    `json:"credito_disponivel"`
		UltimaCompraEm    *time.Time `json:"ultima_compra_em"`
		UltimoPagamentoEm *time.Time `json:"ultimo_pagamento_em"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT
		  COALESCE((SELECT SUM(i.saldo_pendente) FROM faturacao.invoices i
		    WHERE i.customer_id=c.id AND i.tenant_id=c.tenant_id
		      AND i.status NOT IN ('cancelada','rascunho')),0),
		  COALESCE((SELECT SUM(i.total) FROM faturacao.invoices i
		    WHERE i.customer_id=c.id AND i.tenant_id=c.tenant_id
		      AND i.status NOT IN ('cancelada','rascunho')),0),
		  COALESCE((SELECT SUM(i.valor_pago) FROM faturacao.invoices i
		    WHERE i.customer_id=c.id AND i.tenant_id=c.tenant_id
		      AND i.status NOT IN ('cancelada','rascunho')),0),
		  (SELECT MAX(i.invoice_date) FROM faturacao.invoices i
		    WHERE i.customer_id=c.id AND i.tenant_id=c.tenant_id
		      AND i.status NOT IN ('cancelada','rascunho')),
		  (SELECT MAX(p.pago_em) FROM clientes.customer_payments p
		    WHERE p.customer_id=c.id AND p.tenant_id=c.tenant_id),
		  COALESCE((SELECT cl.limite_credito FROM clientes.customer_credit_limits cl
		    WHERE cl.customer_id=c.id AND cl.ativo LIMIT 1),0)
		FROM clientes.customers c WHERE c.id=$1 AND c.tenant_id=$2`,
		chi.URLParam(r, "id"), user.TenantID).
		Scan(&row.SaldoDevedor, &row.TotalCompras, &row.TotalPago, &row.UltimaCompraEm,
			&row.UltimoPagamentoEm, &row.LimiteCredito)
	if err != nil {
		jsonErr(w, "Erro ao calcular saldo", http.StatusInternalServerError)
		return
	}
	row.CreditoDisponivel = row.LimiteCredito - row.SaldoDevedor
	if row.CreditoDisponivel < 0 {
		row.CreditoDisponivel = 0
	}
	jsonOK(w, row, http.StatusOK)
}

func (h *Handler) ListarContactosSeguro(w http.ResponseWriter, r *http.Request) {
	if h.requireCustomer(w, r) {
		h.ListarContactos(w, r)
	}
}

func (h *Handler) AdicionarContactoSeguro(w http.ResponseWriter, r *http.Request) {
	if h.requireCustomer(w, r) {
		h.AdicionarContacto(w, r)
	}
}

func (h *Handler) ActualizarContactoSeguro(w http.ResponseWriter, r *http.Request) {
	if h.requireCustomer(w, r) {
		h.ActualizarContacto(w, r)
	}
}

func (h *Handler) RemoverContactoSeguro(w http.ResponseWriter, r *http.Request) {
	if h.requireCustomer(w, r) {
		h.RemoverContacto(w, r)
	}
}

func (h *Handler) ListarEnderecosSeguro(w http.ResponseWriter, r *http.Request) {
	if h.requireCustomer(w, r) {
		h.ListarEnderecos(w, r)
	}
}

func (h *Handler) AdicionarEnderecoSeguro(w http.ResponseWriter, r *http.Request) {
	if h.requireCustomer(w, r) {
		h.AdicionarEndereco(w, r)
	}
}

func (h *Handler) ActualizarEnderecoSeguro(w http.ResponseWriter, r *http.Request) {
	if h.requireCustomer(w, r) {
		h.ActualizarEndereco(w, r)
	}
}

func (h *Handler) RemoverEnderecoSeguro(w http.ResponseWriter, r *http.Request) {
	if h.requireCustomer(w, r) {
		h.RemoverEndereco(w, r)
	}
}

func (h *Handler) ListarPagamentosSeguro(w http.ResponseWriter, r *http.Request) {
	if h.requireCustomer(w, r) {
		h.ListarPagamentos(w, r)
	}
}

func (h *Handler) RegistarPagamentoSeguro(w http.ResponseWriter, r *http.Request) {
	if h.requireCustomer(w, r) {
		h.RegistarPagamento(w, r)
	}
}

func (h *Handler) ListarHistoricoSeguro(w http.ResponseWriter, r *http.Request) {
	if h.requireCustomer(w, r) {
		h.ListarHistorico(w, r)
	}
}

func (h *Handler) ListarNotas(w http.ResponseWriter, r *http.Request) {
	if !h.requireCustomer(w, r) {
		return
	}
	rows, err := h.db.Query(r.Context(), `
		SELECT id,nota,created_by,created_at FROM clientes.customer_notes
		WHERE customer_id=$1 ORDER BY created_at DESC`, chi.URLParam(r, "id"))
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data, _ := pgx.CollectRows(rows, pgx.RowToMap)
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarNota(w http.ResponseWriter, r *http.Request) {
	if !h.requireCustomer(w, r) {
		return
	}
	user := mw.GetUser(r)
	var body struct {
		Nota string `json:"nota"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || strings.TrimSpace(body.Nota) == "" {
		jsonErr(w, "nota e obrigatoria", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO clientes.customer_notes(customer_id,nota,created_by)
		VALUES($1,$2,$3) RETURNING id`, chi.URLParam(r, "id"), body.Nota, user.ID).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ListarTagsCliente(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, err := h.db.Query(r.Context(), `
		SELECT id,codigo,nome,cor,created_at FROM clientes.customer_tags
		WHERE tenant_id=$1 ORDER BY nome`, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data, _ := pgx.CollectRows(rows, pgx.RowToMap)
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarTagCliente(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo string  `json:"codigo"`
		Nome   string  `json:"nome"`
		Cor    *string `json:"cor"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome sao obrigatorios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO clientes.customer_tags(tenant_id,codigo,nome,cor)
		VALUES($1,$2,$3,$4) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Cor).Scan(&id)
	if err != nil {
		jsonErr(w, "Tag duplicada ou invalida", http.StatusConflict)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) AssociarTagCliente(w http.ResponseWriter, r *http.Request) {
	if !h.requireCustomer(w, r) {
		return
	}
	user := mw.GetUser(r)
	var body struct {
		TagID int64 `json:"tag_id"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.TagID == 0 {
		jsonErr(w, "tag_id e obrigatorio", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		INSERT INTO clientes.customer_tag_links(customer_id,customer_tag_id)
		SELECT $1,t.id FROM clientes.customer_tags t WHERE t.id=$2 AND t.tenant_id=$3
		ON CONFLICT(customer_id,customer_tag_id) DO NOTHING`,
		chi.URLParam(r, "id"), body.TagID, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Tag nao encontrada ou ja associada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverTagCliente(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tag, _ := h.db.Exec(r.Context(), `
		DELETE FROM clientes.customer_tag_links l
		USING clientes.customers c, clientes.customer_tags t
		WHERE l.customer_id=$1 AND l.customer_tag_id=$2
		  AND c.id=l.customer_id AND c.tenant_id=$3
		  AND t.id=l.customer_tag_id AND t.tenant_id=$3`,
		chi.URLParam(r, "id"), chi.URLParam(r, "tag_id"), user.TenantID)
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Associacao nao encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListarDescontosCliente(w http.ResponseWriter, r *http.Request) {
	if !h.requireCustomer(w, r) {
		return
	}
	rows, err := h.db.Query(r.Context(), `
		SELECT id,tipo,valor,motivo,ativo,inicio_em,fim_em,created_at,updated_at
		FROM clientes.customer_discounts WHERE customer_id=$1 ORDER BY created_at DESC`,
		chi.URLParam(r, "id"))
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data, _ := pgx.CollectRows(rows, pgx.RowToMap)
	jsonOK(w, data, http.StatusOK)
}

type customerDiscountInput struct {
	Tipo     *string  `json:"tipo"`
	Valor    *float64 `json:"valor"`
	Motivo   *string  `json:"motivo"`
	Ativo    *bool    `json:"ativo"`
	InicioEm *string  `json:"inicio_em"`
	FimEm    *string  `json:"fim_em"`
}

func (h *Handler) CriarDescontoCliente(w http.ResponseWriter, r *http.Request) {
	if !h.requireCustomer(w, r) {
		return
	}
	var body customerDiscountInput
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Tipo == nil || body.Valor == nil || *body.Valor < 0 {
		jsonErr(w, "tipo e valor validos sao obrigatorios", http.StatusBadRequest)
		return
	}
	if *body.Tipo == "percentual" && *body.Valor > 100 {
		jsonErr(w, "Desconto percentual nao pode exceder 100", http.StatusBadRequest)
		return
	}
	ativo := true
	if body.Ativo != nil {
		ativo = *body.Ativo
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO clientes.customer_discounts(customer_id,tipo,valor,motivo,ativo,inicio_em,fim_em)
		VALUES($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
		chi.URLParam(r, "id"), body.Tipo, body.Valor, body.Motivo, ativo, body.InicioEm, body.FimEm).Scan(&id)
	if err != nil {
		jsonErr(w, "Dados do desconto invalidos", http.StatusBadRequest)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarDescontoCliente(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body customerDiscountInput
	if json.NewDecoder(r.Body).Decode(&body) != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	if body.Valor != nil && *body.Valor < 0 {
		jsonErr(w, "valor invalido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE clientes.customer_discounts d SET
		  tipo=COALESCE($1,tipo),valor=COALESCE($2,valor),motivo=COALESCE($3,motivo),
		  ativo=COALESCE($4,ativo),inicio_em=COALESCE($5,inicio_em),
		  fim_em=COALESCE($6,fim_em),updated_at=NOW()
		FROM clientes.customers c
		WHERE d.id=$7 AND d.customer_id=$8 AND c.id=d.customer_id AND c.tenant_id=$9`,
		body.Tipo, body.Valor, body.Motivo, body.Ativo, body.InicioEm, body.FimEm,
		chi.URLParam(r, "desc_id"), chi.URLParam(r, "id"), user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Desconto nao encontrado ou invalido", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverDescontoCliente(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tag, _ := h.db.Exec(r.Context(), `
		DELETE FROM clientes.customer_discounts d USING clientes.customers c
		WHERE d.id=$1 AND d.customer_id=$2 AND c.id=d.customer_id AND c.tenant_id=$3`,
		chi.URLParam(r, "desc_id"), chi.URLParam(r, "id"), user.TenantID)
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Desconto nao encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RelatorioClientes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	report := chi.URLParam(r, "report")
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit < 1 || limit > 500 {
		limit = 50
	}
	dias, _ := strconv.Atoi(r.URL.Query().Get("dias"))
	if dias < 1 {
		dias = 90
	}
	var query string
	var args []any
	switch report {
	case "top-clientes":
		query = `SELECT c.id,c.codigo,c.nome,COUNT(i.id) numero_compras,
			COALESCE(SUM(i.total),0) total_compras
			FROM clientes.customers c
			JOIN faturacao.invoices i ON i.customer_id=c.id AND i.tenant_id=c.tenant_id
			WHERE c.tenant_id=$1 AND i.status NOT IN ('cancelada','rascunho')
			GROUP BY c.id ORDER BY total_compras DESC LIMIT $2`
		args = []any{user.TenantID, limit}
	case "saldos-devedores":
		query = `SELECT c.id,c.codigo,c.nome,COALESCE(SUM(i.saldo_pendente),0) saldo_devedor,
			MIN(i.due_date) FILTER(WHERE i.saldo_pendente>0) vencimento_mais_antigo
			FROM clientes.customers c
			LEFT JOIN faturacao.invoices i ON i.customer_id=c.id AND i.tenant_id=c.tenant_id
			  AND i.status NOT IN ('cancelada','rascunho')
			WHERE c.tenant_id=$1 GROUP BY c.id
			HAVING COALESCE(SUM(i.saldo_pendente),0)>0
			ORDER BY saldo_devedor DESC LIMIT $2`
		args = []any{user.TenantID, limit}
	case "credito-utilizado":
		query = `SELECT c.id,c.codigo,c.nome,cl.limite_credito,
			COALESCE(SUM(i.saldo_pendente),0) credito_utilizado,
			GREATEST(cl.limite_credito-COALESCE(SUM(i.saldo_pendente),0),0) credito_disponivel
			FROM clientes.customers c
			JOIN clientes.customer_credit_limits cl ON cl.customer_id=c.id AND cl.ativo
			LEFT JOIN faturacao.invoices i ON i.customer_id=c.id AND i.tenant_id=c.tenant_id
			  AND i.status NOT IN ('cancelada','rascunho')
			WHERE c.tenant_id=$1 GROUP BY c.id,cl.limite_credito
			ORDER BY credito_utilizado DESC LIMIT $2`
		args = []any{user.TenantID, limit}
	case "sem-actividade":
		query = `SELECT c.id,c.codigo,c.nome,MAX(i.invoice_date) ultima_compra_em
			FROM clientes.customers c
			LEFT JOIN faturacao.invoices i ON i.customer_id=c.id AND i.tenant_id=c.tenant_id
			  AND i.status NOT IN ('cancelada','rascunho')
			WHERE c.tenant_id=$1 GROUP BY c.id
			HAVING MAX(i.invoice_date) IS NULL OR MAX(i.invoice_date)<CURRENT_DATE-$2::int
			ORDER BY ultima_compra_em NULLS FIRST LIMIT $3`
		args = []any{user.TenantID, dias, limit}
	default:
		jsonErr(w, "Relatorio desconhecido", http.StatusNotFound)
		return
	}
	rows, err := h.db.Query(r.Context(), query, args...)
	if err != nil {
		jsonErr(w, "Erro ao gerar relatorio", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data, err := pgx.CollectRows(rows, pgx.RowToMap)
	if err != nil {
		jsonErr(w, "Erro ao gerar relatorio", http.StatusInternalServerError)
		return
	}
	jsonOK(w, data, http.StatusOK)
}
