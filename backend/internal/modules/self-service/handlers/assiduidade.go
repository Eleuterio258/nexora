package handlers

import (
	"net/http"
	"time"

	mw "nexora/internal/middleware"
)

type registoPresenca struct {
	ID            int64      `json:"id"`
	Data          time.Time  `json:"data"`
	HoraEntrada   *time.Time `json:"hora_entrada"`
	HoraSaida     *time.Time `json:"hora_saida"`
	HorasTrabalhadas *float64 `json:"horas_trabalhadas"`
	Tipo          string     `json:"tipo"`
	Latitude      *float64   `json:"latitude"`
	Longitude     *float64   `json:"longitude"`
	Observacao    *string    `json:"observacao"`
}

// MinhaAssiduidade lista os registos de presença do colaborador autenticado.
func (h *Handler) MinhaAssiduidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcID, ok := h.funcionarioID(r)
	if !ok {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}

	mes  := r.URL.Query().Get("mes")
	ano  := r.URL.Query().Get("ano")
	if mes == "" || ano == "" {
		now := time.Now()
		if mes == "" { mes = now.Format("01") }
		if ano == "" { ano  = now.Format("2006") }
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT id, data, hora_entrada, hora_saida,
		       CASE WHEN hora_entrada IS NOT NULL AND hora_saida IS NOT NULL
		            THEN EXTRACT(EPOCH FROM (hora_saida::time - hora_entrada::time))/3600
		            ELSE horas_extra END AS horas,
		       COALESCE(tipo,'presente'),
		       latitude, longitude, observacao
		  FROM rh.presencas
		 WHERE funcionario_id=$1 AND tenant_id=$2
		   AND EXTRACT(YEAR FROM data)=$3::int AND EXTRACT(MONTH FROM data)=$4::int
		 ORDER BY data DESC`, funcID, user.TenantID, ano, mes)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []registoPresenca{}
	for rows.Next() {
		var p registoPresenca
		if rows.Scan(&p.ID, &p.Data, &p.HoraEntrada, &p.HoraSaida, &p.HorasTrabalhadas,
			&p.Tipo, &p.Latitude, &p.Longitude, &p.Observacao) == nil {
			data = append(data, p)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// ResumoAssiduidade devolve resumo mensal (dias, horas, atrasos, faltas).
func (h *Handler) ResumoAssiduidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcID, ok := h.funcionarioID(r)
	if !ok {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}

	mes := r.URL.Query().Get("mes")
	ano := r.URL.Query().Get("ano")
	now := time.Now()
	if mes == "" { mes = now.Format("01") }
	if ano == "" { ano  = now.Format("2006") }

	var diasTrabalhados int; var horasTotais float64
	var atrasos, faltas, horasExtra int
	h.db.QueryRow(r.Context(), `
		SELECT
		  COUNT(DISTINCT data)                                                               AS dias,
		  COALESCE(SUM(CASE WHEN hora_entrada IS NOT NULL AND hora_saida IS NOT NULL
		                    THEN EXTRACT(EPOCH FROM (hora_saida::time - hora_entrada::time))/3600
		                    ELSE COALESCE(horas_extra,0) END),0)                            AS horas,
		  COUNT(*) FILTER (WHERE tipo='atraso')                                             AS atrasos,
		  COUNT(*) FILTER (WHERE tipo='falta')                                              AS faltas,
		  COUNT(*) FILTER (WHERE horas_extra > 0)                                           AS horas_extra
		FROM rh.presencas
		WHERE funcionario_id=$1 AND tenant_id=$2
		  AND EXTRACT(YEAR FROM data)=$3::int AND EXTRACT(MONTH FROM data)=$4::int`,
		funcID, user.TenantID, ano, mes).
		Scan(&diasTrabalhados, &horasTotais, &atrasos, &faltas, &horasExtra)

	jsonOK(w, map[string]any{
		"mes":              mes,
		"ano":              ano,
		"dias_trabalhados": diasTrabalhados,
		"horas_totais":     horasTotais,
		"atrasos":          atrasos,
		"faltas":           faltas,
		"horas_extra":      horasExtra,
	}, http.StatusOK)
}

// CriarJustificacao submete uma justificação de falta ou atraso.
func (h *Handler) CriarJustificacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcID, ok := h.funcionarioID(r)
	if !ok {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}

	var body struct {
		Tipo        string  `json:"tipo"`
		Data        string  `json:"data"`
		Motivo      string  `json:"motivo"`
		FicheiroURL *string `json:"ficheiro_url"`
	}
	if err := decodeJSON(r, &body); err != nil || body.Data == "" || body.Motivo == "" {
		jsonErr(w, "data e motivo são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.Tipo != "falta" && body.Tipo != "atraso" {
		body.Tipo = "falta"
	}

	var id int64
	if err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.justificacoes (tenant_id, funcionario_id, tipo, data, motivo, ficheiro_url)
		VALUES ($1,$2,$3,$4::date,$5,$6) RETURNING id`,
		user.TenantID, funcID, body.Tipo, body.Data, body.Motivo, body.FicheiroURL).Scan(&id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ListarJustificacoes lista as justificações do colaborador.
func (h *Handler) ListarJustificacoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcID, ok := h.funcionarioID(r)
	if !ok {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}

	type row struct {
		ID        int64     `json:"id"`
		Tipo      string    `json:"tipo"`
		Data      time.Time `json:"data"`
		Motivo    string    `json:"motivo"`
		Estado    string    `json:"estado"`
		CreatedAt time.Time `json:"created_at"`
	}
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, tipo, data, motivo, estado, created_at
		  FROM rh.justificacoes
		 WHERE funcionario_id=$1 AND tenant_id=$2
		 ORDER BY data DESC LIMIT 50`, funcID, user.TenantID)
	if rows == nil { jsonOK(w, []row{}, http.StatusOK); return }
	defer rows.Close()

	data := []row{}
	for rows.Next() {
		var j row
		if rows.Scan(&j.ID, &j.Tipo, &j.Data, &j.Motivo, &j.Estado, &j.CreatedAt) == nil {
			data = append(data, j)
		}
	}
	jsonOK(w, data, http.StatusOK)
}
