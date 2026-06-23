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
		Codigo    string  `json:"codigo"`
		Nome      string  `json:"nome"`
		Telefone  *string `json:"telefone"`
		Documento *string `json:"documento"`
		Carta     *string `json:"carta_conducao"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Codigo == "" || b.Nome == "" {
		jsonErr(w, "codigo e nome sao obrigatorios", 400)
		return
	}
	h.createJSON(w, r, `INSERT INTO logistica.delivery_drivers
		(tenant_id,codigo,nome,telefone,documento,carta_conducao) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		u.TenantID, b.Codigo, b.Nome, b.Telefone, b.Documento, b.Carta)
}

func (h *Handler) ListarMotoristas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome),'[]') FROM (
		SELECT * FROM logistica.delivery_drivers WHERE tenant_id=$1) x`, u.TenantID)
}

func (h *Handler) CriarViatura(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Codigo     string   `json:"codigo"`
		Matricula  string   `json:"matricula"`
		Marca      *string  `json:"marca"`
		Modelo     *string  `json:"modelo"`
		Capacidade *float64 `json:"capacidade_kg"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Codigo == "" || b.Matricula == "" {
		jsonErr(w, "codigo e matricula sao obrigatorios", 400)
		return
	}
	h.createJSON(w, r, `INSERT INTO logistica.delivery_vehicles
		(tenant_id,codigo,matricula,marca,modelo,capacidade_kg) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		u.TenantID, b.Codigo, b.Matricula, b.Marca, b.Modelo, b.Capacidade)
}

func (h *Handler) ListarViaturas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.codigo),'[]') FROM (
		SELECT * FROM logistica.delivery_vehicles WHERE tenant_id=$1) x`, u.TenantID)
}

func (h *Handler) CriarRota(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Codigo    string   `json:"codigo"`
		Nome      string   `json:"nome"`
		Origem    string   `json:"origem"`
		Destino   string   `json:"destino"`
		Distancia *float64 `json:"distancia_km"`
		Duracao   *int     `json:"duracao_estimada_min"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Codigo == "" || b.Nome == "" || b.Origem == "" || b.Destino == "" {
		jsonErr(w, "codigo, nome, origem e destino sao obrigatorios", 400)
		return
	}
	h.createJSON(w, r, `INSERT INTO logistica.delivery_routes
		(tenant_id,codigo,nome,origem,destino,distancia_km,duracao_estimada_min)
		VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
		u.TenantID, b.Codigo, b.Nome, b.Origem, b.Destino, b.Distancia, b.Duracao)
}

func (h *Handler) ListarRotas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome),'[]') FROM (
		SELECT * FROM logistica.delivery_routes WHERE tenant_id=$1) x`, u.TenantID)
}

func (h *Handler) CriarEstadoEntrega(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Codigo string `json:"codigo"`
		Nome   string `json:"nome"`
		Ordem  int    `json:"ordem"`
		Final  bool   `json:"final"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Codigo == "" || b.Nome == "" {
		jsonErr(w, "codigo e nome sao obrigatorios", 400)
		return
	}
	h.createJSON(w, r, `INSERT INTO logistica.delivery_statuses
		(tenant_id,codigo,nome,ordem,final) VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		u.TenantID, b.Codigo, b.Nome, b.Ordem, b.Final)
}

func (h *Handler) ListarEstadosEntrega(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.ordem,x.nome),'[]') FROM (
		SELECT * FROM logistica.delivery_statuses WHERE tenant_id=$1 AND activo) x`, u.TenantID)
}

func (h *Handler) CriarEnvio(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		Numero        string  `json:"numero"`
		ReferenceType *string `json:"reference_type"`
		ReferenceID   *int64  `json:"reference_id"`
		CustomerID    *int64  `json:"customer_id"`
		RouteID       *int64  `json:"route_id"`
		DriverID      *int64  `json:"driver_id"`
		VehicleID     *int64  `json:"vehicle_id"`
		StatusID      *int64  `json:"status_id"`
		Endereco      string  `json:"endereco_entrega"`
		Contacto      *string `json:"contacto_entrega"`
		DataPrevista  *string `json:"data_prevista"`
		Observacoes   *string `json:"observacoes"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.Numero == "" || b.Endereco == "" {
		jsonErr(w, "numero e endereco_entrega sao obrigatorios", 400)
		return
	}
	h.createJSON(w, r, `INSERT INTO logistica.shipments
		(tenant_id,numero,reference_type,reference_id,customer_id,route_id,driver_id,vehicle_id,status_id,
		endereco_entrega,contacto_entrega,data_prevista,observacoes,created_by)
		SELECT $1,$2,$3,$4,$5,$6,$7,$8,COALESCE($9,(SELECT id FROM logistica.delivery_statuses
		WHERE tenant_id=$1 AND activo ORDER BY ordem,id LIMIT 1)),$10,$11,$12::timestamptz,$13,$14 RETURNING id`,
		u.TenantID, b.Numero, b.ReferenceType, b.ReferenceID, b.CustomerID, b.RouteID, b.DriverID,
		b.VehicleID, b.StatusID, b.Endereco, b.Contacto, b.DataPrevista, b.Observacoes, u.ID)
}

func (h *Handler) ListarEnvios(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "s.tenant_id=$1"
	args := []any{u.TenantID}
	logisticsFilter(r, &where, &args, "status_id", "s.status_id")
	logisticsFilter(r, &where, &args, "driver_id", "s.driver_id")
	logisticsFilter(r, &where, &args, "vehicle_id", "s.vehicle_id")
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.created_at DESC,x.id DESC),'[]') FROM (
		SELECT s.*,ds.codigo status,ds.nome status_nome,d.nome driver_name,v.matricula vehicle_plate,r.nome route_name,
		COALESCE((SELECT jsonb_agg(to_jsonb(i) ORDER BY i.id) FROM logistica.shipment_items i
		WHERE i.shipment_id=s.id),'[]') items FROM logistica.shipments s
		LEFT JOIN logistica.delivery_statuses ds ON ds.id=s.status_id
		LEFT JOIN logistica.delivery_drivers d ON d.id=s.driver_id
		LEFT JOIN logistica.delivery_vehicles v ON v.id=s.vehicle_id
		LEFT JOIN logistica.delivery_routes r ON r.id=s.route_id WHERE `+where+`) x`, args...)
}

