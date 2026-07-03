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

	where := "m.tenant_id = $1"
	args := []any{user.TenantID}

	if estado != "" {
		args = append(args, estado)
		where += " AND u.estado = $" + strconv.Itoa(len(args))
	}
	if search != "" {
		args = append(args, "%"+search+"%")
		idx := strconv.Itoa(len(args))
		where += " AND (u.nome ILIKE $" + idx + " OR u.email ILIKE $" + idx + ")"
	}

	countArgs := make([]any, len(args))
	copy(countArgs, args)

	args = append(args, limit, offset)
	dataQ := `SELECT u.id, u.nome, u.email, u.telefone, u.estado, u.email_verificado, u.ultimo_login_em, u.created_at, COALESCE(NULLIF(m.escopo, ''), 'erp')
		FROM users u JOIN auth.memberships m ON m.user_id = u.id
		WHERE ` + where + ` ORDER BY u.nome ASC LIMIT $` + strconv.Itoa(len(args)-1) + ` OFFSET $` + strconv.Itoa(len(args))

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
		Escopo          string     `json:"escopo"`
	}
	data := []Row{}
	for rows.Next() {
		var u Row
		if err := rows.Scan(&u.ID, &u.Nome, &u.Email, &u.Telefone,
			&u.Estado, &u.EmailVerificado, &u.UltimoLoginEm, &u.CreatedAt, &u.Escopo); err == nil {
			data = append(data, u)
		}
	}

	var total int
	h.db.QueryRow(r.Context(),
		`SELECT COUNT(*) FROM users u JOIN auth.memberships m ON m.user_id = u.id WHERE `+where,
		countArgs...).Scan(&total)

	jsonOK(w, map[string]any{
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
		Escopo   string  `json:"escopo"`
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

	if body.Escopo == "" {
		body.Escopo = "erp"
	}
	if body.Escopo != "erp" && body.Escopo != "escola" {
		jsonErr(w, "escopo inválido: erp ou escola", http.StatusBadRequest)
		return
	}

	var created struct {
		ID        int64     `json:"id"`
		Nome      string    `json:"nome"`
		Email     string    `json:"email"`
		Telefone  *string   `json:"telefone"`
		Estado    string    `json:"estado"`
		Escopo    string    `json:"escopo"`
		CreatedAt time.Time `json:"created_at"`
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	err = tx.QueryRow(r.Context(), `
		INSERT INTO users (nome, email, password_hash, telefone, estado)
		VALUES ($1, LOWER($2), $3, $4, 'pendente')
		RETURNING id, nome, email, telefone, estado, created_at`,
		body.Nome, body.Email, string(hash), body.Telefone,
	).Scan(&created.ID, &created.Nome, &created.Email, &created.Telefone, &created.Estado, &created.CreatedAt)

	if err != nil {
		if isPgUniqueViolation(err) {
			jsonErr(w, "Email já está em uso", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	_, err = tx.Exec(r.Context(), `
		INSERT INTO auth.memberships (user_id, tenant_id, escopo) VALUES ($1, $2, $3)`,
		created.ID, user.TenantID, body.Escopo)
	if err != nil {
		jsonErr(w, "Erro interno ao associar tenant", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	created.Escopo = body.Escopo
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
		Escopo          string     `json:"escopo"`
		EmailVerificado bool       `json:"email_verificado"`
		CargoID         *int64     `json:"cargo_id"`
		CargoNome       *string    `json:"cargo_nome"`
		UltimoLoginEm   *time.Time `json:"ultimo_login_em"`
		CreatedAt       time.Time  `json:"created_at"`
		UpdatedAt       time.Time  `json:"updated_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT u.id, u.nome, u.email, u.telefone, u.estado, u.tipo, COALESCE(NULLIF(m.escopo, ''), 'erp'), u.email_verificado,
		       m.cargo_id, c.nome, u.ultimo_login_em, u.created_at, u.updated_at
		  FROM users u
		  JOIN auth.memberships m ON m.user_id = u.id AND m.tenant_id = $2
		  LEFT JOIN cargos c ON c.id = m.cargo_id
		 WHERE u.id = $1`, id, user.TenantID).
		Scan(&u.ID, &u.Nome, &u.Email, &u.Telefone, &u.Estado, &u.Tipo, &u.Escopo,
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
		Escopo   *string `json:"escopo"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	if body.Escopo != nil && *body.Escopo != "erp" && *body.Escopo != "escola" {
		jsonErr(w, "escopo inválido: erp ou escola", http.StatusBadRequest)
		return
	}

	var u struct {
		ID        int64     `json:"id"`
		Nome      string    `json:"nome"`
		Email     string    `json:"email"`
		Telefone  *string   `json:"telefone"`
		Estado    string    `json:"estado"`
		Escopo    string    `json:"escopo"`
		UpdatedAt time.Time `json:"updated_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		UPDATE auth.memberships SET
		  escopo = COALESCE($1, escopo),
		  updated_at = NOW()
		WHERE user_id = $2 AND tenant_id = $3
		RETURNING escopo`,
		body.Escopo, id, user.TenantID).
		Scan(&u.Escopo)

	if err != nil {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}

	err = h.db.QueryRow(r.Context(), `
		UPDATE users SET
		  nome = COALESCE($1, nome),
		  telefone = COALESCE($2, telefone),
		  updated_at = NOW()
		WHERE id = $3
		RETURNING id, nome, email, telefone, estado, updated_at`,
		body.Nome, body.Telefone, id).
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
			 WHERE id = $2 AND EXISTS(
			   SELECT 1 FROM auth.memberships WHERE user_id = $2 AND tenant_id = $3
			 )
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
		UPDATE users SET tipo=$1, permissoes_atualizadas_em=NOW(), updated_at=NOW() WHERE id=$2`,
		body.Tipo, id)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}
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
		UPDATE users SET password_hash=$1, updated_at=NOW() WHERE id=$2`,
		string(hash), id)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
