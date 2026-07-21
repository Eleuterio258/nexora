package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ── Tipos de evento (rh.tipos_evento) ──
//
// Catálogo configurável por tenant: o administrador cria/desactiva tipos de
// evento sem alterar código (requisito secção 2). Não há remoção física —
// desactivar (ativo=false) preserva a integridade de eventos já gravados com
// esse tipo (rh.eventos_assiduidade.tipo_evento_id não tem ON DELETE CASCADE).

type tipoEventoRow struct {
	ID           int64   `json:"id"`
	Codigo       string  `json:"codigo"`
	Nome         string  `json:"nome"`
	Categoria    string  `json:"categoria"`
	Sentido      *string `json:"sentido"`
	TipoPar      *string `json:"tipo_par"`
	AfetaCalculo string  `json:"afeta_calculo"`
	Cor          *string `json:"cor"`
	Ativo        bool    `json:"ativo"`
}

func (h *Handler) ListarTiposEvento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, codigo, nome, categoria, sentido, tipo_par, afeta_calculo, cor, ativo
		  FROM rh.tipos_evento
		 WHERE tenant_id = $1
		 ORDER BY categoria, nome`, user.TenantID)
	defer rows.Close()
	data := []tipoEventoRow{}
	for rows.Next() {
		var t tipoEventoRow
		if rows.Scan(&t.ID, &t.Codigo, &t.Nome, &t.Categoria, &t.Sentido, &t.TipoPar, &t.AfetaCalculo, &t.Cor, &t.Ativo) == nil {
			data = append(data, t)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarTipoEvento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo       string  `json:"codigo"`
		Nome         string  `json:"nome"`
		Categoria    string  `json:"categoria"`
		Sentido      *string `json:"sentido"`
		TipoPar      *string `json:"tipo_par"`
		AfetaCalculo string  `json:"afeta_calculo"`
		Cor          *string `json:"cor"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "código e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.Categoria == "" {
		body.Categoria = "marcacao"
	}
	if body.AfetaCalculo == "" {
		body.AfetaCalculo = "nenhum"
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.tipos_evento (tenant_id, codigo, nome, categoria, sentido, tipo_par, afeta_calculo, cor)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Categoria, body.Sentido, body.TipoPar, body.AfetaCalculo, body.Cor,
	).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um tipo de evento com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarTipoEvento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Nome         *string `json:"nome"`
		Categoria    *string `json:"categoria"`
		Sentido      *string `json:"sentido"`
		TipoPar      *string `json:"tipo_par"`
		AfetaCalculo *string `json:"afeta_calculo"`
		Cor          *string `json:"cor"`
		Ativo        *bool   `json:"ativo"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.tipos_evento SET
		  nome=COALESCE($1,nome), categoria=COALESCE($2,categoria), sentido=COALESCE($3,sentido),
		  tipo_par=COALESCE($4,tipo_par), afeta_calculo=COALESCE($5,afeta_calculo), cor=COALESCE($6,cor),
		  ativo=COALESCE($7,ativo), updated_at=NOW()
		WHERE id=$8 AND tenant_id=$9`,
		body.Nome, body.Categoria, body.Sentido, body.TipoPar, body.AfetaCalculo, body.Cor, body.Ativo, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Tipo de evento não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// RemoverTipoEvento desactiva o tipo de evento (nunca elimina fisicamente —
// eventos já gravados com este tipo continuam válidos e consultáveis).
func (h *Handler) RemoverTipoEvento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.tipos_evento SET ativo=FALSE, updated_at=NOW() WHERE id=$1 AND tenant_id=$2`,
		id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Tipo de evento não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Métodos de marcação (rh.metodos_marcacao) ──

type metodoMarcacaoRow struct {
	ID                int64  `json:"id"`
	Codigo            string `json:"codigo"`
	Nome              string `json:"nome"`
	RequerDispositivo bool   `json:"requer_dispositivo"`
	RequerLocalizacao bool   `json:"requer_localizacao"`
	RequerSelfie      bool   `json:"requer_selfie"`
	Ativo             bool   `json:"ativo"`
}

func (h *Handler) ListarMetodosMarcacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, codigo, nome, requer_dispositivo, requer_localizacao, requer_selfie, ativo
		  FROM rh.metodos_marcacao
		 WHERE tenant_id = $1
		 ORDER BY nome`, user.TenantID)
	defer rows.Close()
	data := []metodoMarcacaoRow{}
	for rows.Next() {
		var m metodoMarcacaoRow
		if rows.Scan(&m.ID, &m.Codigo, &m.Nome, &m.RequerDispositivo, &m.RequerLocalizacao, &m.RequerSelfie, &m.Ativo) == nil {
			data = append(data, m)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarMetodoMarcacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo            string `json:"codigo"`
		Nome              string `json:"nome"`
		RequerDispositivo bool   `json:"requer_dispositivo"`
		RequerLocalizacao bool   `json:"requer_localizacao"`
		RequerSelfie      bool   `json:"requer_selfie"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "código e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.metodos_marcacao (tenant_id, codigo, nome, requer_dispositivo, requer_localizacao, requer_selfie)
		VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.RequerDispositivo, body.RequerLocalizacao, body.RequerSelfie,
	).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um método de marcação com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarMetodoMarcacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Nome              *string `json:"nome"`
		RequerDispositivo *bool   `json:"requer_dispositivo"`
		RequerLocalizacao *bool   `json:"requer_localizacao"`
		RequerSelfie      *bool   `json:"requer_selfie"`
		Ativo             *bool   `json:"ativo"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.metodos_marcacao SET
		  nome=COALESCE($1,nome), requer_dispositivo=COALESCE($2,requer_dispositivo),
		  requer_localizacao=COALESCE($3,requer_localizacao), requer_selfie=COALESCE($4,requer_selfie),
		  ativo=COALESCE($5,ativo), updated_at=NOW()
		WHERE id=$6 AND tenant_id=$7`,
		body.Nome, body.RequerDispositivo, body.RequerLocalizacao, body.RequerSelfie, body.Ativo, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Método de marcação não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverMetodoMarcacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.metodos_marcacao SET ativo=FALSE, updated_at=NOW() WHERE id=$1 AND tenant_id=$2`,
		id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Método de marcação não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
