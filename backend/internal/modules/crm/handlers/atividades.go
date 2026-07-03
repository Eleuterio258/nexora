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

type Atividade struct {
	ID             int64      `json:"id"`
	LeadID         *int64     `json:"lead_id"`
	OportunidadeID *int64     `json:"oportunidade_id"`
	Tipo           string     `json:"tipo"`
	Titulo         string     `json:"titulo"`
	Descricao      *string    `json:"descricao"`
	DataAtividade  *time.Time `json:"data_atividade"`
	Concluida      bool       `json:"concluida"`
	Responsavel    *string    `json:"responsavel"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
}

type atividadeInput struct {
	LeadID         *int64  `json:"lead_id"`
	OportunidadeID *int64  `json:"oportunidade_id"`
	Tipo           *string `json:"tipo"`
	Titulo         string  `json:"titulo"`
	Descricao      *string `json:"descricao"`
	DataAtividade  *string `json:"data_atividade"`
	Responsavel    *string `json:"responsavel"`
}

var atividadeTipos = map[string]bool{
	"nota": true, "tarefa": true, "chamada": true, "reuniao": true, "email": true,
}

const atividadeSelectCols = `id, lead_id, oportunidade_id, tipo, titulo, descricao, data_atividade,
	concluida, responsavel, created_at, updated_at`

func scanAtividade(row pgx.Row) (*Atividade, error) {
	var a Atividade
	if err := row.Scan(&a.ID, &a.LeadID, &a.OportunidadeID, &a.Tipo, &a.Titulo, &a.Descricao,
		&a.DataAtividade, &a.Concluida, &a.Responsavel, &a.CreatedAt, &a.UpdatedAt); err != nil {
		return nil, err
	}
	return &a, nil
}

// ── Listagem / CRUD ──────────────────────────────────────────────────────────

func (h *Handler) ListarAtividades(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)

	where := "tenant_id=$1"
	args := []any{user.TenantID}

	if leadIDStr := q.Get("lead_id"); leadIDStr != "" {
		if leadID, err := strconv.ParseInt(leadIDStr, 10, 64); err == nil {
			args = append(args, leadID)
			where += " AND lead_id=$" + strconv.Itoa(len(args))
		}
	}
	if oportunidadeIDStr := q.Get("oportunidade_id"); oportunidadeIDStr != "" {
		if oportunidadeID, err := strconv.ParseInt(oportunidadeIDStr, 10, 64); err == nil {
			args = append(args, oportunidadeID)
			where += " AND oportunidade_id=$" + strconv.Itoa(len(args))
		}
	}
	if tipo := q.Get("tipo"); tipo != "" {
		args = append(args, tipo)
		where += " AND tipo=$" + strconv.Itoa(len(args))
	}
	if concluidaStr := q.Get("concluida"); concluidaStr != "" {
		args = append(args, concluidaStr == "1" || concluidaStr == "true")
		where += " AND concluida=$" + strconv.Itoa(len(args))
	}
	if resp := q.Get("responsavel"); resp != "" {
		args = append(args, resp)
		where += " AND responsavel=$" + strconv.Itoa(len(args))
	}
	if s := q.Get("search"); s != "" {
		args = append(args, "%"+s+"%")
		where += " AND titulo ILIKE $" + strconv.Itoa(len(args))
	}

	countArgs := append([]any{}, args...)
	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(),
		"SELECT "+atividadeSelectCols+" FROM crm.atividades WHERE "+where+
			" ORDER BY COALESCE(data_atividade, created_at) ASC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []*Atividade{}
	for rows.Next() {
		a, err := scanAtividade(rows)
		if err == nil {
			data = append(data, a)
		}
	}

	var total int
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM crm.atividades WHERE "+where, countArgs...).Scan(&total)
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 {
		page = 1
	}
	jsonOK(w, map[string]any{"data": data, "meta": map[string]int{"total": total, "page": page, "limit": limit}}, http.StatusOK)
}

func (h *Handler) CriarAtividade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body atividadeInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Titulo = strings.TrimSpace(body.Titulo)
	if body.Titulo == "" {
		jsonErr(w, "O título é obrigatório.", http.StatusUnprocessableEntity)
		return
	}
	if body.LeadID == nil && body.OportunidadeID == nil {
		jsonErr(w, "Indique lead_id ou oportunidade_id.", http.StatusUnprocessableEntity)
		return
	}

	tipo := strDefault(body.Tipo, "nota")
	if !atividadeTipos[tipo] {
		jsonErr(w, "Tipo inválido.", http.StatusUnprocessableEntity)
		return
	}

	ctx := r.Context()
	if body.LeadID != nil {
		var exists bool
		if err := h.db.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM leads WHERE id=$1 AND tenant_id=$2)", *body.LeadID, user.TenantID).Scan(&exists); err != nil || !exists {
			jsonErr(w, "Lead não encontrado.", http.StatusNotFound)
			return
		}
	}
	if body.OportunidadeID != nil {
		var exists bool
		if err := h.db.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM oportunidades WHERE id=$1 AND tenant_id=$2)", *body.OportunidadeID, user.TenantID).Scan(&exists); err != nil || !exists {
			jsonErr(w, "Oportunidade não encontrada.", http.StatusNotFound)
			return
		}
	}

	var dataAtividade *time.Time
	if body.DataAtividade != nil && strings.TrimSpace(*body.DataAtividade) != "" {
		t, err := parseDataAtividade(strings.TrimSpace(*body.DataAtividade))
		if err != nil {
			jsonErr(w, "Formato de data inválido.", http.StatusUnprocessableEntity)
			return
		}
		dataAtividade = &t
	}

	var id int64
	err := h.db.QueryRow(ctx, `
		INSERT INTO crm.atividades (tenant_id, lead_id, oportunidade_id, tipo, titulo, descricao, data_atividade, responsavel)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
		RETURNING id`,
		user.TenantID, body.LeadID, body.OportunidadeID, tipo, body.Titulo, body.Descricao, dataAtividade, body.Responsavel,
	).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro ao guardar na base de dados.", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterAtividade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	row := h.db.QueryRow(r.Context(), "SELECT "+atividadeSelectCols+" FROM crm.atividades WHERE id=$1 AND tenant_id=$2", id, user.TenantID)
	a, err := scanAtividade(row)
	if err != nil {
		jsonErr(w, "Atividade não encontrada.", http.StatusNotFound)
		return
	}
	jsonOK(w, a, http.StatusOK)
}

func (h *Handler) ActualizarAtividade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body atividadeInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Titulo = strings.TrimSpace(body.Titulo)
	if body.Titulo == "" {
		jsonErr(w, "O título é obrigatório.", http.StatusUnprocessableEntity)
		return
	}

	var tipo *string
	if body.Tipo != nil {
		t := strings.TrimSpace(*body.Tipo)
		if !atividadeTipos[t] {
			jsonErr(w, "Tipo inválido.", http.StatusUnprocessableEntity)
			return
		}
		tipo = &t
	}

	var dataAtividade *time.Time
	if body.DataAtividade != nil && strings.TrimSpace(*body.DataAtividade) != "" {
		t, err := parseDataAtividade(strings.TrimSpace(*body.DataAtividade))
		if err != nil {
			jsonErr(w, "Formato de data inválido.", http.StatusUnprocessableEntity)
			return
		}
		dataAtividade = &t
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE crm.atividades SET
			titulo=$1,
			tipo=COALESCE($2, tipo),
			descricao=COALESCE($3, descricao),
			data_atividade=COALESCE($4, data_atividade),
			responsavel=COALESCE($5, responsavel),
			updated_at=NOW()
		WHERE id=$6 AND tenant_id=$7`,
		body.Titulo, tipo, body.Descricao, dataAtividade, body.Responsavel, id, user.TenantID,
	)
	if err != nil {
		jsonErr(w, "Erro ao actualizar na base de dados.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Atividade não encontrada.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverAtividade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), "DELETE FROM crm.atividades WHERE id=$1 AND tenant_id=$2", id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao eliminar.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Atividade não encontrada.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ConcluirAtividade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), "UPDATE crm.atividades SET concluida=TRUE, updated_at=NOW() WHERE id=$1 AND tenant_id=$2", id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Atividade não encontrada.", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}
