package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

type Oportunidade struct {
	ID                int64      `json:"id"`
	Titulo            string     `json:"titulo"`
	LeadID            *int64     `json:"lead_id"`
	ClienteID         *int64     `json:"cliente_id"`
	Estagio           string     `json:"estagio"`
	ValorEstimado     float64    `json:"valor_estimado"`
	Moeda             string     `json:"moeda"`
	Probabilidade     int16      `json:"probabilidade"`
	DataFechoPrevista *string    `json:"data_fecho_prevista"`
	DataFechoReal     *string    `json:"data_fecho_real"`
	MotivoPerda       *string    `json:"motivo_perda"`
	Responsavel       *string    `json:"responsavel"`
	ResponsavelID     *int64     `json:"responsavel_id"`
	Descricao         *string    `json:"descricao"`
	CreatedAt         time.Time  `json:"created_at"`
	UpdatedAt         time.Time  `json:"updated_at"`
}

type oportunidadeInput struct {
	Titulo            string   `json:"titulo"`
	LeadID            *int64   `json:"lead_id"`
	ClienteID         *int64   `json:"cliente_id"`
	Estagio           *string  `json:"estagio"`
	ValorEstimado     *float64 `json:"valor_estimado"`
	Moeda             *string  `json:"moeda"`
	Probabilidade     *int16   `json:"probabilidade"`
	DataFechoPrevista *string  `json:"data_fecho_prevista"`
	Responsavel       *string  `json:"responsavel"`
	ResponsavelID     *int64   `json:"responsavel_id"`
	Descricao         *string  `json:"descricao"`
}

var oportunidadeEstagios = map[string]string{
	"novo":        "Novo",
	"qualificado": "Qualificado",
	"proposta":    "Proposta",
	"negociacao":  "Negociação",
	"ganho":       "Ganho",
	"perdido":     "Perdido",
}

const oportunidadeSelectCols = `id, titulo, lead_id, cliente_id, estagio, valor_estimado, moeda, probabilidade,
	to_char(data_fecho_prevista, 'YYYY-MM-DD'), to_char(data_fecho_real, 'YYYY-MM-DD'), motivo_perda,
	responsavel, responsavel_id, descricao, created_at, updated_at`

func scanOportunidade(row pgx.Row) (*Oportunidade, error) {
	var o Oportunidade
	if err := row.Scan(&o.ID, &o.Titulo, &o.LeadID, &o.ClienteID, &o.Estagio, &o.ValorEstimado, &o.Moeda,
		&o.Probabilidade, &o.DataFechoPrevista, &o.DataFechoReal, &o.MotivoPerda,
		&o.Responsavel, &o.ResponsavelID, &o.Descricao, &o.CreatedAt, &o.UpdatedAt); err != nil {
		return nil, err
	}
	return &o, nil
}

// ── Listagem / CRUD ──────────────────────────────────────────────────────────

func (h *Handler) ListarOportunidades(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)

	where := "tenant_id=$1"
	args := []any{user.TenantID}

	if estagio := q.Get("estagio"); estagio != "" {
		args = append(args, estagio)
		where += " AND estagio=$" + strconv.Itoa(len(args))
	}
	if resp := q.Get("responsavel"); resp != "" {
		args = append(args, resp)
		where += " AND responsavel=$" + strconv.Itoa(len(args))
	}
	if respIDStr := q.Get("responsavel_id"); respIDStr != "" {
		if respID, err := strconv.ParseInt(respIDStr, 10, 64); err == nil {
			args = append(args, respID)
			where += " AND responsavel_id=$" + strconv.Itoa(len(args))
		}
	}
	if leadIDStr := q.Get("lead_id"); leadIDStr != "" {
		if leadID, err := strconv.ParseInt(leadIDStr, 10, 64); err == nil {
			args = append(args, leadID)
			where += " AND lead_id=$" + strconv.Itoa(len(args))
		}
	}
	if clienteIDStr := q.Get("cliente_id"); clienteIDStr != "" {
		if clienteID, err := strconv.ParseInt(clienteIDStr, 10, 64); err == nil {
			args = append(args, clienteID)
			where += " AND cliente_id=$" + strconv.Itoa(len(args))
		}
	}
	if s := q.Get("search"); s != "" {
		args = append(args, "%"+s+"%")
		where += " AND titulo ILIKE $" + strconv.Itoa(len(args))
	}

	countArgs := append([]any{}, args...)
	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(),
		"SELECT "+oportunidadeSelectCols+" FROM crm.oportunidades WHERE "+where+
			" ORDER BY created_at DESC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []*Oportunidade{}
	for rows.Next() {
		o, err := scanOportunidade(rows)
		if err == nil {
			data = append(data, o)
		}
	}

	var total int
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM crm.oportunidades WHERE "+where, countArgs...).Scan(&total)
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 {
		page = 1
	}
	jsonOK(w, map[string]any{"data": data, "meta": map[string]int{"total": total, "page": page, "limit": limit}}, http.StatusOK)
}

