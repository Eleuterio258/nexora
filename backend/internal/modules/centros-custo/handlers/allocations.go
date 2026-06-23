package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

type costCenterAllocationRow struct {
	ID                int64     `json:"id"`
	CostCenterID      int64     `json:"cost_center_id"`
	SourceService     string    `json:"source_service"`
	SourceType        string    `json:"source_type"`
	SourceID          int64     `json:"source_id"`
	SourceLineID      *int64    `json:"source_line_id"`
	Descricao         *string   `json:"descricao"`
	Valor             float64   `json:"valor"`
	Moeda             string    `json:"moeda"`
	AllocationPercent float64   `json:"allocation_percent"`
	ReferenciaTipo    *string   `json:"referencia_tipo"`
	ReferenciaID      *int64    `json:"referencia_id"`
	CreatedAt         time.Time `json:"created_at"`
}

const costCenterAllocationSelect = `
	SELECT id, cost_center_id, source_service, source_type, source_id, source_line_id,
	       descricao, valor, moeda, allocation_percent, referencia_tipo, referencia_id, created_at
	  FROM centros_custo.cost_center_allocations
`

func scanCostCenterAllocations(rows pgx.Rows) []costCenterAllocationRow {
	data := []costCenterAllocationRow{}
	for rows.Next() {
		var a costCenterAllocationRow
		if rows.Scan(&a.ID, &a.CostCenterID, &a.SourceService, &a.SourceType, &a.SourceID, &a.SourceLineID,
			&a.Descricao, &a.Valor, &a.Moeda, &a.AllocationPercent, &a.ReferenciaTipo, &a.ReferenciaID, &a.CreatedAt) == nil {
			data = append(data, a)
		}
	}
	return data
}

func (h *Handler) ListarAlocacoesCC(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("cost_center_id"); v != "" {
		args = append(args, v)
		where += " AND cost_center_id=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("source_service"); v != "" {
		args = append(args, v)
		where += " AND source_service=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("source_type"); v != "" {
		args = append(args, v)
		where += " AND source_type=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("referencia_tipo"); v != "" {
		args = append(args, v)
		where += " AND referencia_tipo=$" + strconv.Itoa(len(args))
	}
	limit, offset := pageParams(r)
	args = append(args, limit, offset)
	limitIdx := strconv.Itoa(len(args) - 1)
	offsetIdx := strconv.Itoa(len(args))
	rows, err := h.db.Query(r.Context(), costCenterAllocationSelect+` WHERE `+where+
		` ORDER BY created_at DESC LIMIT $`+limitIdx+` OFFSET $`+offsetIdx, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	jsonOK(w, scanCostCenterAllocations(rows), http.StatusOK)
}

func (h *Handler) CriarAlocacaoCC(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		CostCenterID      int64    `json:"cost_center_id"`
		SourceService     string   `json:"source_service"`
		SourceType        string   `json:"source_type"`
		SourceID          int64    `json:"source_id"`
		SourceLineID      *int64   `json:"source_line_id"`
		Descricao         *string  `json:"descricao"`
		Valor             *float64 `json:"valor"`
		Moeda             *string  `json:"moeda"`
		AllocationPercent *float64 `json:"allocation_percent"`
		ReferenciaTipo    *string  `json:"referencia_tipo"`
		ReferenciaID      *int64   `json:"referencia_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.CostCenterID == 0 ||
		body.SourceService == "" || body.SourceType == "" || body.SourceID == 0 || body.Valor == nil {
		jsonErr(w, "cost_center_id, source_service, source_type, source_id e valor são obrigatórios", http.StatusBadRequest)
		return
	}
	if *body.Valor < 0 {
		jsonErr(w, "valor não pode ser negativo", http.StatusBadRequest)
		return
	}
	if body.AllocationPercent != nil && (*body.AllocationPercent <= 0 || *body.AllocationPercent > 100) {
		jsonErr(w, "allocation_percent deve estar entre 0 (exclusive) e 100", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO centros_custo.cost_center_allocations
		  (tenant_id, cost_center_id, source_service, source_type, source_id, source_line_id,
		   descricao, valor, moeda, allocation_percent, referencia_tipo, referencia_id, created_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,COALESCE($9,'MZN'),COALESCE($10,100),$11,$12,$13) RETURNING id`,
		user.TenantID, body.CostCenterID, body.SourceService, body.SourceType, body.SourceID, body.SourceLineID,
		body.Descricao, *body.Valor, body.Moeda, body.AllocationPercent, body.ReferenciaTipo, body.ReferenciaID, user.ID).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterAlocacaoCC(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	rows, err := h.db.Query(r.Context(), costCenterAllocationSelect+` WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	alocacoes := scanCostCenterAllocations(rows)
	rows.Close()
	if len(alocacoes) == 0 {
		jsonErr(w, "Alocação não encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, alocacoes[0], http.StatusOK)
}
