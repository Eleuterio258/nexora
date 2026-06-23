package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) ObterPerfil(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID && caller.Tipo != "superadmin" {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}

	var p struct {
		ID             int64      `json:"id"`
		UserID         int64      `json:"user_id"`
		PrimeiroNome   *string    `json:"primeiro_nome"`
		UltimoNome     *string    `json:"ultimo_nome"`
		NomeExibicao   *string    `json:"nome_exibicao"`
		DataNascimento *time.Time `json:"data_nascimento"`
		Genero         *string    `json:"genero"`
		Idioma         string     `json:"idioma"`
		Timezone       string     `json:"timezone"`
		Bio            *string    `json:"bio"`
		CreatedAt      time.Time  `json:"created_at"`
		UpdatedAt      time.Time  `json:"updated_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, user_id, primeiro_nome, ultimo_nome, nome_exibicao,
		       data_nascimento, genero, idioma, timezone, bio, created_at, updated_at
		  FROM profiles WHERE user_id = $1`, userID).
		Scan(&p.ID, &p.UserID, &p.PrimeiroNome, &p.UltimoNome, &p.NomeExibicao,
			&p.DataNascimento, &p.Genero, &p.Idioma, &p.Timezone, &p.Bio,
			&p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		jsonErr(w, "Perfil não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, p, http.StatusOK)
}

func (h *Handler) CriarPerfil(w http.ResponseWriter, r *http.Request) {
	caller := mw.GetUser(r)
	var body struct {
		PrimeiroNome   *string `json:"primeiro_nome"`
		UltimoNome     *string `json:"ultimo_nome"`
		NomeExibicao   *string `json:"nome_exibicao"`
		DataNascimento *string `json:"data_nascimento"`
		Genero         *string `json:"genero"`
		Idioma         *string `json:"idioma"`
		Timezone       *string `json:"timezone"`
		Bio            *string `json:"bio"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	var id int64
	var createdAt time.Time
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO profiles (user_id, primeiro_nome, ultimo_nome, nome_exibicao,
		                      data_nascimento, genero, idioma, timezone, bio)
		VALUES ($1,$2,$3,$4,$5,$6,COALESCE($7,'pt'),COALESCE($8,'Africa/Maputo'),$9)
		RETURNING id, created_at`,
		caller.ID, body.PrimeiroNome, body.UltimoNome, body.NomeExibicao,
		body.DataNascimento, body.Genero, body.Idioma, body.Timezone, body.Bio).
		Scan(&id, &createdAt)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Perfil já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "user_id": caller.ID, "created_at": createdAt}, http.StatusCreated)
}

func (h *Handler) ActualizarPerfil(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID && caller.Tipo != "superadmin" {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}

	var body struct {
		PrimeiroNome   *string `json:"primeiro_nome"`
		UltimoNome     *string `json:"ultimo_nome"`
		NomeExibicao   *string `json:"nome_exibicao"`
		DataNascimento *string `json:"data_nascimento"`
		Genero         *string `json:"genero"`
		Idioma         *string `json:"idioma"`
		Timezone       *string `json:"timezone"`
		Bio            *string `json:"bio"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	tag, err := h.db.Exec(r.Context(), `
		UPDATE profiles SET
		  primeiro_nome   = COALESCE($1, primeiro_nome),
		  ultimo_nome     = COALESCE($2, ultimo_nome),
		  nome_exibicao   = COALESCE($3, nome_exibicao),
		  data_nascimento = COALESCE($4::date, data_nascimento),
		  genero          = COALESCE($5, genero),
		  idioma          = COALESCE($6, idioma),
		  timezone        = COALESCE($7, timezone),
		  bio             = COALESCE($8, bio),
		  updated_at      = NOW()
		WHERE user_id = $9`,
		body.PrimeiroNome, body.UltimoNome, body.NomeExibicao,
		body.DataNascimento, body.Genero, body.Idioma, body.Timezone, body.Bio, userID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Perfil não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
