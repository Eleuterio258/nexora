package handlers

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func hashToken(t string) string {
	return fmt.Sprintf("%x", sha256.Sum256([]byte(t)))
}

func (h *Handler) ListarTokens(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	rows, err := h.db.Query(r.Context(), `
		SELECT id, tipo, expira_em, revogado_em, created_at
		  FROM user_tokens WHERE user_id = $1 AND revogado_em IS NULL
		  ORDER BY created_at DESC`, userID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID         int64      `json:"id"`
		Tipo       string     `json:"tipo"`
		ExpiraEm   *time.Time `json:"expira_em"`
		RevogadoEm *time.Time `json:"revogado_em"`
		CreatedAt  time.Time  `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var x Row
		if rows.Scan(&x.ID, &x.Tipo, &x.ExpiraEm, &x.RevogadoEm, &x.CreatedAt) == nil {
			data = append(data, x)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarToken(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	var body struct {
		Tipo     string     `json:"tipo"`
		ExpiraEm *time.Time `json:"expira_em"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Tipo == "" {
		jsonErr(w, "tipo é obrigatório", http.StatusBadRequest)
		return
	}
	b := make([]byte, 32)
	rand.Read(b)
	rawToken := hex.EncodeToString(b)

	var id int64
	h.db.QueryRow(r.Context(), `
		INSERT INTO user_tokens (user_id, tipo, token_hash, expira_em)
		VALUES ($1, $2, $3, $4) RETURNING id`,
		userID, body.Tipo, hashToken(rawToken), body.ExpiraEm).Scan(&id)

	jsonOK(w, map[string]any{"id": id, "token": rawToken}, http.StatusCreated)
}

func (h *Handler) RevogarToken(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	tokenID := chi.URLParam(r, "tokenId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	tag, _ := h.db.Exec(r.Context(), `
		UPDATE user_tokens SET revogado_em = NOW() WHERE id = $1 AND user_id = $2`, tokenID, userID)
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Token não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
