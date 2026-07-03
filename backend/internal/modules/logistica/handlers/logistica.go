package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	mw "nexora/internal/middleware"
)

func (h *Handler) listJSON(w http.ResponseWriter, r *http.Request, query string, args ...any) {
	var raw []byte
	if err := h.db.QueryRow(r.Context(), query, args...).Scan(&raw); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func logisticsFilter(r *http.Request, where *string, args *[]any, key, column string) {
	value := strings.TrimSpace(r.URL.Query().Get(key))
	if value == "" {
		return
	}
	*args = append(*args, value)
	*where += " AND " + column + "=$" + strconv.Itoa(len(*args))
}

func (h *Handler) createJSON(w http.ResponseWriter, r *http.Request, query string, args ...any) {
	var id int64
	if err := h.db.QueryRow(r.Context(), query, args...).Scan(&id); err != nil {
		jsonErr(w, "Dados invalidos ou registo duplicado", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) CriarMotorista(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Codigo      string  `json:"codigo"`
		Nome        string  `json:"nome"`
		Telefone    *string `json:"telefone"`
		CartaNumero *string `json:"carta_numero"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Codigo == "" || b.Nome == "" {
		jsonErr(w, "codigo e nome sao obrigatorios", 400)
		return
	}
	h.createJSON(w, r, `INSERT INTO logistica.logistics_drivers
		(tenant_id,codigo,nome,telefone,carta_numero) VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		u.TenantID, b.Codigo, b.Nome, b.Telefone, b.CartaNumero)
}

func (h *Handler) ListarMotoristas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome),'[]') FROM (
		SELECT * FROM logistica.logistics_drivers WHERE tenant_id=$1 AND activo) x`, u.TenantID)
}

func (h *Handler) CriarViatura(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Codigo      string   `json:"codigo"`
		Matricula   string   `json:"matricula"`
		Descricao   *string  `json:"descricao"`
		Capacidade  *float64 `json:"capacidade_kg"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Codigo == "" || b.Matricula == "" {
		jsonErr(w, "codigo e matricula sao obrigatorios", 400)
		return
	}
	h.createJSON(w, r, `INSERT INTO logistica.logistics_vehicles
		(tenant_id,codigo,matricula,descricao,capacidade_kg) VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		u.TenantID, b.Codigo, b.Matricula, b.Descricao, b.Capacidade)
}

func (h *Handler) ListarViaturas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.codigo),'[]') FROM (
		SELECT * FROM logistica.logistics_vehicles WHERE tenant_id=$1 AND activo) x`, u.TenantID)
}

func (h *Handler) CriarRota(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Codigo     string   `json:"codigo"`
		Nome       string   `json:"nome"`
		Origem     string   `json:"origem"`
		Destino    string   `json:"destino"`
		Distancia  *float64 `json:"distancia_km"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Codigo == "" || b.Nome == "" || b.Origem == "" || b.Destino == "" {
		jsonErr(w, "codigo, nome, origem e destino sao obrigatorios", 400)
		return
	}
	h.createJSON(w, r, `INSERT INTO logistica.logistics_routes
		(tenant_id,codigo,nome,origem,destino,distancia_km)
		VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		u.TenantID, b.Codigo, b.Nome, b.Origem, b.Destino, b.Distancia)
}

func (h *Handler) ListarRotas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome),'[]') FROM (
		SELECT * FROM logistica.logistics_routes WHERE tenant_id=$1 AND activo) x`, u.TenantID)
}

func (h *Handler) CriarEnvio(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Numero          string  `json:"numero"`
		SourceService   string  `json:"source_service"`
		SourceType      *string `json:"source_type"`
		SourceID        *int64  `json:"source_id"`
		CustomerID      *int64  `json:"customer_id"`
		RouteID         *int64  `json:"route_id"`
		DriverID        *int64  `json:"driver_id"`
		VehicleID       *int64  `json:"vehicle_id"`
		DeliveryAddress string  `json:"delivery_address"`
		ScheduledDate   *string `json:"scheduled_date"`
		Status          *string `json:"status"`
		Observacoes     *string `json:"observacoes"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Numero == "" || b.DeliveryAddress == "" {
		jsonErr(w, "numero e delivery_address sao obrigatorios", 400)
		return
	}
	status := "planeada"
	if b.Status != nil && *b.Status != "" {
		status = *b.Status
	}
	sourceService := "logistica"
	if b.SourceService != "" {
		sourceService = b.SourceService
	}
	h.createJSON(w, r, `INSERT INTO logistica.logistics_shipments
		(tenant_id,numero,source_service,source_type,source_id,customer_id,logistics_route_id,driver_id,vehicle_id,
		delivery_address,scheduled_date,status,observacoes,created_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11::date,$12,$13,$14) RETURNING id`,
		u.TenantID, b.Numero, sourceService, b.SourceType, b.SourceID, b.CustomerID, b.RouteID, b.DriverID,
		b.VehicleID, b.DeliveryAddress, b.ScheduledDate, status, b.Observacoes, u.ID)
}

