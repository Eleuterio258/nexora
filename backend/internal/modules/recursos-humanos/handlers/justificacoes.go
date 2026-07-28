package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
)

// ListarJustificacoesPendentes lista as justificações de falta/atraso
// pendentes de decisão — GET /api/rh/justificacoes. Sucessor em falta desde
// que o self-service (POST /api/self-service/assiduidade/justificacoes) foi
// implementado: até agora não havia nenhuma forma de um gestor ver ou decidir
// estes pedidos, apesar do schema (estado/aprovado_por/aprovado_em) já estar
// pronto para isso.
func (h *Handler) ListarJustificacoesPendentes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	type row struct {
		ID              int64     `json:"id"`
		FuncionarioID   int64     `json:"funcionario_id"`
		FuncionarioNome string    `json:"funcionario_nome"`
		Tipo            string    `json:"tipo"`
		Data            time.Time `json:"data"`
		Motivo          string    `json:"motivo"`
		FicheiroURL     *string   `json:"ficheiro_url"`
		CreatedAt       time.Time `json:"created_at"`
	}
	rows, _ := h.db.Query(r.Context(), `
		SELECT j.id, j.funcionario_id, f.nome_completo, j.tipo, j.data, j.motivo, j.ficheiro_url, j.created_at
		  FROM rh.justificacoes j
		  JOIN rh.funcionarios f ON f.id = j.funcionario_id
		 WHERE j.tenant_id = $1 AND j.estado = 'pendente'
		 ORDER BY j.created_at`, user.TenantID)
	if rows == nil {
		jsonOK(w, []row{}, http.StatusOK)
		return
	}
	defer rows.Close()

	data := []row{}
	for rows.Next() {
		var j row
		if rows.Scan(&j.ID, &j.FuncionarioID, &j.FuncionarioNome, &j.Tipo, &j.Data, &j.Motivo, &j.FicheiroURL, &j.CreatedAt) == nil {
			data = append(data, j)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// AprovarJustificacao aprova uma justificação pendente e marca o dia
// correspondente em rh.presencas como justificado — sem isso, a falta/atraso
// continuaria a contar contra o colaborador em ResumoAssiduidade/Home mesmo
// depois de aprovada. POST /api/rh/justificacoes/{id}/aprovar.
func (h *Handler) AprovarJustificacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var funcionarioID int64
	var data time.Time
	if err := h.db.QueryRow(r.Context(), `
		SELECT funcionario_id, data FROM rh.justificacoes
		 WHERE id=$1 AND tenant_id=$2 AND estado='pendente'`,
		id, user.TenantID,
	).Scan(&funcionarioID, &data); err != nil {
		jsonErr(w, "Justificação não encontrada ou já processada", http.StatusConflict)
		return
	}

	if !h.podeGerirFuncionario(r, funcionarioID) {
		jsonErr(w, "Sem permissão para aprovar esta justificação", http.StatusForbidden)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	tag, err := tx.Exec(r.Context(), `
		UPDATE rh.justificacoes
		   SET estado='aprovado', aprovado_por=$1, aprovado_em=NOW()
		 WHERE id=$2 AND tenant_id=$3 AND estado='pendente'`,
		user.ID, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Justificação já foi processada", http.StatusConflict)
		return
	}

	if _, err := tx.Exec(r.Context(), `
		UPDATE rh.presencas
		   SET justificado = TRUE
		 WHERE funcionario_id=$1 AND tenant_id=$2 AND data=$3::date`,
		funcionarioID, user.TenantID, data); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	registoID, _ := strconv.ParseInt(id, 10, 64)
	ip := r.RemoteAddr
	estadoAnterior, estadoNovo := "pendente", "aprovado"
	_ = assiduidade.RegistarAuditoria(r.Context(), h.db, assiduidade.AuditoriaEntry{
		TenantID: user.TenantID, Tabela: "justificacoes", RegistoID: registoID,
		Operacao: "UPDATE", AlteradoPor: &user.ID, IPOrigem: &ip,
		EstadoAnterior: &estadoAnterior, EstadoNovo: &estadoNovo,
	})

	w.WriteHeader(http.StatusNoContent)
}

// RejeitarJustificacao rejeita uma justificação pendente — o dia mantém-se
// como falta/atraso normal em rh.presencas (não há nada a desfazer, o
// justificado só é marcado na aprovação). POST /api/rh/justificacoes/{id}/rejeitar.
func (h *Handler) RejeitarJustificacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Justificacao *string `json:"justificacao"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)

	var funcionarioID int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT funcionario_id FROM rh.justificacoes WHERE id=$1 AND tenant_id=$2 AND estado='pendente'`,
		id, user.TenantID).Scan(&funcionarioID); err != nil {
		jsonErr(w, "Justificação não encontrada ou já processada", http.StatusConflict)
		return
	}

	if !h.podeGerirFuncionario(r, funcionarioID) {
		jsonErr(w, "Sem permissão para rejeitar esta justificação", http.StatusForbidden)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.justificacoes
		   SET estado='rejeitado', aprovado_por=$1, aprovado_em=NOW()
		 WHERE id=$2 AND tenant_id=$3 AND estado='pendente'`,
		user.ID, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Justificação já foi processada", http.StatusConflict)
		return
	}

	registoID, _ := strconv.ParseInt(id, 10, 64)
	ip := r.RemoteAddr
	estadoAnterior, estadoNovo := "pendente", "rejeitado"
	_ = assiduidade.RegistarAuditoria(r.Context(), h.db, assiduidade.AuditoriaEntry{
		TenantID: user.TenantID, Tabela: "justificacoes", RegistoID: registoID,
		Operacao: "UPDATE", AlteradoPor: &user.ID, Motivo: body.Justificacao, IPOrigem: &ip,
		EstadoAnterior: &estadoAnterior, EstadoNovo: &estadoNovo,
	})

	w.WriteHeader(http.StatusNoContent)
}
