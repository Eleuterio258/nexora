package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgconn"
	mw "nexora/internal/middleware"
)

func (h *Handler) listJSON(w http.ResponseWriter, r *http.Request, query string, args ...any) {
	var raw []byte
	if err := h.db.QueryRow(r.Context(), query, args...).Scan(&raw); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func treasuryFilter(r *http.Request, where *string, args *[]any, queryKey, column string) {
	value := strings.TrimSpace(r.URL.Query().Get(queryKey))
	if value == "" {
		return
	}
	*args = append(*args, value)
	*where += " AND " + column + "=$" + strconv.Itoa(len(*args))
}

func (h *Handler) CriarContaBancaria(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var body struct {
		Codigo       string  `json:"codigo"`
		Banco        string  `json:"banco"`
		NumeroConta  string  `json:"numero_conta"`
		IBAN         *string `json:"iban"`
		Moeda        string  `json:"moeda"`
		SaldoInicial float64 `json:"saldo_inicial"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Codigo == "" || body.Banco == "" || body.NumeroConta == "" {
		jsonErr(w, "codigo, banco e numero_conta sao obrigatorios", http.StatusBadRequest)
		return
	}
	if body.Moeda == "" {
		body.Moeda = "MZN"
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO tesouraria.bank_accounts
		(tenant_id,codigo,banco,numero_conta,iban,moeda,saldo_inicial,saldo_actual)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$7) RETURNING id`,
		u.TenantID, body.Codigo, body.Banco, body.NumeroConta, body.IBAN, body.Moeda, body.SaldoInicial).Scan(&id)
	if err != nil {
		jsonErr(w, "Conta bancaria duplicada ou invalida", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ListarContasBancarias(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.banco,x.codigo),'[]') FROM (
		SELECT id,codigo,banco,numero_conta,iban,moeda,saldo_inicial,saldo_actual,activo,created_at
		FROM tesouraria.bank_accounts WHERE tenant_id=$1) x`, u.TenantID)
}

func (h *Handler) CriarCaixa(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var body struct {
		Codigo       string  `json:"codigo"`
		Nome         string  `json:"nome"`
		Moeda        string  `json:"moeda"`
		SaldoInicial float64 `json:"saldo_inicial"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome sao obrigatorios", http.StatusBadRequest)
		return
	}
	if body.Moeda == "" {
		body.Moeda = "MZN"
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO tesouraria.cash_registers
		(tenant_id,codigo,nome,moeda,saldo_inicial,saldo_actual)
		VALUES ($1,$2,$3,$4,$5,$5) RETURNING id`,
		u.TenantID, body.Codigo, body.Nome, body.Moeda, body.SaldoInicial).Scan(&id)
	if err != nil {
		jsonErr(w, "Caixa duplicado ou invalido", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ListarCaixas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome),'[]') FROM (
		SELECT id,codigo,nome,moeda,saldo_inicial,saldo_actual,activo,created_at
		FROM tesouraria.cash_registers WHERE tenant_id=$1) x`, u.TenantID)
}

func (h *Handler) CriarMovimento(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var body struct {
		BankAccountID  *int64  `json:"bank_account_id"`
		CashRegisterID *int64  `json:"cash_register_id"`
		Tipo           string  `json:"tipo"`
		Valor          float64 `json:"valor"`
		Moeda          string  `json:"moeda"`
		Data           string  `json:"data_movimento"`
		Metodo         *string `json:"metodo"`
		Referencia     *string `json:"referencia"`
		Descricao      *string `json:"descricao"`
		ReferenceType  *string `json:"reference_type"`
		ReferenceID    *int64  `json:"reference_id"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Valor <= 0 ||
		(body.Tipo != "recebimento" && body.Tipo != "pagamento") ||
		(body.BankAccountID == nil) == (body.CashRegisterID == nil) {
		jsonErr(w, "Origem, tipo e valor validos sao obrigatorios", http.StatusBadRequest)
		return
	}
	if body.Moeda == "" {
		body.Moeda = "MZN"
	}
	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())
	var id int64
	err = tx.QueryRow(r.Context(), `INSERT INTO tesouraria.movements
		(tenant_id,bank_account_id,cash_register_id,tipo,valor,moeda,data_movimento,metodo,referencia,
		descricao,reference_type,reference_id,created_by)
		VALUES ($1,$2,$3,$4,$5,$6,COALESCE(NULLIF($7,'')::date,CURRENT_DATE),$8,$9,$10,$11,$12,$13)
		RETURNING id`, u.TenantID, body.BankAccountID, body.CashRegisterID, body.Tipo, body.Valor,
		body.Moeda, body.Data, body.Metodo, body.Referencia, body.Descricao, body.ReferenceType, body.ReferenceID, u.ID).Scan(&id)
	if err != nil {
		jsonErr(w, "Movimento invalido", http.StatusUnprocessableEntity)
		return
	}
	delta := body.Valor
	if body.Tipo == "pagamento" {
		delta = -delta
	}
	var tag pgconn.CommandTag
	if body.BankAccountID != nil {
		tag, err = tx.Exec(r.Context(), `UPDATE tesouraria.bank_accounts SET saldo_actual=saldo_actual+$1,updated_at=NOW()
			WHERE id=$2 AND tenant_id=$3 AND activo`, delta, *body.BankAccountID, u.TenantID)
	} else {
		tag, err = tx.Exec(r.Context(), `UPDATE tesouraria.cash_registers SET saldo_actual=saldo_actual+$1,updated_at=NOW()
			WHERE id=$2 AND tenant_id=$3 AND activo`, delta, *body.CashRegisterID, u.TenantID)
	}
	if err != nil || tag.RowsAffected() != 1 {
		jsonErr(w, "Conta ou caixa activa nao encontrada", http.StatusUnprocessableEntity)
		return
	}
	if tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro ao actualizar saldo", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ListarMovimentos(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "m.tenant_id=$1"
	args := []any{u.TenantID}
	treasuryFilter(r, &where, &args, "tipo", "m.tipo")
	treasuryFilter(r, &where, &args, "bank_account_id", "m.bank_account_id")
	treasuryFilter(r, &where, &args, "cash_register_id", "m.cash_register_id")
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.data_movimento DESC,x.id DESC),'[]') FROM (
		SELECT m.*,b.banco,b.numero_conta,c.nome caixa_nome FROM tesouraria.movements m
		LEFT JOIN tesouraria.bank_accounts b ON b.id=m.bank_account_id
		LEFT JOIN tesouraria.cash_registers c ON c.id=m.cash_register_id WHERE `+where+`) x`, args...)
}

func (h *Handler) CriarReconciliacao(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var body struct {
		BankAccountID int64   `json:"bank_account_id"`
		PeriodoInicio string  `json:"periodo_inicio"`
		PeriodoFim    string  `json:"periodo_fim"`
		SaldoExtracto float64 `json:"saldo_extracto"`
		Observacoes   *string `json:"observacoes"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.BankAccountID == 0 || body.PeriodoInicio == "" || body.PeriodoFim == "" {
		jsonErr(w, "Conta e periodo sao obrigatorios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO tesouraria.reconciliations
		(tenant_id,bank_account_id,periodo_inicio,periodo_fim,saldo_extracto,saldo_sistema,diferenca,observacoes,criada_por)
		SELECT $1,b.id,$3::date,$4::date,$5,
		b.saldo_inicial+COALESCE((SELECT SUM(CASE WHEN m.tipo='recebimento' THEN m.valor ELSE -m.valor END)
		FROM tesouraria.movements m WHERE m.bank_account_id=b.id AND m.tenant_id=$1 AND m.data_movimento<=$4::date),0),
		$5-(b.saldo_inicial+COALESCE((SELECT SUM(CASE WHEN m.tipo='recebimento' THEN m.valor ELSE -m.valor END)
		FROM tesouraria.movements m WHERE m.bank_account_id=b.id AND m.tenant_id=$1 AND m.data_movimento<=$4::date),0)),
		$6,$7 FROM tesouraria.bank_accounts b WHERE b.id=$2 AND b.tenant_id=$1 RETURNING id`,
		u.TenantID, body.BankAccountID, body.PeriodoInicio, body.PeriodoFim, body.SaldoExtracto, body.Observacoes, u.ID).Scan(&id)
	if err != nil {
		jsonErr(w, "Reconciliacao invalida ou duplicada", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ListarReconciliacoes(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "r.tenant_id=$1"
	args := []any{u.TenantID}
	treasuryFilter(r, &where, &args, "status", "r.status")
	treasuryFilter(r, &where, &args, "bank_account_id", "r.bank_account_id")
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.periodo_fim DESC,x.id DESC),'[]') FROM (
		SELECT r.*,b.banco,b.numero_conta FROM tesouraria.reconciliations r
		JOIN tesouraria.bank_accounts b ON b.id=r.bank_account_id WHERE `+where+`) x`, args...)
}

func (h *Handler) FecharReconciliacao(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	tag, err := h.db.Exec(r.Context(), `UPDATE tesouraria.reconciliations SET status='fechada',
		fechada_por=$1,fechada_em=NOW(),updated_at=NOW() WHERE id=$2 AND tenant_id=$3 AND status='aberta'`,
		u.ID, chi.URLParam(r, "id"), u.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Reconciliacao aberta nao encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}
