package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"
	mw "nexora/internal/middleware"
	"nexora/internal/modules/recursos-humanos/service/funcionario"
	"nexora/internal/shared/adapters"
	"nexora/internal/ws"
)

// proximoNumeroSerie obtem (com lock) a serie ativa do tipo indicado,
// incrementa a sua sequencia e devolve o numero de documento gerado e o
// id da serie, para serem gravados no documento dentro da mesma transacao.
// Réplica local de modulo-faturacao/handlers/faturacao.go (helper duplicado por convenção).
func proximoNumeroSerie(ctx context.Context, tx pgx.Tx, tenantID int64, tipo string) (string, int64, error) {
	var serieID int64
	var prefixo string
	var sequencia int
	err := tx.QueryRow(ctx, `
		SELECT id, prefixo, sequencia
		  FROM invoice_series
		 WHERE tenant_id=$1 AND tipo=$2 AND ativo=true
		 ORDER BY ano DESC
		 LIMIT 1
		 FOR UPDATE`, tenantID, tipo).Scan(&serieID, &prefixo, &sequencia)
	if err != nil {
		return "", 0, err
	}
	sequencia++
	if _, err := tx.Exec(ctx, `UPDATE invoice_series SET sequencia=$1 WHERE id=$2`, sequencia, serieID); err != nil {
		return "", 0, err
	}
	return fmt.Sprintf("%s%04d", prefixo, sequencia), serieID, nil
}

func nullString(s string) any {
	if s == "" {
		return nil
	}
	return s
}

var metodosPagamentoValidos = map[string]bool{
	"numerario": true, "transferencia": true, "tpa": true, "mpesa": true, "emola": true, "outro": true,
}

// ── Terminais ───────────────────────────────────────────────────────────────

