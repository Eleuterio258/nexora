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

type Cartao struct {
	ID          int64     `json:"id"`
	ListaID     int64     `json:"lista_id"`
	Titulo      string    `json:"titulo"`
	Descricao   *string   `json:"descricao"`
	Posicao     int       `json:"posicao"`
	DataInicio  *string   `json:"data_inicio"`
	DataFim     *string   `json:"data_fim"`
	Prioridade  string    `json:"prioridade"`
	Responsaveis []int64  `json:"responsaveis"`
	Concluido   bool      `json:"concluido"`
	Arquivado   bool      `json:"arquivado"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type cartaoInput struct {
	Titulo       string  `json:"titulo"`
	Descricao    *string `json:"descricao"`
	DataInicio   *string `json:"data_inicio"`
	DataFim      *string `json:"data_fim"`
	Prioridade   string  `json:"prioridade"`
}

type moverInput struct {
	ListaID int64 `json:"lista_id"`
	Posicao int   `json:"posicao"`
}

func (h *Handler) CriarCartao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	listaID := chi.URLParam(r, "id")

	var body cartaoInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Titulo = strings.TrimSpace(body.Titulo)
	if body.Titulo == "" {
		jsonErr(w, "O título é obrigatório.", http.StatusUnprocessableEntity)
		return
	}

	// Verificar que a lista pertence ao tenant
	var exists bool
	h.db.QueryRow(r.Context(),
		`SELECT EXISTS(SELECT 1 FROM tarefas.listas WHERE id=$1 AND tenant_id=$2)`,
		listaID, user.TenantID,
	).Scan(&exists)
	if !exists {
		jsonErr(w, "Lista não encontrada.", http.StatusNotFound)
		return
	}

	// Posição = último + 1
	var maxPos int
	h.db.QueryRow(r.Context(),
		`SELECT COALESCE(MAX(posicao),0)+1 FROM tarefas.cartoes WHERE lista_id=$1`, listaID,
	).Scan(&maxPos)

	prioridade := "media"
	if p := body.Prioridade; p == "baixa" || p == "media" || p == "alta" || p == "urgente" {
		prioridade = p
	}

	var id int64
	err := h.db.QueryRow(r.Context(),
		`INSERT INTO tarefas.cartoes(tenant_id,lista_id,titulo,descricao,posicao,data_inicio,data_fim,prioridade)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
		user.TenantID, listaID, body.Titulo, body.Descricao, maxPos,
		nilIfEmpty(body.DataInicio), nilIfEmpty(body.DataFim), prioridade,
	).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro ao guardar.", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "posicao": maxPos}, http.StatusCreated)
}

func nilIfEmpty(s *string) *string {
	if s == nil || *s == "" {
		return nil
	}
	return s
}

func (h *Handler) ObterCartao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var c Cartao
	err := h.db.QueryRow(r.Context(),
		`SELECT id,lista_id,titulo,descricao,posicao,
		        to_char(data_inicio,'YYYY-MM-DD'),to_char(data_fim,'YYYY-MM-DD'),
		        prioridade,responsaveis,concluido,arquivado,created_at,updated_at
		 FROM tarefas.cartoes WHERE id=$1 AND tenant_id=$2`, id, user.TenantID,
	).Scan(&c.ID, &c.ListaID, &c.Titulo, &c.Descricao, &c.Posicao,
		&c.DataInicio, &c.DataFim, &c.Prioridade, &c.Responsaveis,
		&c.Concluido, &c.Arquivado, &c.CreatedAt, &c.UpdatedAt)
	if err == pgx.ErrNoRows {
		jsonErr(w, "Cartão não encontrado.", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	}
	jsonOK(w, c, http.StatusOK)
}

func (h *Handler) ActualizarCartao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body cartaoInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Titulo = strings.TrimSpace(body.Titulo)
	if body.Titulo == "" {
		jsonErr(w, "O título é obrigatório.", http.StatusUnprocessableEntity)
		return
	}
	prioridade := "media"
	if p := body.Prioridade; p == "baixa" || p == "media" || p == "alta" || p == "urgente" {
		prioridade = p
	}

	tag, err := h.db.Exec(r.Context(),
		`UPDATE tarefas.cartoes
		 SET titulo=$1,descricao=$2,data_inicio=$3,data_fim=$4,prioridade=$5,updated_at=NOW()
		 WHERE id=$6 AND tenant_id=$7`,
		body.Titulo, body.Descricao,
		nilIfEmpty(body.DataInicio), nilIfEmpty(body.DataFim),
		prioridade, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Cartão não encontrado.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) MoverCartao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body moverInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}

	// Verificar que a lista de destino pertence ao tenant
	var exists bool
	h.db.QueryRow(r.Context(),
		`SELECT EXISTS(SELECT 1 FROM tarefas.listas WHERE id=$1 AND tenant_id=$2)`,
		body.ListaID, user.TenantID,
	).Scan(&exists)
	if !exists {
		jsonErr(w, "Lista de destino não encontrada.", http.StatusNotFound)
		return
	}

	tag, err := h.db.Exec(r.Context(),
		`UPDATE tarefas.cartoes SET lista_id=$1,posicao=$2,updated_at=NOW()
		 WHERE id=$3 AND tenant_id=$4`,
		body.ListaID, body.Posicao, id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Cartão não encontrado.", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

func (h *Handler) EliminarCartao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(),
		`DELETE FROM tarefas.cartoes WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Cartão não encontrado.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ConcluirCartao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	// toggle: se concluido=false, passa a true; se já true, mantém
	tag, err := h.db.Exec(r.Context(),
		`UPDATE tarefas.cartoes SET concluido=NOT concluido,updated_at=NOW()
		 WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Cartão não encontrado.", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}