func (h *Handler) CriarOportunidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body oportunidadeInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Titulo = strings.TrimSpace(body.Titulo)
	if body.Titulo == "" {
		jsonErr(w, "O título é obrigatório.", http.StatusUnprocessableEntity)
		return
	}

	estagio := strDefault(body.Estagio, "novo")
	if _, ok := oportunidadeEstagios[estagio]; !ok {
		jsonErr(w, "Estágio inválido.", http.StatusUnprocessableEntity)
		return
	}

	valor := 0.0
	if body.ValorEstimado != nil {
		if *body.ValorEstimado < 0 {
			jsonErr(w, "O valor estimado não pode ser negativo.", http.StatusUnprocessableEntity)
			return
		}
		valor = *body.ValorEstimado
	}

	probabilidade := int16(0)
	if body.Probabilidade != nil {
		if *body.Probabilidade < 0 || *body.Probabilidade > 100 {
			jsonErr(w, "A probabilidade deve estar entre 0 e 100.", http.StatusUnprocessableEntity)
			return
		}
		probabilidade = *body.Probabilidade
	}

	dataFechoPrevista, ok := parseDateOrNil(body.DataFechoPrevista)
	if !ok {
		jsonErr(w, "Formato de data de fecho prevista inválido.", http.StatusUnprocessableEntity)
		return
	}

	if body.ResponsavelID != nil && body.Responsavel == nil {
		body.Responsavel = h.resolveResponsavelNome(r, *body.ResponsavelID)
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO crm.oportunidades
			(tenant_id, titulo, lead_id, cliente_id, estagio, valor_estimado, moeda, probabilidade,
			 data_fecho_prevista, responsavel, responsavel_id, descricao)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
		RETURNING id`,
		user.TenantID, body.Titulo, body.LeadID, body.ClienteID, estagio, valor,
		strDefault(body.Moeda, "MZN"), probabilidade, dataFechoPrevista,
		body.Responsavel, body.ResponsavelID, body.Descricao,
	).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro ao guardar na base de dados.", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterOportunidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	row := h.db.QueryRow(r.Context(), "SELECT "+oportunidadeSelectCols+" FROM crm.oportunidades WHERE id=$1 AND tenant_id=$2", id, user.TenantID)
	o, err := scanOportunidade(row)
	if err != nil {
		jsonErr(w, "Oportunidade não encontrada.", http.StatusNotFound)
		return
	}
	jsonOK(w, o, http.StatusOK)
}

// ActualizarOportunidade nunca altera o estagio - essa transicao e feita
// exclusivamente via MoverOportunidade e MarcarPerdida.
func (h *Handler) ActualizarOportunidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body oportunidadeInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Titulo = strings.TrimSpace(body.Titulo)
	if body.Titulo == "" {
		jsonErr(w, "O título é obrigatório.", http.StatusUnprocessableEntity)
		return
	}

	valor := 0.0
	if body.ValorEstimado != nil {
		if *body.ValorEstimado < 0 {
			jsonErr(w, "O valor estimado não pode ser negativo.", http.StatusUnprocessableEntity)
			return
		}
		valor = *body.ValorEstimado
	}

	probabilidade := int16(0)
	if body.Probabilidade != nil {
		if *body.Probabilidade < 0 || *body.Probabilidade > 100 {
			jsonErr(w, "A probabilidade deve estar entre 0 e 100.", http.StatusUnprocessableEntity)
			return
		}
		probabilidade = *body.Probabilidade
	}

	dataFechoPrevista, ok := parseDateOrNil(body.DataFechoPrevista)
	if !ok {
		jsonErr(w, "Formato de data de fecho prevista inválido.", http.StatusUnprocessableEntity)
		return
	}

	if body.ResponsavelID != nil && body.Responsavel == nil {
		body.Responsavel = h.resolveResponsavelNome(r, *body.ResponsavelID)
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE crm.oportunidades SET
			titulo=$1, lead_id=$2, cliente_id=$3, valor_estimado=$4, moeda=$5, probabilidade=$6,
			data_fecho_prevista=$7, responsavel=$8, responsavel_id=$9, descricao=$10, updated_at=NOW()
		WHERE id=$11 AND tenant_id=$12`,
		body.Titulo, body.LeadID, body.ClienteID, valor, strDefault(body.Moeda, "MZN"),
		probabilidade, dataFechoPrevista, body.Responsavel, body.ResponsavelID, body.Descricao, id, user.TenantID,
	)
	if err != nil {
		jsonErr(w, "Erro ao actualizar na base de dados.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Oportunidade não encontrada.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverOportunidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), "DELETE FROM crm.oportunidades WHERE id=$1 AND tenant_id=$2", id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao eliminar.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Oportunidade não encontrada.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Pipeline ─────────────────────────────────────────────────────────────────

// MoverOportunidade altera o estagio e regista uma atividade de sistema com a
// transicao, replicando a logica de MoverCandidatura para o pipeline de vendas.
func (h *Handler) MoverOportunidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Estagio string `json:"estagio"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	novoLabel, ok := oportunidadeEstagios[body.Estagio]
	if !ok {
		jsonErr(w, "Estágio inválido.", http.StatusUnprocessableEntity)
		return
	}

	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	var estagioAtual string
	if err := tx.QueryRow(ctx, "SELECT estagio FROM crm.oportunidades WHERE id=$1 AND tenant_id=$2 FOR UPDATE", id, user.TenantID).Scan(&estagioAtual); err != nil {
		jsonErr(w, "Oportunidade não encontrada.", http.StatusNotFound)
		return
	}

	if (estagioAtual == "ganho" || estagioAtual == "perdido") && body.Estagio != estagioAtual {
		jsonErr(w, "Esta oportunidade já está fechada e não pode mudar de estágio.", http.StatusUnprocessableEntity)
		return
	}

	if _, err := tx.Exec(ctx, `
		UPDATE crm.oportunidades SET
			estagio=$1::varchar,
			data_fecho_real = CASE WHEN $1::varchar IN ('ganho','perdido') THEN CURRENT_DATE ELSE data_fecho_real END,
			probabilidade = CASE WHEN $1::varchar='ganho' THEN 100 WHEN $1::varchar='perdido' THEN 0 ELSE probabilidade END,
			updated_at=NOW()
		WHERE id=$2`, body.Estagio, id); err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}

	if estagioAtual != body.Estagio {
		texto := fmt.Sprintf("Estágio alterado: %s → %s", oportunidadeEstagios[estagioAtual], novoLabel)
		if _, err := tx.Exec(ctx,
			"INSERT INTO crm.atividades (tenant_id, oportunidade_id, tipo, titulo, descricao, concluida) VALUES ($1,$2,'nota','Estágio alterado',$3,TRUE)",
			user.TenantID, id, texto); err != nil {
			jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// MarcarPerdida fecha a oportunidade como "perdido", registando o motivo e uma
// atividade de sistema com a transicao.
func (h *Handler) MarcarPerdida(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		MotivoPerda string `json:"motivo_perda"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	motivo := strings.TrimSpace(body.MotivoPerda)

	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	var estagioAtual string
	if err := tx.QueryRow(ctx, "SELECT estagio FROM crm.oportunidades WHERE id=$1 AND tenant_id=$2 FOR UPDATE", id, user.TenantID).Scan(&estagioAtual); err != nil {
		jsonErr(w, "Oportunidade não encontrada.", http.StatusNotFound)
		return
	}
	if estagioAtual == "ganho" || estagioAtual == "perdido" {
		jsonErr(w, "Esta oportunidade já está fechada.", http.StatusUnprocessableEntity)
		return
	}

	if _, err := tx.Exec(ctx, `
		UPDATE crm.oportunidades SET
			estagio='perdido', data_fecho_real=CURRENT_DATE, probabilidade=0,
			motivo_perda=$1, updated_at=NOW()
		WHERE id=$2`, nullIfEmpty(motivo), id); err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}

	texto := fmt.Sprintf("Estágio alterado: %s → Perdido", oportunidadeEstagios[estagioAtual])
	if motivo != "" {
		texto += "\nMotivo: " + motivo
	}
	if _, err := tx.Exec(ctx,
		"INSERT INTO crm.atividades (tenant_id, oportunidade_id, tipo, titulo, descricao, concluida) VALUES ($1,$2,'nota','Estágio alterado',$3,TRUE)",
		user.TenantID, id, texto); err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}
