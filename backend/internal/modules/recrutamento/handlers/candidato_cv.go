package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"

	mw "nexora/internal/middleware"
)

// ============================================================================
// Experiências profissionais do candidato
// ============================================================================

type experienciaCandidato struct {
	ID          int64      `json:"id"`
	CandidatoID int64      `json:"candidato_id"`
	Cargo       string     `json:"cargo"`
	Empresa     string     `json:"empresa"`
	Local       *string    `json:"local"`
	DataInicio  string     `json:"data_inicio"`
	DataFim     *string    `json:"data_fim"`
	Actual      bool       `json:"actual"`
	Descricao   *string    `json:"descricao"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
}

const experienciaSelectCols = `id, candidato_id, cargo, empresa, local,
    to_char(data_inicio, 'YYYY-MM-DD'), to_char(data_fim, 'YYYY-MM-DD'),
    actual, descricao, created_at, updated_at`

func scanExperiencia(row pgx.Row) (*experienciaCandidato, error) {
	var e experienciaCandidato
	if err := row.Scan(&e.ID, &e.CandidatoID, &e.Cargo, &e.Empresa, &e.Local,
		&e.DataInicio, &e.DataFim, &e.Actual, &e.Descricao, &e.CreatedAt, &e.UpdatedAt); err != nil {
		return nil, err
	}
	return &e, nil
}

type experienciaInput struct {
	Cargo      string  `json:"cargo"`
	Empresa    string  `json:"empresa"`
	Local      *string `json:"local"`
	DataInicio string  `json:"data_inicio"`
	DataFim    *string `json:"data_fim"`
	Actual     *bool   `json:"actual"`
	Descricao  *string `json:"descricao"`
}

func (in *experienciaInput) validate() error {
	in.Cargo = strings.TrimSpace(in.Cargo)
	in.Empresa = strings.TrimSpace(in.Empresa)
	if in.Cargo == "" {
		return errValidation("O cargo é obrigatório")
	}
	if in.Empresa == "" {
		return errValidation("A empresa é obrigatória")
	}
	if in.DataInicio == "" {
		return errValidation("A data de início é obrigatória")
	}
	if in.DataFim != nil && *in.DataFim != "" && in.DataInicio > *in.DataFim {
		return errValidation("A data de início não pode ser posterior à data de fim")
	}
	if in.Actual == nil {
		f := false
		in.Actual = &f
	}
	return nil
}

func (h *Handler) ListarExperiencias(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT `+experienciaSelectCols+`
		  FROM recrutamento.candidato_experiencias
		 WHERE candidato_id=$1 AND tenant_id=$2
		 ORDER BY data_inicio DESC`, c.ID, c.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []experienciaCandidato{}
	for rows.Next() {
		if e, err := scanExperiencia(rows); err == nil {
			data = append(data, *e)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarExperiencia(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)

	var body experienciaInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	if err := body.validate(); err != nil {
		jsonErr(w, err.Error(), http.StatusUnprocessableEntity)
		return
	}

	row := h.db.QueryRow(r.Context(), `
		INSERT INTO recrutamento.candidato_experiencias
			(candidato_id, tenant_id, cargo, empresa, local, data_inicio, data_fim, actual, descricao)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING `+experienciaSelectCols,
		c.ID, c.TenantID, clean(body.Cargo, 150), clean(body.Empresa, 150),
		nullIfEmpty(clean(ptrString(body.Local), 150)), body.DataInicio,
		nullIfEmpty(clean(ptrString(body.DataFim), 10)), *body.Actual,
		nullIfEmpty(clean(ptrString(body.Descricao), 2000)))
	exp, err := scanExperiencia(row)
	if err != nil {
		jsonErr(w, "Erro ao criar experiência", http.StatusInternalServerError)
		return
	}
	jsonOK(w, exp, http.StatusCreated)
}

func (h *Handler) AtualizarExperiencia(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)
	id := h.decodeID(chi.URLParam(r, "id"))

	var body experienciaInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	if err := body.validate(); err != nil {
		jsonErr(w, err.Error(), http.StatusUnprocessableEntity)
		return
	}

	cmd, err := h.db.Exec(r.Context(), `
		UPDATE recrutamento.candidato_experiencias
		   SET cargo=$1, empresa=$2, local=$3, data_inicio=$4, data_fim=$5,
		       actual=$6, descricao=$7, updated_at=NOW()
		 WHERE id=$8 AND candidato_id=$9 AND tenant_id=$10`,
		clean(body.Cargo, 150), clean(body.Empresa, 150),
		nullIfEmpty(clean(ptrString(body.Local), 150)), body.DataInicio,
		nullIfEmpty(clean(ptrString(body.DataFim), 10)), *body.Actual,
		nullIfEmpty(clean(ptrString(body.Descricao), 2000)),
		id, c.ID, c.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao actualizar experiência", http.StatusInternalServerError)
		return
	}
	if cmd.RowsAffected() == 0 {
		jsonErr(w, "Experiência não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverExperiencia(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)
	id := h.decodeID(chi.URLParam(r, "id"))

	cmd, err := h.db.Exec(r.Context(), `
		DELETE FROM recrutamento.candidato_experiencias
		 WHERE id=$1 AND candidato_id=$2 AND tenant_id=$3`,
		id, c.ID, c.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao remover experiência", http.StatusInternalServerError)
		return
	}
	if cmd.RowsAffected() == 0 {
		jsonErr(w, "Experiência não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ============================================================================
// Formação académica do candidato
// ============================================================================

type formacaoCandidato struct {
	ID          int64     `json:"id"`
	CandidatoID int64     `json:"candidato_id"`
	Curso       string    `json:"curso"`
	Instituicao string    `json:"instituicao"`
	Local       *string   `json:"local"`
	AnoInicio   *int16    `json:"ano_inicio"`
	AnoFim      *int16    `json:"ano_fim"`
	Nota        *string   `json:"nota"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

const formacaoSelectCols = `id, candidato_id, curso, instituicao, local,
    ano_inicio, ano_fim, nota, created_at, updated_at`

func scanFormacao(row pgx.Row) (*formacaoCandidato, error) {
	var f formacaoCandidato
	if err := row.Scan(&f.ID, &f.CandidatoID, &f.Curso, &f.Instituicao, &f.Local,
		&f.AnoInicio, &f.AnoFim, &f.Nota, &f.CreatedAt, &f.UpdatedAt); err != nil {
		return nil, err
	}
	return &f, nil
}

type formacaoInput struct {
	Curso       string  `json:"curso"`
	Instituicao string  `json:"instituicao"`
	Local       *string `json:"local"`
	AnoInicio   *int16  `json:"ano_inicio"`
	AnoFim      *int16  `json:"ano_fim"`
	Nota        *string `json:"nota"`
}

func (in *formacaoInput) validate() error {
	in.Curso = strings.TrimSpace(in.Curso)
	in.Instituicao = strings.TrimSpace(in.Instituicao)
	if in.Curso == "" {
		return errValidation("O curso é obrigatório")
	}
	if in.Instituicao == "" {
		return errValidation("A instituição é obrigatória")
	}
	return nil
}

func (h *Handler) ListarFormacoes(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT `+formacaoSelectCols+`
		  FROM recrutamento.candidato_formacoes
		 WHERE candidato_id=$1 AND tenant_id=$2
		 ORDER BY ano_inicio DESC NULLS LAST`, c.ID, c.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []formacaoCandidato{}
	for rows.Next() {
		if f, err := scanFormacao(rows); err == nil {
			data = append(data, *f)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarFormacao(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)

	var body formacaoInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	if err := body.validate(); err != nil {
		jsonErr(w, err.Error(), http.StatusUnprocessableEntity)
		return
	}

	row := h.db.QueryRow(r.Context(), `
		INSERT INTO recrutamento.candidato_formacoes
			(candidato_id, tenant_id, curso, instituicao, local, ano_inicio, ano_fim, nota)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING `+formacaoSelectCols,
		c.ID, c.TenantID, clean(body.Curso, 200), clean(body.Instituicao, 200),
		nullIfEmpty(clean(ptrString(body.Local), 150)),
		body.AnoInicio, body.AnoFim,
		nullIfEmpty(clean(ptrString(body.Nota), 50)))
	f, err := scanFormacao(row)
	if err != nil {
		jsonErr(w, "Erro ao criar formação", http.StatusInternalServerError)
		return
	}
	jsonOK(w, f, http.StatusCreated)
}

func (h *Handler) AtualizarFormacao(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)
	id := h.decodeID(chi.URLParam(r, "id"))

	var body formacaoInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	if err := body.validate(); err != nil {
		jsonErr(w, err.Error(), http.StatusUnprocessableEntity)
		return
	}

	cmd, err := h.db.Exec(r.Context(), `
		UPDATE recrutamento.candidato_formacoes
		   SET curso=$1, instituicao=$2, local=$3, ano_inicio=$4, ano_fim=$5,
		       nota=$6, updated_at=NOW()
		 WHERE id=$7 AND candidato_id=$8 AND tenant_id=$9`,
		clean(body.Curso, 200), clean(body.Instituicao, 200),
		nullIfEmpty(clean(ptrString(body.Local), 150)),
		body.AnoInicio, body.AnoFim,
		nullIfEmpty(clean(ptrString(body.Nota), 50)),
		id, c.ID, c.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao actualizar formação", http.StatusInternalServerError)
		return
	}
	if cmd.RowsAffected() == 0 {
		jsonErr(w, "Formação não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverFormacao(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)
	id := h.decodeID(chi.URLParam(r, "id"))

	cmd, err := h.db.Exec(r.Context(), `
		DELETE FROM recrutamento.candidato_formacoes
		 WHERE id=$1 AND candidato_id=$2 AND tenant_id=$3`,
		id, c.ID, c.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao remover formação", http.StatusInternalServerError)
		return
	}
	if cmd.RowsAffected() == 0 {
		jsonErr(w, "Formação não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ============================================================================
// Notificações do candidato
// ============================================================================

type notificacaoCandidato struct {
	ID        int64          `json:"id"`
	Tipo      string         `json:"tipo"`
	Titulo    string         `json:"titulo"`
	Corpo     string         `json:"corpo"`
	Lida      bool           `json:"lida"`
	Dados     map[string]any `json:"dados"`
	CreatedAt time.Time      `json:"created_at"`
}

const notificacaoSelectCols = `id, tipo, titulo, corpo, lida, dados, created_at`

func scanNotificacao(row pgx.Row) (*notificacaoCandidato, error) {
	var n notificacaoCandidato
	if err := row.Scan(&n.ID, &n.Tipo, &n.Titulo, &n.Corpo, &n.Lida, &n.Dados, &n.CreatedAt); err != nil {
		return nil, err
	}
	return &n, nil
}

func (h *Handler) ListarNotificacoes(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)
	limit, offset := pageParams(r)

	q := r.URL.Query()
	where := "candidato_id=$1 AND tenant_id=$2"
	args := []any{c.ID, c.TenantID}

	if q.Get("nao_lidas") == "true" {
		args = append(args, false)
		where += " AND lida=$" + strconv.Itoa(len(args))
	}

	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(), `
		SELECT `+notificacaoSelectCols+`
		  FROM recrutamento.candidato_notificacoes
		 WHERE `+where+`
		 ORDER BY created_at DESC
		 LIMIT $`+strconv.Itoa(n-1)+` OFFSET $`+strconv.Itoa(n), args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []notificacaoCandidato{}
	for rows.Next() {
		if n, err := scanNotificacao(rows); err == nil {
			data = append(data, *n)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) MarcarNotificacaoLida(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)
	id := h.decodeID(chi.URLParam(r, "id"))

	cmd, err := h.db.Exec(r.Context(), `
		UPDATE recrutamento.candidato_notificacoes
		   SET lida=TRUE
		 WHERE id=$1 AND candidato_id=$2 AND tenant_id=$3`,
		id, c.ID, c.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if cmd.RowsAffected() == 0 {
		jsonErr(w, "Notificação não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) MarcarTodasNotificacoesLidas(w http.ResponseWriter, r *http.Request) {
	c := mw.GetCandidatoUser(r)

	_, err := h.db.Exec(r.Context(), `
		UPDATE recrutamento.candidato_notificacoes
		   SET lida=TRUE
		 WHERE candidato_id=$1 AND tenant_id=$2 AND lida=FALSE`,
		c.ID, c.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ============================================================================
// Helpers locais
// ============================================================================

type validationError string

func errValidation(msg string) error { return validationError(msg) }
func (e validationError) Error() string { return string(e) }


