package handlers

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

// ListarPedidosCorrecaoPendentes lista os pedidos de correcção de ponto
// pendentes de decisão, para a fila de aprovação de RH.
func (h *Handler) ListarPedidosCorrecaoPendentes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	type row struct {
		ID              int64     `json:"id"`
		FuncionarioID   int64     `json:"funcionario_id"`
		FuncionarioNome string    `json:"funcionario_nome"`
		PresencaID      *int64    `json:"presenca_id"`
		Data            time.Time `json:"data"`
		HoraEntrada     *string   `json:"hora_entrada_solicitada"`
		HoraSaida       *string   `json:"hora_saida_solicitada"`
		Motivo          string    `json:"motivo"`
		CreatedAt       time.Time `json:"created_at"`
	}
	rows, _ := h.db.Query(r.Context(), `
		SELECT c.id, c.funcionario_id, f.nome, c.presenca_id, c.data,
		       c.hora_entrada_solicitada, c.hora_saida_solicitada, c.motivo, c.created_at
		  FROM rh.pedidos_correcao_ponto c
		  JOIN rh.funcionarios f ON f.id = c.funcionario_id
		 WHERE c.tenant_id=$1 AND c.estado='pendente'
		 ORDER BY c.data ASC`, user.TenantID)
	if rows == nil {
		jsonOK(w, []row{}, http.StatusOK)
		return
	}
	defer rows.Close()

	data := []row{}
	for rows.Next() {
		var p row
		if rows.Scan(&p.ID, &p.FuncionarioID, &p.FuncionarioNome, &p.PresencaID, &p.Data,
			&p.HoraEntrada, &p.HoraSaida, &p.Motivo, &p.CreatedAt) == nil {
			data = append(data, p)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// AprovarPedidoCorrecao aprova um pedido pendente e aplica as horas propostas
// ao registo de presença do dia (cria o registo se ainda não existir).
func (h *Handler) AprovarPedidoCorrecao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var funcionarioID int64
	var data time.Time
	var horaEntrada, horaSaida *string
	if err := h.db.QueryRow(r.Context(), `
		SELECT funcionario_id, data, hora_entrada_solicitada, hora_saida_solicitada
		  FROM rh.pedidos_correcao_ponto WHERE id=$1 AND tenant_id=$2 AND estado='pendente'`,
		id, user.TenantID).Scan(&funcionarioID, &data, &horaEntrada, &horaSaida); err != nil {
		jsonErr(w, "Pedido não encontrado ou já processado", http.StatusConflict)
		return
	}

	if !h.podeGerirFuncionario(r, funcionarioID) {
		jsonErr(w, "Sem permissão para aprovar este pedido", http.StatusForbidden)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.pedidos_correcao_ponto SET estado='aprovado', decidido_por=$1, decidido_em=NOW()
		 WHERE id=$2 AND tenant_id=$3 AND estado='pendente'`,
		user.ID, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Pedido já foi processado", http.StatusConflict)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
		INSERT INTO rh.presencas (tenant_id, funcionario_id, data, hora_entrada, hora_saida)
		VALUES ($1,$2,$3,$4,$5)
		ON CONFLICT (funcionario_id, data) DO UPDATE
		   SET hora_entrada = COALESCE(EXCLUDED.hora_entrada, rh.presencas.hora_entrada),
		       hora_saida   = COALESCE(EXCLUDED.hora_saida, rh.presencas.hora_saida)`,
		user.TenantID, funcionarioID, data, horaEntrada, horaSaida); err != nil {
		jsonErr(w, "Pedido aprovado mas falhou ao actualizar a presença", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// RejeitarPedidoCorrecao rejeita um pedido de correcção de ponto pendente.
func (h *Handler) RejeitarPedidoCorrecao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var funcionarioID int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT funcionario_id FROM rh.pedidos_correcao_ponto WHERE id=$1 AND tenant_id=$2 AND estado='pendente'`,
		id, user.TenantID).Scan(&funcionarioID); err != nil {
		jsonErr(w, "Pedido não encontrado ou já processado", http.StatusConflict)
		return
	}

	if !h.podeGerirFuncionario(r, funcionarioID) {
		jsonErr(w, "Sem permissão para rejeitar este pedido", http.StatusForbidden)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.pedidos_correcao_ponto SET estado='rejeitado', decidido_por=$1, decidido_em=NOW()
		 WHERE id=$2 AND tenant_id=$3 AND estado='pendente'`,
		user.ID, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Pedido já foi processado", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
