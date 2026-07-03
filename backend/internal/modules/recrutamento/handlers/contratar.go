package handlers

import (
	"fmt"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

// ContrataResult dados devolvidos após a contratação de um candidato.
type ContrataResult struct {
	CandidaturaID int64  `json:"candidatura_id"`
	EmployeeID    int64  `json:"rh_employee_id"`
	Mensagem      string `json:"mensagem"`
}

// ContratarCandidato efectua a contratação de um candidato aprovado:
//  1. Marca a candidatura como 'contratado'
//  2. Cria funcionário em rh.employees (se módulo RH estiver instalado)
//  3. Devolve o rh_employee_id para que o admin crie o professor escolar
//
// Após contratar, o admin deve:
//
//	POST /api/escolar/teachers  (criar professor)
//	POST /api/escolar/teachers/{id}/rh-link  (ligar ao funcionário RH)
func (h *Handler) ContratarCandidato(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	candID := chi.URLParam(r, "id")

	// 1. Obter dados do candidato e garantir que está aprovado
	var cand struct {
		ID            int64
		Nome          string
		Email         string
		Telefone      *string
		Estado        string
		VagaArea      *string
		CandidatoUser *int64
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT c.id, c.nome, c.email, c.telefone, c.estado, v.area, cd.user_id
		FROM recrutamento.candidaturas c
		LEFT JOIN recrutamento.vagas v ON v.id = c.vaga_id
		LEFT JOIN recrutamento.candidatos cd ON cd.id = c.candidato_id
		WHERE c.id = $1 AND c.tenant_id = $2`,
		candID, u.TenantID,
	).Scan(&cand.ID, &cand.Nome, &cand.Email, &cand.Telefone, &cand.Estado, &cand.VagaArea, &cand.CandidatoUser)
	if err == pgx.ErrNoRows {
		jsonErr(w, "Candidatura nao encontrada", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if cand.Estado != "aprovada" {
		jsonErr(w, "So candidaturas aprovadas podem ser contratadas", http.StatusConflict)
		return
	}

	// 2. Marcar candidatura como contratada
	_, err = h.db.Exec(r.Context(), `
		UPDATE recrutamento.candidaturas
		SET estado = 'contratado', updated_at = NOW()
		WHERE id = $1 AND tenant_id = $2`, cand.ID, u.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao actualizar candidatura", http.StatusInternalServerError)
		return
	}

	result := ContrataResult{
		CandidaturaID: cand.ID,
		Mensagem:      "Candidato contratado. Crie o professor em /api/escolar/teachers e ligue via /api/escolar/teachers/{id}/rh-link.",
	}

	// 3. Criar funcionário em rh.employees (se módulo RH instalado)
	numero := fmt.Sprintf("RH-%d-%d", u.TenantID, cand.ID)
	var telefone string
	if cand.Telefone != nil {
		telefone = *cand.Telefone
	}
	// 4. Resolver/criar a conta de utilizador (auth.users) — reaproveita a
	//    identidade de candidato existente, ou o email já registado, ou cria de raiz.
	var userID int64
	if cand.CandidatoUser != nil {
		userID = *cand.CandidatoUser
	} else {
		err = h.db.QueryRow(r.Context(), `SELECT id FROM auth.users WHERE email = $1`, cand.Email).Scan(&userID)
		if err == pgx.ErrNoRows {
			err = h.db.QueryRow(r.Context(), `
				INSERT INTO auth.users (nome, email, password_hash, estado, tipo)
				VALUES ($1, $2, '', 'pendente', 'funcionario') RETURNING id`,
				cand.Nome, cand.Email).Scan(&userID)
		}
		if err != nil {
			jsonErr(w, "Erro ao criar conta de utilizador", http.StatusInternalServerError)
			return
		}
	}

	var empID int64
	err = h.db.QueryRow(r.Context(), `
		INSERT INTO rh.funcionarios
		(tenant_id, numero_funcionario, nome_completo, email, telefone, data_admissao, estado, user_id)
		VALUES ($1, $2, $3, $4, $5, $6, 'ativo', $7)
		ON CONFLICT (tenant_id, numero_funcionario) WHERE numero_funcionario IS NOT NULL AND numero_funcionario <> '' DO UPDATE
		  SET nome_completo = EXCLUDED.nome_completo,
		      email         = EXCLUDED.email,
		      user_id       = EXCLUDED.user_id
		RETURNING id`,
		u.TenantID, numero, cand.Nome, cand.Email, telefone, time.Now(), userID,
	).Scan(&empID)
	if err == nil && empID > 0 {
		result.EmployeeID = empID
		result.Mensagem = fmt.Sprintf(
			"Funcionario RH criado (id=%d). Crie o professor em /api/escolar/teachers e ligue com /api/escolar/teachers/{id}/rh-link.",
			empID,
		)

		// Devolve o utilizador ao tipo/vínculo de funcionário e activa a membership
		// ERP, fechando o ciclo candidato → funcionário na mesma conta.
		h.db.Exec(r.Context(), `UPDATE auth.users SET tipo = 'funcionario' WHERE id = $1`, userID)
		h.db.Exec(r.Context(), `
			INSERT INTO auth.memberships (user_id, tenant_id, escopo, ativo)
			VALUES ($1, $2, 'erp', true)
			ON CONFLICT (user_id) DO UPDATE SET tenant_id = EXCLUDED.tenant_id, escopo = 'erp', ativo = true, updated_at = NOW()`,
			userID, u.TenantID)
	}
	// RH não instalado ou erro — prossegue sem funcionário

	jsonOK(w, result, http.StatusCreated)
}
