package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

type unidadeRow struct {
	ID              int64   `json:"id"`
	Codigo          string  `json:"codigo"`
	Nome            string  `json:"nome"`
	Tipo            string  `json:"tipo"`
	Descricao       *string `json:"descricao"`
	ParentID        *int64  `json:"parent_id"`
	UnidadePaiNome  *string `json:"unidade_pai_nome"`
	ResponsavelID   *int64  `json:"responsavel_id"`
	ResponsavelNome *string `json:"responsavel_nome"`
	Ativo           bool    `json:"ativo"`
	NumFuncionarios int     `json:"num_funcionarios"`
}

const unidadeSelect = `
	SELECT u.id, u.codigo, u.nome, u.tipo, u.descricao, u.parent_id, p.nome, u.responsavel_id, f.nome_completo, u.ativo,
	       (SELECT COUNT(*) FROM funcionarios fu WHERE fu.unit_id = u.id)
	  FROM unidades_organizacionais u
	  LEFT JOIN funcionarios f ON f.id = u.responsavel_id
	  LEFT JOIN unidades_organizacionais p ON p.id = u.parent_id
`

func scanUnidades(rows pgx.Rows) []unidadeRow {
	data := []unidadeRow{}
	for rows.Next() {
		var u unidadeRow
		if rows.Scan(&u.ID, &u.Codigo, &u.Nome, &u.Tipo, &u.Descricao, &u.ParentID, &u.UnidadePaiNome, &u.ResponsavelID, &u.ResponsavelNome, &u.Ativo, &u.NumFuncionarios) == nil {
			data = append(data, u)
		}
	}
	return data
}

type funcionarioResumo struct {
	ID                int64   `json:"id"`
	NumeroFuncionario *string `json:"numero_funcionario"`
	NomeCompleto      string  `json:"nome_completo"`
	Cargo             *string `json:"cargo"`
	Estado            string  `json:"estado"`
}

func scanFuncionariosResumo(rows pgx.Rows) []funcionarioResumo {
	data := []funcionarioResumo{}
	for rows.Next() {
		var f funcionarioResumo
		if rows.Scan(&f.ID, &f.NumeroFuncionario, &f.NomeCompleto, &f.Cargo, &f.Estado) == nil {
			data = append(data, f)
		}
	}
	return data
}

type caminhoItem struct {
	ID   int64  `json:"id"`
	Nome string `json:"nome"`
}

// caminhoUnidade devolve o caminho da raiz até à unidade indicada (incluindo-a).
func (h *Handler) caminhoUnidade(ctx context.Context, tenantID int64, id string) []caminhoItem {
	rows, _ := h.db.Query(ctx, `
		WITH RECURSIVE caminho AS (
			SELECT id, nome, parent_id, 0 AS nivel FROM unidades_organizacionais WHERE id=$1 AND tenant_id=$2
			UNION ALL
			SELECT p.id, p.nome, p.parent_id, c.nivel+1
			  FROM unidades_organizacionais p
			  JOIN caminho c ON p.id = c.parent_id
		)
		SELECT id, nome FROM caminho ORDER BY nivel DESC`, id, tenantID)
	defer rows.Close()
	caminho := []caminhoItem{}
	for rows.Next() {
		var c caminhoItem
		if rows.Scan(&c.ID, &c.Nome) == nil {
			caminho = append(caminho, c)
		}
	}
	return caminho
}

func (h *Handler) ObterUnidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), unidadeSelect+` WHERE u.id=$1 AND u.tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	unidades := scanUnidades(rows)
	rows.Close()
	if len(unidades) == 0 {
		jsonErr(w, "Unidade não encontrada", http.StatusNotFound)
		return
	}

	caminho := h.caminhoUnidade(r.Context(), user.TenantID, id)

	jsonOK(w, map[string]any{
		"unidade": unidades[0],
		"caminho": caminho,
		"nivel":   len(caminho) - 1,
	}, http.StatusOK)
}

func (h *Handler) RemoverUnidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var temFilhos, temFuncionarios bool
	err := h.db.QueryRow(r.Context(), `
		SELECT EXISTS(SELECT 1 FROM unidades_organizacionais WHERE parent_id=$1 AND tenant_id=$2),
		       EXISTS(SELECT 1 FROM funcionarios WHERE unit_id=$1 AND tenant_id=$2)`,
		id, user.TenantID).Scan(&temFilhos, &temFuncionarios)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if temFilhos || temFuncionarios {
		jsonErr(w, "Não é possível eliminar uma unidade com sub-unidades ou funcionários associados", http.StatusConflict)
		return
	}

	tag, err := h.db.Exec(r.Context(), `DELETE FROM unidades_organizacionais WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Unidade não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListarFilhosUnidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	rows, _ := h.db.Query(r.Context(), unidadeSelect+` WHERE u.parent_id=$1 AND u.tenant_id=$2 ORDER BY u.nome`, id, user.TenantID)
	defer rows.Close()
	jsonOK(w, scanUnidades(rows), http.StatusOK)
}

func (h *Handler) ListarSubarvoreUnidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	rows, _ := h.db.Query(r.Context(), `
		WITH RECURSIVE sub AS (
			SELECT id FROM unidades_organizacionais WHERE id=$1 AND tenant_id=$2
			UNION ALL
			SELECT u.id FROM unidades_organizacionais u JOIN sub s ON u.parent_id = s.id
		)
		`+unidadeSelect+` WHERE u.id IN (SELECT id FROM sub) AND u.id != $1 ORDER BY u.nome`, id, user.TenantID)
	defer rows.Close()
	jsonOK(w, scanUnidades(rows), http.StatusOK)
}

func (h *Handler) ObterCaminhoUnidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	caminho := h.caminhoUnidade(r.Context(), user.TenantID, id)
	if len(caminho) == 0 {
		jsonErr(w, "Unidade não encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, caminho, http.StatusOK)
}

func (h *Handler) ListarFuncionariosUnidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	rows, _ := h.db.Query(r.Context(), `
		SELECT f.id, f.numero_funcionario, f.nome_completo, f.cargo, f.estado
		  FROM funcionarios f
		 WHERE f.unit_id=$1 AND f.tenant_id=$2
		 ORDER BY f.nome_completo`, id, user.TenantID)
	defer rows.Close()
	jsonOK(w, scanFuncionariosResumo(rows), http.StatusOK)
}

func (h *Handler) ListarFuncionariosSubarvore(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	rows, _ := h.db.Query(r.Context(), `
		WITH RECURSIVE sub AS (
			SELECT id FROM unidades_organizacionais WHERE id=$1 AND tenant_id=$2
			UNION ALL
			SELECT u.id FROM unidades_organizacionais u JOIN sub s ON u.parent_id = s.id
		)
		SELECT f.id, f.numero_funcionario, f.nome_completo, f.cargo, f.estado
		  FROM funcionarios f
		 WHERE f.unit_id IN (SELECT id FROM sub) AND f.tenant_id=$2
		 ORDER BY f.nome_completo`, id, user.TenantID)
	defer rows.Close()
	jsonOK(w, scanFuncionariosResumo(rows), http.StatusOK)
}

func (h *Handler) MoverUnidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	idStr := chi.URLParam(r, "id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		jsonErr(w, "id inválido", http.StatusBadRequest)
		return
	}

	var body struct {
		ParentID *int64 `json:"parent_id"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	if body.ParentID != nil {
		if *body.ParentID == id {
			jsonErr(w, "Uma unidade não pode ser sua própria unidade-pai", http.StatusBadRequest)
			return
		}
		var ehDescendente bool
		h.db.QueryRow(r.Context(), `
			WITH RECURSIVE sub AS (
				SELECT id FROM unidades_organizacionais WHERE id=$1 AND tenant_id=$2
				UNION ALL
				SELECT u.id FROM unidades_organizacionais u JOIN sub s ON u.parent_id = s.id
			)
			SELECT EXISTS(SELECT 1 FROM sub WHERE id=$3 AND id != $1)`,
			id, user.TenantID, *body.ParentID).Scan(&ehDescendente)
		if ehDescendente {
			jsonErr(w, "Não é possível mover uma unidade para uma das suas próprias sub-unidades", http.StatusBadRequest)
			return
		}
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE unidades_organizacionais SET parent_id=$1, updated_at=NOW() WHERE id=$2 AND tenant_id=$3`,
		body.ParentID, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Unidade não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
