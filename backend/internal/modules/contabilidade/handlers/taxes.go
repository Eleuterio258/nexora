package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

var tiposTaxaValidos = map[string]bool{
	"iva": true, "isento": true, "zero": true, "outro": true,
}

type taxRow struct {
	ID         int64   `json:"id"`
	Codigo     string  `json:"codigo"`
	Nome       string  `json:"nome"`
	Taxa       float64 `json:"taxa"`
	Tipo       string  `json:"tipo"`
	TaxGroupID *int64  `json:"tax_group_id"`
	Ativo      bool    `json:"ativo"`
}

type taxRuleRow struct {
	ID          int64    `json:"id"`
	ValorMinimo float64  `json:"valor_minimo"`
	ValorMaximo *float64 `json:"valor_maximo"`
	Taxa        float64  `json:"taxa"`
	Ordem       int      `json:"ordem"`
}

func (h *Handler) ListarTaxas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("tax_group_id"); v != "" {
		args = append(args, v)
		where += " AND tax_group_id=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("ativo"); v != "" {
		args = append(args, v == "true")
		where += " AND ativo=$" + strconv.Itoa(len(args))
	}
	rows, err := h.db.Query(r.Context(), `
		SELECT id, codigo, nome, taxa, tipo, tax_group_id, ativo
		  FROM impostos.taxes WHERE `+where+` ORDER BY codigo`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data := []taxRow{}
	for rows.Next() {
		var t taxRow
		if rows.Scan(&t.ID, &t.Codigo, &t.Nome, &t.Taxa, &t.Tipo, &t.TaxGroupID, &t.Ativo) == nil {
			data = append(data, t)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarTaxa(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo     string  `json:"codigo"`
		Nome       string  `json:"nome"`
		Taxa       float64 `json:"taxa"`
		Tipo       string  `json:"tipo"`
		TaxGroupID *int64  `json:"tax_group_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.Tipo == "" {
		body.Tipo = "iva"
	}
	if !tiposTaxaValidos[body.Tipo] {
		jsonErr(w, "tipo inválido", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO impostos.taxes (tenant_id,codigo,nome,taxa,tipo,tax_group_id)
		VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Taxa, body.Tipo, body.TaxGroupID).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Código já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterTaxa(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var t taxRow
	err := h.db.QueryRow(r.Context(), `
		SELECT id, codigo, nome, taxa, tipo, tax_group_id, ativo
		  FROM impostos.taxes WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&t.ID, &t.Codigo, &t.Nome, &t.Taxa, &t.Tipo, &t.TaxGroupID, &t.Ativo)
	if err != nil {
		jsonErr(w, "Taxa não encontrada", http.StatusNotFound)
		return
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT id, valor_minimo, valor_maximo, taxa, ordem
		  FROM impostos.tax_rules WHERE tax_id=$1 ORDER BY valor_minimo`, t.ID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	regras := []taxRuleRow{}
	for rows.Next() {
		var rule taxRuleRow
		if rows.Scan(&rule.ID, &rule.ValorMinimo, &rule.ValorMaximo, &rule.Taxa, &rule.Ordem) == nil {
			regras = append(regras, rule)
		}
	}
	rows.Close()

	jsonOK(w, map[string]any{
		"id": t.ID, "codigo": t.Codigo, "nome": t.Nome, "taxa": t.Taxa, "tipo": t.Tipo,
		"tax_group_id": t.TaxGroupID, "ativo": t.Ativo, "regras": regras,
	}, http.StatusOK)
}

func (h *Handler) ActualizarTaxa(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Codigo     *string  `json:"codigo"`
		Nome       *string  `json:"nome"`
		Taxa       *float64 `json:"taxa"`
		Tipo       *string  `json:"tipo"`
		TaxGroupID *int64   `json:"tax_group_id"`
		Ativo      *bool    `json:"ativo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	if body.Tipo != nil && !tiposTaxaValidos[*body.Tipo] {
		jsonErr(w, "tipo inválido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE impostos.taxes SET
		  codigo=COALESCE($1,codigo), nome=COALESCE($2,nome), taxa=COALESCE($3,taxa),
		  tipo=COALESCE($4,tipo), tax_group_id=COALESCE($5,tax_group_id), ativo=COALESCE($6,ativo)
		WHERE id=$7 AND tenant_id=$8`,
		body.Codigo, body.Nome, body.Taxa, body.Tipo, body.TaxGroupID, body.Ativo, id, user.TenantID)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Código já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Taxa não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) AdicionarRegraTaxa(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var taxID int64
	if err := h.db.QueryRow(r.Context(), `SELECT id FROM impostos.taxes WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).Scan(&taxID); err != nil {
		jsonErr(w, "Taxa não encontrada", http.StatusNotFound)
		return
	}

	var body struct {
		ValorMinimo float64  `json:"valor_minimo"`
		ValorMaximo *float64 `json:"valor_maximo"`
		Taxa        float64  `json:"taxa"`
		Ordem       int      `json:"ordem"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	if body.ValorMaximo != nil && *body.ValorMaximo <= body.ValorMinimo {
		jsonErr(w, "o valor máximo deve ser superior ao valor mínimo", http.StatusBadRequest)
		return
	}
	if body.Taxa < 0 {
		jsonErr(w, "a taxa não pode ser negativa", http.StatusBadRequest)
		return
	}

	rows, err := h.db.Query(r.Context(), `SELECT valor_minimo, valor_maximo FROM impostos.tax_rules WHERE tax_id=$1`, taxID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	type intervalo struct {
		min float64
		max *float64
	}
	existentes := []intervalo{}
	for rows.Next() {
		var iv intervalo
		if rows.Scan(&iv.min, &iv.max) == nil {
			existentes = append(existentes, iv)
		}
	}
	rows.Close()

	for _, iv := range existentes {
		if intervalosSobrepostos(iv.min, iv.max, body.ValorMinimo, body.ValorMaximo) {
			jsonErr(w, "esta faixa sobrepõe-se a uma regra existente", http.StatusConflict)
			return
		}
	}

	var newID int64
	err = h.db.QueryRow(r.Context(), `
		INSERT INTO impostos.tax_rules (tax_id,valor_minimo,valor_maximo,taxa,ordem)
		VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		taxID, body.ValorMinimo, body.ValorMaximo, body.Taxa, body.Ordem).Scan(&newID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": newID}, http.StatusCreated)
}

// intervalosSobrepostos indica se dois intervalos [min,max) se sobrepõem,
// tratando max==nil como sem limite superior.
func intervalosSobrepostos(aMin float64, aMax *float64, bMin float64, bMax *float64) bool {
	if aMax != nil && *aMax <= bMin {
		return false
	}
	if bMax != nil && *bMax <= aMin {
		return false
	}
	return true
}
