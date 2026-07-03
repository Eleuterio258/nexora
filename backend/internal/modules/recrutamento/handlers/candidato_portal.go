package handlers

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
)

// ── GET /api/public/recrutamento/candidatos/perfil ───────────────────────────

func (h *Handler) MeuPerfil(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)

	var perfil struct {
		ID              int64     `json:"id"`
		Nome            string    `json:"nome"`
		Email           string    `json:"email"`
		Telefone        *string   `json:"telefone"`
		EmailVerificado bool      `json:"email_verificado"`
		CreatedAt       time.Time `json:"criado_em"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, nome, email, telefone, email_verificado, created_at
		  FROM recrutamento.candidatos
		 WHERE id=$1 AND tenant_id=$2`,
		c.ID, c.TenantID).Scan(
		&perfil.ID, &perfil.Nome, &perfil.Email, &perfil.Telefone,
		&perfil.EmailVerificado, &perfil.CreatedAt)
	if err != nil {
		jsonErr(w, "Perfil não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, perfil, http.StatusOK)
}

// ── PUT /api/public/recrutamento/candidatos/perfil ───────────────────────────

func (h *Handler) ActualizarMeuPerfil(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)

	var body struct {
		Nome            *string `json:"nome"`
		Telefone        *string `json:"telefone"`
		PasswordAtual   *string `json:"password_atual"`
		PasswordNova    *string `json:"password_nova"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}

	// Validar nome se fornecido
	if body.Nome != nil && len([]rune(strings.TrimSpace(*body.Nome))) < 2 {
		jsonErr(w, "Nome inválido", http.StatusUnprocessableEntity)
		return
	}

	// Mudança de password: requer password actual
	if body.PasswordNova != nil {
		if body.PasswordAtual == nil || strings.TrimSpace(*body.PasswordAtual) == "" {
			jsonErr(w, "A palavra-passe actual é obrigatória para alterar a palavra-passe", http.StatusUnprocessableEntity)
			return
		}
		if len(*body.PasswordNova) < 6 {
			jsonErr(w, "A nova palavra-passe deve ter pelo menos 6 caracteres", http.StatusUnprocessableEntity)
			return
		}

		var currentHash string
		if err := h.db.QueryRow(r.Context(),
			`SELECT password_hash FROM recrutamento.candidatos WHERE id=$1`,
			c.ID).Scan(&currentHash); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		if err := bcrypt.CompareHashAndPassword([]byte(currentHash), []byte(*body.PasswordAtual)); err != nil {
			jsonErr(w, "Palavra-passe actual incorrecta", http.StatusUnprocessableEntity)
			return
		}

		newHash, err := bcrypt.GenerateFromPassword([]byte(*body.PasswordNova), bcrypt.DefaultCost)
		if err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		newHashStr := string(newHash)

		if body.Nome != nil {
			nomeLimpo := clean(*body.Nome, 150)
			_, err = h.db.Exec(r.Context(), `
				UPDATE recrutamento.candidatos
				   SET nome=$1, telefone=COALESCE($2,telefone), password_hash=$3, updated_at=NOW()
				 WHERE id=$4`,
				nomeLimpo, body.Telefone, newHashStr, c.ID)
		} else {
			_, err = h.db.Exec(r.Context(), `
				UPDATE recrutamento.candidatos
				   SET telefone=COALESCE($1,telefone), password_hash=$2, updated_at=NOW()
				 WHERE id=$3`,
				body.Telefone, newHashStr, c.ID)
		}
		if err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)
		return
	}

	// Sem mudança de password
	if body.Nome == nil && body.Telefone == nil {
		jsonErr(w, "Nenhum campo para actualizar", http.StatusBadRequest)
		return
	}

	var err error
	if body.Nome != nil {
		nomeLimpo := clean(*body.Nome, 150)
		_, err = h.db.Exec(r.Context(), `
			UPDATE recrutamento.candidatos
			   SET nome=$1, telefone=COALESCE($2,telefone), updated_at=NOW()
			 WHERE id=$3`,
			nomeLimpo, body.Telefone, c.ID)
	} else {
		_, err = h.db.Exec(r.Context(), `
			UPDATE recrutamento.candidatos
			   SET telefone=$1, updated_at=NOW()
			 WHERE id=$2`,
			body.Telefone, c.ID)
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── GET /api/public/recrutamento/candidatos/candidaturas ─────────────────────

type candidaturaPublica struct {
	ID                  int64      `json:"id"`
	VagaID              *int64     `json:"vaga_id"`
	VagaTitulo          string     `json:"vaga_titulo"`
	Estado              string     `json:"estado"`
	EstadoLabel         string     `json:"estado_label"`
	CodigoAcompanhamento *string   `json:"codigo_acompanhamento"`
	EntrevistaData      *time.Time `json:"entrevista_data"`
	EntrevistaLocal     *string    `json:"entrevista_local"`
	EntrevistaLink      *string    `json:"entrevista_link"`
	CriadoEm           time.Time  `json:"criado_em"`
	ActualizadoEm      time.Time  `json:"actualizado_em"`
}

func (h *Handler) MinhasCandidaturas(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT id, vaga_id, vaga_titulo, estado, codigo_acompanhamento,
		       entrevista_data, entrevista_local, entrevista_link,
		       created_at, updated_at
		  FROM recrutamento.candidaturas
		 WHERE candidato_id=$1 AND tenant_id=$2
		 ORDER BY created_at DESC`,
		c.ID, c.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []candidaturaPublica{}
	for rows.Next() {
		var ca candidaturaPublica
		if err := rows.Scan(
			&ca.ID, &ca.VagaID, &ca.VagaTitulo, &ca.Estado, &ca.CodigoAcompanhamento,
			&ca.EntrevistaData, &ca.EntrevistaLocal, &ca.EntrevistaLink,
			&ca.CriadoEm, &ca.ActualizadoEm,
		); err == nil {
			ca.EstadoLabel = estadoLabels[ca.Estado]
			data = append(data, ca)
		}
	}
	jsonOK(w, data, http.StatusOK)
}
