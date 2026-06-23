package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

func (h *Handler) ListarAPIKeys(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT id, nome, key_prefix, ativa, ultimo_uso_em, expira_em, created_at
		  FROM api_keys
		 WHERE tenant_id = $1
		 ORDER BY created_at DESC`, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID          int64      `json:"id"`
		Nome        string     `json:"nome"`
		KeyPrefix   string     `json:"key_prefix"`
		Ativa       bool       `json:"ativa"`
		UltimoUsoEm *time.Time `json:"ultimo_uso_em"`
		ExpiraEm    *time.Time `json:"expira_em"`
		CreatedAt   time.Time  `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var k Row
		if err := rows.Scan(&k.ID, &k.Nome, &k.KeyPrefix, &k.Ativa, &k.UltimoUsoEm, &k.ExpiraEm, &k.CreatedAt); err == nil {
			data = append(data, k)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarAPIKey(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Nome     string     `json:"nome"`
		ExpiraEm *time.Time `json:"expira_em"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nome == "" {
		jsonErr(w, "nome é obrigatório", http.StatusBadRequest)
		return
	}

	b := make([]byte, 32)
	rand.Read(b)
	rawKey := "nxk_" + hex.EncodeToString(b)
	prefix := rawKey[:12]
	keyHash := mw.HashToken(rawKey)

	var id int64
	var createdAt time.Time
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO api_keys (tenant_id, user_id, nome, key_prefix, key_hash, expira_em)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at`,
		user.TenantID, user.ID, body.Nome, prefix, keyHash, body.ExpiraEm,
	).Scan(&id, &createdAt)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]interface{}{
		"id":         id,
		"nome":       body.Nome,
		"key":        rawKey,
		"key_prefix": prefix,
		"expira_em":  body.ExpiraEm,
		"created_at": createdAt,
	}, http.StatusCreated)
}

func (h *Handler) ObterAPIKey(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var k struct {
		ID          int64      `json:"id"`
		Nome        string     `json:"nome"`
		KeyPrefix   string     `json:"key_prefix"`
		Ativa       bool       `json:"ativa"`
		UltimoUsoEm *time.Time `json:"ultimo_uso_em"`
		ExpiraEm    *time.Time `json:"expira_em"`
		CreatedAt   time.Time  `json:"created_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, nome, key_prefix, ativa, ultimo_uso_em, expira_em, created_at
		  FROM api_keys WHERE id = $1 AND tenant_id = $2`, id, user.TenantID).
		Scan(&k.ID, &k.Nome, &k.KeyPrefix, &k.Ativa, &k.UltimoUsoEm, &k.ExpiraEm, &k.CreatedAt)
	if err != nil {
		jsonErr(w, "API Key não encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, k, http.StatusOK)
}

func (h *Handler) ActualizarAPIKey(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Nome     *string    `json:"nome"`
		ExpiraEm *time.Time `json:"expira_em"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	var k struct {
		ID        int64      `json:"id"`
		Nome      string     `json:"nome"`
		KeyPrefix string     `json:"key_prefix"`
		Ativa     bool       `json:"ativa"`
		ExpiraEm  *time.Time `json:"expira_em"`
	}
	err := h.db.QueryRow(r.Context(), `
		UPDATE api_keys SET
		  nome = COALESCE($1, nome),
		  expira_em = COALESCE($2, expira_em)
		WHERE id = $3 AND tenant_id = $4
		RETURNING id, nome, key_prefix, ativa, expira_em`,
		body.Nome, body.ExpiraEm, id, user.TenantID).
		Scan(&k.ID, &k.Nome, &k.KeyPrefix, &k.Ativa, &k.ExpiraEm)
	if err != nil {
		jsonErr(w, "API Key não encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, k, http.StatusOK)
}

func (h *Handler) RevogarAPIKey(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), `
		UPDATE api_keys SET ativa = FALSE WHERE id = $1 AND tenant_id = $2`, id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "API Key não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
