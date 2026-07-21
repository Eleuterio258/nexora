package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/modules/recursos-humanos/models"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
)

// CriarCorrecaoEvento submete um pedido de correcção sobre o novo modelo de
// eventos — sucessor de rh.pedidos_correcao_ponto (que fica limitado ao
// modelo antigo "1 entrada + 1 saída/dia" e não recebe novos pedidos).
// POST /api/rh/correcoes.
func (h *Handler) CriarCorrecaoEvento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body models.CriarCorrecaoRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "corpo do pedido inválido", http.StatusBadRequest)
		return
	}
	if body.FuncionarioID == 0 || body.Tipo == "" || body.Motivo == "" || body.DataReferencia == "" {
		jsonErr(w, "funcionario_id, tipo, data_referencia e motivo são obrigatórios", http.StatusBadRequest)
		return
	}
	if !h.podeGerirFuncionario(r, body.FuncionarioID) {
		jsonErr(w, "Sem permissão para submeter correcções para este funcionário", http.StatusForbidden)
		return
	}

	var tipoEventoID *int64
	if body.TipoEventoCodigo != nil && *body.TipoEventoCodigo != "" {
		var id int64
		if err := h.db.QueryRow(r.Context(), `
			SELECT id FROM rh.tipos_evento WHERE tenant_id=$1 AND codigo=$2 AND ativo=TRUE`,
			user.TenantID, *body.TipoEventoCodigo).Scan(&id); err == nil {
			tipoEventoID = &id
		}
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.correcoes_evento (
			tenant_id, funcionario_id, evento_id, data_referencia, tipo, tipo_evento_id,
			ocorrido_em_solicitado, localidade_id_solicitada, motivo, documento_url, solicitado_por
		) VALUES ($1,$2,$3,$4::date,$5,$6,$7,$8,$9,$10,$11)
		RETURNING id`,
		user.TenantID, body.FuncionarioID, body.EventoID, body.DataReferencia, body.Tipo, tipoEventoID,
		body.OcorridoEmSolicitado, body.LocalidadeIDSolicitada, body.Motivo, body.DocumentoURL, user.ID,
	).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ListarCorrecoesEventoPendentes lista os pedidos de correcção pendentes de
// decisão — GET /api/rh/correcoes.
func (h *Handler) ListarCorrecoesEventoPendentes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	type row struct {
		ID                   int64      `json:"id"`
		FuncionarioID        int64      `json:"funcionario_id"`
		FuncionarioNome      string     `json:"funcionario_nome"`
		EventoID             *int64     `json:"evento_id"`
		DataReferencia       time.Time  `json:"data_referencia"`
		Tipo                 string     `json:"tipo"`
		TipoEventoCodigo     *string    `json:"tipo_evento_codigo"`
		OcorridoEmSolicitado *time.Time `json:"ocorrido_em_solicitado"`
		Motivo               string     `json:"motivo"`
		DocumentoURL         *string    `json:"documento_url"`
		SolicitadoEm         time.Time  `json:"solicitado_em"`
	}
	rows, _ := h.db.Query(r.Context(), `
		SELECT c.id, c.funcionario_id, f.nome_completo, c.evento_id, c.data_referencia,
		       c.tipo, te.codigo, c.ocorrido_em_solicitado, c.motivo, c.documento_url, c.solicitado_em
		  FROM rh.correcoes_evento c
		  JOIN rh.funcionarios f ON f.id = c.funcionario_id
		  LEFT JOIN rh.tipos_evento te ON te.id = c.tipo_evento_id
		 WHERE c.tenant_id = $1 AND c.estado = 'pendente'
		 ORDER BY c.solicitado_em`, user.TenantID)
	defer rows.Close()
	data := []row{}
	for rows.Next() {
		var c row
		if rows.Scan(&c.ID, &c.FuncionarioID, &c.FuncionarioNome, &c.EventoID, &c.DataReferencia,
			&c.Tipo, &c.TipoEventoCodigo, &c.OcorridoEmSolicitado, &c.Motivo, &c.DocumentoURL, &c.SolicitadoEm) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// AprovarCorrecaoEvento aprova um pedido pendente. Quando o pedido tem
// tipo_evento_id + ocorrido_em_solicitado, gera um NOVO evento com
// estado='corrigido' (nunca sobrescreve o evento original — requisito
// secção 5) e liga-o ao pedido via evento_gerado_id.
// POST /api/rh/correcoes/{id}/aprovar.
func (h *Handler) AprovarCorrecaoEvento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var funcionarioID int64
	var eventoOriginalID *int64
	var tipoEventoID *int64
	var tipoEventoCodigo *string
	var ocorridoEmSolicitado *time.Time
	var localidadeID *int64
	var motivo string
	if err := h.db.QueryRow(r.Context(), `
		SELECT c.funcionario_id, c.evento_id, c.tipo_evento_id, te.codigo,
		       c.ocorrido_em_solicitado, c.localidade_id_solicitada, c.motivo
		  FROM rh.correcoes_evento c
		  LEFT JOIN rh.tipos_evento te ON te.id = c.tipo_evento_id
		 WHERE c.id=$1 AND c.tenant_id=$2 AND c.estado='pendente'`,
		id, user.TenantID,
	).Scan(&funcionarioID, &eventoOriginalID, &tipoEventoID, &tipoEventoCodigo, &ocorridoEmSolicitado, &localidadeID, &motivo); err != nil {
		jsonErr(w, "Pedido não encontrado ou já processado", http.StatusConflict)
		return
	}

	if !h.podeGerirFuncionario(r, funcionarioID) {
		jsonErr(w, "Sem permissão para aprovar este pedido", http.StatusForbidden)
		return
	}

	var eventoGeradoID *int64
	if tipoEventoCodigo != nil && ocorridoEmSolicitado != nil {
		estadoCorrigido := "corrigido"
		ev, err := h.assiduidade.RegistarEvento(r.Context(), user.TenantID, assiduidade.RegistarEventoInput{
			FuncionarioID:    funcionarioID,
			TipoEventoCodigo: *tipoEventoCodigo,
			OcorridoEm:       *ocorridoEmSolicitado,
			Origem:           "manual",
			LocalidadeID:     localidadeID,
			RegistadoPor:     &user.ID,
			Motivo:           &motivo,
			EstadoForcado:    &estadoCorrigido,
			EventoPaiID:      eventoOriginalID,
		})
		if err != nil {
			jsonErr(w, "Erro ao gerar evento corrigido: "+err.Error(), http.StatusInternalServerError)
			return
		}
		eventoGeradoID = &ev.ID
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.correcoes_evento
		   SET estado='aprovado', decidido_por=$1, decidido_em=NOW(), evento_gerado_id=$2, updated_at=NOW()
		 WHERE id=$3 AND tenant_id=$4 AND estado='pendente'`,
		user.ID, eventoGeradoID, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Pedido já foi processado", http.StatusConflict)
		return
	}

	registoID, _ := strconv.ParseInt(id, 10, 64)
	ip := r.RemoteAddr
	estadoAnterior, estadoNovo := "pendente", "aprovado"
	_ = assiduidade.RegistarAuditoria(r.Context(), h.db, assiduidade.AuditoriaEntry{
		TenantID: user.TenantID, Tabela: "correcoes_evento", RegistoID: registoID,
		Operacao: "UPDATE", AlteradoPor: &user.ID, Motivo: &motivo, IPOrigem: &ip,
		EstadoAnterior: &estadoAnterior, EstadoNovo: &estadoNovo,
	})

	jsonOK(w, map[string]any{"evento_gerado_id": eventoGeradoID}, http.StatusOK)
}

