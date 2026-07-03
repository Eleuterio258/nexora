package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

type listaInput struct {
	Titulo   string `json:"titulo"`
	QuadroID int64  `json:"quadro_id"`
	Posicao  *int   `json:"posicao"`
}

type reordenarInput struct {
	Itens []struct {
		ID      int64 `json:"id"`
		Posicao int   `json:"posicao"`
	} `json:"itens"`
}

func (h *Handler) CriarLista(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	quadroID := chi.URLParam(r, "id")

	var body listaInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Titulo = strings.TrimSpace(body.Titulo)
	if body.Titulo == "" {
		jsonErr(w, "O título é obrigatório.", http.StatusUnprocessableEntity)
		return
	}

	// Verificar que o quadro pertence ao tenant
	var exists bool
	h.db.QueryRow(r.Context(),
		`SELECT EXISTS(SELECT 1 FROM tarefas.quadros WHERE id=$1 AND tenant_id=$2)`,
		quadroID, user.TenantID,
	).Scan(&exists)
	if !exists {
		jsonErr(w, "Quadro não encontrado.", http.StatusNotFound)
		return
	}

	// Posição = última + 1
	var maxPos int
	h.db.QueryRow(r.Context(),
		`SELECT COALESCE(MAX(posicao),0)+1 FROM tarefas.listas WHERE quadro_id=$1`, quadroID,
	).Scan(&maxPos)

	var id int64
	err := h.db.QueryRow(r.Context(),
		`INSERT INTO tarefas.listas(tenant_id,quadro_id,titulo,posicao)
		 VALUES ($1,$2,$3,$4) RETURNING id`,
		user.TenantID, quadroID, body.Titulo, maxPos,
	).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro ao guardar.", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "posicao": maxPos}, http.StatusCreated)
}

func (h *Handler) ActualizarLista(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body listaInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Titulo = strings.TrimSpace(body.Titulo)
	if body.Titulo == "" {
		jsonErr(w, "O título é obrigatório.", http.StatusUnprocessableEntity)
		return
	}

	tag, err := h.db.Exec(r.Context(),
		`UPDATE tarefas.listas SET titulo=$1,updated_at=NOW()
		 WHERE id=$2 AND tenant_id=$3`,
		body.Titulo, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Lista não encontrada.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) EliminarLista(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(),
		`DELETE FROM tarefas.listas WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao eliminar.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Lista não encontrada.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ReordenarListas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body reordenarInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	for _, item := range body.Itens {
		tx.Exec(r.Context(),
			`UPDATE tarefas.listas SET posicao=$1,updated_at=NOW() WHERE id=$2 AND tenant_id=$3`,
			item.Posicao, item.ID, user.TenantID)
	}
	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro ao reordenar.", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}
