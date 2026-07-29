package handlers

import (
	"encoding/json"
	"net/http"

	mw "nexora/internal/middleware"
)

// ── Troca de papel ───────────────────────────────────────────────────────────
//
// POST /api/auth/papel  {"tipo": "candidato"}
//
// Emite um token para OUTRO papel da mesma pessoa, a partir de uma sessão já
// autenticada. Existe porque o login só sabe abrir uma porta de cada vez: o
// despacho em loginWithCredentials olha para auth.users.tipo e emite um token
// desse tipo, com o escopo correspondente. Quem é as duas coisas — a Ana Paulo
// Machava é candidata e funcionária da mesma instituição — só conseguia chegar
// a uma delas, e mudar isso obrigava a alterar o tipo da conta, o que lhe
// tirava a outra.
//
// A autorização não vem do pedido: vem de pessoas.v_pessoa_tipos, ou seja, da
// existência de um registo real desse papel ligado à MESMA pessoa. Não há aqui
// nenhuma escolha livre de identidade — só se pode passar a ser aquilo que já
// se é. É a mesma razão pela qual o funcionário nunca vem do corpo do pedido
// nos endpoints de assiduidade.
func (h *Handler) TrocarPapel(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body struct {
		Tipo string `json:"tipo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Tipo == "" {
		jsonErr(w, "tipo é obrigatório", http.StatusBadRequest)
		return
	}

	// A conta pode ter mudado de dono conceptual (ver pessoa_id), por isso
	// resolve-se sempre a pessoa a partir do utilizador autenticado.
	var pessoaID *int64
	if err := h.db.QueryRow(r.Context(),
		`SELECT pessoa_id FROM users WHERE id = $1`, user.ID).Scan(&pessoaID); err != nil || pessoaID == nil {
		jsonErr(w, "Conta sem pessoa associada", http.StatusConflict)
		return
	}

	var existe bool
	if err := h.db.QueryRow(r.Context(), `
		SELECT EXISTS (
			SELECT 1 FROM pessoas.v_pessoa_tipos
			 WHERE pessoa_id = $1 AND tipo = $2 AND activo
		)`, *pessoaID, body.Tipo).Scan(&existe); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if !existe {
		jsonErr(w, "Esta pessoa não tem esse papel", http.StatusForbidden)
		return
	}

	var nome string
	if err := h.db.QueryRow(r.Context(), `SELECT nome FROM users WHERE id = $1`, user.ID).Scan(&nome); err != nil {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}

	// Reaproveita os mesmos emissores do login: o token e a sessão de cada
	// portal são criados exactamente como se a pessoa tivesse entrado por essa
	// porta, sem caminho paralelo a manter.
	switch body.Tipo {
	case "aluno":
		h.loginAluno(w, r, user.ID, nome)
	case "encarregado":
		h.loginEncarregado(w, r, user.ID, nome)
	case "candidato":
		h.LoginCandidato(w, r, user.ID, nome)
	case "funcionario", "professor":
		h.trocarParaERP(w, r, user.ID, nome)
	default:
		jsonErr(w, "Tipo não suportado para troca de papel", http.StatusBadRequest)
	}
}

// trocarParaERP emite tokens de ERP para a membership activa da conta.
func (h *Handler) trocarParaERP(w http.ResponseWriter, r *http.Request, userID int64, nome string) {
	var u userIdentity
	err := h.db.QueryRow(r.Context(), `
		SELECT u.id, m.tenant_id, m.id, u.nome, u.email, u.estado, u.tipo,
		       COALESCE(NULLIF(m.escopo, ''), 'erp')
		  FROM users u
		  JOIN auth.memberships m ON m.user_id = u.id AND m.ativo = true
		 WHERE u.id = $1
		 ORDER BY m.principal DESC NULLS LAST, m.id ASC
		 LIMIT 1`, userID,
	).Scan(&u.id, &u.tenantID, &u.membershipID, &u.nome, &u.email, &u.estado, &u.tipo, &u.escopo)
	if err != nil {
		jsonErr(w, "Sem vínculo activo a nenhum tenant", http.StatusForbidden)
		return
	}
	// O tipo da conta pode ainda dizer 'candidato' — quem manda aqui é o
	// vínculo. Sem isto o token sairia com o tipo antigo e o middleware
	// devolvia a pessoa ao portal de onde ela está a tentar sair.
	if u.tipo == "candidato" || u.tipo == "aluno" || u.tipo == "encarregado" {
		u.tipo = "funcionario"
	}
	h.issueFuncionarioTokens(w, r, &u, nil)
}
