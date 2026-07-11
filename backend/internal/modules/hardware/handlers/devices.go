package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// DeviceRequest representa o body para criação/edição de dispositivo.
type DeviceRequest struct {
	Nome         string             `json:"nome"`
	SerialNumber *string            `json:"serial_number"`
	Modelo       *string            `json:"modelo"`
	Localizacao  *string            `json:"localizacao"`
	Tipo         *string            `json:"tipo"`
	Driver       *string            `json:"driver"`
	BranchID     *int64             `json:"branch_id"`
	IPPermitido  *string            `json:"ip_permitido"`
	Configs      map[string]*string `json:"configs"`
}

// DeviceResponse omiti o hash da chave por segurança.
type DeviceResponse struct {
	ID           int64              `json:"id"`
	TenantID     int64              `json:"tenant_id"`
	BranchID     *int64             `json:"branch_id"`
	Nome         string             `json:"nome"`
	SerialNumber *string            `json:"serial_number"`
	Modelo       string             `json:"modelo"`
	Localizacao  *string            `json:"localizacao"`
	Tipo         string             `json:"tipo"`
	Driver       string             `json:"driver"`
	IPPermitido  *string            `json:"ip_permitido"`
	APIKeyPrefix string             `json:"api_key_prefix"`
	Configs      map[string]*string `json:"configs"`
	Ativo        bool               `json:"ativo"`
	UltimoUsoEm  *time.Time         `json:"ultimo_uso_em"`
	CreatedAt    time.Time          `json:"created_at"`
}

func (h *Handler) ListarDispositivos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT id, tenant_id, branch_id, nome, serial_number, modelo, localizacao, tipo, driver,
		       COALESCE(ip_permitido::text, '') as ip_permitido, api_key_prefix, ativo, ultimo_uso_em, created_at
		  FROM hardware.devices
		 WHERE tenant_id = $1
		 ORDER BY created_at DESC`, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []DeviceResponse{}
	for rows.Next() {
		var d DeviceResponse
		var ip string
		if err := rows.Scan(&d.ID, &d.TenantID, &d.BranchID, &d.Nome, &d.SerialNumber, &d.Modelo, &d.Localizacao, &d.Tipo, &d.Driver,
			&ip, &d.APIKeyPrefix, &d.Ativo, &d.UltimoUsoEm, &d.CreatedAt); err == nil {
			if ip != "" {
				d.IPPermitido = &ip
			}
			data = append(data, d)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) ObterDispositivo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var d DeviceResponse
	var ip string
	err := h.db.QueryRow(r.Context(), `
		SELECT id, tenant_id, branch_id, nome, serial_number, modelo, localizacao, tipo, driver,
		       COALESCE(ip_permitido::text, '') as ip_permitido, api_key_prefix, ativo, ultimo_uso_em, created_at
		  FROM hardware.devices
		 WHERE id = $1 AND tenant_id = $2`, id, user.TenantID,
	).Scan(&d.ID, &d.TenantID, &d.BranchID, &d.Nome, &d.SerialNumber, &d.Modelo, &d.Localizacao, &d.Tipo, &d.Driver,
		&ip, &d.APIKeyPrefix, &d.Ativo, &d.UltimoUsoEm, &d.CreatedAt)
	if err != nil {
		jsonErr(w, "Dispositivo não encontrado", http.StatusNotFound)
		return
	}
	if ip != "" {
		d.IPPermitido = &ip
	}
	d.Configs = h.loadConfigsMap(r, d.ID)
	jsonOK(w, d, http.StatusOK)
}

func (h *Handler) CriarDispositivo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body DeviceRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nome == "" {
		jsonErr(w, "nome é obrigatório", http.StatusBadRequest)
		return
	}

	tipo := "entrada_saida"
	if body.Tipo != nil && *body.Tipo != "" {
		if !validDeviceTipo(*body.Tipo) {
			jsonErr(w, "tipo inválido", http.StatusBadRequest)
			return
		}
		tipo = *body.Tipo
	}

	driver := "hikvision"
	if body.Driver != nil && *body.Driver != "" {
		if !validDriver(*body.Driver) {
			jsonErr(w, "driver inválido", http.StatusBadRequest)
			return
		}
		driver = *body.Driver
	}

	modelo := "Hikvision DS-K1T673TDGX"
	if body.Modelo != nil && *body.Modelo != "" {
		modelo = *body.Modelo
	}

	rawKey, keyHash, prefix := generateAPIKey()

	var ip interface{}
	if body.IPPermitido != nil && *body.IPPermitido != "" {
		ip = *body.IPPermitido
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO hardware.devices
		  (tenant_id, branch_id, nome, serial_number, modelo, localizacao, tipo, driver, ip_permitido, api_key_hash, api_key_prefix)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING id`,
		user.TenantID, body.BranchID, body.Nome, body.SerialNumber, modelo,
		body.Localizacao, tipo, driver, ip, keyHash, prefix,
	).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Serial number já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro ao criar dispositivo", http.StatusInternalServerError)
		return
	}

	if err := h.saveDeviceConfigs(r, id, body.Configs); err != nil {
		jsonErr(w, "Dispositivo criado mas erro ao guardar configurações", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"id":             id,
		"api_key":        rawKey,
		"api_key_prefix": prefix,
	}, http.StatusCreated)
}

