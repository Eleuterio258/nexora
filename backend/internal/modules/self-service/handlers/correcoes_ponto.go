package handlers

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

// CriarPedidoCorrecao submete um pedido de correcção de ponto: o colaborador
// aponta o dia (e, se souber, o registo de presença) e propõe as horas
// correctas. Distinto de uma justificação de falta/atraso — aqui há sempre
// uma proposta de hora_entrada/hora_saida a validar por RH.
func (h *Handler) CriarPedidoCorrecao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcID, ok := h.funcionarioID(r)
	if !ok {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}

	var body struct {
		PresencaID  *int64  `json:"presenca_id"`
		Data        string  `json:"data"`
		HoraEntrada *string `json:"hora_entrada_solicitada"`
		HoraSaida   *string `json:"hora_saida_solicitada"`
		Motivo      string  `json:"motivo"`
	}
	if err := decodeJSON(r, &body); err != nil || body.Data == "" || body.Motivo == "" {
		jsonErr(w, "data e motivo são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.HoraEntrada == nil && body.HoraSaida == nil {
		jsonErr(w, "hora_entrada_solicitada ou hora_saida_solicitada são obrigatórias", http.StatusBadRequest)
		return
	}

	// Se indicado, o presenca_id tem de pertencer mesmo a este funcionário.
	if body.PresencaID != nil {
		var dono int64
		if err := h.db.QueryRow(r.Context(),
			`SELECT funcionario_id FROM rh.presencas WHERE id=$1 AND tenant_id=$2`,
			*body.PresencaID, user.TenantID).Scan(&dono); err != nil || dono != funcID {
			jsonErr(w, "Registo de presença inválido", http.StatusBadRequest)
			return
		}
	}

	var id int64
	if err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.pedidos_correcao_ponto
			(tenant_id, funcionario_id, presenca_id, data, hora_entrada_solicitada, hora_saida_solicitada, motivo)
		VALUES ($1,$2,$3,$4::date,$5,$6,$7) RETURNING id`,
		user.TenantID, funcID, body.PresencaID, body.Data, body.HoraEntrada, body.HoraSaida, body.Motivo,
	).Scan(&id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ListarPedidosCorrecao lista os pedidos de correcção de ponto do colaborador
// autenticado (mais recentes primeiro).
func (h *Handler) ListarPedidosCorrecao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcID, ok := h.funcionarioID(r)
	if !ok {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}

	type row struct {
		ID          int64     `json:"id"`
		PresencaID  *int64    `json:"presenca_id"`
		Data        time.Time `json:"data"`
		HoraEntrada *string   `json:"hora_entrada_solicitada"`
		HoraSaida   *string   `json:"hora_saida_solicitada"`
		Motivo      string    `json:"motivo"`
		Estado      string    `json:"estado"`
		CreatedAt   time.Time `json:"created_at"`
	}
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, presenca_id, data, hora_entrada_solicitada, hora_saida_solicitada, motivo, estado, created_at
		  FROM rh.pedidos_correcao_ponto
		 WHERE funcionario_id=$1 AND tenant_id=$2
		 ORDER BY data DESC LIMIT 50`, funcID, user.TenantID)
	if rows == nil {
		jsonOK(w, []row{}, http.StatusOK)
		return
	}
	defer rows.Close()

	data := []row{}
	for rows.Next() {
		var p row
		if rows.Scan(&p.ID, &p.PresencaID, &p.Data, &p.HoraEntrada, &p.HoraSaida, &p.Motivo, &p.Estado, &p.CreatedAt) == nil {
			data = append(data, p)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// CancelarPedidoCorrecao cancela um pedido de correcção ainda pendente,
// submetido pelo próprio colaborador.
func (h *Handler) CancelarPedidoCorrecao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcID, ok := h.funcionarioID(r)
	if !ok {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.pedidos_correcao_ponto SET estado='cancelado'
		 WHERE id=$1 AND tenant_id=$2 AND funcionario_id=$3 AND estado='pendente'`,
		id, user.TenantID, funcID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Pedido não encontrado ou já processado", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
