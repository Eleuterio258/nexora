package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/modules/recursos-humanos/models"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
)

// CriarEvento regista um evento de assiduidade submetido manualmente por RH
// (ou por um gestor autorizado) para um funcionário — POST /api/rh/eventos.
// Marcações do próprio funcionário via self-service usam um endpoint
// separado no módulo self-service, que chama o mesmo Service.
func (h *Handler) CriarEvento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body models.CriarEventoRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "corpo do pedido inválido", http.StatusBadRequest)
		return
	}
	if body.FuncionarioID == 0 || body.TipoEventoCodigo == "" || body.Origem == "" {
		jsonErr(w, "funcionario_id, tipo_evento_codigo e origem são obrigatórios", http.StatusBadRequest)
		return
	}
	if !h.podeGerirFuncionario(r, body.FuncionarioID) {
		jsonErr(w, "Sem permissão para registar eventos deste funcionário", http.StatusForbidden)
		return
	}

	ocorridoEm := time.Now()
	if body.OcorridoEm != nil {
		ocorridoEm = *body.OcorridoEm
	}
	var dataReferencia *time.Time
	if body.DataReferencia != nil && *body.DataReferencia != "" {
		if d, err := time.Parse("2006-01-02", *body.DataReferencia); err == nil {
			dataReferencia = &d
		}
	}

	registadoPor := user.ID
	ip := r.RemoteAddr
	ua := r.UserAgent()

	ev, err := h.assiduidade.RegistarEvento(r.Context(), user.TenantID, assiduidade.RegistarEventoInput{
		FuncionarioID:    body.FuncionarioID,
		TipoEventoCodigo: body.TipoEventoCodigo,
		MetodoCodigo:     body.MetodoCodigo,
		OcorridoEm:       ocorridoEm,
		DataReferencia:   dataReferencia,
		Origem:           body.Origem,
		Latitude:         body.Latitude,
		Longitude:        body.Longitude,
		LocalidadeID:     body.LocalidadeID,
		FotoURL:          body.FotoURL,
		DocumentoURL:     body.DocumentoURL,
		RegistadoPor:     &registadoPor,
		Motivo:           body.Motivo,
		Observacoes:      body.Observacoes,
		IPOrigem:         &ip,
		UserAgent:        &ua,
	})
	if err != nil {
		if err == assiduidade.ErrTipoEventoDesconhecido {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno ao registar evento", http.StatusInternalServerError)
		return
	}
	jsonOK(w, ev, http.StatusCreated)
}

// ListarEventosFuncionario lista os eventos de assiduidade de um funcionário
// num intervalo de datas — GET /api/rh/funcionarios/{id}/eventos?data_inicio=&data_fim=.
func (h *Handler) ListarEventosFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	dataInicio := r.URL.Query().Get("data_inicio")
	dataFim := r.URL.Query().Get("data_fim")
	if dataInicio == "" {
		dataInicio = time.Now().AddDate(0, 0, -30).Format("2006-01-02")
	}
	if dataFim == "" {
		dataFim = time.Now().Format("2006-01-02")
	}

	rows, _ := h.db.Query(r.Context(), `
		SELECT e.id, te.codigo, te.nome, mm.codigo, e.ocorrido_em, e.data_referencia,
		       e.origem, e.estado, e.latitude, e.longitude, e.dentro_geofence, e.motivo, e.observacoes
		  FROM rh.eventos_assiduidade e
		  JOIN rh.tipos_evento te ON te.id = e.tipo_evento_id
		  LEFT JOIN rh.metodos_marcacao mm ON mm.id = e.metodo_id
		 WHERE e.tenant_id = $1 AND e.funcionario_id = $2
		   AND e.data_referencia BETWEEN $3::date AND $4::date
		 ORDER BY e.ocorrido_em DESC`,
		user.TenantID, funcionarioID, dataInicio, dataFim)
	defer rows.Close()

	type row struct {
		ID             int64      `json:"id"`
		TipoCodigo     string     `json:"tipo_evento_codigo"`
		TipoNome       string     `json:"tipo_evento_nome"`
		MetodoCodigo   *string    `json:"metodo_codigo"`
		OcorridoEm     time.Time  `json:"ocorrido_em"`
		DataReferencia time.Time  `json:"data_referencia"`
		Origem         string     `json:"origem"`
		Estado         string     `json:"estado"`
		Latitude       *float64   `json:"latitude"`
		Longitude      *float64   `json:"longitude"`
		DentroGeofence *bool      `json:"dentro_geofence"`
		Motivo         *string    `json:"motivo"`
		Observacoes    *string    `json:"observacoes"`
	}
	data := []row{}
	for rows.Next() {
		var e row
		if rows.Scan(&e.ID, &e.TipoCodigo, &e.TipoNome, &e.MetodoCodigo, &e.OcorridoEm, &e.DataReferencia,
			&e.Origem, &e.Estado, &e.Latitude, &e.Longitude, &e.DentroGeofence, &e.Motivo, &e.Observacoes) == nil {
			data = append(data, e)
		}
	}
	jsonOK(w, data, http.StatusOK)
}