func (h *Handler) AdicionarItemEnvio(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		ShipmentID int64    `json:"shipment_id"`
		ProductID  *int64   `json:"product_id"`
		Descricao  string   `json:"descricao"`
		Quantidade float64  `json:"quantidade"`
		Peso       *float64 `json:"peso_kg"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.ShipmentID == 0 || b.Descricao == "" || b.Quantidade <= 0 {
		jsonErr(w, "shipment_id, descricao e quantidade sao obrigatorios", 400)
		return
	}
	h.createJSON(w, r, `INSERT INTO logistica.shipment_items (shipment_id,product_id,descricao,quantidade,peso_kg)
		SELECT s.id,$3,$4,$5,$6 FROM logistica.shipments s WHERE s.id=$2 AND s.tenant_id=$1 RETURNING shipment_items.id`,
		u.TenantID, b.ShipmentID, b.ProductID, b.Descricao, b.Quantidade, b.Peso)
}

func (h *Handler) CriarTracking(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var b struct {
		ShipmentID  int64    `json:"shipment_id"`
		StatusID    int64    `json:"status_id"`
		Latitude    *float64 `json:"latitude"`
		Longitude   *float64 `json:"longitude"`
		Localizacao *string  `json:"localizacao"`
		Observacoes *string  `json:"observacoes"`
	}
	if json.NewDecoder(r.Body).Decode(&b) != nil || b.ShipmentID == 0 || b.StatusID == 0 {
		jsonErr(w, "shipment_id e status_id sao obrigatorios", 400)
		return
	}
	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", 500)
		return
	}
	defer tx.Rollback(r.Context())
	var id int64
	var final bool
	err = tx.QueryRow(r.Context(), `INSERT INTO logistica.delivery_tracking
		(tenant_id,shipment_id,status_id,latitude,longitude,localizacao,observacoes,registado_por)
		SELECT $1,s.id,ds.id,$4,$5,$6,$7,$8 FROM logistica.shipments s
		JOIN logistica.delivery_statuses ds ON ds.id=$3 AND ds.tenant_id=$1 AND ds.activo
		WHERE s.id=$2 AND s.tenant_id=$1 RETURNING id,(SELECT final FROM logistica.delivery_statuses WHERE id=$3)`,
		u.TenantID, b.ShipmentID, b.StatusID, b.Latitude, b.Longitude, b.Localizacao, b.Observacoes, u.ID).Scan(&id, &final)
	if err != nil {
		jsonErr(w, "Envio ou estado invalido", 422)
		return
	}
	_, err = tx.Exec(r.Context(), `UPDATE logistica.shipments SET status_id=$1,
		data_entrega=CASE WHEN $2 THEN COALESCE(data_entrega,NOW()) ELSE data_entrega END,updated_at=NOW()
		WHERE id=$3 AND tenant_id=$4`, b.StatusID, final, b.ShipmentID, u.TenantID)
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro ao actualizar envio", 500)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ListarTracking(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "t.tenant_id=$1"
	args := []any{u.TenantID}
	logisticsFilter(r, &where, &args, "shipment_id", "t.shipment_id")
	h.listJSON(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.registado_em DESC,x.id DESC),'[]') FROM (
		SELECT t.*,s.numero shipment_number,ds.codigo status,ds.nome status_nome
		FROM logistica.delivery_tracking t JOIN logistica.shipments s ON s.id=t.shipment_id
		JOIN logistica.delivery_statuses ds ON ds.id=t.status_id WHERE `+where+`) x`, args...)
}

func (h *Handler) ListarLogsEntrega(w http.ResponseWriter, r *http.Request) {
	h.ListarTracking(w, r)
}
