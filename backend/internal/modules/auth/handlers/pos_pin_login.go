package handlers

import (
	"encoding/json"
	"net/http"

	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/recursos-humanos/service/funcionario"
)

// LoginOperadorPorPIN troca o operador activo de um terminal POS por PIN,
// sem tocar na sessão/token de quem chama (tipicamente o próprio terminal,
// autenticado com o seu token de longa duração — ver issueTerminalTokens em
// pos_login.go). É a peça que faltava para "troca rápida de turno": hoje só
// existe LoginPorPIN (email+PIN, emite tokens novos mas não tem noção de
// "dentro deste terminal/tenant") — aqui não se pede email, só o PIN, e a
// procura fica restrita ao tenant do chamador (nunca a pesquisa global).
//
// PINs são guardados como hash bcrypt (auth.user_auth_codes.secret_hash),
// por isso não são pesquisáveis directamente por valor — à semelhança de
// loginTerminalPOS (pos_login.go), comparam-se por bcrypt contra cada
// candidato do tenant com PIN activo, um a um, até encontrar o dono.
func (h *Handler) LoginOperadorPorPIN(w http.ResponseWriter, r *http.Request) {
	caller := mw.GetUser(r)
	if caller == nil || caller.TenantID == 0 {
		jsonErr(w, "Não autenticado", http.StatusUnauthorized)
		return
	}

	var body struct {
		PIN string `json:"pin"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.PIN == "" {
		jsonErr(w, "pin é obrigatório", http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	rows, err := h.db.Query(ctx, `
		SELECT u.id, u.nome, u.email, u.estado, u.tipo, m.id, COALESCE(NULLIF(m.escopo,''),'erp'), c.secret_hash
		  FROM auth.user_auth_codes c
		  JOIN users u ON u.id = c.user_id
		  JOIN auth.memberships m ON m.user_id = u.id AND m.tenant_id = $1 AND m.ativo = true
		 WHERE c.tipo = $2 AND c.ativo = true`,
		caller.TenantID, authCodeTypePIN,
	)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	type candidato struct {
		u    userIdentity
		hash string
	}
	var candidatos []candidato
	for rows.Next() {
		var c candidato
		c.u.tenantID = caller.TenantID
		if rows.Scan(&c.u.id, &c.u.nome, &c.u.email, &c.u.estado, &c.u.tipo, &c.u.membershipID, &c.u.escopo, &c.hash) == nil {
			candidatos = append(candidatos, c)
		}
	}
	rows.Close()

	for _, c := range candidatos {
		if bcrypt.CompareHashAndPassword([]byte(c.hash), []byte(body.PIN)) != nil {
			continue
		}
		if c.u.estado != "ativo" {
			h.logAuthAttempt(r, &c.u, c.u.email, false, "conta "+c.u.estado)
			jsonErr(w, "Conta "+c.u.estado, http.StatusForbidden)
			return
		}

		h.logAuthAttempt(r, &c.u, c.u.email, true, "login por pin no terminal")

		var funcionarioID *int64
		if f, err := funcionario.NewService(h.db).PorUserID(ctx, c.u.tenantID, c.u.id); err == nil {
			funcionarioID = &f.ID
		}
		h.issueFuncionarioTokens(w, r, &c.u, funcionarioID)
		return
	}

	jsonErr(w, "PIN inválido", http.StatusUnauthorized)
}