func (h *Handler) ActualizarDispositivo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body DeviceRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}

	if body.Tipo != nil && *body.Tipo != "" && !validDeviceTipo(*body.Tipo) {
		jsonErr(w, "tipo inválido", http.StatusBadRequest)
		return
	}
	if body.Driver != nil && *body.Driver != "" && !validDriver(*body.Driver) {
		jsonErr(w, "driver inválido", http.StatusBadRequest)
		return
	}

	var ip interface{}
	if body.IPPermitido != nil {
		if *body.IPPermitido == "" {
			ip = nil
		} else {
			ip = *body.IPPermitido
		}
	}

	_, err := h.db.Exec(r.Context(), `
		UPDATE hardware.devices
		   SET nome = COALESCE($1, nome),
		       serial_number = COALESCE($2, serial_number),
		       modelo = COALESCE($3, modelo),
		       localizacao = COALESCE($4, localizacao),
		       tipo = COALESCE($5, tipo),
		       driver = COALESCE($6, driver),
		       branch_id = COALESCE($7, branch_id),
		       ip_permitido = COALESCE($8, ip_permitido),
		       updated_at = NOW()
		 WHERE id = $9 AND tenant_id = $10`,
		body.Nome, body.SerialNumber, body.Modelo, body.Localizacao, body.Tipo,
		body.Driver, body.BranchID, ip, id, user.TenantID,
	)
	if err == nil {
		_ = h.saveDeviceConfigs(r, parseID(id), body.Configs)
	}
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Serial number já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro ao actualizar dispositivo", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) AlternarEstadoDispositivo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Ativo bool `json:"ativo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}

	_, err := h.db.Exec(r.Context(), `
		UPDATE hardware.devices SET ativo = $1, updated_at = NOW()
		 WHERE id = $2 AND tenant_id = $3`,
		body.Ativo, id, user.TenantID,
	)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) GerarNovaChave(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	rawKey, keyHash, prefix := generateAPIKey()
	_, err := h.db.Exec(r.Context(), `
		UPDATE hardware.devices
		   SET api_key_hash = $1, api_key_prefix = $2, updated_at = NOW()
		 WHERE id = $3 AND tenant_id = $4`,
		keyHash, prefix, id, user.TenantID,
	)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"api_key":        rawKey,
		"api_key_prefix": prefix,
	}, http.StatusOK)
}

// DeviceUserRequest representa o body para mapear employee_no a entidade ERP.
type DeviceUserRequest struct {
	EmployeeNo string `json:"employee_no"`
	EntityType string `json:"entity_type"`
	EntityID   int64  `json:"entity_id"`
}

