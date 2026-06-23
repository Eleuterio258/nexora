package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

type Lead struct {
	ID           int64      `json:"id"`
	Nome         string     `json:"nome"`
	Empresa      *string    `json:"empresa"`
	Email        *string    `json:"email"`
	Telefone     *string    `json:"telefone"`
	Origem       string     `json:"origem"`
	Estado       string     `json:"estado"`
	Responsavel  *string    `json:"responsavel"`
	Notas        *string    `json:"notas"`
	ClienteID    *int64     `json:"cliente_id"`
	ConvertidoEm *time.Time `json:"convertido_em"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
}

type leadInput struct {
	Nome        string  `json:"nome"`
	Empresa     *string `json:"empresa"`
	Email       *string `json:"email"`
	Telefone    *string `json:"telefone"`
	Origem      *string `json:"origem"`
	Estado      *string `json:"estado"`
	Responsavel *string `json:"responsavel"`
	Notas       *string `json:"notas"`
}

var leadOrigens = map[string]bool{
	"site": true, "referencia": true, "redes_sociais": true, "evento": true,
	"chamada_fria": true, "email": true, "anuncio": true, "outro": true,
}

var leadEstados = map[string]string{
	"novo":           "Novo",
	"contactado":     "Contactado",
	"qualificado":    "Qualificado",
	"desqualificado": "Desqualificado",
	"convertido":     "Convertido",
}

const leadSelectCols = `id, nome, empresa, email, telefone, origem, estado, responsavel, notas,
	cliente_id, convertido_em, created_at, updated_at`

func scanLead(row pgx.Row) (*Lead, error) {
	var l Lead
	if err := row.Scan(&l.ID, &l.Nome, &l.Empresa, &l.Email, &l.Telefone, &l.Origem, &l.Estado,
		&l.Responsavel, &l.Notas, &l.ClienteID, &l.ConvertidoEm, &l.CreatedAt, &l.UpdatedAt); err != nil {
		return nil, err
	}
	return &l, nil
}

// ── Listagem / CRUD ──────────────────────────────────────────────────────────

func (h *Handler) ListarLeads(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)

	where := "tenant_id=$1"
	args := []any{user.TenantID}

	if estado := q.Get("estado"); estado != "" {
		args = append(args, estado)
		where += " AND estado=$" + strconv.Itoa(len(args))
	}
	if origem := q.Get("origem"); origem != "" {
		args = append(args, origem)
		where += " AND origem=$" + strconv.Itoa(len(args))
	}
	if resp := q.Get("responsavel"); resp != "" {
		args = append(args, resp)
		where += " AND responsavel=$" + strconv.Itoa(len(args))
	}
	if s := q.Get("search"); s != "" {
		args = append(args, "%"+s+"%")
		n := strconv.Itoa(len(args))
		where += " AND (nome ILIKE $" + n + " OR empresa ILIKE $" + n + " OR email ILIKE $" + n + ")"
	}

	countArgs := append([]any{}, args...)
	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(),
		"SELECT "+leadSelectCols+" FROM leads WHERE "+where+
			" ORDER BY created_at DESC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []*Lead{}
	for rows.Next() {
		l, err := scanLead(rows)
		if err == nil {
			data = append(data, l)
		}
	}

	var total int
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM leads WHERE "+where, countArgs...).Scan(&total)
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 {
		page = 1
	}
	jsonOK(w, map[string]any{"data": data, "meta": map[string]int{"total": total, "page": page, "limit": limit}}, http.StatusOK)
}

func (h *Handler) CriarLead(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body leadInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Nome = strings.TrimSpace(body.Nome)
	if body.Nome == "" {
		jsonErr(w, "O nome é obrigatório.", http.StatusUnprocessableEntity)
		return
	}

	origem := strDefault(body.Origem, "outro")
	if !leadOrigens[origem] {
		jsonErr(w, "Origem inválida.", http.StatusUnprocessableEntity)
		return
	}
	estado := strDefault(body.Estado, "novo")
	if _, ok := leadEstados[estado]; !ok {
		jsonErr(w, "Estado inválido.", http.StatusUnprocessableEntity)
		return
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO leads (tenant_id, nome, empresa, email, telefone, origem, estado, responsavel, notas)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
		RETURNING id`,
		user.TenantID, body.Nome, body.Empresa, body.Email, body.Telefone,
		origem, estado, body.Responsavel, body.Notas,
	).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro ao guardar na base de dados.", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterLead(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	row := h.db.QueryRow(r.Context(), "SELECT "+leadSelectCols+" FROM leads WHERE id=$1 AND tenant_id=$2", id, user.TenantID)
	l, err := scanLead(row)
	if err != nil {
		jsonErr(w, "Lead não encontrado.", http.StatusNotFound)
		return
	}
	jsonOK(w, l, http.StatusOK)
}

