package handlers

import (
	"net/http"
	"time"

	mw "nexora/internal/middleware"
	"golang.org/x/crypto/bcrypt"
)

// MeuPerfil devolve os dados do perfil do colaborador.
func (h *Handler) MeuPerfil(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	type perfil struct {
		UserID          int64      `json:"user_id"`
		Nome            string     `json:"nome"`
		Email           string     `json:"email"`
		Telefone        *string    `json:"telefone"`
		// Dados do funcionário (se existir)
		FuncionarioID   *int64     `json:"funcionario_id"`
		NomeCompleto    *string    `json:"nome_completo"`
		Cargo           *string    `json:"cargo"`
		Departamento    *string    `json:"departamento"`
		DataAdmissao    *time.Time `json:"data_admissao"`
		TipoContrato    *string    `json:"tipo_contrato"`
		UltimoLoginEm   *time.Time `json:"ultimo_login_em"`
	}

	var p perfil
	p.UserID = user.ID

	// Dados de auth
	h.db.QueryRow(r.Context(), `
		SELECT nome, email, telefone, ultimo_login_em FROM auth.users WHERE id=$1`, user.ID).
		Scan(&p.Nome, &p.Email, &p.Telefone, &p.UltimoLoginEm)

	// Dados do funcionário
	h.db.QueryRow(r.Context(), `
		SELECT f.id, f.nome_completo, f.cargo, u.nome AS departamento,
		       f.data_admissao, f.tipo_contrato
		  FROM rh.funcionarios f
		  LEFT JOIN rh.unidades_organizacionais u ON u.id = f.unit_id
		 WHERE f.user_id=$1 AND f.tenant_id=$2`, user.ID, user.TenantID).
		Scan(&p.FuncionarioID, &p.NomeCompleto, &p.Cargo, &p.Departamento,
			&p.DataAdmissao, &p.TipoContrato)

	jsonOK(w, p, http.StatusOK)
}

// ActualizarPerfil permite ao colaborador actualizar nome, telefone.
func (h *Handler) ActualizarPerfil(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Nome     *string `json:"nome"`
		Telefone *string `json:"telefone"`
	}
	if err := decodeJSON(r, &body); err != nil {
		jsonErr(w, "Body inválido", http.StatusBadRequest)
		return
	}
	h.db.Exec(r.Context(), `
		UPDATE auth.users SET
		  nome=COALESCE($1,nome),
		  telefone=COALESCE($2,telefone),
		  updated_at=NOW()
		WHERE id=$3`, body.Nome, body.Telefone, user.ID)
	w.WriteHeader(http.StatusNoContent)
}

// AlterarSenha permite ao colaborador alterar a sua própria senha.
func (h *Handler) AlterarSenha(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		SenhaActual string `json:"senha_actual"`
		SenhaNova   string `json:"senha_nova"`
	}
	if err := decodeJSON(r, &body); err != nil || body.SenhaActual == "" || len(body.SenhaNova) < 8 {
		jsonErr(w, "A nova senha deve ter pelo menos 8 caracteres", http.StatusBadRequest)
		return
	}

	var hash string
	if err := h.db.QueryRow(r.Context(),
		`SELECT password_hash FROM auth.users WHERE id=$1`, user.ID).Scan(&hash); err != nil {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}
	if bcrypt.CompareHashAndPassword([]byte(hash), []byte(body.SenhaActual)) != nil {
		jsonErr(w, "Senha actual incorrecta", http.StatusUnauthorized)
		return
	}
	novoHash, _ := bcrypt.GenerateFromPassword([]byte(body.SenhaNova), 12)
	h.db.Exec(r.Context(), `UPDATE auth.users SET password_hash=$1, updated_at=NOW() WHERE id=$2`,
		string(novoHash), user.ID)

	// Revogar outras sessões
	h.db.Exec(r.Context(), `UPDATE auth.sessions SET ativa=FALSE, encerrado_em=NOW() WHERE user_id=$1`, user.ID)
	w.WriteHeader(http.StatusNoContent)
}

// MeusDocumentos lista os documentos pessoais do colaborador.
func (h *Handler) MeusDocumentos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcID, ok := h.funcionarioID(r)
	if !ok {
		jsonOK(w, []any{}, http.StatusOK)
		return
	}

	type doc struct {
		ID        int64     `json:"id"`
		Tipo      string    `json:"tipo"`
		Nome      string    `json:"nome"`
		URL       string    `json:"url"`
		CreatedAt time.Time `json:"created_at"`
	}
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, tipo, nome, ficheiro_url, created_at
		  FROM rh.documentos
		 WHERE funcionario_id=$1 AND tenant_id=$2
		 ORDER BY created_at DESC`, funcID, user.TenantID)
	if rows == nil { jsonOK(w, []doc{}, http.StatusOK); return }
	defer rows.Close()
	data := []doc{}
	for rows.Next() {
		var d doc
		if rows.Scan(&d.ID, &d.Tipo, &d.Nome, &d.URL, &d.CreatedAt) == nil {
			data = append(data, d)
		}
	}
	jsonOK(w, data, http.StatusOK)
}
