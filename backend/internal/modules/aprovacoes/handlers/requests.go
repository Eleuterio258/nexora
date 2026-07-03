package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/auth/audit"
	mw "nexora/internal/middleware"
)

type requestResponse struct {
	ID         int64     `json:"id"`
	TenantID   int64     `json:"tenant_id"`
	FlowID     int64     `json:"flow_id"`
	FlowNome   string    `json:"flow_nome"`
	Feature    string    `json:"feature"`
	Entidade   string    `json:"entidade"`
	EntidadeID int64     `json:"entidade_id"`
	NivelAtual int       `json:"nivel_atual"`
	NivelTotal int       `json:"nivel_total"`
	Estado     string    `json:"estado"`
	CriadoPor  int64     `json:"criado_por"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type decisionRow struct {
	ID          int64     `json:"id"`
	Nivel       int       `json:"nivel"`
	Decisao     string    `json:"decisao"`
	AprovadoPor int64     `json:"aprovado_por"`
	NomeUsuario string    `json:"nome_usuario"`
	Comentario  *string   `json:"comentario"`
	CreatedAt   time.Time `json:"created_at"`
}

// GET /api/aprovacoes/requests?estado=pendente&feature=compras.requisicoes
func (h *Handler) ListarRequests(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	estado := q.Get("estado")
	feature := q.Get("feature")

	query := `
		SELECT ar.id, ar.tenant_id, ar.flow_id, af.nome, af.feature,
		       ar.entidade, ar.entidade_id, ar.nivel_atual,
		       jsonb_array_length(af.niveis) AS nivel_total,
		       ar.estado, ar.criado_por, ar.created_at, ar.updated_at
		  FROM saas.approval_requests ar
		  JOIN saas.approval_flows af ON af.id = ar.flow_id
		 WHERE ar.tenant_id = $1`
	args := []any{user.TenantID}

	if estado != "" {
		args = append(args, estado)
		query += " AND ar.estado = $" + strconv.Itoa(len(args))
	}
	if feature != "" {
		args = append(args, feature)
		query += " AND af.feature = $" + strconv.Itoa(len(args))
	}
	if user.Tipo == "funcionario" {
		args = append(args, user.ID)
		n := strconv.Itoa(len(args))
		query += " AND (ar.criado_por = $" + n +
			" OR EXISTS(SELECT 1 FROM auth.memberships m" +
			" WHERE m.user_id = $" + n + " AND m.tenant_id = ar.tenant_id" +
			" AND (af.niveis->>(ar.nivel_atual-1))::jsonb->>'cargo_id' = m.cargo_id::text))"
	}
	query += " ORDER BY ar.created_at DESC LIMIT 100"

	rows, err := h.db.Query(r.Context(), query, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []requestResponse{}
	for rows.Next() {
		var rr requestResponse
		if rows.Scan(&rr.ID, &rr.TenantID, &rr.FlowID, &rr.FlowNome, &rr.Feature,
			&rr.Entidade, &rr.EntidadeID, &rr.NivelAtual, &rr.NivelTotal,
			&rr.Estado, &rr.CriadoPor, &rr.CreatedAt, &rr.UpdatedAt) == nil {
			data = append(data, rr)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// GET /api/aprovacoes/requests/pendentes-meu-cargo
func (h *Handler) ListarPendentesCargoActual(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT ar.id, ar.tenant_id, ar.flow_id, af.nome, af.feature,
		       ar.entidade, ar.entidade_id, ar.nivel_atual,
		       jsonb_array_length(af.niveis) AS nivel_total,
		       ar.estado, ar.criado_por, ar.created_at, ar.updated_at
		  FROM saas.approval_requests ar
		  JOIN saas.approval_flows af ON af.id = ar.flow_id
		  JOIN auth.memberships m ON m.user_id = $1 AND m.tenant_id = $2
		 WHERE ar.tenant_id = $2
		   AND ar.estado = 'pendente'
		   AND (af.niveis->>(ar.nivel_atual-1))::jsonb->>'cargo_id' = m.cargo_id::text
		 ORDER BY ar.created_at ASC`, user.ID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []requestResponse{}
	for rows.Next() {
		var rr requestResponse
		if rows.Scan(&rr.ID, &rr.TenantID, &rr.FlowID, &rr.FlowNome, &rr.Feature,
			&rr.Entidade, &rr.EntidadeID, &rr.NivelAtual, &rr.NivelTotal,
			&rr.Estado, &rr.CriadoPor, &rr.CreatedAt, &rr.UpdatedAt) == nil {
			data = append(data, rr)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// GET /api/aprovacoes/requests/{id}
func (h *Handler) ObterRequest(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var rr requestResponse
	err := h.db.QueryRow(r.Context(), `
		SELECT ar.id, ar.tenant_id, ar.flow_id, af.nome, af.feature,
		       ar.entidade, ar.entidade_id, ar.nivel_atual,
		       jsonb_array_length(af.niveis) AS nivel_total,
		       ar.estado, ar.criado_por, ar.created_at, ar.updated_at
		  FROM saas.approval_requests ar
		  JOIN saas.approval_flows af ON af.id = ar.flow_id
		 WHERE ar.id = $1 AND ar.tenant_id = $2`, id, user.TenantID).
		Scan(&rr.ID, &rr.TenantID, &rr.FlowID, &rr.FlowNome, &rr.Feature,
			&rr.Entidade, &rr.EntidadeID, &rr.NivelAtual, &rr.NivelTotal,
			&rr.Estado, &rr.CriadoPor, &rr.CreatedAt, &rr.UpdatedAt)
	if err != nil {
		jsonErr(w, "Pedido não encontrado", http.StatusNotFound)
		return
	}

	dRows, _ := h.db.Query(r.Context(), `
		SELECT ad.id, ad.nivel, ad.decisao, ad.aprovado_por, u.nome, ad.comentario, ad.created_at
		  FROM saas.approval_decisions ad
		  JOIN auth.users u ON u.id = ad.aprovado_por
		 WHERE ad.request_id = $1
		 ORDER BY ad.nivel, ad.created_at`, id)
	decisions := []decisionRow{}
	if dRows != nil {
		defer dRows.Close()
		for dRows.Next() {
			var d decisionRow
			if dRows.Scan(&d.ID, &d.Nivel, &d.Decisao, &d.AprovadoPor, &d.NomeUsuario, &d.Comentario, &d.CreatedAt) == nil {
				decisions = append(decisions, d)
			}
		}
	}
	jsonOK(w, map[string]any{"request": rr, "decisions": decisions}, http.StatusOK)
}

// POST /api/aprovacoes/requests/{id}/decidir
// Corpo: { "decisao": "aprovado"|"rejeitado", "comentario": "..." }
func (h *Handler) DecidirRequest(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Decisao    string  `json:"decisao"`
		Comentario *string `json:"comentario"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil ||
		(body.Decisao != "aprovado" && body.Decisao != "rejeitado") {
		jsonErr(w, "decisao deve ser 'aprovado' ou 'rejeitado'", http.StatusBadRequest)
		return
	}

	var flowID int64
	var nivelAtual int
	var niveis []byte
	var entidade string
	var entidadeID int64
	err := h.db.QueryRow(r.Context(), `
		SELECT ar.flow_id, ar.nivel_atual, af.niveis, ar.entidade, ar.entidade_id
		  FROM saas.approval_requests ar
		  JOIN saas.approval_flows af ON af.id = ar.flow_id
		 WHERE ar.id = $1 AND ar.tenant_id = $2 AND ar.estado = 'pendente'`,
		id, user.TenantID).
		Scan(&flowID, &nivelAtual, &niveis, &entidade, &entidadeID)
	if err != nil {
		jsonErr(w, "Pedido não encontrado ou já processado", http.StatusNotFound)
		return
	}

	var cargoIDStr *string
	h.db.QueryRow(r.Context(),
		`SELECT cargo_id::text FROM auth.memberships WHERE user_id = $1 AND tenant_id = $2`,
		user.ID, user.TenantID).Scan(&cargoIDStr)

	if !podeDecidir(niveis, nivelAtual, cargoIDStr) {
		jsonErr(w, "Não tem permissão para decidir neste nível de aprovação", http.StatusForbidden)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	if _, err := tx.Exec(r.Context(), `
		INSERT INTO saas.approval_decisions (request_id, nivel, decisao, aprovado_por, comentario)
		VALUES ($1, $2, $3, $4, $5)`,
		id, nivelAtual, body.Decisao, user.ID, body.Comentario); err != nil {
		jsonErr(w, "Erro ao registar decisão", http.StatusInternalServerError)
		return
	}

	// totalNiveis calculado a partir dos niveis já lidos — sem query extra e sem race condition
	var niveisArr []json.RawMessage
	json.Unmarshal(niveis, &niveisArr)
	totalNiveis := len(niveisArr)

	if body.Decisao == "rejeitado" {
		if _, err := tx.Exec(r.Context(),
			`UPDATE saas.approval_requests SET estado='rejeitado', updated_at=NOW() WHERE id=$1`, id); err != nil {
			jsonErr(w, "Erro ao actualizar estado", http.StatusInternalServerError)
			return
		}
		atualizarEstadoEntidade(r.Context(), tx, entidade, entidadeID, "rejeitada")
	} else {
		if nivelAtual >= totalNiveis {
			if _, err := tx.Exec(r.Context(),
				`UPDATE saas.approval_requests SET estado='aprovado', updated_at=NOW() WHERE id=$1`, id); err != nil {
				jsonErr(w, "Erro ao actualizar estado", http.StatusInternalServerError)
				return
			}
			atualizarEstadoEntidade(r.Context(), tx, entidade, entidadeID, "aprovada")
		} else {
			if _, err := tx.Exec(r.Context(),
				`UPDATE saas.approval_requests SET nivel_atual=$1, updated_at=NOW() WHERE id=$2`,
				nivelAtual+1, id); err != nil {
				jsonErr(w, "Erro ao avançar nível", http.StatusInternalServerError)
				return
			}
		}
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro ao guardar decisão", http.StatusInternalServerError)
		return
	}

	_ = audit.LogRequest(r, h.db, audit.Entry{
		UserID:    user.ID,
		TenantID:  user.TenantID,
		Acao:      "decidir",
		Modulo:    "aprovacoes",
		Recurso:   "approval_request",
		RecursoID: id,
		Detalhes:  map[string]any{"decisao": body.Decisao, "nivel": nivelAtual},
	})

	h.ObterRequest(w, r)
}

// POST /api/aprovacoes/requests/{id}/cancelar
func (h *Handler) CancelarRequest(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), `
		UPDATE saas.approval_requests
		   SET estado='cancelado', updated_at=NOW()
		 WHERE id=$1 AND tenant_id=$2 AND criado_por=$3 AND estado='pendente'`,
		id, user.TenantID, user.ID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Pedido não encontrado, já processado, ou não é o criador", http.StatusNotFound)
		return
	}
	_ = audit.LogRequest(r, h.db, audit.Entry{
		UserID:    user.ID,
		TenantID:  user.TenantID,
		Acao:      "cancelar",
		Modulo:    "aprovacoes",
		Recurso:   "approval_request",
		RecursoID: id,
	})
	w.WriteHeader(http.StatusNoContent)
}

// ── Helpers ────────────────────────────────────────────────────────────────────

// atualizarEstadoEntidade actualiza o status da entidade originadora quando o fluxo termina.
func atualizarEstadoEntidade(ctx context.Context, tx pgx.Tx, entidade string, id int64, estado string) {
	switch entidade {
	case "compras.purchase_requests":
		tx.Exec(ctx, `UPDATE compras.purchase_requests SET status=$1, updated_at=NOW() WHERE id=$2`, estado, id)

	case "gestao_escolar.school_fees":
		if estado == "aprovado" {
			// Aplicar o desconto pendente que foi guardado aquando da submissão
			tx.Exec(ctx, `
				UPDATE gestao_escolar.school_fees
				   SET desconto                = COALESCE(desconto, 0) + COALESCE(desconto_pendente, 0),
				       desconto_motivo         = desconto_pendente_motivo,
				       desconto_pendente       = NULL,
				       desconto_pendente_motivo = NULL,
				       valor_pago             = LEAST(valor_pago + COALESCE(desconto_pendente, 0), valor_total),
				       status                 = CASE
				           WHEN (valor_total - COALESCE(desconto, 0) - COALESCE(desconto_pendente, 0)) <= valor_pago
				               THEN 'paga'
				               ELSE status
				           END,
				       updated_at             = NOW()
				 WHERE id = $1 AND desconto_pendente IS NOT NULL`, id)
		} else {
			// Rejeitado: limpar desconto pendente
			tx.Exec(ctx, `
				UPDATE gestao_escolar.school_fees
				   SET desconto_pendente       = NULL,
				       desconto_pendente_motivo = NULL,
				       updated_at             = NOW()
				 WHERE id = $1`, id)
		}
	}
}

// podeDecidir verifica se o cargoID do utilizador corresponde ao cargo do nível actual.
func podeDecidir(niveis []byte, nivelAtual int, cargoIDStr *string) bool {
	if cargoIDStr == nil {
		return false
	}
	var arr []map[string]any
	if err := json.Unmarshal(niveis, &arr); err != nil || len(arr) < nivelAtual {
		return false
	}
	nivel := arr[nivelAtual-1]
	switch v := nivel["cargo_id"].(type) {
	case float64:
		return strconv.FormatInt(int64(v), 10) == *cargoIDStr
	case string:
		return v == *cargoIDStr
	}
	return false
}
