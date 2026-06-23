package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

var tiposProcessoDisciplinarValidos = map[string]bool{
	"advertencia_verbal":  true,
	"advertencia_escrita": true,
	"suspensao":           true,
	"despedimento":        true,
	"outro":               true,
}

var estadosProcessoDisciplinarValidos = map[string]bool{
	"aberto":     true,
	"em_analise": true,
	"decidido":   true,
	"arquivado":  true,
}

// ── Processos Disciplinares: registo por funcionário ────────────────────────

func (h *Handler) ListarProcessosDisciplinaresFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), `
		SELECT id, tipo, motivo, descricao, data_ocorrencia, data_abertura, estado, decisao, data_decisao, aberto_por, decidido_por, created_at
		  FROM processos_disciplinares
		 WHERE funcionario_id=$1 AND tenant_id=$2
		 ORDER BY data_ocorrencia DESC`, funcionarioID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID             int64      `json:"id"`
		Tipo           string     `json:"tipo"`
		Motivo         string     `json:"motivo"`
		Descricao      *string    `json:"descricao"`
		DataOcorrencia time.Time  `json:"data_ocorrencia"`
		DataAbertura   time.Time  `json:"data_abertura"`
		Estado         string     `json:"estado"`
		Decisao        *string    `json:"decisao"`
		DataDecisao    *time.Time `json:"data_decisao"`
		AbertoPor      *int64     `json:"aberto_por"`
		DecididoPor    *int64     `json:"decidido_por"`
		CreatedAt      time.Time  `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var p Row
		if rows.Scan(&p.ID, &p.Tipo, &p.Motivo, &p.Descricao, &p.DataOcorrencia, &p.DataAbertura, &p.Estado, &p.Decisao, &p.DataDecisao, &p.AbertoPor, &p.DecididoPor, &p.CreatedAt) == nil {
			data = append(data, p)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarProcessoDisciplinarFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	var body struct {
		Tipo           string  `json:"tipo"`
		Motivo         string  `json:"motivo"`
		Descricao      *string `json:"descricao"`
		DataOcorrencia string  `json:"data_ocorrencia"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Motivo == "" || body.DataOcorrencia == "" {
		jsonErr(w, "tipo, motivo e data_ocorrencia são obrigatórios", http.StatusBadRequest)
		return
	}
	if !tiposProcessoDisciplinarValidos[body.Tipo] {
		jsonErr(w, "tipo inválido", http.StatusBadRequest)
		return
	}
	if _, err := time.Parse("2006-01-02", body.DataOcorrencia); err != nil {
		jsonErr(w, "data_ocorrencia inválida", http.StatusBadRequest)
		return
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO processos_disciplinares (tenant_id, funcionario_id, tipo, motivo, descricao, data_ocorrencia, aberto_por)
		VALUES ($1,$2,$3,$4,$5,$6::date,$7) RETURNING id`,
		user.TenantID, funcionarioID, body.Tipo, body.Motivo, body.Descricao, body.DataOcorrencia, user.ID).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarProcessoDisciplinarFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")
	registoID := chi.URLParam(r, "registoId")

	var body struct {
		Estado      *string `json:"estado"`
		Decisao     *string `json:"decisao"`
		DataDecisao *string `json:"data_decisao"`
		Descricao   *string `json:"descricao"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	if body.Estado != nil && !estadosProcessoDisciplinarValidos[*body.Estado] {
		jsonErr(w, "estado inválido", http.StatusBadRequest)
		return
	}
	if body.Estado != nil && *body.Estado == "decidido" {
		if body.Decisao == nil || *body.Decisao == "" || body.DataDecisao == nil || *body.DataDecisao == "" {
			jsonErr(w, "decisao e data_decisao são obrigatórios para decidir o processo", http.StatusBadRequest)
			return
		}
	}
	if body.DataDecisao != nil && *body.DataDecisao != "" {
		if _, err := time.Parse("2006-01-02", *body.DataDecisao); err != nil {
			jsonErr(w, "data_decisao inválida", http.StatusBadRequest)
			return
		}
	}

	var decididoPor *int64
	if body.Estado != nil && *body.Estado == "decidido" {
		decididoPor = &user.ID
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE processos_disciplinares SET
		  estado=COALESCE($1,estado), decisao=COALESCE($2,decisao), data_decisao=COALESCE($3::date,data_decisao),
		  descricao=COALESCE($4,descricao), decidido_por=COALESCE($5,decidido_por)
		WHERE id=$6 AND funcionario_id=$7 AND tenant_id=$8`,
		body.Estado, body.Decisao, body.DataDecisao, body.Descricao, decididoPor, registoID, funcionarioID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Processo disciplinar não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverProcessoDisciplinarFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")
	registoID := chi.URLParam(r, "registoId")

	tag, err := h.db.Exec(r.Context(), `
		DELETE FROM processos_disciplinares
		 WHERE id=$1 AND funcionario_id=$2 AND tenant_id=$3`,
		registoID, funcionarioID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Processo disciplinar não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
