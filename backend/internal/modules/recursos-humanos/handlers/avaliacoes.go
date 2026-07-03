package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

// ── Critérios de Avaliação: catálogo configurável ────────────────────────────

type criterioAvaliacaoRow struct {
	ID        int64   `json:"id"`
	Codigo    string  `json:"codigo"`
	Nome      string  `json:"nome"`
	Descricao *string `json:"descricao"`
	Peso      float64 `json:"peso"`
	Ativo     bool    `json:"ativo"`
	NumUsos   int     `json:"num_usos"`
}

func (h *Handler) ListarCriteriosAvaliacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT c.id, c.codigo, c.nome, c.descricao, c.peso, c.ativo,
		       (SELECT COUNT(*) FROM rh.avaliacao_criterios ac WHERE ac.criterio_id = c.id)
		  FROM rh.criterios_avaliacao c
		 WHERE c.tenant_id=$1
		 ORDER BY c.nome`, user.TenantID)
	defer rows.Close()
	data := []criterioAvaliacaoRow{}
	for rows.Next() {
		var c criterioAvaliacaoRow
		if rows.Scan(&c.ID, &c.Codigo, &c.Nome, &c.Descricao, &c.Peso, &c.Ativo, &c.NumUsos) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarCriterioAvaliacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo    string   `json:"codigo"`
		Nome      string   `json:"nome"`
		Descricao *string  `json:"descricao"`
		Peso      *float64 `json:"peso"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "código e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	peso := 1.0
	if body.Peso != nil {
		peso = *body.Peso
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.criterios_avaliacao (tenant_id, codigo, nome, descricao, peso)
		VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Descricao, peso).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um critério de avaliação com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarCriterioAvaliacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Codigo    *string  `json:"codigo"`
		Nome      *string  `json:"nome"`
		Descricao *string  `json:"descricao"`
		Peso      *float64 `json:"peso"`
		Ativo     *bool    `json:"ativo"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	if body.Codigo != nil && *body.Codigo == "" {
		jsonErr(w, "código não pode ser vazio", http.StatusBadRequest)
		return
	}
	if body.Nome != nil && *body.Nome == "" {
		jsonErr(w, "nome não pode ser vazio", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.criterios_avaliacao SET
		  codigo=COALESCE($1,codigo), nome=COALESCE($2,nome), descricao=COALESCE($3,descricao),
		  peso=COALESCE($4,peso), ativo=COALESCE($5,ativo), updated_at=NOW()
		WHERE id=$6 AND tenant_id=$7`,
		body.Codigo, body.Nome, body.Descricao, body.Peso, body.Ativo, id, user.TenantID)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um critério de avaliação com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Critério de avaliação não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverCriterioAvaliacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var emUso bool
	if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM rh.avaliacao_criterios ac JOIN rh.criterios_avaliacao c ON c.id = ac.criterio_id WHERE ac.criterio_id=$1 AND c.tenant_id=$2)`, id, user.TenantID).Scan(&emUso); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if emUso {
		jsonErr(w, "Não é possível eliminar um critério associado a avaliações existentes", http.StatusConflict)
		return
	}

	tag, err := h.db.Exec(r.Context(), `DELETE FROM rh.criterios_avaliacao WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Critério de avaliação não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Avaliações: fluxo rascunho → submetida → aprovada ───────────────────────

// SubmeterAvaliacao move uma avaliação de 'rascunho' para 'submetida'.
// Apenas o avaliador que a criou (ou um superadmin) pode submetê-la.
func (h *Handler) SubmeterAvaliacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var avaliadorID int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT avaliador_id FROM rh.avaliacoes WHERE id=$1 AND tenant_id=$2 AND estado='rascunho'`,
		id, user.TenantID).Scan(&avaliadorID); err != nil {
		jsonErr(w, "Avaliação não encontrada ou já submetida", http.StatusConflict)
		return
	}

	if avaliadorID != user.ID && user.Tipo != "superadmin" {
		jsonErr(w, "Sem permissão para submeter esta avaliação", http.StatusForbidden)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.avaliacoes SET estado='submetida' WHERE id=$1 AND tenant_id=$2 AND estado='rascunho'`,
		id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Avaliação já foi processada", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// AprovarAvaliacaoDesempenho move uma avaliação de 'submetida' para 'aprovada'.
// Apenas o responsável hierárquico do funcionário avaliado (ou um superadmin)
// pode aprová-la.
func (h *Handler) AprovarAvaliacaoDesempenho(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var funcionarioID int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT funcionario_id FROM rh.avaliacoes WHERE id=$1 AND tenant_id=$2 AND estado='submetida'`,
		id, user.TenantID).Scan(&funcionarioID); err != nil {
		jsonErr(w, "Avaliação não encontrada ou não está submetida", http.StatusConflict)
		return
	}

	if !h.podeGerirFuncionario(r, funcionarioID) {
		jsonErr(w, "Sem permissão para aprovar esta avaliação", http.StatusForbidden)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.avaliacoes SET estado='aprovada', aprovado_por=$1, aprovado_em=NOW()
		 WHERE id=$2 AND tenant_id=$3 AND estado='submetida'`,
		user.ID, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Avaliação já foi processada", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
