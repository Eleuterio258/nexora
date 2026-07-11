package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/hardware/adapters"
	"nexora/internal/modules/hardware/models"
	"nexora/internal/modules/hardware/service"
)

// Handler já é definido em handler.go.

// ReceberEvento recebe eventos do driver configurado no dispositivo.
// Mantém compatibilidade com Hikvision no endpoint /api/hardware/events.
func (h *Handler) ReceberEvento(w http.ResponseWriter, r *http.Request) {
	h.receberEventoComAdapter(w, r, "")
}

// ReceberEventoGenerico recebe eventos no formato REST normalizado.
func (h *Handler) ReceberEventoGenerico(w http.ResponseWriter, r *http.Request) {
	h.receberEventoComAdapter(w, r, "generic_rest")
}

// ReceberEventoZKTeco recebe eventos de terminais ZKTeco via Push/ADMS
// (application/x-www-form-urlencoded, um evento por pedido).
func (h *Handler) ReceberEventoZKTeco(w http.ResponseWriter, r *http.Request) {
	h.receberEventoComAdapter(w, r, "zkteco")
}

func (h *Handler) receberEventoComAdapter(w http.ResponseWriter, r *http.Request, forcedDriver string) {
	device := mw.GetDevice(r)
	if device == nil {
		jsonErr(w, "Dispositivo não autenticado", http.StatusUnauthorized)
		return
	}

	driverName := forcedDriver
	if driverName == "" {
		driverName = device.Driver
	}

	adapter, ok := adapters.DefaultRegistry.Get(driverName)
	if !ok {
		jsonErr(w, "Driver não suportado: "+driverName, http.StatusBadRequest)
		return
	}

	configs, err := h.loadDeviceConfigs(r, device.ID)
	if err != nil {
		jsonErr(w, "Erro ao carregar configurações do dispositivo", http.StatusInternalServerError)
		return
	}

	if err := adapter.ValidateAuth(r, device, configs); err != nil {
		jsonErr(w, err.Error(), http.StatusUnauthorized)
		return
	}

	event, err := adapter.ParseEvent(r)
	if err != nil {
		jsonErr(w, err.Error(), http.StatusBadRequest)
		return
	}

	processor := service.NewProcessor(h.db)
	eventID, result, err := processor.Process(r.Context(), device.ID, device.TenantID, event)
	if err != nil {
		jsonErr(w, err.Error(), http.StatusInternalServerError)
		return
	}

	resp := map[string]any{
		"id":        eventID,
		"processed": result.Processed,
	}
	if result.PresencaID != nil {
		resp["presenca_id"] = *result.PresencaID
	}
	if result.AttendanceID != nil {
		resp["attendance_id"] = *result.AttendanceID
	}
	if result.ErrorMessage != "" {
		resp["error"] = result.ErrorMessage
	}

	status := http.StatusCreated
	if !result.Processed {
		status = http.StatusOK
	}
	jsonOK(w, resp, status)
}

// BatchRequest representa um lote de eventos normalizados.
type BatchRequest struct {
	Events []models.NormalizedEvent `json:"events"`
}

// BatchResponse representa o resultado do processamento em lote.
type BatchResponse struct {
	Total   int               `json:"total"`
	Processed int             `json:"processed"`
	Failed    int             `json:"failed"`
	Results   []BatchItemResult `json:"results"`
}

type BatchItemResult struct {
	Index        int    `json:"index"`
	EmployeeNo   string `json:"employee_no"`
	EventID      int64  `json:"event_id"`
	Processed    bool   `json:"processed"`
	PresencaID   *int64 `json:"presenca_id,omitempty"`
	AttendanceID *int64 `json:"attendance_id,omitempty"`
	Error        string `json:"error,omitempty"`
}

// ReceberEventosEmLote processa múltiplos eventos normalizados.
func (h *Handler) ReceberEventosEmLote(w http.ResponseWriter, r *http.Request) {
	device := mw.GetDevice(r)
	if device == nil {
		jsonErr(w, "Dispositivo não autenticado", http.StatusUnauthorized)
		return
	}

	var payload BatchRequest
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}

	if len(payload.Events) == 0 {
		jsonErr(w, "events é obrigatório e não pode estar vazio", http.StatusBadRequest)
		return
	}
	if len(payload.Events) > 100 {
		jsonErr(w, "Limite máximo de 100 eventos por pedido", http.StatusBadRequest)
		return
	}

	processor := service.NewProcessor(h.db)
	resp := BatchResponse{
		Total:   len(payload.Events),
		Results: make([]BatchItemResult, 0, len(payload.Events)),
	}

	for i, event := range payload.Events {
		result := BatchItemResult{
			Index:      i,
			EmployeeNo: event.EmployeeNo,
		}

		eventID, proc, err := processor.Process(r.Context(), device.ID, device.TenantID, &event)
		if err != nil {
			result.Error = err.Error()
			resp.Failed++
		} else {
			result.EventID = eventID
			result.Processed = proc.Processed
			result.PresencaID = proc.PresencaID
			result.AttendanceID = proc.AttendanceID
			if !proc.Processed && proc.ErrorMessage != "" {
				result.Error = proc.ErrorMessage
				resp.Failed++
			} else {
				resp.Processed++
			}
		}

		resp.Results = append(resp.Results, result)
	}

	jsonOK(w, resp, http.StatusOK)
}

