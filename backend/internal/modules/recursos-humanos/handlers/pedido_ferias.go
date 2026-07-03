package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

// ListarMeusPedidosFerias devolve os pedidos de férias/ausências do funcionário
// ligado ao utilizador autenticado.
func (h *Handler) ListarMeusPedidosFerias(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var funcionarioID int64
	err := h.db.QueryRow(r.Context(), `
		SELECT id FROM rh.funcionarios WHERE user_id=$1 AND tenant_id=$2`,
		user.ID, user.TenantID).Scan(&funcionarioID)
	if err != nil {
		jsonErr(w, "Funcionário não encontrado para este utilizador", http.StatusNotFound)
		return
	}

	rows, _ := h.db.Query(r.Context(), `
		SELECT a.id, ta.nome, a.data_inicio, a.data_fim, a.dias, a.motivo, a.estado, a.created_at
		  FROM rh.ausencias a
		  LEFT JOIN rh.tipos_ausencia ta ON ta.id = a.tipo_id
		 WHERE a.funcionario_id=$1 AND a.tenant_id=$2
		 ORDER BY a.created_at DESC`, funcionarioID, user.TenantID)
	defer rows.Close()

	type Row struct {
		ID         int64      `json:"id"`
		TipoNome   *string    `json:"tipo_nome"`
		DataInicio time.Time  `json:"data_inicio"`
		DataFim    time.Time  `json:"data_fim"`
		Dias       *int       `json:"dias"`
		Motivo     *string    `json:"motivo"`
		Estado     string     `json:"estado"`
		CriadoEm  time.Time  `json:"criado_em"`
	}
	data := []Row{}
	for rows.Next() {
		var a Row
		if rows.Scan(&a.ID, &a.TipoNome, &a.DataInicio, &a.DataFim, &a.Dias, &a.Motivo, &a.Estado, &a.CriadoEm) == nil {
			data = append(data, a)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// CriarMeuPedidoFerias cria um pedido de ausência para o próprio utilizador.
func (h *Handler) CriarMeuPedidoFerias(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var funcionarioID int64
	err := h.db.QueryRow(r.Context(), `
		SELECT id FROM rh.funcionarios WHERE user_id=$1 AND tenant_id=$2`,
		user.ID, user.TenantID).Scan(&funcionarioID)
	if err != nil {
		jsonErr(w, "Funcionário não encontrado para este utilizador", http.StatusNotFound)
		return
	}

	var body struct {
		TipoID     int64   `json:"tipo_id"`
		DataInicio string  `json:"data_inicio"`
		DataFim    string  `json:"data_fim"`
		Motivo     *string `json:"motivo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.TipoID == 0 || body.DataInicio == "" || body.DataFim == "" {
		jsonErr(w, "tipo_id, data_inicio e data_fim são obrigatórios", http.StatusBadRequest)
		return
	}

	var tipoExiste bool
	if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM rh.tipos_ausencia WHERE id=$1 AND tenant_id=$2 AND ativo)`, body.TipoID, user.TenantID).Scan(&tipoExiste); err != nil || !tipoExiste {
		jsonErr(w, "Tipo de ausência inválido", http.StatusBadRequest)
		return
	}

	inicio, err1 := time.Parse("2006-01-02", body.DataInicio)
	fim, err2 := time.Parse("2006-01-02", body.DataFim)
	if err1 != nil || err2 != nil || fim.Before(inicio) {
		jsonErr(w, "data_fim deve ser igual ou posterior a data_inicio", http.StatusBadRequest)
		return
	}
	dias := businessDays(inicio, fim)

	var id int64
	if err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.ausencias (tenant_id, funcionario_id, tipo_id, data_inicio, data_fim, dias, motivo, estado)
		VALUES ($1,$2,$3,$4::date,$5::date,$6,$7,'pendente') RETURNING id`,
		user.TenantID, funcionarioID, body.TipoID, body.DataInicio, body.DataFim, dias, body.Motivo).Scan(&id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// CancelarMeuPedidoFerias cancela um pedido pendente do próprio utilizador.
func (h *Handler) CancelarMeuPedidoFerias(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var funcionarioID int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT id FROM rh.funcionarios WHERE user_id=$1 AND tenant_id=$2`,
		user.ID, user.TenantID).Scan(&funcionarioID); err != nil {
		jsonErr(w, "Funcionário não encontrado para este utilizador", http.StatusNotFound)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.ausencias SET estado='cancelado'
		 WHERE id=$1 AND tenant_id=$2 AND funcionario_id=$3 AND estado='pendente'`,
		id, user.TenantID, funcionarioID)
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