func (h *Handler) ActualizarLead(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body leadInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Nome = strings.TrimSpace(body.Nome)
	if body.Nome == "" {
		jsonErr(w, "O nome é obrigatório.", http.StatusUnprocessableEntity)
		return
	}
	origem := strDefault(body.Origem, "outro")
	if !leadOrigens[origem] {
		jsonErr(w, "Origem inválida.", http.StatusUnprocessableEntity)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE leads SET
			nome=$1, empresa=$2, email=$3, telefone=$4, origem=$5, responsavel=$6, notas=$7, updated_at=NOW()
		WHERE id=$8 AND tenant_id=$9`,
		body.Nome, body.Empresa, body.Email, body.Telefone, origem, body.Responsavel, body.Notas, id, user.TenantID,
	)
	if err != nil {
		jsonErr(w, "Erro ao actualizar na base de dados.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Lead não encontrado.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// MoverLead avança o lead pelo funil de qualificação (novo/contactado/qualificado/
// desqualificado). A transição para "convertido" só é permitida via /converter.
func (h *Handler) MoverLead(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Estado string `json:"estado"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	if body.Estado == "convertido" {
		jsonErr(w, "Use o endpoint /converter para converter o lead.", http.StatusUnprocessableEntity)
		return
	}
	if _, ok := leadEstados[body.Estado]; !ok {
		jsonErr(w, "Estado inválido.", http.StatusUnprocessableEntity)
		return
	}

	var estadoAtual string
	if err := h.db.QueryRow(r.Context(), "SELECT estado FROM leads WHERE id=$1 AND tenant_id=$2", id, user.TenantID).Scan(&estadoAtual); err != nil {
		jsonErr(w, "Lead não encontrado.", http.StatusNotFound)
		return
	}
	if estadoAtual == "convertido" {
		jsonErr(w, "Este lead já foi convertido.", http.StatusUnprocessableEntity)
		return
	}

	if _, err := h.db.Exec(r.Context(), "UPDATE leads SET estado=$1, updated_at=NOW() WHERE id=$2 AND tenant_id=$3", body.Estado, id, user.TenantID); err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

func (h *Handler) RemoverLead(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), "DELETE FROM leads WHERE id=$1 AND tenant_id=$2", id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao eliminar.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Lead não encontrado.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Conversão ────────────────────────────────────────────────────────────────

type converterLeadInput struct {
	CriarOportunidade  bool     `json:"criar_oportunidade"`
	OportunidadeTitulo *string  `json:"oportunidade_titulo"`
	ValorEstimado      *float64 `json:"valor_estimado"`
	Moeda              *string  `json:"moeda"`
}

// ConverterLead transforma o lead num cliente (clientes.customers) e, opcionalmente,
// cria uma oportunidade associada, replicando admin/api/lead_converter.php.
func (h *Handler) ConverterLead(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body converterLeadInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	var nome string
	var empresa, email, telefone, responsavel *string
	var estado string
	var clienteID *int64
	if err := tx.QueryRow(ctx,
		"SELECT nome, empresa, email, telefone, responsavel, estado, cliente_id FROM leads WHERE id=$1 AND tenant_id=$2 FOR UPDATE",
		id, user.TenantID,
	).Scan(&nome, &empresa, &email, &telefone, &responsavel, &estado, &clienteID); err != nil {
		jsonErr(w, "Lead não encontrado.", http.StatusNotFound)
		return
	}

	if estado == "convertido" {
		jsonErr(w, "Lead já convertido.", http.StatusConflict)
		return
	}

	if clienteID == nil {
		nomeCliente := nome
		if empresa != nil && strings.TrimSpace(*empresa) != "" {
			nomeCliente = *empresa
		}
		var novoClienteID int64
		if err := tx.QueryRow(ctx, `
			INSERT INTO clientes.customers (tenant_id, nome, email, telefone, estado, observacao)
			VALUES ($1,$2,$3,$4,'ativo',$5)
			RETURNING id`,
			user.TenantID, nomeCliente, email, telefone,
			fmt.Sprintf("Criado a partir do lead CRM #%s", id),
		).Scan(&novoClienteID); err != nil {
			jsonErr(w, "Erro ao criar cliente.", http.StatusInternalServerError)
			return
		}
		clienteID = &novoClienteID
	}

	if _, err := tx.Exec(ctx,
		"UPDATE leads SET estado='convertido', cliente_id=$1, convertido_em=NOW(), updated_at=NOW() WHERE id=$2",
		clienteID, id,
	); err != nil {
		jsonErr(w, "Erro ao actualizar lead.", http.StatusInternalServerError)
		return
	}

	var oportunidadeID *int64
	if body.CriarOportunidade {
		titulo := strDefault(body.OportunidadeTitulo, "Oportunidade — "+nome)
		valor := 0.0
		if body.ValorEstimado != nil && *body.ValorEstimado >= 0 {
			valor = *body.ValorEstimado
		}
		moeda := strDefault(body.Moeda, "MZN")

		var novoOportunidadeID int64
		if err := tx.QueryRow(ctx, `
			INSERT INTO oportunidades (tenant_id, titulo, lead_id, cliente_id, estagio, valor_estimado, moeda, responsavel)
			VALUES ($1,$2,$3,$4,'novo',$5,$6,$7)
			RETURNING id`,
			user.TenantID, titulo, id, clienteID, valor, moeda, responsavel,
		).Scan(&novoOportunidadeID); err != nil {
			jsonErr(w, "Erro ao criar oportunidade.", http.StatusInternalServerError)
			return
		}
		oportunidadeID = &novoOportunidadeID
	}

	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro ao converter lead.", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "cliente_id": clienteID, "oportunidade_id": oportunidadeID}, http.StatusOK)
}
