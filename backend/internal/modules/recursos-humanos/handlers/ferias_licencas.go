package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

// ── Tipos de Ausência: catálogo configurável ────────────────────────────────

type tipoAusenciaRow struct {
	ID         int64    `json:"id"`
	Codigo     string   `json:"codigo"`
	Nome       string   `json:"nome"`
	DiasAnuais *float64 `json:"dias_anuais"`
	Remunerada bool     `json:"remunerada"`
	AfetaSaldo bool     `json:"afeta_saldo"`
	Ativo      bool     `json:"ativo"`
	NumPedidos int      `json:"num_pedidos"`
}

func (h *Handler) ListarTiposAusencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT t.id, t.codigo, t.nome, t.dias_anuais, t.remunerada, t.afeta_saldo, t.ativo,
		       (SELECT COUNT(*) FROM rh.ausencias a WHERE a.tipo_id = t.id)
		  FROM rh.tipos_ausencia t
		 WHERE t.tenant_id=$1
		 ORDER BY t.nome`, user.TenantID)
	defer rows.Close()
	data := []tipoAusenciaRow{}
	for rows.Next() {
		var t tipoAusenciaRow
		if rows.Scan(&t.ID, &t.Codigo, &t.Nome, &t.DiasAnuais, &t.Remunerada, &t.AfetaSaldo, &t.Ativo, &t.NumPedidos) == nil {
			data = append(data, t)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarTipoAusencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo     string   `json:"codigo"`
		Nome       string   `json:"nome"`
		DiasAnuais *float64 `json:"dias_anuais"`
		Remunerada *bool    `json:"remunerada"`
		AfetaSaldo *bool    `json:"afeta_saldo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "código e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	remunerada := true
	if body.Remunerada != nil {
		remunerada = *body.Remunerada
	}
	afetaSaldo := false
	if body.AfetaSaldo != nil {
		afetaSaldo = *body.AfetaSaldo
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.tipos_ausencia (tenant_id, codigo, nome, dias_anuais, remunerada, afeta_saldo)
		VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.DiasAnuais, remunerada, afetaSaldo).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um tipo de ausência com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarTipoAusencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Codigo     *string  `json:"codigo"`
		Nome       *string  `json:"nome"`
		DiasAnuais *float64 `json:"dias_anuais"`
		Remunerada *bool    `json:"remunerada"`
		AfetaSaldo *bool    `json:"afeta_saldo"`
		Ativo      *bool    `json:"ativo"`
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
		UPDATE rh.tipos_ausencia SET
		  codigo=COALESCE($1,codigo), nome=COALESCE($2,nome), dias_anuais=COALESCE($3,dias_anuais),
		  remunerada=COALESCE($4,remunerada), afeta_saldo=COALESCE($5,afeta_saldo),
		  ativo=COALESCE($6,ativo), updated_at=NOW()
		WHERE id=$7 AND tenant_id=$8`,
		body.Codigo, body.Nome, body.DiasAnuais, body.Remunerada, body.AfetaSaldo, body.Ativo, id, user.TenantID)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um tipo de ausência com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Tipo de ausência não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverTipoAusencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var emUso bool
	if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM rh.ausencias WHERE tipo_id=$1 AND tenant_id=$2)`, id, user.TenantID).Scan(&emUso); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if emUso {
		jsonErr(w, "Não é possível eliminar um tipo de ausência associado a pedidos existentes", http.StatusConflict)
		return
	}

	tag, err := h.db.Exec(r.Context(), `DELETE FROM rh.tipos_ausencia WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Tipo de ausência não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Saldos de férias/licenças por funcionário ───────────────────────────────

type saldoAusenciaRow struct {
	TipoAusenciaID int64   `json:"tipo_ausencia_id"`
	TipoNome       string  `json:"tipo_nome"`
	Ano            int     `json:"ano"`
	DiasAtribuidos float64 `json:"dias_atribuidos"`
	DiasUsados     float64 `json:"dias_usados"`
}

func (h *Handler) ListarSaldosAusenciaFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	ano := time.Now().Year()
	if v := r.URL.Query().Get("ano"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			ano = n
		}
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT t.id, t.nome, $3::int, COALESCE(s.dias_atribuidos, 0), COALESCE(s.dias_usados, 0)
		  FROM rh.tipos_ausencia t
		  LEFT JOIN rh.saldos_ausencia s ON s.tipo_ausencia_id = t.id AND s.funcionario_id = $1 AND s.ano = $3
		 WHERE t.tenant_id=$2 AND t.afeta_saldo AND t.ativo
		 ORDER BY t.nome`, funcionarioID, user.TenantID, ano)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []saldoAusenciaRow{}
	for rows.Next() {
		var s saldoAusenciaRow
		if rows.Scan(&s.TipoAusenciaID, &s.TipoNome, &s.Ano, &s.DiasAtribuidos, &s.DiasUsados) == nil {
			data = append(data, s)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) DefinirSaldoAusencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	var body struct {
		TipoAusenciaID int64    `json:"tipo_ausencia_id"`
		Ano            int      `json:"ano"`
		DiasAtribuidos *float64 `json:"dias_atribuidos"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.TipoAusenciaID == 0 || body.Ano == 0 || body.DiasAtribuidos == nil {
		jsonErr(w, "tipo_ausencia_id, ano e dias_atribuidos são obrigatórios", http.StatusBadRequest)
		return
	}

	var existe bool
	if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM rh.tipos_ausencia WHERE id=$1 AND tenant_id=$2)`, body.TipoAusenciaID, user.TenantID).Scan(&existe); err != nil || !existe {
		jsonErr(w, "Tipo de ausência inválido", http.StatusBadRequest)
		return
	}

	_, err := h.db.Exec(r.Context(), `
		INSERT INTO rh.saldos_ausencia (tenant_id, funcionario_id, tipo_ausencia_id, ano, dias_atribuidos)
		VALUES ($1,$2,$3,$4,$5)
		ON CONFLICT (funcionario_id, tipo_ausencia_id, ano) DO UPDATE SET
		  dias_atribuidos=EXCLUDED.dias_atribuidos, updated_at=NOW()`,
		user.TenantID, funcionarioID, body.TipoAusenciaID, body.Ano, *body.DiasAtribuidos)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ajustarSaldoAusencia soma delta (pode ser negativo) aos dias usados do
// saldo de férias/licenças do funcionário para o tipo e ano indicados,
// criando o registo de saldo se ainda não existir.
func (h *Handler) ajustarSaldoAusencia(ctx context.Context, tenantID, funcionarioID, tipoAusenciaID int64, ano int, delta float64) {
	h.db.Exec(ctx, `
		INSERT INTO rh.saldos_ausencia (tenant_id, funcionario_id, tipo_ausencia_id, ano, dias_usados)
		VALUES ($1,$2,$3,$4,GREATEST($5,0))
		ON CONFLICT (funcionario_id, tipo_ausencia_id, ano) DO UPDATE SET
		  dias_usados=GREATEST(saldos_ausencia.dias_usados + $5, 0), updated_at=NOW()`,
		tenantID, funcionarioID, tipoAusenciaID, ano, delta)
}

// ── Ausências: transições de estado gozada / cancelada ──────────────────────

func (h *Handler) MarcarAusenciaGozada(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var funcionarioID int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT funcionario_id FROM rh.ausencias WHERE id=$1 AND tenant_id=$2 AND estado='aprovado'`,
		id, user.TenantID).Scan(&funcionarioID); err != nil {
		jsonErr(w, "Pedido não encontrado ou não está aprovado", http.StatusConflict)
		return
	}

	if !h.podeGerirFuncionario(r, funcionarioID) {
		jsonErr(w, "Sem permissão para alterar este pedido", http.StatusForbidden)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.ausencias SET estado='gozada' WHERE id=$1 AND tenant_id=$2 AND estado='aprovado'`,
		id, user.TenantID)
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

func (h *Handler) CancelarAusencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var funcionarioID int64
	var tipoID *int64
	var dias *int
	var dataInicio time.Time
	var estadoAnterior string
	if err := h.db.QueryRow(r.Context(), `
		SELECT funcionario_id, tipo_id, dias, data_inicio, estado FROM rh.ausencias
		 WHERE id=$1 AND tenant_id=$2 AND estado IN ('pendente','aprovado')`,
		id, user.TenantID).Scan(&funcionarioID, &tipoID, &dias, &dataInicio, &estadoAnterior); err != nil {
		jsonErr(w, "Pedido não encontrado ou não pode ser cancelado", http.StatusConflict)
		return
	}

	if !h.podeGerirFuncionario(r, funcionarioID) {
		jsonErr(w, "Sem permissão para cancelar este pedido", http.StatusForbidden)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.ausencias SET estado='cancelada' WHERE id=$1 AND tenant_id=$2 AND estado IN ('pendente','aprovado')`,
		id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Pedido já foi processado", http.StatusConflict)
		return
	}

	if estadoAnterior == "aprovado" && tipoID != nil && dias != nil {
		var afetaSaldo bool
		if h.db.QueryRow(r.Context(), `SELECT afeta_saldo FROM rh.tipos_ausencia WHERE id=$1`, *tipoID).Scan(&afetaSaldo) == nil && afetaSaldo {
			h.ajustarSaldoAusencia(r.Context(), user.TenantID, funcionarioID, *tipoID, dataInicio.Year(), -float64(*dias))
		}
	}

	w.WriteHeader(http.StatusNoContent)
}