func (h *Handler) ListarDeviceUsers(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	deviceID := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), `
		SELECT id, employee_no, entity_type, entity_id, ativo, created_at
		  FROM hardware.device_users
		 WHERE tenant_id = $1 AND device_id = $2
		 ORDER BY created_at DESC`, user.TenantID, deviceID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type row struct {
		ID         int64     `json:"id"`
		EmployeeNo string    `json:"employee_no"`
		EntityType string    `json:"entity_type"`
		EntityID   int64     `json:"entity_id"`
		Ativo      bool      `json:"ativo"`
		CreatedAt  time.Time `json:"created_at"`
	}
	data := []row{}
	for rows.Next() {
		var u row
		if rows.Scan(&u.ID, &u.EmployeeNo, &u.EntityType, &u.EntityID, &u.Ativo, &u.CreatedAt) == nil {
			data = append(data, u)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarDeviceUser(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	deviceID := chi.URLParam(r, "id")

	var body DeviceUserRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.EmployeeNo == "" || body.EntityType == "" || body.EntityID == 0 {
		jsonErr(w, "employee_no, entity_type e entity_id são obrigatórios", http.StatusBadRequest)
		return
	}
	if !validEntityType(body.EntityType) {
		jsonErr(w, "entity_type inválido", http.StatusBadRequest)
		return
	}

	// Verifica se dispositivo pertence ao tenant.
	var exists bool
	_ = h.db.QueryRow(r.Context(), `
		SELECT TRUE FROM hardware.devices WHERE id = $1 AND tenant_id = $2`,
		deviceID, user.TenantID,
	).Scan(&exists)
	if !exists {
		jsonErr(w, "Dispositivo não encontrado", http.StatusNotFound)
		return
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO hardware.device_users (tenant_id, device_id, employee_no, entity_type, entity_id)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (tenant_id, device_id, employee_no)
		DO UPDATE SET entity_type = EXCLUDED.entity_type, entity_id = EXCLUDED.entity_id, ativo = TRUE, updated_at = NOW()
		RETURNING id`,
		user.TenantID, deviceID, body.EmployeeNo, body.EntityType, body.EntityID,
	).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro ao criar mapeamento", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RemoverDeviceUser(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	deviceID := chi.URLParam(r, "id")
	mappingID := chi.URLParam(r, "mappingId")

	_, err := h.db.Exec(r.Context(), `
		DELETE FROM hardware.device_users
		 WHERE id = $1 AND device_id = $2 AND tenant_id = $3`,
		mappingID, deviceID, user.TenantID,
	)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func generateAPIKey() (raw, hash, prefix string) {
	b := make([]byte, 32)
	rand.Read(b)
	raw = "nxk_" + hex.EncodeToString(b)
	prefix = raw[:12]
	hash = mw.HashToken(raw)
	return
}

func validDeviceTipo(t string) bool {
	switch t {
	case "entrada", "saida", "entrada_saida", "sala":
		return true
	}
	return false
}

func validEntityType(t string) bool {
	switch t {
	case "funcionario", "aluno", "professor":
		return true
	}
	return false
}

// parseID converte string para int64 com fallback.
func parseID(s string) int64 {
	id, _ := strconv.ParseInt(s, 10, 64)
	return id
}

func (h *Handler) loadConfigsMap(r *http.Request, deviceID int64) map[string]*string {
	configs := make(map[string]*string)
	rows, err := h.db.Query(r.Context(), `
		SELECT chave, valor
		  FROM hardware.device_configs
		 WHERE device_id = $1`, deviceID)
	if err != nil {
		return configs
	}
	defer rows.Close()

	for rows.Next() {
		var k, v string
		if rows.Scan(&k, &v) == nil {
			configs[k] = &v
		}
	}
	return configs
}

func (h *Handler) saveDeviceConfigs(r *http.Request, deviceID int64, configs map[string]*string) error {
	if len(configs) == 0 {
		return nil
	}

	for k, v := range configs {
		if v == nil {
			_, _ = h.db.Exec(r.Context(), `
				DELETE FROM hardware.device_configs WHERE device_id = $1 AND chave = $2`,
				deviceID, k)
			continue
		}
		_, err := h.db.Exec(r.Context(), `
			INSERT INTO hardware.device_configs (device_id, chave, valor)
			VALUES ($1, $2, $3)
			ON CONFLICT (device_id, chave)
			DO UPDATE SET valor = EXCLUDED.valor, updated_at = NOW()`,
			deviceID, k, *v)
		if err != nil {
			return err
		}
	}
	return nil
}

func validDriver(d string) bool {
	switch d {
	case "hikvision", "zkteco", "generic_rest", "generic_mqtt", "custom":
		return true
	}
	return false
}
