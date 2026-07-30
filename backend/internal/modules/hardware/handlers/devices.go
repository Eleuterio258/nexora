package handlers

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
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

// Nota sobre tenant_id em hardware.devices
//
// hardware.devices.tenant_id é um empresas.companies.id — garantido pela FK
// devices_tenant_id_fkey — enquanto AuthUser.TenantID, vindo do JWT, é um
// saas.tenants.id (auth.memberships.tenant_id referencia saas.tenants
// directamente). São os dois espaços de IDs descritos em pkg/tenantid, e o
// processador de eventos traduz de um para o outro com tenantid.ResolveSaas.
//
// Comparar os dois directamente — o que estes handlers faziam — não devolvia
// nada no caso benigno e, no caso mau, atravessava a fronteira do tenant:
// basta que o saas.tenants.id de um tenant coincida com o companies.id de
// outro (ex.: saas.tenants 7 = e258tech, mas companies 7 = Instituto
// Politécnico). Por isso todas as queries a hardware.devices filtram pelas
// empresas do tenant autenticado — no plural, porque um tenant pode ter mais
// do que uma empresa.
func (h *Handler) ListarDispositivos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	rows, err := h.db.Query(r.Context(), `
		SELECT id, tenant_id, branch_id, nome, serial_number, modelo, localizacao, tipo, driver,
		       COALESCE(ip_permitido::text, '') as ip_permitido, api_key_prefix, ativo, ultimo_uso_em, created_at
		  FROM hardware.devices
		 WHERE tenant_id IN (SELECT id FROM empresas.companies WHERE tenant_id = $1)
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
		 WHERE id = $1
		   AND tenant_id IN (SELECT id FROM empresas.companies WHERE tenant_id = $2)`, id, user.TenantID,
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

	// tenant_id aqui é um empresas.companies.id (ver a nota acima de
	// ListarDispositivos). Gravar o user.TenantID do JWT sem traduzir punha o
	// dispositivo numa empresa arbitrária: no melhor caso inexistente (a FK
	// rejeitava), no pior a empresa de outro tenant, e então tudo o que esse
	// dispositivo marcasse era escrito no tenant vizinho, porque o
	// processador de eventos parte de devices.tenant_id para chegar ao tenant
	// SaaS.
	companyID, err := h.empresaDoDispositivo(r.Context(), user.TenantID, body.BranchID)
	if err != nil {
		jsonErr(w, err.Error(), http.StatusUnprocessableEntity)
		return
	}

	var id int64
	err = h.db.QueryRow(r.Context(), `
		INSERT INTO hardware.devices
		  (tenant_id, branch_id, nome, serial_number, modelo, localizacao, tipo, driver, ip_permitido, api_key_hash, api_key_prefix)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING id`,
		companyID, body.BranchID, body.Nome, body.SerialNumber, modelo,
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
		 WHERE id = $9
		   AND tenant_id IN (SELECT id FROM empresas.companies WHERE tenant_id = $10)`,
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
		 WHERE id = $2
		   AND tenant_id IN (SELECT id FROM empresas.companies WHERE tenant_id = $3)`,
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
		 WHERE id = $3
		   AND tenant_id IN (SELECT id FROM empresas.companies WHERE tenant_id = $4)`,
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

	// Verifica se dispositivo pertence ao tenant. O tenant_id gravado em
	// hardware.device_users é o saas.tenants.id (mesmo espaço de
	// rh.funcionarios.tenant_id, para onde entity_id aponta), por isso o
	// INSERT abaixo usa user.TenantID sem tradução; só esta verificação de
	// posse toca em hardware.devices e precisa das empresas do tenant.
	var exists bool
	_ = h.db.QueryRow(r.Context(), `
		SELECT TRUE FROM hardware.devices
		 WHERE id = $1
		   AND tenant_id IN (SELECT id FROM empresas.companies WHERE tenant_id = $2)`,
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

// empresaDoDispositivo escolhe a empresa (empresas.companies.id) em que gravar
// um dispositivo do tenant autenticado — o valor que vai para
// hardware.devices.tenant_id.
//
// Com branch_id, é a empresa dessa filial, desde que a filial seja do tenant;
// isto impede de caminho que um dispositivo fique com branch_id de uma empresa
// e tenant_id de outra. Sem branch_id, a escolha só é inequívoca quando o
// tenant tem exactamente uma empresa — com várias, quem cria tem de dizer qual,
// indicando a filial.
func (h *Handler) empresaDoDispositivo(ctx context.Context, tenantID int64, branchID *int64) (int64, error) {
	if branchID != nil {
		var companyID int64
		err := h.db.QueryRow(ctx, `
			SELECT b.company_id
			  FROM empresas.company_branches b
			  JOIN empresas.companies c ON c.id = b.company_id
			 WHERE b.id = $1 AND c.tenant_id = $2`, *branchID, tenantID,
		).Scan(&companyID)
		if err != nil {
			return 0, errors.New("branch_id não pertence a nenhuma empresa deste tenant")
		}
		return companyID, nil
	}

	var companyIDs []int64
	err := h.db.QueryRow(ctx, `
		SELECT COALESCE(array_agg(id ORDER BY id), '{}')
		  FROM empresas.companies
		 WHERE tenant_id = $1`, tenantID,
	).Scan(&companyIDs)
	if err != nil {
		return 0, errors.New("erro ao resolver a empresa do tenant")
	}

	switch len(companyIDs) {
	case 0:
		return 0, errors.New("tenant sem empresa associada")
	case 1:
		return companyIDs[0], nil
	default:
		return 0, errors.New("tenant com várias empresas: indique branch_id")
	}
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
