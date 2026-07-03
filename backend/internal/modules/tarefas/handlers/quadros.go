package handlers

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

type Quadro struct {
	ID        int64     `json:"id"`
	TenantID  int64     `json:"tenant_id"`
	Titulo    string    `json:"titulo"`
	Descricao *string   `json:"descricao"`
	Cor       string    `json:"cor"`
	Arquivado bool      `json:"arquivado"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type quadroInput struct {
	Titulo    string  `json:"titulo"`
	Descricao *string `json:"descricao"`
	Cor       *string `json:"cor"`
}

func (h *Handler) ListarQuadros(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	arquivado := r.URL.Query().Get("arquivado") == "1"

	rows, err := h.db.Query(r.Context(),
		`SELECT id, titulo, descricao, cor, arquivado, created_at, updated_at,
		        (SELECT COUNT(*) FROM tarefas.cartoes c
		         JOIN tarefas.listas l ON l.id=c.lista_id
		         WHERE l.quadro_id=q.id AND NOT c.arquivado) total_cartoes
		 FROM tarefas.quadros q
		 WHERE tenant_id=$1 AND arquivado=$2
		 ORDER BY updated_at DESC`, user.TenantID, arquivado)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type quadroItem struct {
		Quadro
		TotalCartoes int `json:"total_cartoes"`
	}
	data := []quadroItem{}
	for rows.Next() {
		var q quadroItem
		if err := rows.Scan(&q.ID, &q.Titulo, &q.Descricao, &q.Cor, &q.Arquivado,
			&q.CreatedAt, &q.UpdatedAt, &q.TotalCartoes); err == nil {
			data = append(data, q)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarQuadro(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body quadroInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Titulo = strings.TrimSpace(body.Titulo)
	if body.Titulo == "" {
		jsonErr(w, "O título é obrigatório.", http.StatusUnprocessableEntity)
		return
	}
	cor := "#F59E0B"
	if body.Cor != nil && *body.Cor != "" {
		cor = *body.Cor
	}

	var id int64
	err := h.db.QueryRow(r.Context(),
		`INSERT INTO tarefas.quadros(tenant_id, titulo, descricao, cor)
		 VALUES ($1,$2,$3,$4) RETURNING id`,
		user.TenantID, body.Titulo, body.Descricao, cor,
	).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro ao guardar.", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterQuadro(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var q Quadro
	err := h.db.QueryRow(r.Context(),
		`SELECT id, tenant_id, titulo, descricao, cor, arquivado, created_at, updated_at
		 FROM tarefas.quadros WHERE id=$1 AND tenant_id=$2`, id, user.TenantID,
	).Scan(&q.ID, &q.TenantID, &q.Titulo, &q.Descricao, &q.Cor, &q.Arquivado, &q.CreatedAt, &q.UpdatedAt)
	if err == pgx.ErrNoRows {
		jsonErr(w, "Quadro não encontrado.", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	}

	// Listas com cartões
	rows, err := h.db.Query(r.Context(),
		`SELECT l.id, l.titulo, l.posicao,
		        COALESCE(jsonb_agg(
		            jsonb_build_object(
		                'id',c.id,'titulo',c.titulo,'descricao',c.descricao,
		                'posicao',c.posicao,'data_fim',c.data_fim,'prioridade',c.prioridade,
		                'concluido',c.concluido,'responsaveis',c.responsaveis
		            ) ORDER BY c.posicao
		        ) FILTER (WHERE c.id IS NOT NULL AND NOT c.arquivado), '[]') cartoes
		 FROM tarefas.listas l
		 LEFT JOIN tarefas.cartoes c ON c.lista_id=l.id
		 WHERE l.quadro_id=$1 AND NOT l.arquivada
		 GROUP BY l.id ORDER BY l.posicao`, q.ID)
	if err != nil {
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type lista struct {
		ID      int64           `json:"id"`
		Titulo  string          `json:"titulo"`
		Posicao int             `json:"posicao"`
		Cartoes json.RawMessage `json:"cartoes"`
	}
	listas := []lista{}
	for rows.Next() {
		var l lista
		if err := rows.Scan(&l.ID, &l.Titulo, &l.Posicao, &l.Cartoes); err == nil {
			listas = append(listas, l)
		}
	}

	jsonOK(w, map[string]any{"quadro": q, "listas": listas}, http.StatusOK)
}

func (h *Handler) ActualizarQuadro(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body quadroInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Titulo = strings.TrimSpace(body.Titulo)
	if body.Titulo == "" {
		jsonErr(w, "O título é obrigatório.", http.StatusUnprocessableEntity)
		return
	}
	cor := "#F59E0B"
	if body.Cor != nil && *body.Cor != "" {
		cor = *body.Cor
	}

	tag, err := h.db.Exec(r.Context(),
		`UPDATE tarefas.quadros SET titulo=$1,descricao=$2,cor=$3,updated_at=NOW()
		 WHERE id=$4 AND tenant_id=$5`,
		body.Titulo, body.Descricao, cor, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Quadro não encontrado.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) EliminarQuadro(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(),
		`DELETE FROM tarefas.quadros WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao eliminar.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Quadro não encontrado.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ArquivarQuadro(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(),
		`UPDATE tarefas.quadros SET arquivado=TRUE,updated_at=NOW() WHERE id=$1 AND tenant_id=$2`,
		id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Quadro não encontrado.", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}