func (h *Handler) ListarTerminais(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)

	where := "tenant_id=$1 AND deleted_at IS NULL"
	args := []any{user.TenantID}

	if v := q.Get("ativo"); v != "" {
		args = append(args, v == "true")
		where += " AND activo=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("warehouse_id"); v != "" {
		if wid, err := strconv.ParseInt(v, 10, 64); err == nil {
			args = append(args, wid)
			where += " AND warehouse_id=$" + strconv.Itoa(len(args))
		}
	}
	if v := q.Get("caixa_id"); v != "" {
		if cid, err := strconv.ParseInt(v, 10, 64); err == nil {
			args = append(args, cid)
			where += " AND caixa_id=$" + strconv.Itoa(len(args))
		}
	}

	rows, _ := h.db.Query(r.Context(), `
		SELECT id, codigo, nome, warehouse_id, caixa_id, activo
		  FROM pos_terminals WHERE `+where+` ORDER BY nome LIMIT $`+strconv.Itoa(len(args)+1)+` OFFSET $`+strconv.Itoa(len(args)+2), append(args, limit, offset)...)
	defer rows.Close()
	type Row struct {
		ID          int64  `json:"id"`
		Codigo      string `json:"codigo"`
		Nome        string `json:"nome"`
		WarehouseID *int64 `json:"warehouse_id"`
		CaixaID     *int64 `json:"caixa_id"`
		Activo      bool   `json:"activo"`
	}
	data := []Row{}
	for rows.Next() {
		var t Row
		if rows.Scan(&t.ID, &t.Codigo, &t.Nome, &t.WarehouseID, &t.CaixaID, &t.Activo) == nil {
			data = append(data, t)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// cargoTerminalPOSNome é o cargo automático atribuído às contas de terminal
// (ver ensureCargoTerminalPOS) — só tem a permissão pos:operar_pos, para que
// o terminal fique restrito ao módulo POS pelo mesmo motor de permissões já
// usado para funcionários, sem precisar de escopo ou middleware novos.
const cargoTerminalPOSNome = "Terminal POS"

// ensureCargoTerminalPOS devolve o id do cargo "Terminal POS" do tenant,
// criando-o (com a permissão pos:operar_pos) se ainda não existir.
func ensureCargoTerminalPOS(ctx context.Context, tx pgx.Tx, tenantID int64) (int64, error) {
	var cargoID int64
	err := tx.QueryRow(ctx, `
		SELECT id FROM auth.cargos WHERE tenant_id=$1 AND nome=$2`,
		tenantID, cargoTerminalPOSNome).Scan(&cargoID)
	if err == nil {
		return cargoID, nil
	}
	if err != pgx.ErrNoRows {
		return 0, err
	}

	if err := tx.QueryRow(ctx, `
		INSERT INTO auth.cargos (tenant_id, nome, descricao)
		VALUES ($1, $2, 'Cargo automático para contas de terminal POS (acesso restrito à operação de caixa)')
		RETURNING id`,
		tenantID, cargoTerminalPOSNome).Scan(&cargoID); err != nil {
		return 0, err
	}
	if _, err := tx.Exec(ctx, `
		INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES ($1, 'pos', 'operar_pos')
		ON CONFLICT DO NOTHING`, cargoID); err != nil {
		return 0, err
	}
	return cargoID, nil
}

// CriarTerminal regista o terminal e, para o poder autenticar sozinho (ver
// PosLogin em auth/handlers), provisiona também uma conta de funcionário
// dedicada: email sintético (codigo@terminal.internal), password = código de
// ativação, cargo "Terminal POS". Não reaproveita CriarUtilizador porque essa
// validação de negócio (password >= 8 caracteres) não se aplica a um código
// de ativação de 6 dígitos.
func (h *Handler) CriarTerminal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo         string `json:"codigo"`
		Nome           string `json:"nome"`
		WarehouseID    *int64 `json:"warehouse_id"`
		CaixaID        *int64 `json:"caixa_id"`
		ActivationCode string `json:"activation_code"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" || body.ActivationCode == "" {
		jsonErr(w, "codigo, nome e activation_code são obrigatórios", http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	cargoID, err := ensureCargoTerminalPOS(ctx, tx, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno ao preparar cargo do terminal", http.StatusInternalServerError)
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(body.ActivationCode), 12)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	syntheticEmail := fmt.Sprintf("terminal.%d.%s@nexora.local", user.TenantID, strings.ToLower(body.Codigo))

	var userID int64
	if err := tx.QueryRow(ctx, `
		INSERT INTO auth.users (nome, email, password_hash, estado, tipo)
		VALUES ($1, LOWER($2), $3, 'ativo', 'funcionario')
		RETURNING id`,
		body.Nome, syntheticEmail, string(hash)).Scan(&userID); err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe uma conta de terminal com esse código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO auth.memberships (user_id, tenant_id, cargo_id, escopo, papel)
		VALUES ($1, $2, $3, 'erp', 'funcionario')`,
		userID, user.TenantID, cargoID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	var id int64
	err = tx.QueryRow(ctx, `
		INSERT INTO pos_terminals (tenant_id, codigo, nome, warehouse_id, caixa_id, user_id)
		VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.WarehouseID, body.CaixaID, userID).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um terminal com esse código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// alterarEstadoTerminal liga/desliga um terminal (coluna activo). Desativar é o
// equivalente "soft-delete" usado pelo cliente PayCore Mobile — o ERP não tem
// DELETE de terminal. Devolve o terminal actualizado no mesmo shape de
// ListarTerminais para o cliente poder actualizar o estado localmente.
func (h *Handler) alterarEstadoTerminal(w http.ResponseWriter, r *http.Request, activo bool) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	type Row struct {
		ID          int64  `json:"id"`
		Codigo      string `json:"codigo"`
		Nome        string `json:"nome"`
		WarehouseID *int64 `json:"warehouse_id"`
		CaixaID     *int64 `json:"caixa_id"`
		Activo      bool   `json:"activo"`
	}
	var t Row
	err := h.db.QueryRow(r.Context(), `
		UPDATE pos_terminals SET activo=$1, updated_at=NOW()
		 WHERE id=$2 AND tenant_id=$3 AND deleted_at IS NULL
		 RETURNING id, codigo, nome, warehouse_id, caixa_id, activo`,
		activo, id, user.TenantID).Scan(&t.ID, &t.Codigo, &t.Nome, &t.WarehouseID, &t.CaixaID, &t.Activo)
	if err == pgx.ErrNoRows {
		jsonErr(w, "Terminal não encontrado", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, t, http.StatusOK)
}

// ActivarTerminal marca o terminal como activo.
func (h *Handler) ActivarTerminal(w http.ResponseWriter, r *http.Request) {
	h.alterarEstadoTerminal(w, r, true)
}

// DesactivarTerminal marca o terminal como inactivo (soft-delete do cliente).
func (h *Handler) DesactivarTerminal(w http.ResponseWriter, r *http.Request) {
	h.alterarEstadoTerminal(w, r, false)
}

// ObterTerminal devolve um terminal pelo ID.
func (h *Handler) ObterTerminal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	type Row struct {
		ID          int64      `json:"id"`
		Codigo      string     `json:"codigo"`
		Nome        string     `json:"nome"`
		WarehouseID *int64     `json:"warehouse_id"`
		CaixaID     *int64     `json:"caixa_id"`
		UserID      *int64     `json:"user_id"`
		Activo      bool       `json:"activo"`
		CreatedAt   time.Time  `json:"created_at"`
		UpdatedAt   time.Time  `json:"updated_at"`
		DeletedAt   *time.Time `json:"deleted_at,omitempty"`
	}
	var t Row
	err := h.db.QueryRow(r.Context(), `
		SELECT id, codigo, nome, warehouse_id, caixa_id, user_id, activo, created_at, updated_at, deleted_at
		  FROM pos_terminals
		 WHERE id=$1 AND tenant_id=$2 AND deleted_at IS NULL`, id, user.TenantID).
		Scan(&t.ID, &t.Codigo, &t.Nome, &t.WarehouseID, &t.CaixaID, &t.UserID, &t.Activo, &t.CreatedAt, &t.UpdatedAt, &t.DeletedAt)
	if err == pgx.ErrNoRows {
		jsonErr(w, "Terminal não encontrado", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, t, http.StatusOK)
}

// ActualizarTerminal actualiza nome, warehouse_id e caixa_id de um terminal.
func (h *Handler) ActualizarTerminal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Nome        string `json:"nome"`
		WarehouseID *int64 `json:"warehouse_id"`
		CaixaID     *int64 `json:"caixa_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nome == "" {
		jsonErr(w, "nome é obrigatório", http.StatusBadRequest)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE pos_terminals
		   SET nome=$1, warehouse_id=$2, caixa_id=$3, updated_at=NOW()
		 WHERE id=$4 AND tenant_id=$5 AND deleted_at IS NULL`,
		body.Nome, body.WarehouseID, body.CaixaID, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Terminal não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ArquivarTerminal faz soft-delete de um terminal (apenas se não tiver sessões).
func (h *Handler) ArquivarTerminal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var temSessoes bool
	err := h.db.QueryRow(r.Context(), `
		SELECT EXISTS(SELECT 1 FROM pos_sessions WHERE terminal_id=$1)`, id).Scan(&temSessoes)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if temSessoes {
		jsonErr(w, "Não é possível remover terminal com sessões associadas", http.StatusConflict)
		return
	}

	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	var userID *int64
	if err := tx.QueryRow(ctx, `
		UPDATE pos_terminals
		   SET activo=false, deleted_at=NOW(), updated_at=NOW()
		 WHERE id=$1 AND tenant_id=$2 AND deleted_at IS NULL
		 RETURNING user_id`, id, user.TenantID).Scan(&userID); err != nil {
		if err == pgx.ErrNoRows {
			jsonErr(w, "Terminal não encontrado", http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	// Desactiva a conta sintética associada ao terminal, se existir.
	if userID != nil {
		if _, err := tx.Exec(ctx, `
			UPDATE auth.users SET estado='inactivo', updated_at=NOW()
			 WHERE id=$1 AND tipo='funcionario'`, *userID); err != nil {
			jsonErr(w, "Erro interno ao desactivar conta do terminal", http.StatusInternalServerError)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ObterSessaoAtivaDoTerminal devolve a sessão aberta de um terminal específico.
func (h *Handler) ObterSessaoAtivaDoTerminal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	// Garante que o terminal existe e pertence ao tenant.
	var existe bool
	if err := h.db.QueryRow(r.Context(), `
		SELECT EXISTS(SELECT 1 FROM pos_terminals WHERE id=$1 AND tenant_id=$2 AND deleted_at IS NULL)`,
		id, user.TenantID).Scan(&existe); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if !existe {
		jsonErr(w, "Terminal não encontrado", http.StatusNotFound)
		return
	}

	type Row struct {
		ID            int64     `json:"id"`
		UserID        int64     `json:"user_id"`
		FuncionarioID *int64    `json:"funcionario_id"`
		Status        string    `json:"status"`
		OpeningAmount float64   `json:"opening_amount"`
		OpenedAt      time.Time `json:"opened_at"`
	}
	var s Row
	err := h.db.QueryRow(r.Context(), `
		SELECT id, user_id, funcionario_id, status, opening_amount, opened_at
		  FROM pos_sessions
		 WHERE tenant_id=$1 AND terminal_id=$2 AND status='aberta'
		 LIMIT 1`, user.TenantID, id).
		Scan(&s.ID, &s.UserID, &s.FuncionarioID, &s.Status, &s.OpeningAmount, &s.OpenedAt)
	if err == pgx.ErrNoRows {
		jsonOK(w, map[string]any{"sessao": nil}, http.StatusOK)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, s, http.StatusOK)
}

// ── Catálogo POS ────────────────────────────────────────────────────────────

func (h *Handler) ListarCatalogo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT pci.id, pci.product_id, pci.product_variant_id, p.codigo, p.nome,
		       pci.codigo_barra, pci.preco_venda, pci.moeda, pci.activo
		  FROM pos_catalog_items pci
		  JOIN products p ON p.id = pci.product_id
		 WHERE pci.tenant_id=$1
		 ORDER BY p.nome`, user.TenantID)
	defer rows.Close()
	type Row struct {
		ID               int64   `json:"id"`
		ProductID        int64   `json:"product_id"`
		ProductVariantID *int64  `json:"product_variant_id"`
		Codigo           string  `json:"codigo"`
		Nome             string  `json:"nome"`
		CodigoBarra      *string `json:"codigo_barra"`
		PrecoVenda       float64 `json:"preco_venda"`
		Moeda            string  `json:"moeda"`
		Activo           bool    `json:"activo"`
	}
	data := []Row{}
	for rows.Next() {
		var c Row
		if rows.Scan(&c.ID, &c.ProductID, &c.ProductVariantID, &c.Codigo, &c.Nome, &c.CodigoBarra, &c.PrecoVenda, &c.Moeda, &c.Activo) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarAoCatalogo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		ProductID        int64   `json:"product_id"`
		ProductVariantID *int64  `json:"product_variant_id"`
		CodigoBarra      *string `json:"codigo_barra"`
		PrecoVenda       float64 `json:"preco_venda"`
		Moeda            string  `json:"moeda"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ProductID == 0 || body.PrecoVenda < 0 {
		jsonErr(w, "product_id e preco_venda são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.Moeda == "" {
		body.Moeda = "MZN"
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO pos_catalog_items (tenant_id, product_id, product_variant_id, codigo_barra, preco_venda, moeda, activo, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,true,NOW())
		ON CONFLICT (tenant_id, product_id, product_variant_id) DO UPDATE
		   SET codigo_barra=EXCLUDED.codigo_barra, preco_venda=EXCLUDED.preco_venda,
		       moeda=EXCLUDED.moeda, activo=true, updated_at=NOW()
		RETURNING id`,
		user.TenantID, body.ProductID, body.ProductVariantID, body.CodigoBarra, body.PrecoVenda, body.Moeda).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RemoverDoCatalogo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(), `UPDATE pos_catalog_items SET activo=false, updated_at=NOW() WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Item de catálogo não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Sessões de caixa ────────────────────────────────────────────────────────

func (h *Handler) ListarSessoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("status"); v != "" {
		args = append(args, v)
		where += " AND status=$" + strconv.Itoa(len(args))
	}
	args = append(args, limit, offset)
	n := len(args)
	rows, _ := h.db.Query(r.Context(),
		"SELECT id, terminal_id, user_id, opened_at, closed_at, opening_amount, closing_amount, status "+
			"FROM pos_sessions WHERE "+where+" ORDER BY opened_at DESC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	defer rows.Close()
	type Row struct {
		ID            int64      `json:"id"`
		TerminalID    int64      `json:"terminal_id"`
		UserID        int64      `json:"user_id"`
		OpenedAt      time.Time  `json:"opened_at"`
		ClosedAt      *time.Time `json:"closed_at"`
		OpeningAmount float64    `json:"opening_amount"`
		ClosingAmount *float64   `json:"closing_amount"`
		Status        string     `json:"status"`
	}
	data := []Row{}
	for rows.Next() {
		var s Row
		if rows.Scan(&s.ID, &s.TerminalID, &s.UserID, &s.OpenedAt, &s.ClosedAt, &s.OpeningAmount, &s.ClosingAmount, &s.Status) == nil {
			data = append(data, s)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AbrirSessao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		TerminalID    int64   `json:"terminal_id"`
		OpeningAmount float64 `json:"opening_amount"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.TerminalID == 0 {
		jsonErr(w, "terminal_id é obrigatório", http.StatusBadRequest)
		return
	}

	// O token de terminal não deve abrir sessões — apenas operadores humanos.
	// Esta proteção é redundante com o middleware RequireHumanOperator, mas
	// defende contra chamadas internas ou testes que o contornem.
	if mw.IsTerminalToken(r) {
		jsonErr(w, "Operação requer autenticação de operador humano", http.StatusForbidden)
		return
	}

	// Resolver o funcionário de RH associado à conta pessoal do operador.
	funcID, err := h.resolveFuncionarioID(r.Context(), user.TenantID, user.ID)
	if err != nil || funcID == 0 {
		jsonErr(w, "Utilizador não está ligado a um funcionário ativo", http.StatusForbidden)
		return
	}

	var ativo bool
	if err := h.db.QueryRow(r.Context(), `SELECT activo FROM pos_terminals WHERE id=$1 AND tenant_id=$2`, body.TerminalID, user.TenantID).Scan(&ativo); err != nil || !ativo {
		jsonErr(w, "Terminal não encontrado ou inativo", http.StatusBadRequest)
		return
	}

	// Validar autorização do funcionário no terminal (Fase 3).
	// Quando não existem atribuições para o terminal, permite (modo permissivo).
	autorizado, err := h.funcionarioAutorizadoNoTerminal(r.Context(), user.TenantID, body.TerminalID, funcID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if !autorizado {
		jsonErr(w, "Funcionário não autorizado a operar este terminal", http.StatusForbidden)
		return
	}

	// Não permitir duas sessões abertas para o mesmo terminal (Fase 3).
	var existeTerminalAberto int64
	if err := h.db.QueryRow(r.Context(), `SELECT id FROM pos_sessions WHERE tenant_id=$1 AND terminal_id=$2 AND status='aberta'`, user.TenantID, body.TerminalID).Scan(&existeTerminalAberto); err == nil {
		jsonErr(w, fmt.Sprintf("Já existe uma sessão de caixa aberta para este terminal (#%d)", existeTerminalAberto), http.StatusConflict)
		return
	}

	var id int64
	err = h.db.QueryRow(r.Context(), `
		INSERT INTO pos_sessions (tenant_id, terminal_id, user_id, funcionario_id, opening_amount)
		VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		user.TenantID, body.TerminalID, user.ID, funcID, body.OpeningAmount).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// resolveFuncionarioID devolve o rh.funcionarios.id associado a um user_id no
// tenant, ou 0 se não existir/inativo. Centraliza a resolução para evitar
// duplicação entre sessões e vendas.
func (h *Handler) resolveFuncionarioID(ctx context.Context, tenantID, userID int64) (int64, error) {
	f, err := funcionario.NewService(h.db).PorUserID(ctx, tenantID, userID)
	if err != nil {
		return 0, err
	}
	if f == nil || strings.ToLower(f.Estado) != "ativo" {
		return 0, fmt.Errorf("funcionário inativo ou não encontrado")
	}
	return f.ID, nil
}

// funcionarioAutorizadoNoTerminal verifica se um funcionário pode operar um
// terminal. Se não existirem atribuições para o terminal, permite (modo
// permissivo). Se existirem, exige pelo menos uma ativa e válida.
func (h *Handler) funcionarioAutorizadoNoTerminal(ctx context.Context, tenantID, terminalID, funcionarioID int64) (bool, error) {
	var totalAtribuicoes int
	err := h.db.QueryRow(ctx, `
		SELECT COUNT(*) FROM pos.terminal_funcionarios
		 WHERE tenant_id=$1 AND terminal_id=$2 AND ativo=true
		   AND (valido_de IS NULL OR valido_de <= NOW())
		   AND (valido_ate IS NULL OR valido_ate >= NOW())`, tenantID, terminalID).Scan(&totalAtribuicoes)
	if err != nil {
		return false, err
	}
	if totalAtribuicoes == 0 {
		return true, nil
	}
	var autorizado int
	err = h.db.QueryRow(ctx, `
		SELECT COUNT(*) FROM pos.terminal_funcionarios
		 WHERE tenant_id=$1 AND terminal_id=$2 AND funcionario_id=$3 AND ativo=true
		   AND (valido_de IS NULL OR valido_de <= NOW())
		   AND (valido_ate IS NULL OR valido_ate >= NOW())`, tenantID, terminalID, funcionarioID).Scan(&autorizado)
	return autorizado > 0, err
}

func (h *Handler) ObterSessaoAtual(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var s struct {
		ID            int64     `json:"id"`
		TerminalID    int64     `json:"terminal_id"`
		OpeningAmount float64   `json:"opening_amount"`
		Status        string    `json:"status"`
		OpenedAt      time.Time `json:"opened_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, terminal_id, opening_amount, status, opened_at
		  FROM pos_sessions WHERE tenant_id=$1 AND user_id=$2 AND status='aberta'`,
		user.TenantID, user.ID).Scan(&s.ID, &s.TerminalID, &s.OpeningAmount, &s.Status, &s.OpenedAt)
	if err != nil {
		jsonErr(w, "Não existe nenhuma sessão de caixa aberta", http.StatusNotFound)
		return
	}
	jsonOK(w, s, http.StatusOK)
}

// detalharPagamentosSessao soma as vendas concluídas da sessão por método de
// pagamento — devolve o mapa completo (informativo, todos os métodos) e em
// separado o total em numerário (o único fisicamente contável na gaveta, e
// por isso o único que entra no cálculo de "valor esperado" do fecho).
func (h *Handler) detalharPagamentosSessao(ctx context.Context, sessaoID string) (map[string]float64, float64, error) {
	rows, err := h.db.Query(ctx, `
		SELECT sp.tipo, COALESCE(SUM(sp.valor),0)
		  FROM pos_sale_payments sp
		  JOIN pos_sales s ON s.id = sp.pos_sale_id
		 WHERE s.pos_session_id=$1 AND s.status='concluida'
		 GROUP BY sp.tipo`, sessaoID)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	detalhamento := map[string]float64{}
	var totalNumerario float64
	for rows.Next() {
		var tipo string
		var total float64
		if rows.Scan(&tipo, &total) != nil {
			continue
		}
		detalhamento[tipo] = total
		if tipo == "numerario" {
			totalNumerario = total
		}
	}
	return detalhamento, totalNumerario, nil
}

// resumoMovimentosCaixa soma os movimentos (suprimento/sangria/depósito) de
// uma sessão por tipo. "outro" fica de fora do cálculo automático do valor
// esperado — existe só para registo/auditoria, não tem sinal óbvio (nem
// sempre é entrada, nem sempre é saída).
func (h *Handler) resumoMovimentosCaixa(ctx context.Context, tenantID int64, sessaoID string) (suprimentos, sangrias, depositos float64, err error) {
	rows, err := h.db.Query(ctx, `
		SELECT tipo, COALESCE(SUM(valor),0) FROM pos_cash_movements
		 WHERE pos_session_id=$1 AND tenant_id=$2
		 GROUP BY tipo`, sessaoID, tenantID)
	if err != nil {
		return 0, 0, 0, err
	}
	defer rows.Close()
	for rows.Next() {
		var tipo string
		var total float64
		if rows.Scan(&tipo, &total) != nil {
			continue
		}
		switch tipo {
		case "suprimento":
			suprimentos = total
		case "sangria":
			sangrias = total
		case "deposito":
			depositos = total
		}
	}
	return suprimentos, sangrias, depositos, nil
}

// FecharSessao calcula o valor esperado em numerário — fundo de caixa +
// vendas em numerário + suprimentos - sangrias - depósitos — e devolve
// também o detalhamento por método de pagamento (informativo; só o
// numerário é fisicamente contável). Se enviada, a contagem de notas/moedas
// tem de bater com closing_amount; se houver diferença não-trivial, exige
// justificativa em vez de aceitar o fecho em silêncio.
func (h *Handler) FecharSessao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		ClosingAmount float64        `json:"closing_amount"`
		ContagemNotas map[string]int `json:"contagem_notas"`
		Justificativa *string        `json:"justificativa"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "closing_amount é obrigatório", http.StatusBadRequest)
		return
	}
	var openingAmount float64
	if err := h.db.QueryRow(r.Context(), `SELECT opening_amount FROM pos_sessions WHERE id=$1 AND tenant_id=$2 AND status='aberta'`, id, user.TenantID).Scan(&openingAmount); err != nil {
		jsonErr(w, "Sessão de caixa não encontrada ou já fechada", http.StatusNotFound)
		return
	}

	detalhamentoMetodos, totalNumerario, err := h.detalharPagamentosSessao(r.Context(), id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	suprimentos, sangrias, depositos, err := h.resumoMovimentosCaixa(r.Context(), user.TenantID, id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	valorEsperado := openingAmount + totalNumerario + suprimentos - sangrias - depositos
	diferenca := body.ClosingAmount - valorEsperado

	if body.ContagemNotas != nil {
		var somaContagem float64
		for denomTxt, qtd := range body.ContagemNotas {
			denom, errConv := strconv.ParseFloat(denomTxt, 64)
			if errConv != nil || qtd < 0 {
				jsonErr(w, "contagem_notas inválida — chaves devem ser o valor da nota/moeda, valores a quantidade", http.StatusBadRequest)
				return
			}
			somaContagem += denom * float64(qtd)
		}
		if math.Abs(somaContagem-body.ClosingAmount) > 0.005 {
			jsonErr(w, fmt.Sprintf("A contagem de notas/moedas soma %.2f, mas closing_amount é %.2f", somaContagem, body.ClosingAmount), http.StatusUnprocessableEntity)
			return
		}
	}
	if math.Abs(diferenca) > 0.005 && (body.Justificativa == nil || strings.TrimSpace(*body.Justificativa) == "") {
		jsonErr(w, fmt.Sprintf("Há uma diferença de caixa de %.2f — indique uma justificativa para fechar", diferenca), http.StatusUnprocessableEntity)
		return
	}

	var contagemJSON []byte
	if body.ContagemNotas != nil {
		contagemJSON, _ = json.Marshal(body.ContagemNotas)
	}

	if _, err := h.db.Exec(r.Context(), `
		UPDATE pos_sessions
		   SET closing_amount=$1, closed_at=NOW(), status='fechada',
		       contagem_notas=$2, justificativa_diferenca=$3
		 WHERE id=$4`,
		body.ClosingAmount, contagemJSON, body.Justificativa, id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"valor_esperado":       valorEsperado,
		"diferenca":            diferenca,
		"detalhamento_metodos": detalhamentoMetodos,
		"movimentos": map[string]float64{
			"suprimentos": suprimentos, "sangrias": sangrias, "depositos": depositos,
		},
	}, http.StatusOK)
}

// ObterFechoSessao devolve o "relatório de fecho" completo de uma sessão —
// pensado para o app poder mostrar/imprimir sem repetir os cálculos que já
// aconteceram em FecharSessao. Funciona tanto para sessões já fechadas
// (mostra os valores gravados) como para uma sessão ainda aberta (pré-visualização
// de "quanto daria se fechasse agora").
func (h *Handler) ObterFechoSessao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var s struct {
		ID            int64
		TerminalID    int64
		TerminalNome  string
		UserID        int64
		OperadorNome  string
		OpenedAt      time.Time
		ClosedAt      *time.Time
		OpeningAmount float64
		ClosingAmount *float64
		Status        string
		ContagemNotas []byte
		Justificativa *string
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT s.id, s.terminal_id, COALESCE(t.nome,''), s.user_id, COALESCE(u.nome,''),
		       s.opened_at, s.closed_at, s.opening_amount, s.closing_amount, s.status,
		       s.contagem_notas, s.justificativa_diferenca
		  FROM pos_sessions s
		  LEFT JOIN pos_terminals t ON t.id = s.terminal_id
		  LEFT JOIN auth.users u ON u.id = s.user_id
		 WHERE s.id=$1 AND s.tenant_id=$2`,
		id, user.TenantID,
	).Scan(&s.ID, &s.TerminalID, &s.TerminalNome, &s.UserID, &s.OperadorNome,
		&s.OpenedAt, &s.ClosedAt, &s.OpeningAmount, &s.ClosingAmount, &s.Status,
		&s.ContagemNotas, &s.Justificativa)
	if err != nil {
		jsonErr(w, "Sessão de caixa não encontrada", http.StatusNotFound)
		return
	}

	detalhamentoMetodos, totalNumerario, err := h.detalharPagamentosSessao(r.Context(), id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	suprimentos, sangrias, depositos, err := h.resumoMovimentosCaixa(r.Context(), user.TenantID, id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	valorEsperado := s.OpeningAmount + totalNumerario + suprimentos - sangrias - depositos

	var diferenca *float64
	if s.ClosingAmount != nil {
		d := *s.ClosingAmount - valorEsperado
		diferenca = &d
	}

	var contagem map[string]int
	if len(s.ContagemNotas) > 0 {
		_ = json.Unmarshal(s.ContagemNotas, &contagem)
	}

	jsonOK(w, map[string]any{
		"sessao": map[string]any{
			"id": s.ID, "terminal_id": s.TerminalID, "terminal_nome": s.TerminalNome,
			"user_id": s.UserID, "operador_nome": s.OperadorNome,
			"opened_at": s.OpenedAt, "closed_at": s.ClosedAt, "status": s.Status,
			"opening_amount": s.OpeningAmount, "closing_amount": s.ClosingAmount,
		},
		"detalhamento_metodos": detalhamentoMetodos,
		"movimentos": map[string]float64{
			"suprimentos": suprimentos, "sangrias": sangrias, "depositos": depositos,
		},
		"valor_esperado": valorEsperado,
		"diferenca":      diferenca,
		"contagem_notas": contagem,
		"justificativa":  s.Justificativa,
	}, http.StatusOK)
}

// ── Produtos (pesquisa rápida) ──────────────────────────────────────────────

func (h *Handler) BuscarProdutos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	termo := q.Get("q")
	if termo == "" {
		jsonOK(w, []any{}, http.StatusOK)
		return
	}
	var warehouseID any
	if v := q.Get("warehouse_id"); v != "" {
		warehouseID = v
	}
	rows, _ := h.db.Query(r.Context(), `
		SELECT pci.id, pci.product_id, pci.product_variant_id, p.codigo, p.nome,
		       pci.codigo_barra, pci.preco_venda, p.iva_percentual, si.available_quantity
		  FROM pos_catalog_items pci
		  JOIN products p ON p.id = pci.product_id
		  LEFT JOIN stock_items si ON si.product_id = pci.product_id AND si.tenant_id = pci.tenant_id
		       AND si.warehouse_id = $2 AND si.product_variant_id IS NOT DISTINCT FROM pci.product_variant_id
		 WHERE pci.tenant_id=$1 AND pci.activo=true
		   AND (p.nome ILIKE $3 OR p.codigo ILIKE $3 OR pci.codigo_barra = $4)
		 ORDER BY p.nome LIMIT 20`,
		user.TenantID, warehouseID, "%"+termo+"%", termo)
	defer rows.Close()
	type Row struct {
		ID                int64    `json:"id"`
		ProductID         int64    `json:"product_id"`
		ProductVariantID  *int64   `json:"product_variant_id"`
		Codigo            string   `json:"codigo"`
		Nome              string   `json:"nome"`
		CodigoBarra       *string  `json:"codigo_barra"`
		PrecoVenda        float64  `json:"preco_venda"`
		IvaPercentual     float64  `json:"iva_percentual"`
		AvailableQuantity *float64 `json:"available_quantity"`
	}
	data := []Row{}
	for rows.Next() {
		var p Row
		if rows.Scan(&p.ID, &p.ProductID, &p.ProductVariantID, &p.Codigo, &p.Nome, &p.CodigoBarra, &p.PrecoVenda, &p.IvaPercentual, &p.AvailableQuantity) == nil {
			data = append(data, p)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// ── Vendas ────────────────────────────────────────────────────────────────────

func (h *Handler) ListarVendas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	for _, f := range []string{"status", "pos_session_id"} {
		if v := q.Get(f); v != "" {
			args = append(args, v)
			where += " AND " + f + "=$" + strconv.Itoa(len(args))
		}
	}
	// Busca livre por número do documento, client_reference (terminal
	// offline) ou referência de pagamento (pos_sale_payments.referencia,
	// ex.: ID de transação Mobile Money) — as três condições em OR, porque
	// do ponto de vista de quem procura é "por número ou por referência",
	// não os dois ao mesmo tempo.
	if v := q.Get("q"); v != "" {
		args = append(args, "%"+v+"%")
		n := strconv.Itoa(len(args))
		where += " AND (numero ILIKE $" + n + " OR client_reference ILIKE $" + n +
			" OR EXISTS (SELECT 1 FROM pos_sale_payments p WHERE p.pos_sale_id = pos_sales.id AND p.referencia ILIKE $" + n + "))"
	}
	countArgs := make([]any, len(args))
	copy(countArgs, args)
	args = append(args, limit, offset)
	n := len(args)
	rows, _ := h.db.Query(r.Context(),
		"SELECT id, numero, pos_session_id, terminal_id, customer_id, status, subtotal, desconto_total, imposto_total, total, valor_recebido, troco, moeda, sold_at, created_at "+
			"FROM pos_sales WHERE "+where+" ORDER BY created_at DESC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	defer rows.Close()
	type Row struct {
		ID            int64      `json:"id"`
		Numero        string     `json:"numero"`
		PosSessionID  int64      `json:"pos_session_id"`
		TerminalID    int64      `json:"terminal_id"`
		CustomerID    *int64     `json:"customer_id"`
		Status        string     `json:"status"`
		Subtotal      float64    `json:"subtotal"`
		DescontoTotal float64    `json:"desconto_total"`
		ImpostoTotal  float64    `json:"imposto_total"`
		Total         float64    `json:"total"`
		ValorRecebido float64    `json:"valor_recebido"`
		Troco         float64    `json:"troco"`
		Moeda         string     `json:"moeda"`
		SoldAt        *time.Time `json:"sold_at"`
		CreatedAt     time.Time  `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var s Row
		if rows.Scan(&s.ID, &s.Numero, &s.PosSessionID, &s.TerminalID, &s.CustomerID, &s.Status, &s.Subtotal, &s.DescontoTotal, &s.ImpostoTotal, &s.Total, &s.ValorRecebido, &s.Troco, &s.Moeda, &s.SoldAt, &s.CreatedAt) == nil {
			data = append(data, s)
		}
	}
	var total int
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM pos_sales WHERE "+where, countArgs...).Scan(&total)
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 {
		page = 1
	}
	jsonOK(w, map[string]any{"data": data, "meta": map[string]int{"total": total, "page": page, "limit": limit}}, http.StatusOK)
}

// vendaExistentePorReferencia resolve uma venda já criada a partir do
// client_reference gerado pelo terminal offline (ver CriarVenda). Devolve o
// mesmo shape do sucesso de CriarVenda para que um retry idempotente seja
// indistinguível, do ponto de vista do cliente, de uma criação bem-sucedida.
func (h *Handler) vendaExistentePorReferencia(ctx context.Context, tenantID int64, ref string) (map[string]any, error) {
	var id int64
	var numero string
	var total, troco float64
	var invoiceID *int64
	var invoiceNumero *string
	err := h.db.QueryRow(ctx, `
		SELECT s.id, s.numero, s.total, s.troco, s.invoice_id, i.numero
		  FROM pos_sales s LEFT JOIN faturacao.invoices i ON i.id = s.invoice_id
		 WHERE s.tenant_id=$1 AND s.client_reference=$2`,
		tenantID, ref).Scan(&id, &numero, &total, &troco, &invoiceID, &invoiceNumero)
	if err != nil {
		return nil, err
	}
	return map[string]any{
		"id": id, "numero": numero, "total": total, "troco": troco,
		"invoice_id": invoiceID, "invoice_numero": invoiceNumero,
	}, nil
}

func (h *Handler) CriarVenda(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		PosSessionID    int64   `json:"pos_session_id"`
		CustomerID      *int64  `json:"customer_id"`
		ClientReference *string `json:"client_reference"`
		Itens           []struct {
			ProductID        int64   `json:"product_id"`
			ProductVariantID *int64  `json:"product_variant_id"`
			Descricao        *string `json:"descricao"`
			Quantidade       float64 `json:"quantidade"`
			PrecoUnitario    float64 `json:"preco_unitario"`
			DescontoPercent  float64 `json:"desconto_percent"`
			ImpostoPercent   float64 `json:"imposto_percent"`
		} `json:"itens"`
		Pagamentos []struct {
			Tipo            string  `json:"tipo"`
			Valor           float64 `json:"valor"`
			Referencia      *string `json:"referencia"`
			PaymentMethodID *int64  `json:"payment_method_id"`
		} `json:"pagamentos"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.PosSessionID == 0 || len(body.Itens) == 0 || len(body.Pagamentos) == 0 {
		jsonErr(w, "pos_session_id, itens e pagamentos são obrigatórios", http.StatusBadRequest)
		return
	}
	for _, p := range body.Pagamentos {
		if !metodosPagamentoValidos[p.Tipo] || p.Valor <= 0 {
			jsonErr(w, "tipo de pagamento inválido", http.StatusBadRequest)
			return
		}
	}

	ctx := r.Context()

	// Idempotência: um terminal offline pode reenviar a mesma venda (ex.:
	// perdeu a resposta HTTP mas o pedido já tinha sido processado). Se
	// client_reference já existir para este tenant, devolve a venda existente
	// em vez de duplicar venda + movimentos de stock.
	temReferencia := body.ClientReference != nil && *body.ClientReference != ""
	if temReferencia {
		if existente, err := h.vendaExistentePorReferencia(ctx, user.TenantID, *body.ClientReference); err == nil {
			jsonOK(w, existente, http.StatusOK)
			return
		}
	}

	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	var terminalID, funcionarioID int64
	if err := tx.QueryRow(ctx, `SELECT terminal_id, COALESCE(funcionario_id,0) FROM pos_sessions WHERE id=$1 AND tenant_id=$2 AND status='aberta'`, body.PosSessionID, user.TenantID).Scan(&terminalID, &funcionarioID); err != nil {
		jsonErr(w, "Sessão de caixa não encontrada ou já fechada", http.StatusBadRequest)
		return
	}
	if funcionarioID == 0 {
		jsonErr(w, "Sessão de caixa sem operador identificado", http.StatusUnprocessableEntity)
		return
	}

	var warehouseID *int64
	if err := tx.QueryRow(ctx, `SELECT warehouse_id FROM pos_terminals WHERE id=$1`, terminalID).Scan(&warehouseID); err != nil || warehouseID == nil {
		jsonErr(w, "Terminal sem armazém configurado", http.StatusUnprocessableEntity)
		return
	}

	numero, _, err := proximoNumeroSerie(ctx, tx, user.TenantID, "VD")
	if err != nil {
		jsonErr(w, "Não existe nenhuma série activa configurada para Vendas POS. Configure em Faturação > Séries Documentais.", http.StatusUnprocessableEntity)
		return
	}

	var id int64
	if err := tx.QueryRow(ctx, `
		INSERT INTO pos_sales (tenant_id, pos_session_id, terminal_id, funcionario_id, numero, customer_id, client_reference, status, sold_at, created_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,'concluida',NOW(),$8) RETURNING id`,
		user.TenantID, body.PosSessionID, terminalID, funcionarioID, numero, body.CustomerID, body.ClientReference, user.ID).Scan(&id); err != nil {
		// Corrida rara: dois pedidos com a mesma client_reference chegaram em
		// paralelo e o outro venceu entretanto (protegido pelo índice único).
		if temReferencia && isUniqueViolation(err) {
			if existente, err2 := h.vendaExistentePorReferencia(ctx, user.TenantID, *body.ClientReference); err2 == nil {
				jsonOK(w, existente, http.StatusOK)
				return
			}
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	var subtotalTotal, descontoTotalTotal, impostoTotalTotal, totalGeral float64
	itensFatura := make([]itemFaturaPOS, 0, len(body.Itens))
	for _, item := range body.Itens {
		if item.Quantidade <= 0 || item.PrecoUnitario < 0 {
			jsonErr(w, "quantidade e preco_unitario são obrigatórios em todos os itens", http.StatusBadRequest)
			return
		}
		subtotal := item.Quantidade * item.PrecoUnitario
		descontoValor := subtotal * item.DescontoPercent / 100
		impostoValor := (subtotal - descontoValor) * item.ImpostoPercent / 100
		total := subtotal - descontoValor + impostoValor

		var stockItemID int64
		var disponivel float64
		if err := tx.QueryRow(ctx, `
			SELECT id, available_quantity FROM stock_items
			 WHERE tenant_id=$1 AND product_id=$2 AND warehouse_id=$3
			   AND product_variant_id IS NOT DISTINCT FROM $4
			 FOR UPDATE`, user.TenantID, item.ProductID, *warehouseID, item.ProductVariantID).Scan(&stockItemID, &disponivel); err != nil || disponivel < item.Quantidade {
			jsonErr(w, fmt.Sprintf("Stock insuficiente para o produto #%d", item.ProductID), http.StatusUnprocessableEntity)
			return
		}

		if _, err := tx.Exec(ctx, `
			INSERT INTO pos_sale_items (pos_sale_id, product_id, product_variant_id, descricao, quantidade, preco_unitario,
			  desconto_valor, imposto_valor, subtotal, total)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
			id, item.ProductID, item.ProductVariantID, item.Descricao, item.Quantidade, item.PrecoUnitario,
			descontoValor, impostoValor, subtotal-descontoValor, total); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}

		if _, err := tx.Exec(ctx, `UPDATE stock_items SET quantity=quantity-$1, updated_at=NOW() WHERE id=$2`,
			item.Quantidade, stockItemID); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		if _, err := tx.Exec(ctx, `INSERT INTO stock_movements (tenant_id, stock_item_id, tipo, quantity, reference_type, reference_id) VALUES ($1,$2,'saida',$3,'pos_sale',$4)`,
			user.TenantID, stockItemID, item.Quantidade, id); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}

		subtotalTotal += subtotal - descontoValor
		descontoTotalTotal += descontoValor
		impostoTotalTotal += impostoValor
		totalGeral += total

		itensFatura = append(itensFatura, itemFaturaPOS{
			ProductID:        item.ProductID,
			ProductVariantID: item.ProductVariantID,
			Descricao:        item.Descricao,
			Quantidade:       item.Quantidade,
			PrecoUnitario:    item.PrecoUnitario,
			DescontoValor:    descontoValor,
			ImpostoValor:     impostoValor,
			Subtotal:         subtotal - descontoValor,
			Total:            total,
		})
	}

	if _, err := tx.Exec(ctx, `UPDATE pos_sales SET subtotal=$1, desconto_total=$2, imposto_total=$3, total=$4 WHERE id=$5`,
		subtotalTotal, descontoTotalTotal, impostoTotalTotal, totalGeral, id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	var valorRecebido float64
	for _, p := range body.Pagamentos {
		valorRecebido += p.Valor
	}
	if valorRecebido < totalGeral-0.005 {
		jsonErr(w, "Valor pago insuficiente", http.StatusUnprocessableEntity)
		return
	}
	troco := valorRecebido - totalGeral
	for _, p := range body.Pagamentos {
		if _, err := tx.Exec(ctx, `INSERT INTO pos_sale_payments (pos_sale_id, payment_method_id, tipo, valor, referencia) VALUES ($1,$2,$3,$4,$5)`,
			id, p.PaymentMethodID, p.Tipo, p.Valor, p.Referencia); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
	}
	if _, err := tx.Exec(ctx, `UPDATE pos_sales SET valor_recebido=$1, troco=$2 WHERE id=$3`, valorRecebido, troco, id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	// Faturação fiscal: toda venda POS concluída gera fatura fiscal já
	// emitida (o pagamento integral acima de "Valor pago insuficiente" já
	// foi validado), na MESMA transacção da venda — se falhar, a venda
	// inteira é revertida, para nunca existir uma venda concluída sem
	// documento fiscal correspondente.
	customerID := body.CustomerID
	if customerID == nil {
		cid, err := h.consumidorFinalID(ctx, tx, user.TenantID)
		if err != nil {
			jsonErr(w, "Erro interno ao preparar cliente para a fatura", http.StatusInternalServerError)
			return
		}
		customerID = &cid
	}
	invoiceID, invoiceNumero, err := h.criarFaturaParaVenda(ctx, tx, faturaVendaParams{
		tenantID:   user.TenantID,
		customerID: *customerID,
		userID:     user.ID,
		itens:      itensFatura,
		subtotal:   subtotalTotal,
		desconto:   descontoTotalTotal,
		imposto:    impostoTotalTotal,
		total:      totalGeral,
		moeda:      "MZN",
	})
	if err != nil {
		jsonErr(w, "Não existe nenhuma série activa configurada para Faturas (FT). Configure em Faturação > Séries Documentais.", http.StatusUnprocessableEntity)
		return
	}
	if _, err := tx.Exec(ctx, `UPDATE pos_sales SET invoice_id=$1 WHERE id=$2`, invoiceID, id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	adapters.PostInvoiceJournalEntry(ctx, h.db, h.accounting, user.TenantID, user.ID, invoiceID)

	if h.wsHub != nil {
		h.wsHub.SendEvent(user.ID, ws.EvtVendaCriada, map[string]any{"id": id, "numero": numero, "total": totalGeral})
		h.wsHub.SendEvent(user.ID, ws.EvtPagamentoRecebido, map[string]any{"venda_id": id, "valor": valorRecebido})
	}
	if h.push != nil {
		h.push.SendToUser(ctx, user.ID, "Venda concluída",
			fmt.Sprintf("Venda %s registada — %.2f %s", numero, totalGeral, "MZN"),
			map[string]string{"tipo": "venda_criada", "venda_id": strconv.FormatInt(id, 10)})
	}

	jsonOK(w, map[string]any{
		"id": id, "numero": numero, "total": totalGeral, "troco": troco,
		"invoice_id": invoiceID, "invoice_numero": invoiceNumero,
	}, http.StatusCreated)
}

func (h *Handler) ObterVenda(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var s struct {
		ID            int64      `json:"id"`
		Numero        string     `json:"numero"`
		PosSessionID  int64      `json:"pos_session_id"`
		TerminalID    int64      `json:"terminal_id"`
		CustomerID    *int64     `json:"customer_id"`
		Status        string     `json:"status"`
		Moeda         string     `json:"moeda"`
		Subtotal      float64    `json:"subtotal"`
		DescontoTotal float64    `json:"desconto_total"`
		ImpostoTotal  float64    `json:"imposto_total"`
		Total         float64    `json:"total"`
		ValorRecebido float64    `json:"valor_recebido"`
		Troco         float64    `json:"troco"`
		SoldAt        *time.Time `json:"sold_at"`
		CreatedAt     time.Time  `json:"created_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, numero, pos_session_id, terminal_id, customer_id, status, moeda, subtotal, desconto_total, imposto_total, total, valor_recebido, troco, sold_at, created_at
		  FROM pos_sales WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&s.ID, &s.Numero, &s.PosSessionID, &s.TerminalID, &s.CustomerID, &s.Status, &s.Moeda, &s.Subtotal, &s.DescontoTotal, &s.ImpostoTotal, &s.Total, &s.ValorRecebido, &s.Troco, &s.SoldAt, &s.CreatedAt)
	if err != nil {
		jsonErr(w, "Venda não encontrada", http.StatusNotFound)
		return
	}
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, product_id, product_variant_id, descricao, quantidade, preco_unitario, desconto_valor, imposto_valor, subtotal, total, quantidade_devolvida
		  FROM pos_sale_items WHERE pos_sale_id=$1 ORDER BY id`, id)
	defer rows.Close()
	type Item struct {
		ID                  int64   `json:"id"`
		ProductID           int64   `json:"product_id"`
		ProductVariantID    *int64  `json:"product_variant_id"`
		Descricao           *string `json:"descricao"`
		Quantidade          float64 `json:"quantidade"`
		PrecoUnitario       float64 `json:"preco_unitario"`
		DescontoValor       float64 `json:"desconto_valor"`
		ImpostoValor        float64 `json:"imposto_valor"`
		Subtotal            float64 `json:"subtotal"`
		Total               float64 `json:"total"`
		QuantidadeDevolvida float64 `json:"quantidade_devolvida"`
	}
	items := []Item{}
	for rows.Next() {
		var i Item
		if rows.Scan(&i.ID, &i.ProductID, &i.ProductVariantID, &i.Descricao, &i.Quantidade, &i.PrecoUnitario, &i.DescontoValor, &i.ImpostoValor, &i.Subtotal, &i.Total, &i.QuantidadeDevolvida) == nil {
			items = append(items, i)
		}
	}
	payRows, _ := h.db.Query(r.Context(), `SELECT id, payment_method_id, tipo, valor, referencia FROM pos_sale_payments WHERE pos_sale_id=$1 ORDER BY id`, id)
	defer payRows.Close()
	type Payment struct {
		ID              int64   `json:"id"`
		PaymentMethodID *int64  `json:"payment_method_id"`
		Tipo            string  `json:"tipo"`
		Valor           float64 `json:"valor"`
		Referencia      *string `json:"referencia"`
	}
	payments := []Payment{}
	for payRows.Next() {
		var p Payment
		if payRows.Scan(&p.ID, &p.PaymentMethodID, &p.Tipo, &p.Valor, &p.Referencia) == nil {
			payments = append(payments, p)
		}
	}
	jsonOK(w, map[string]any{"venda": s, "itens": items, "pagamentos": payments}, http.StatusOK)
}

func (h *Handler) CancelarVenda(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Reason string `json:"reason"`
	}
	// corpo é opcional — nem todos os clientes enviam motivo
	json.NewDecoder(r.Body).Decode(&body)

	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	var terminalID int64
	if err := tx.QueryRow(ctx, `SELECT terminal_id FROM pos_sales WHERE id=$1 AND tenant_id=$2 AND status='concluida' FOR UPDATE`, id, user.TenantID).Scan(&terminalID); err != nil {
		jsonErr(w, "Venda não encontrada ou já cancelada", http.StatusNotFound)
		return
	}
	var warehouseID *int64
	if err := tx.QueryRow(ctx, `SELECT warehouse_id FROM pos_terminals WHERE id=$1`, terminalID).Scan(&warehouseID); err != nil || warehouseID == nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	rows, err := tx.Query(ctx, `SELECT product_id, product_variant_id, quantidade FROM pos_sale_items WHERE pos_sale_id=$1`, id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	type saleItem struct {
		productID  int64
		variantID  *int64
		quantidade float64
	}
	var items []saleItem
	for rows.Next() {
		var it saleItem
		if rows.Scan(&it.productID, &it.variantID, &it.quantidade) == nil {
			items = append(items, it)
		}
	}
	rows.Close()

	for _, it := range items {
		var stockItemID int64
		if err := tx.QueryRow(ctx, `
			SELECT id FROM stock_items
			 WHERE tenant_id=$1 AND product_id=$2 AND warehouse_id=$3
			   AND product_variant_id IS NOT DISTINCT FROM $4
			 FOR UPDATE`, user.TenantID, it.productID, *warehouseID, it.variantID).Scan(&stockItemID); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		if _, err := tx.Exec(ctx, `UPDATE stock_items SET quantity=quantity+$1, updated_at=NOW() WHERE id=$2`,
			it.quantidade, stockItemID); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		if _, err := tx.Exec(ctx, `INSERT INTO stock_movements (tenant_id, stock_item_id, tipo, quantity, reference_type, reference_id) VALUES ($1,$2,'entrada',$3,'pos_sale_cancel',$4)`,
			user.TenantID, stockItemID, it.quantidade, id); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
	}

	if _, err := tx.Exec(ctx, `UPDATE pos_sales SET status='cancelada', motivo_cancelamento=$1 WHERE id=$2`,
		nullString(body.Reason), id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
