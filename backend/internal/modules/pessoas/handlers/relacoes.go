package handlers

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

type relacaoRow struct {
	ID            int64     `json:"id"`
	Direcao       string    `json:"direcao"` // "responsavel_por" | "dependente_de"
	PessoaID      int64     `json:"pessoa_id"`
	PessoaNome    string    `json:"pessoa_nome"`
	TipoRelacao   string    `json:"tipo_relacao"`
	ResponsavelLegal bool   `json:"responsavel_legal"`
	Principal     bool      `json:"principal"`
	DataInicio    time.Time `json:"data_inicio"`
}

// ListarRelacoesPessoa devolve as relações de uma pessoa nas duas direcções:
// de quem ela é responsável (ex.: encarregado → alunos) e quem são os
// responsáveis dela (ex.: aluno → encarregados). Ver
// docs/analise-modelo-pessoa-multi-tenant.md secção 9.
func (h *Handler) ListarRelacoesPessoa(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	pessoaID := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), `
		SELECT pr.id, 'responsavel_por' AS direcao, p2.id, p2.nome_completo,
		       pr.tipo_relacao, pr.responsavel_legal, pr.principal, pr.data_inicio
		  FROM pessoas.pessoa_relacoes pr
		  JOIN pessoas.pessoas p2 ON p2.id = pr.pessoa_relacionada_id
		 WHERE pr.pessoa_id = $1 AND pr.tenant_id = $2 AND pr.data_fim IS NULL
		UNION ALL
		SELECT pr.id, 'dependente_de' AS direcao, p1.id, p1.nome_completo,
		       pr.tipo_relacao, pr.responsavel_legal, pr.principal, pr.data_inicio
		  FROM pessoas.pessoa_relacoes pr
		  JOIN pessoas.pessoas p1 ON p1.id = pr.pessoa_id
		 WHERE pr.pessoa_relacionada_id = $1 AND pr.tenant_id = $2 AND pr.data_fim IS NULL
		 ORDER BY 1`,
		pessoaID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []relacaoRow{}
	for rows.Next() {
		var rr relacaoRow
		if rows.Scan(&rr.ID, &rr.Direcao, &rr.PessoaID, &rr.PessoaNome,
			&rr.TipoRelacao, &rr.ResponsavelLegal, &rr.Principal, &rr.DataInicio) == nil {
			data = append(data, rr)
		}
	}
	jsonOK(w, data, http.StatusOK)
}