// RejeitarCorrecaoEvento rejeita um pedido de correcção pendente.
// POST /api/rh/correcoes/{id}/rejeitar.
func (h *Handler) RejeitarCorrecaoEvento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Justificacao *string `json:"justificacao"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	var funcionarioID int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT funcionario_id FROM rh.correcoes_evento WHERE id=$1 AND tenant_id=$2 AND estado='pendente'`,
		id, user.TenantID).Scan(&funcionarioID); err != nil {
		jsonErr(w, "Pedido não encontrado ou já processado", http.StatusConflict)
		return
	}

	if !h.podeGerirFuncionario(r, funcionarioID) {
		jsonErr(w, "Sem permissão para rejeitar este pedido", http.StatusForbidden)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.correcoes_evento
		   SET estado='rejeitado', decidido_por=$1, decidido_em=NOW(), justificacao_decisao=$2, updated_at=NOW()
		 WHERE id=$3 AND tenant_id=$4 AND estado='pendente'`,
		user.ID, body.Justificacao, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Pedido já foi processado", http.StatusConflict)
		return
	}

	registoID, _ := strconv.ParseInt(id, 10, 64)
	ip := r.RemoteAddr
	estadoAnterior, estadoNovo := "pendente", "rejeitado"
	_ = assiduidade.RegistarAuditoria(r.Context(), h.db, assiduidade.AuditoriaEntry{
		TenantID: user.TenantID, Tabela: "correcoes_evento", RegistoID: registoID,
		Operacao: "UPDATE", AlteradoPor: &user.ID, Motivo: body.Justificacao, IPOrigem: &ip,
		EstadoAnterior: &estadoAnterior, EstadoNovo: &estadoNovo,
	})

	w.WriteHeader(http.StatusNoContent)
}
