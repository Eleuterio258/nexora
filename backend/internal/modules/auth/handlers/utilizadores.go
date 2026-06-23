package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
)

func (h *Handler) ListarUtilizadores(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	estado := q.Get("estado")
	search := q.Get("search")
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 {
		page = 1
	}
	limit, _ := strconv.Atoi(q.Get("limit"))
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	where := "tenant_id = $1"
	args := []interface{}{user.TenantID}

	if estado != "" {
		args = append(args, estado)
		where += " AND estado = $" + strconv.Itoa(len(args))
	}
	if search != "" {
		args = append(args, "%"+search+"%")
		idx := strconv.Itoa(len(args))
		where += " AND (nome ILIKE $" + idx + " OR email ILIKE $" + idx + ")"
	}

	countArgs := make([]interface{}, len(args))
	copy(countArgs, args)

	args = append(args, limit, offset)
	dataQ := "SELECT id, nome, email, telefone, estado, email_verificado, ultimo_login_em, created_at FROM users WHERE " +
		where + " ORDER BY nome ASC LIMIT $" + strconv.Itoa(len(args)-1) + " OFFSET $" + strconv.Itoa(len(args))

	rows, err := h.db.Query(r.Context(), dataQ, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID              int64      `json:"id"`
		Nome            string     `json:"nome"`
		Email           string     `json:"email"`
		Telefone        *string    `json:"telefone"`
		Estado          string     `json:"estado"`
		EmailVerificado bool       `json:"email_verificado"`
		UltimoLoginEm   *time.Time `json:"ultimo_login_em"`
		CreatedAt       time.Time  `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var u Row
		if err := rows.Scan(&u.ID, &u.Nome, &u.Email, &u.Telefone,
			&u.Estado, &u.EmailVerificado, &u.UltimoLoginEm, &u.CreatedAt); err == nil {
			data = append(data, u)
		}
	}

	var total int
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM users WHERE "+where, countArgs...).Scan(&total)

	jsonOK(w, map[string]interface{}{
		"data": data,
		"meta": map[string]int{"total": total, "page": page, "limit": limit},
	}, http.StatusOK)
}

func (h *Handler) CriarUtilizador(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Nome     string  `json:"nome"`
		Email    string  `json:"email"`
		Password string  `json:"password"`
		Telefone *string `json:"telefone"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nome == "" || body.Email == "" || body.Password == "" {
		jsonErr(w, "nome, email e password são obrigatórios", http.StatusBadRequest)
		return
	}
	if len(body.Password) < 8 {
		jsonErr(w, "Password deve ter pelo menos 8 caracteres", http.StatusBadRequest)
		return
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte(body.Password), 12)

	var created struct {
		ID        int64     `json:"id"`
		Nome      string    `json:"nome"`
		Email     string    `json:"email"`
		Telefone  *string   `json:"telefone"`
		Estado    string    `json:"estado"`
		CreatedAt time.Time `json:"created_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO users (tenant_id, nome, email, password_hash, telefone, estado)
		VALUES ($1, $2, LOWER($3), $4, $5, 'pendente')
		RETURNING id, nome, email, telefone, estado, created_at`,
		user.TenantID, body.Nome, body.Email, string(hash), body.Telefone,
	).Scan(&created.ID, &created.Nome, &created.Email, &created.Telefone, &created.Estado, &created.CreatedAt)

	if err != nil {
		if isPgUniqueViolation(err) {
			jsonErr(w, "Email já está em uso", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, created, http.StatusCreated)
}

func (h *Handler) ObterUtilizador(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var u struct {
		ID              int64      `json:"id"`
		Nome            string     `json:"nome"`
		Email           string     `json:"email"`
		Telefone        *string    `json:"telefone"`
		Estado          string     `json:"estado"`
		Tipo            string     `json:"tipo"`
		EmailVerificado bool       `json:"email_verificado"`
		CargoID         *int64     `json:"cargo_id"`
		CargoNome       *string    `json:"cargo_nome"`
		UltimoLoginEm   *time.Time `json:"ultimo_login_em"`
		CreatedAt       time.Time  `json:"created_at"`
		UpdatedAt       time.Time  `json:"updated_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT u.id, u.nome, u.email, u.telefone, u.estado, u.tipo, u.email_verificado,
		       u.cargo_id, c.nome, u.ultimo_login_em, u.created_at, u.updated_at
		  FROM users u
		  LEFT JOIN cargos c ON c.id = u.cargo_id
		 WHERE u.id = $1 AND u.tenant_id = $2`, id, user.TenantID).
		Scan(&u.ID, &u.Nome, &u.Email, &u.Telefone, &u.Estado, &u.Tipo,
			&u.EmailVerificado, &u.CargoID, &u.CargoNome, &u.UltimoLoginEm, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, u, http.StatusOK)
}

func (h *Handler) ActualizarUtilizador(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Nome     *string `json:"nome"`
		Telefone *string `json:"telefone"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	var u struct {
		ID        int64     `json:"id"`
		Nome      string    `json:"nome"`
		Email     string    `json:"email"`
		Telefone  *string   `json:"telefone"`
		Estado    string    `json:"estado"`
		UpdatedAt time.Time `json:"updated_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		UPDATE users SET
		  nome = COALESCE($1, nome),
		  telefone = COALESCE($2, telefone),
		  updated_at = NOW()
		WHERE id = $3 AND tenant_id = $4
		RETURNING id, nome, email, telefone, estado, updated_at`,
		body.Nome, body.Telefone, id, user.TenantID).
		Scan(&u.ID, &u.Nome, &u.Email, &u.Telefone, &u.Estado, &u.UpdatedAt)
	if err != nil {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, u, http.StatusOK)
}

func (h *Handler) mudarEstado(estado string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user := mw.GetUser(r)
		id := chi.URLParam(r, "id")

		var u struct {
			ID     int64  `json:"id"`
			Nome   string `json:"nome"`
			Estado string `json:"estado"`
		}
		err := h.db.QueryRow(r.Context(), `
			UPDATE users SET estado = $1, updated_at = NOW()
			 WHERE id = $2 AND tenant_id = $3
			 RETURNING id, nome, estado`,
			estado, id, user.TenantID).Scan(&u.ID, &u.Nome, &u.Estado)
		if err != nil {
			jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
			return
		}
		if estado == "bloqueado" {
			h.db.Exec(r.Context(), `UPDATE sessions SET ativa = FALSE, encerrado_em = NOW() WHERE user_id = $1`, id)
		}
		jsonOK(w, u, http.StatusOK)
	}
}

func (h *Handler) ActivarUtilizador(w http.ResponseWriter, r *http.Request) {
	h.mudarEstado("ativo")(w, r)
}

func (h *Handler) BloquearUtilizador(w http.ResponseWriter, r *http.Request) {
	h.mudarEstado("bloqueado")(w, r)
}

func (h *Handler) DesactivarUtilizador(w http.ResponseWriter, r *http.Request) {
	h.mudarEstado("inativo")(w, r)
}

// AlterarTipo muda o tipo do utilizador (funcionario/superadmin). Apenas superadmins.
func (h *Handler) AlterarTipo(w http.ResponseWriter, r *http.Request) {
	caller := mw.GetUser(r)
	if caller.Tipo != "superadmin" {
		jsonErr(w, "Apenas superadmins podem alterar o tipo de utilizador", http.StatusForbidden)
		return
	}
	id := chi.URLParam(r, "id")

	var body struct {
		Tipo string `json:"tipo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Body inválido", http.StatusBadRequest)
		return
	}
	if body.Tipo != "funcionario" && body.Tipo != "superadmin" {
		jsonErr(w, "tipo inválido: funcionario ou superadmin", http.StatusBadRequest)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE users SET tipo=$1, updated_at=NOW() WHERE id=$2 AND tenant_id=$3`,
		body.Tipo, id, caller.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}
	// Revogar sessões activas para forçar re-login com o novo tipo
	h.db.Exec(r.Context(), `UPDATE sessions SET ativa=FALSE, encerrado_em=NOW() WHERE user_id=$1`, id)
	w.WriteHeader(http.StatusNoContent)
}

// ResetPasswordAdmin define uma nova senha para o utilizador sem exigir a senha actual. Apenas superadmins.
func (h *Handler) ResetPasswordAdmin(w http.ResponseWriter, r *http.Request) {
	caller := mw.GetUser(r)
	if caller.Tipo != "superadmin" {
		jsonErr(w, "Apenas superadmins podem redefinir senhas", http.StatusForbidden)
		return
	}
	id := chi.URLParam(r, "id")

	var body struct {
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || len(body.Password) < 8 {
		jsonErr(w, "A senha deve ter pelo menos 8 caracteres", http.StatusBadRequest)
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(body.Password), 12)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE users SET password_hash=$1, updated_at=NOW() WHERE id=$2 AND tenant_id=$3`,
		string(hash), id, caller.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
