package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

// ── Assiduidade: presenças e horas extra ────────────────────────────────────

// ListarPresencasPorTipo lista presenças de toda a equipa (não só um
// funcionário) filtradas por `tipo` (atraso/falta/presente/saida_antecipada)
// — alimenta o ecrã "Ocorrências/Alertas" do app de gestor, que precisa de
// ver atrasos/faltas cross-equipa, algo que `ListarPresencas` (por
// funcionário) e `GET /api/rh/funcionarios/{id}/presencas` não cobrem.
//
// Query params: `tipo` (lista separada por vírgulas, ex. "atraso,falta"),
// `data_inicio`/`data_fim` (YYYY-MM-DD), `unit_id`.
func (h *Handler) ListarPresencasPorTipo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()

	where := "p.tenant_id=$1"
	args := []any{user.TenantID}

	if v := q.Get("tipo"); v != "" {
		tipos := strings.Split(v, ",")
		placeholders := make([]string, 0, len(tipos))
		for _, t := range tipos {
			args = append(args, strings.TrimSpace(t))
			placeholders = append(placeholders, "$"+strconv.Itoa(len(args)))
		}
		where += " AND p.tipo IN (" + strings.Join(placeholders, ",") + ")"
	}
	if v := q.Get("data_inicio"); v != "" {
		args = append(args, v)
		where += " AND p.data >= $" + strconv.Itoa(len(args))
	}
	if v := q.Get("data_fim"); v != "" {
		args = append(args, v)
		where += " AND p.data <= $" + strconv.Itoa(len(args))
	}
	if v := q.Get("unit_id"); v != "" {
		args = append(args, v)
		where += " AND f.unit_id = $" + strconv.Itoa(len(args))
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT p.id, p.funcionario_id, f.nome_completo, f.unit_id, u.nome,
		       p.data, p.hora_entrada, p.hora_saida, p.tipo, p.observacoes
		  FROM rh.presencas p
		  JOIN rh.funcionarios f ON f.id = p.funcionario_id
		  LEFT JOIN rh.unidades_organizacionais u ON u.id = f.unit_id
		 WHERE `+where+`
		 ORDER BY p.data DESC, f.nome_completo`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID             int64     `json:"id"`
		FuncionarioID  int64     `json:"funcionario_id"`
		FuncionarioNome string   `json:"funcionario_nome"`
		UnitID         *int64    `json:"unit_id"`
		UnidadeNome    *string   `json:"unidade_nome"`
		Data           time.Time `json:"data"`
		HoraEntrada    *string   `json:"hora_entrada"`
		HoraSaida      *string   `json:"hora_saida"`
		Tipo           *string   `json:"tipo"`
		Observacoes    *string   `json:"observacoes"`
	}
	data := []Row{}
	for rows.Next() {
		var p Row
		if rows.Scan(&p.ID, &p.FuncionarioID, &p.FuncionarioNome, &p.UnitID, &p.UnidadeNome,
			&p.Data, &p.HoraEntrada, &p.HoraSaida, &p.Tipo, &p.Observacoes) == nil {
			data = append(data, p)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) ListarPresencas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), `
		SELECT id, data, hora_entrada, hora_saida, horas_extra, observacoes
		  FROM rh.presencas
		 WHERE funcionario_id=$1 AND tenant_id=$2
		 ORDER BY data DESC`, funcionarioID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID          int64     `json:"id"`
		Data        time.Time `json:"data"`
		HoraEntrada *string   `json:"hora_entrada"`
		HoraSaida   *string   `json:"hora_saida"`
		HorasExtra  float64   `json:"horas_extra"`
		Observacoes *string   `json:"observacoes"`
	}
	data := []Row{}
	for rows.Next() {
		var p Row
		if rows.Scan(&p.ID, &p.Data, &p.HoraEntrada, &p.HoraSaida, &p.HorasExtra, &p.Observacoes) == nil {
			data = append(data, p)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarPresenca(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	var body struct {
		Data        string   `json:"data"`
		HoraEntrada *string  `json:"hora_entrada"`
		HoraSaida   *string  `json:"hora_saida"`
		HorasExtra  *float64 `json:"horas_extra"`
		Observacoes *string  `json:"observacoes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Data == "" {
		jsonErr(w, "data é obrigatória", http.StatusBadRequest)
		return
	}
	if _, err := time.Parse("2006-01-02", body.Data); err != nil {
		jsonErr(w, "data inválida", http.StatusBadRequest)
		return
	}
	if body.HoraEntrada != nil && *body.HoraEntrada != "" && !horaRegex.MatchString(*body.HoraEntrada) {
		jsonErr(w, "hora_entrada inválida", http.StatusBadRequest)
		return
	}
	if body.HoraSaida != nil && *body.HoraSaida != "" && !horaRegex.MatchString(*body.HoraSaida) {
		jsonErr(w, "hora_saida inválida", http.StatusBadRequest)
		return
	}
	horasExtra := 0.0
	if body.HorasExtra != nil {
		horasExtra = *body.HorasExtra
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.presencas (tenant_id, funcionario_id, data, hora_entrada, hora_saida, horas_extra, observacoes)
		VALUES ($1,$2,$3::date,$4,$5,$6,$7)
		ON CONFLICT (funcionario_id, data) DO UPDATE SET
		  hora_entrada=EXCLUDED.hora_entrada, hora_saida=EXCLUDED.hora_saida,
		  horas_extra=EXCLUDED.horas_extra, observacoes=EXCLUDED.observacoes
		RETURNING id`,
		user.TenantID, funcionarioID, body.Data, body.HoraEntrada, body.HoraSaida, horasExtra, body.Observacoes).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RemoverPresenca(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")
	presencaID := chi.URLParam(r, "presencaId")

	tag, err := h.db.Exec(r.Context(), `
		DELETE FROM rh.presencas
		 WHERE id=$1 AND funcionario_id=$2 AND tenant_id=$3`,
		presencaID, funcionarioID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Registo de presença não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