func (h *Handler) ListarEnvios(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "s.tenant_id=$1"
	args := []any{u.TenantID}
	logisticsFilter(r, &where, &args, "status", "s.status")
	logisticsFilter(r, &where, &args, "driver_id", "s.driver_id")
	logisticsFilter(r, &where, &args, "vehicle_id", "s.vehicle_id")
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.created_at DESC,x.id DESC),'[]') FROM (
		SELECT s.*,d.nome driver_name,v.matricula vehicle_plate,r.nome route_name
		FROM logistica.logistics_shipments s
		LEFT JOIN logistica.logistics_drivers d ON d.id=s.driver_id
		LEFT JOIN logistica.logistics_vehicles v ON v.id=s.vehicle_id
		LEFT JOIN logistica.logistics_routes r ON r.id=s.logistics_route_id WHERE `+where+`) x`, args...)
}

func (h *Handler) CriarTracking(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		ShipmentID  int64    `json:"shipment_id"`
		Evento      string   `json:"evento"`
		Latitude    *float64 `json:"latitude"`
		Longitude   *float64 `json:"longitude"`
		Localizacao *string  `json:"localizacao"`
		Observacoes *string  `json:"observacoes"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.ShipmentID == 0 || b.Evento == "" {
		jsonErr(w, "shipment_id e evento sao obrigatorios", 400)
		return
	}
	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", 500)
		return
	}
	defer tx.Rollback(r.Context())
	var id int64
	var eventTime string
	err = tx.QueryRow(r.Context(), `INSERT INTO logistica.logistics_tracking_events
		(tenant_id,shipment_id,evento,latitude,longitude,localizacao,observacoes,created_by)
		SELECT $1,$2,$3,$4,$5,$6,$7,$8 FROM logistica.logistics_shipments s
		WHERE s.id=$2 AND s.tenant_id=$1
		RETURNING id, event_time`,
		u.TenantID, b.ShipmentID, b.Evento, b.Latitude, b.Longitude, b.Localizacao, b.Observacoes, u.ID).Scan(&id, &eventTime)
	if err != nil {
		jsonErr(w, "Envio invalido", 422)
		return
	}
	// Atualiza status do envio consoante o evento
	_, err = tx.Exec(r.Context(), `UPDATE logistica.logistics_shipments
		SET status=CASE
			WHEN lower($1) LIKE '%entreg%' THEN 'entregue'
			WHEN lower($1) LIKE '%transit%' OR lower($1) LIKE '%sai%' THEN 'em_transito'
			ELSE status
		END,
		updated_at=NOW()
		WHERE id=$2 AND tenant_id=$3`, b.Evento, b.ShipmentID, u.TenantID)
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro ao actualizar envio", 500)
		return
	}
	jsonOK(w, map[string]any{"id": id, "event_time": eventTime}, http.StatusCreated)
}

func (h *Handler) ListarTracking(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "t.tenant_id=$1"
	args := []any{u.TenantID}
	logisticsFilter(r, &where, &args, "shipment_id", "t.shipment_id")
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.event_time DESC,x.id DESC),'[]') FROM (
		SELECT t.*,s.numero shipment_number
		FROM logistica.logistics_tracking_events t
		JOIN logistica.logistics_shipments s ON s.id=t.shipment_id
		WHERE `+where+`) x`, args...)
}

func (h *Handler) ListarLogsEntrega(w http.ResponseWriter, r *http.Request) {
	h.ListarTracking(w, r)
}
