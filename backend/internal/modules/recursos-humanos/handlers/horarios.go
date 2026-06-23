package handlers

import (
	"encoding/json"
	"net/http"
	"regexp"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

var horaRegex = regexp.MustCompile(`^([01]\d|2[0-3]):[0-5]\d$`)

type horarioRow struct {
	ID                int64    `json:"id"`
	Codigo            string   `json:"codigo"`
	Nome              string   `json:"nome"`
	Descricao         *string  `json:"descricao"`
	HoraEntrada       string   `json:"hora_entrada"`
	HoraSaida         string   `json:"hora_saida"`
	IntervaloInicio   *string  `json:"intervalo_inicio"`
	IntervaloFim      *string  `json:"intervalo_fim"`
	DiasSemana        string   `json:"dias_semana"`
	CargaSemanalHoras *float64 `json:"carga_semanal_horas"`
	Ativo             bool     `json:"ativo"`
	NumFuncionarios   int      `json:"num_funcionarios"`
}

// diasSemanaValidos verifica se s e uma lista de dias da semana separados por
// virgula (1=segunda .. 7=domingo), sem repeticoes e nao vazia.
func diasSemanaValidos(s string) bool {
	partes := strings.Split(s, ",")
	if len(partes) == 0 {
		return false
	}
	vistos := map[string]bool{}
	for _, p := range partes {
		n, err := strconv.Atoi(p)
		if err != nil || n < 1 || n > 7 || vistos[p] {
			return false
		}
		vistos[p] = true
	}
	return true
}

func (h *Handler) ListarHorarios(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT h.id, h.codigo, h.nome, h.descricao, h.hora_entrada, h.hora_saida,
		       h.intervalo_inicio, h.intervalo_fim, h.dias_semana, h.carga_semanal_horas, h.ativo,
		       (SELECT COUNT(*) FROM funcionarios f WHERE f.horario_id = h.id)
		  FROM horarios_trabalho h
		 WHERE h.tenant_id=$1
		 ORDER BY h.nome`, user.TenantID)
	defer rows.Close()
	data := []horarioRow{}
	for rows.Next() {
		var hr horarioRow
		if rows.Scan(&hr.ID, &hr.Codigo, &hr.Nome, &hr.Descricao, &hr.HoraEntrada, &hr.HoraSaida,
			&hr.IntervaloInicio, &hr.IntervaloFim, &hr.DiasSemana, &hr.CargaSemanalHoras, &hr.Ativo, &hr.NumFuncionarios) == nil {
			data = append(data, hr)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarHorario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo            string   `json:"codigo"`
		Nome              string   `json:"nome"`
		Descricao         *string  `json:"descricao"`
		HoraEntrada       string   `json:"hora_entrada"`
		HoraSaida         string   `json:"hora_saida"`
		IntervaloInicio   *string  `json:"intervalo_inicio"`
		IntervaloFim      *string  `json:"intervalo_fim"`
		DiasSemana        string   `json:"dias_semana"`
		CargaSemanalHoras *float64 `json:"carga_semanal_horas"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "código e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	if !horaRegex.MatchString(body.HoraEntrada) || !horaRegex.MatchString(body.HoraSaida) {
		jsonErr(w, "hora de entrada e hora de saída devem estar no formato HH:MM", http.StatusBadRequest)
		return
	}
	if body.IntervaloInicio != nil && *body.IntervaloInicio != "" && !horaRegex.MatchString(*body.IntervaloInicio) {
		jsonErr(w, "intervalo de início deve estar no formato HH:MM", http.StatusBadRequest)
		return
	}
	if body.IntervaloFim != nil && *body.IntervaloFim != "" && !horaRegex.MatchString(*body.IntervaloFim) {
		jsonErr(w, "intervalo de fim deve estar no formato HH:MM", http.StatusBadRequest)
		return
	}
	if body.DiasSemana == "" {
		body.DiasSemana = "1,2,3,4,5"
	}
	if !diasSemanaValidos(body.DiasSemana) {
		jsonErr(w, "dias da semana inválidos", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO horarios_trabalho (tenant_id, codigo, nome, descricao, hora_entrada, hora_saida, intervalo_inicio, intervalo_fim, dias_semana, carga_semanal_horas)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Descricao, body.HoraEntrada, body.HoraSaida,
		body.IntervaloInicio, body.IntervaloFim, body.DiasSemana, body.CargaSemanalHoras).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um horário com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarHorario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Codigo            *string  `json:"codigo"`
		Nome              *string  `json:"nome"`
		Descricao         *string  `json:"descricao"`
		HoraEntrada       *string  `json:"hora_entrada"`
		HoraSaida         *string  `json:"hora_saida"`
		IntervaloInicio   *string  `json:"intervalo_inicio"`
		IntervaloFim      *string  `json:"intervalo_fim"`
		DiasSemana        *string  `json:"dias_semana"`
		CargaSemanalHoras *float64 `json:"carga_semanal_horas"`
		Ativo             *bool    `json:"ativo"`
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
	if body.HoraEntrada != nil && !horaRegex.MatchString(*body.HoraEntrada) {
		jsonErr(w, "hora de entrada deve estar no formato HH:MM", http.StatusBadRequest)
		return
	}
	if body.HoraSaida != nil && !horaRegex.MatchString(*body.HoraSaida) {
		jsonErr(w, "hora de saída deve estar no formato HH:MM", http.StatusBadRequest)
		return
	}
	if body.IntervaloInicio != nil && *body.IntervaloInicio != "" && !horaRegex.MatchString(*body.IntervaloInicio) {
		jsonErr(w, "intervalo de início deve estar no formato HH:MM", http.StatusBadRequest)
		return
	}
	if body.IntervaloFim != nil && *body.IntervaloFim != "" && !horaRegex.MatchString(*body.IntervaloFim) {
		jsonErr(w, "intervalo de fim deve estar no formato HH:MM", http.StatusBadRequest)
		return
	}
	if body.DiasSemana != nil && !diasSemanaValidos(*body.DiasSemana) {
		jsonErr(w, "dias da semana inválidos", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE horarios_trabalho SET
		  codigo=COALESCE($1,codigo), nome=COALESCE($2,nome), descricao=COALESCE($3,descricao),
		  hora_entrada=COALESCE($4,hora_entrada), hora_saida=COALESCE($5,hora_saida),
		  intervalo_inicio=COALESCE($6,intervalo_inicio), intervalo_fim=COALESCE($7,intervalo_fim),
		  dias_semana=COALESCE($8,dias_semana), carga_semanal_horas=COALESCE($9,carga_semanal_horas),
		  ativo=COALESCE($10,ativo), updated_at=NOW()
		WHERE id=$11 AND tenant_id=$12`,
		body.Codigo, body.Nome, body.Descricao, body.HoraEntrada, body.HoraSaida,
		body.IntervaloInicio, body.IntervaloFim, body.DiasSemana, body.CargaSemanalHoras, body.Ativo, id, user.TenantID)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um horário com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Horário não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverHorario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var temFuncionarios bool
	if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM funcionarios WHERE horario_id=$1 AND tenant_id=$2)`, id, user.TenantID).Scan(&temFuncionarios); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if temFuncionarios {
		jsonErr(w, "Não é possível eliminar um horário associado a funcionários", http.StatusConflict)
		return
	}

	tag, err := h.db.Exec(r.Context(), `DELETE FROM horarios_trabalho WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Horário não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
