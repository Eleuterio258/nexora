package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ── Escalões IRPS ──────────────────────────────────────────────────────────

type escalaoIRPS struct {
	ID         int64    `json:"id"`
	AnoFiscal  int      `json:"ano_fiscal"`
	LimiteInf  float64  `json:"limite_inf"`
	LimiteSup  *float64 `json:"limite_sup"`
	Taxa       float64  `json:"taxa"`
	ParcelaAbd float64  `json:"parcela_ded"`
	Ativo      bool     `json:"ativo"`
}

func (h *Handler) ListarEscaloesIRPS(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	ano := r.URL.Query().Get("ano")

	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if ano != "" {
		args = append(args, ano)
		where += " AND ano_fiscal=$2"
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT id, ano_fiscal, limite_inf, limite_sup, taxa, parcela_ded, ativo
		  FROM rh.irps_escaloes WHERE `+where+` ORDER BY ano_fiscal DESC, limite_inf`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data := []escalaoIRPS{}
	for rows.Next() {
		var e escalaoIRPS
		if rows.Scan(&e.ID, &e.AnoFiscal, &e.LimiteInf, &e.LimiteSup, &e.Taxa, &e.ParcelaAbd, &e.Ativo) == nil {
			data = append(data, e)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarEscalaoIRPS(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		AnoFiscal  int      `json:"ano_fiscal"`
		LimiteInf  float64  `json:"limite_inf"`
		LimiteSup  *float64 `json:"limite_sup"`
		Taxa       float64  `json:"taxa"`
		ParcelaAbd float64  `json:"parcela_ded"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.AnoFiscal < 2020 {
		jsonErr(w, "ano_fiscal, limite_inf e taxa são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.irps_escaloes (tenant_id, ano_fiscal, limite_inf, limite_sup, taxa, parcela_ded)
		VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		user.TenantID, body.AnoFiscal, body.LimiteInf, body.LimiteSup, body.Taxa, body.ParcelaAbd,
	).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um escalão com este limite inferior para este ano", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "ok": true, "msg": "Escalão criado com sucesso."}, http.StatusCreated)
}

func (h *Handler) ActualizarEscalaoIRPS(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		LimiteSup  *float64 `json:"limite_sup"`
		Taxa       float64  `json:"taxa"`
		ParcelaAbd float64  `json:"parcela_ded"`
		Ativo      *bool    `json:"ativo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Dados inválidos", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.irps_escaloes
		   SET limite_sup=$1, taxa=$2, parcela_ded=$3, ativo=COALESCE($4,ativo)
		 WHERE id=$5 AND tenant_id=$6`,
		body.LimiteSup, body.Taxa, body.ParcelaAbd, body.Ativo, id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Escalão não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) EliminarEscalaoIRPS(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(), `DELETE FROM rh.irps_escaloes WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Escalão não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// SeedEscaloesIRPSMozambique2024 insere os escalões padrão de Moçambique 2024
// se o tenant ainda não tiver escalões configurados para esse ano.
func (h *Handler) SeedEscaloesIRPSMozambique2024(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var count int
	h.db.QueryRow(r.Context(), `SELECT COUNT(*) FROM rh.irps_escaloes WHERE tenant_id=$1 AND ano_fiscal=2024`, user.TenantID).Scan(&count)
	if count > 0 {
		jsonErr(w, "Já existem escalões configurados para 2024", http.StatusConflict)
		return
	}

	sup3500 := 3500.0
	sup10k := 10000.0
	sup20k := 20000.0
	sup38k := 38000.0
	escaloes := []struct {
		inf, taxa, parc float64
		sup             *float64
	}{
		{0, 0, 0, &sup3500},
		{3500.01, 0.10, 350, &sup10k},
		{10000.01, 0.15, 850, &sup20k},
		{20000.01, 0.20, 1850, &sup38k},
		{38000.01, 0.32, 6410, nil},
	}
	for _, e := range escaloes {
		h.db.Exec(r.Context(), `
			INSERT INTO rh.irps_escaloes (tenant_id, ano_fiscal, limite_inf, limite_sup, taxa, parcela_ded)
			VALUES ($1,2024,$2,$3,$4,$5) ON CONFLICT DO NOTHING`,
			user.TenantID, e.inf, e.sup, e.taxa, e.parc)
	}
	jsonOK(w, map[string]any{"ok": true, "msg": "Escalões IRPS 2024 (Moçambique) configurados."}, http.StatusCreated)
}