// Ping endpoint para o dispositivo verificar conectividade.
func (h *Handler) Ping(w http.ResponseWriter, r *http.Request) {
	device := mw.GetDevice(r)
	jsonOK(w, map[string]any{
		"ok":          true,
		"device_id":   device.ID,
		"tenant_id":   device.TenantID,
		"device_name": device.Nome,
		"driver":      device.Driver,
	}, http.StatusOK)
}

// ListarEventos lista eventos recebidos dos dispositivos do tenant (painel ERP).
func (h *Handler) ListarEventos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()

	where := "e.tenant_id = $1"
	args := []any{user.TenantID}

	if v := q.Get("device_id"); v != "" {
		args = append(args, v)
		where += " AND e.device_id = $" + strconv.Itoa(len(args))
	}
	if v := q.Get("processed"); v != "" {
		args = append(args, v == "true")
		where += " AND e.processed = $" + strconv.Itoa(len(args))
	}
	if v := q.Get("employee_no"); v != "" {
		args = append(args, v)
		where += " AND e.employee_no = $" + strconv.Itoa(len(args))
	}
	if v := q.Get("data_inicio"); v != "" {
		args = append(args, v)
		where += " AND e.event_time >= $" + strconv.Itoa(len(args)) + "::date"
	}
	if v := q.Get("data_fim"); v != "" {
		args = append(args, v)
		where += " AND e.event_time < ($" + strconv.Itoa(len(args)) + "::date + INTERVAL '1 day')"
	}

	page, limit := 1, 20
	if v := q.Get("page"); v != "" {
		if p, err := strconv.Atoi(v); err == nil && p > 0 {
			page = p
		}
	}
	if v := q.Get("limit"); v != "" {
		if l, err := strconv.Atoi(v); err == nil && l > 0 && l <= 100 {
			limit = l
		}
	}
	offset := (page - 1) * limit

	type row struct {
		ID           int64      `json:"id"`
		DeviceID     int64      `json:"device_id"`
		DeviceName   string     `json:"device_name"`
		EventType    string     `json:"event_type"`
		EmployeeNo   string     `json:"employee_no"`
		EventTime    time.Time  `json:"event_time"`
		Processed    bool       `json:"processed"`
		ProcessedAt  *time.Time `json:"processed_at"`
		PresencaID   *int64     `json:"presenca_id"`
		AttendanceID *int64     `json:"attendance_id"`
		ErrorMessage *string    `json:"error_message"`
		CreatedAt    time.Time  `json:"created_at"`
	}

	countArgs := make([]any, len(args))
	copy(countArgs, args)
	dataArgs := append(args, limit, offset)

	query := `
		SELECT e.id, e.device_id, d.nome, e.event_type, e.employee_no, e.event_time,
		       e.processed, e.processed_at, e.presenca_id, e.attendance_id, e.error_message, e.created_at
		  FROM hardware.device_events e
		  JOIN hardware.devices d ON d.id = e.device_id
		 WHERE ` + where + `
		 ORDER BY e.created_at DESC
		 LIMIT $` + strconv.Itoa(len(dataArgs)-1) + ` OFFSET $` + strconv.Itoa(len(dataArgs))

	rows, err := h.db.Query(r.Context(), query, dataArgs...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []row{}
	for rows.Next() {
		var e row
		var errMsg *string
		if err := rows.Scan(&e.ID, &e.DeviceID, &e.DeviceName, &e.EventType, &e.EmployeeNo, &e.EventTime,
			&e.Processed, &e.ProcessedAt, &e.PresencaID, &e.AttendanceID, &errMsg, &e.CreatedAt); err == nil {
			if errMsg != nil && *errMsg != "" {
				e.ErrorMessage = errMsg
			}
			data = append(data, e)
		}
	}

	var total int
	_ = h.db.QueryRow(r.Context(), `
		SELECT COUNT(*)
		  FROM hardware.device_events e
		  JOIN hardware.devices d ON d.id = e.device_id
		 WHERE `+where, countArgs...).Scan(&total)

	jsonOK(w, map[string]any{
		"data": data,
		"meta": map[string]int{
			"total": total,
			"page":  page,
			"limit": limit,
			"pages": (total + limit - 1) / limit,
		},
	}, http.StatusOK)
}

// loadDeviceConfigs carrega as configurações de um dispositivo.
func (h *Handler) loadDeviceConfigs(r *http.Request, deviceID int64) (map[string]string, error) {
	configs := make(map[string]string)
	rows, err := h.db.Query(r.Context(), `
		SELECT chave, valor
		  FROM hardware.device_configs
		 WHERE device_id = $1`, deviceID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var k, v string
		if err := rows.Scan(&k, &v); err == nil {
			configs[k] = v
		}
	}
	return configs, nil
}

// ListarDrivers lista os drivers disponíveis no sistema.
func (h *Handler) ListarDrivers(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(r.Context(), `
		SELECT codigo, nome, descricao, versao, ativo
		  FROM hardware.drivers
		 ORDER BY nome`)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type row struct {
		Codigo    string `json:"codigo"`
		Nome      string `json:"nome"`
		Descricao string `json:"descricao"`
		Versao    string `json:"versao"`
		Ativo     bool   `json:"ativo"`
	}
	data := []row{}
	for rows.Next() {
		var d row
		if rows.Scan(&d.Codigo, &d.Nome, &d.Descricao, &d.Versao, &d.Ativo) == nil {
			data = append(data, d)
		}
	}
	jsonOK(w, data, http.StatusOK)
}


