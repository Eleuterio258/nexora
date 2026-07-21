package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
)

var ambitosValidos = map[string]bool{
	"empresa": true, "filial": true, "local": true, "departamento": true,
	"cargo": true, "equipa": true, "turno": true, "funcionario": true, "contrato": true,
}

// ── Catálogo de tipos de regra (rh.tipos_regra) — global, não é por tenant ──

type tipoRegraRow struct {
	ID         int64           `json:"id"`
	Codigo     string          `json:"codigo"`
	Nome       string          `json:"nome"`
	Descricao  string          `json:"descricao"`
	Parametros json.RawMessage `json:"parametros"`
	TipoValor  string          `json:"tipo_valor"`
}

func (h *Handler) ListarTiposRegra(w http.ResponseWriter, r *http.Request) {
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, codigo, nome, descricao, parametros, tipo_valor FROM rh.tipos_regra ORDER BY nome`)
	defer rows.Close()
	data := []tipoRegraRow{}
	for rows.Next() {
		var t tipoRegraRow
		if rows.Scan(&t.ID, &t.Codigo, &t.Nome, &t.Descricao, &t.Parametros, &t.TipoValor) == nil {
			data = append(data, t)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// ── Regras configuráveis por âmbito (rh.regras_assiduidade) ──

type regraAssiduidadeRow struct {
	ID              int64           `json:"id"`
	TipoRegraCodigo string          `json:"tipo_regra_codigo"`
	Ambito          string          `json:"ambito"`
	EntidadeID      *int64          `json:"entidade_id"`
	DataInicio      time.Time       `json:"data_inicio"`
	DataFim         *time.Time      `json:"data_fim"`
	Valor           json.RawMessage `json:"valor"`
	Prioridade      int16           `json:"prioridade"`
	Ativo           bool            `json:"ativo"`
}

// ListarRegras lista as regras do tenant, opcionalmente filtradas por
// ?tipo_regra_codigo= e/ou ?ambito=.
func (h *Handler) ListarRegras(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tipoRegraCodigo := r.URL.Query().Get("tipo_regra_codigo")
	ambito := r.URL.Query().Get("ambito")

	rows, _ := h.db.Query(r.Context(), `
		SELECT ra.id, tr.codigo, ra.ambito, ra.entidade_id, ra.data_inicio, ra.data_fim,
		       ra.valor, ra.prioridade, ra.ativo
		  FROM rh.regras_assiduidade ra
		  JOIN rh.tipos_regra tr ON tr.id = ra.tipo_regra_id
		 WHERE ra.tenant_id = $1
		   AND ($2 = '' OR tr.codigo = $2)
		   AND ($3 = '' OR ra.ambito = $3)
		 ORDER BY tr.codigo, ra.prioridade DESC`,
		user.TenantID, tipoRegraCodigo, ambito)
	defer rows.Close()
	data := []regraAssiduidadeRow{}
	for rows.Next() {
		var reg regraAssiduidadeRow
		if rows.Scan(&reg.ID, &reg.TipoRegraCodigo, &reg.Ambito, &reg.EntidadeID, &reg.DataInicio, &reg.DataFim,
			&reg.Valor, &reg.Prioridade, &reg.Ativo) == nil {
			data = append(data, reg)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarRegra(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		TipoRegraCodigo string         `json:"tipo_regra_codigo"`
		Ambito          string         `json:"ambito"`
		EntidadeID      *int64         `json:"entidade_id"`
		DataInicio      *string        `json:"data_inicio"`
		DataFim         *string        `json:"data_fim"`
		Valor           map[string]any `json:"valor"`
		Prioridade      int16          `json:"prioridade"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.TipoRegraCodigo == "" {
		jsonErr(w, "tipo_regra_codigo é obrigatório", http.StatusBadRequest)
		return
	}
	if !ambitosValidos[body.Ambito] {
		jsonErr(w, "âmbito inválido", http.StatusBadRequest)
		return
	}
	if body.Ambito != "empresa" && body.EntidadeID == nil {
		jsonErr(w, "entidade_id é obrigatório para este âmbito", http.StatusBadRequest)
		return
	}
	if body.Valor == nil {
		body.Valor = map[string]any{}
	}

	var tipoRegraID int64
	if err := h.db.QueryRow(r.Context(), `SELECT id FROM rh.tipos_regra WHERE codigo=$1`, body.TipoRegraCodigo).Scan(&tipoRegraID); err != nil {
		jsonErr(w, "tipo de regra desconhecido", http.StatusBadRequest)
		return
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.regras_assiduidade (tenant_id, tipo_regra_id, ambito, entidade_id, data_inicio, data_fim, valor, prioridade)
		VALUES ($1,$2,$3,$4,COALESCE($5::date, CURRENT_DATE),$6::date,$7,$8) RETURNING id`,
		user.TenantID, tipoRegraID, body.Ambito, body.EntidadeID, body.DataInicio, body.DataFim, body.Valor, body.Prioridade,
	).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe uma regra igual para este âmbito/entidade/data de início", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if valorNovo, jsonErr := json.Marshal(body.Valor); jsonErr == nil {
		ip := r.RemoteAddr
		_ = assiduidade.RegistarAuditoria(r.Context(), h.db, assiduidade.AuditoriaEntry{
			TenantID: user.TenantID, Tabela: "regras_assiduidade", RegistoID: id,
			Operacao: "INSERT", ValorNovo: valorNovo, AlteradoPor: &user.ID, IPOrigem: &ip,
		})
	}

	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarRegra(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		DataFim    *string        `json:"data_fim"`
		Valor      map[string]any `json:"valor"`
		Prioridade *int16         `json:"prioridade"`
		Ativo      *bool          `json:"ativo"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	var valorJSON any
	if body.Valor != nil {
		valorJSON = body.Valor
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.regras_assiduidade SET
		  data_fim=COALESCE($1::date,data_fim), valor=COALESCE($2,valor),
		  prioridade=COALESCE($3,prioridade), ativo=COALESCE($4,ativo), updated_at=NOW()
		WHERE id=$5 AND tenant_id=$6`,
		body.DataFim, valorJSON, body.Prioridade, body.Ativo, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Regra não encontrada", http.StatusNotFound)
		return
	}

	regraID, _ := strconv.ParseInt(id, 10, 64)
	ip := r.RemoteAddr
	entry := assiduidade.AuditoriaEntry{
		TenantID: user.TenantID, Tabela: "regras_assiduidade", RegistoID: regraID,
		Operacao: "UPDATE", AlteradoPor: &user.ID, IPOrigem: &ip,
	}
	if valorJSON != nil {
		if v, jsonErr := json.Marshal(valorJSON); jsonErr == nil {
			entry.ValorNovo = v
		}
	}
	_ = assiduidade.RegistarAuditoria(r.Context(), h.db, entry)

	w.WriteHeader(http.StatusNoContent)
}

// RemoverRegra desactiva a regra (ativo=false) em vez de a eliminar — os
// resultados diários já calculados com esta regra ficam intactos e
// consultáveis (rh.resultados_diarios.versao_regra regista quando foram
// calculados, não referencia a regra directamente).
func (h *Handler) RemoverRegra(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.regras_assiduidade SET ativo=FALSE, updated_at=NOW() WHERE id=$1 AND tenant_id=$2`,
		id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Regra não encontrada", http.StatusNotFound)
		return
	}

	regraID, _ := strconv.ParseInt(id, 10, 64)
	ip := r.RemoteAddr
	estadoAnterior, estadoNovo := "ativo", "inativo"
	_ = assiduidade.RegistarAuditoria(r.Context(), h.db, assiduidade.AuditoriaEntry{
		TenantID: user.TenantID, Tabela: "regras_assiduidade", RegistoID: regraID,
		Operacao: "UPDATE", AlteradoPor: &user.ID, IPOrigem: &ip,
		EstadoAnterior: &estadoAnterior, EstadoNovo: &estadoNovo,
	})

	w.WriteHeader(http.StatusNoContent)
}
