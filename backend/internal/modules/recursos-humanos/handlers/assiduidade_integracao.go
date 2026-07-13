package handlers

import (
	"encoding/json"
	"math"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ── Endpoints consumidos por serviços externos de assiduidade (ex.: FaceClock) ──
//
// Autenticados via RequireDeviceAuth (X-API-Key contra hardware.devices), não
// por JWT de utilizador — o serviço externo é registado como um "device" e o
// seu tenant_id vem do próprio registo em hardware.devices. Ver secção 3 e 4
// de assiduidade_system_backend/CONTRATO-INTEGRACAO-ERP.md.

// resolveSaasTenantID traduz o tenant_id injectado por RequireDeviceAuth (que
// é na verdade empresas.companies.id, por causa da FK devices_tenant_id_fkey
// -> companies) para o saas.tenants.id real usado por rh.funcionarios e
// sistema_configuracao.tenant_feature_flags.
//
// Descoberto por teste manual em 2026-07-11: companies.id e saas.tenants.id
// são espaços de identificadores DIFERENTES que por acaso partilham o nome de
// coluna "tenant_id" em várias tabelas (ex.: Enigma School tem companies.id=7
// mas saas.tenants.id=5). O módulo hardware pré-existente (processor.go,
// registarPresenca) NÃO faz esta tradução e grava rh.presencas.tenant_id com
// o companies.id errado — bug pré-existente, fora do âmbito desta integração,
// reportado separadamente e não corrigido aqui.
func resolveSaasTenantID(h *Handler, r *http.Request, companyID int64) (int64, error) {
	var saasTenantID int64
	err := h.db.QueryRow(r.Context(),
		`SELECT tenant_id FROM empresas.companies WHERE id = $1`, companyID,
	).Scan(&saasTenantID)
	return saasTenantID, err
}

// GET /api/hardware/assiduidade/config
// Devolve a configuração activa de rh.assiduidade para o tenant do device autenticado.
func (h *Handler) ObterConfigAssiduidadeDevice(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := resolveSaasTenantID(h, r, user.TenantID)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}
	var activo bool
	var configuracao json.RawMessage
	err = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(tf.activo, fc.ativo_por_defeito), COALESCE(tf.configuracao, '{}'::jsonb)
		  FROM saas.feature_catalog fc
		  LEFT JOIN sistema_configuracao.tenant_feature_flags tf
		    ON tf.tenant_id = $1 AND tf.codigo = fc.key
		 WHERE fc.key = 'rh.assiduidade'`, tenantID).
		Scan(&activo, &configuracao)
	if err != nil {
		jsonErr(w, "Feature rh.assiduidade não encontrada no catálogo", http.StatusNotFound)
		return
	}
	if !activo {
		jsonErr(w, "Assiduidade não activa para este tenant", http.StatusPaymentRequired)
		return
	}
	jsonOK(w, map[string]any{
		"tenant_id":    tenantID,
		"configuracao": configuracao,
	}, http.StatusOK)
}

// FuncionarioIntegracao é o formato de funcionário esperado por integrações
// externas (ex.: sync.py do FaceClock) — nomes em inglês, distinto do payload
// de ListarFuncionarios (que serve a UI do ERP em português). Ver secção 4 do
// CONTRATO-INTEGRACAO-ERP.md: não é uma adaptação de ListarFuncionarios, é um
// endpoint dedicado.
type FuncionarioIntegracao struct {
	ID           int64   `json:"id"`
	EmployeeCode string  `json:"employee_code"`
	FullName     string  `json:"full_name"`
	Email        *string `json:"email"`
	// Role fixo em COLABORADOR nesta fase: o ERP ainda não distingue
	// GESTOR_RH/AUDITOR por funcionário (só por cargo/permissões RBAC
	// completas, que esta integração não expõe) — ver secção 7 do contrato.
	Role     string `json:"role"`
	IsActive bool   `json:"is_active"`
	TenantID int64  `json:"tenant_id"`
}

// GET /api/hardware/assiduidade/funcionarios
// Lista os funcionários do tenant do device autenticado, no formato esperado
// pelo sync.py do FaceClock (employee_code, full_name, email, role, is_active).
func (h *Handler) ListarFuncionariosIntegracao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := resolveSaasTenantID(h, r, user.TenantID)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}
	rows, err := h.db.Query(r.Context(), `
		SELECT f.id,
		       COALESCE(NULLIF(f.numero_funcionario, ''), 'F' || f.id) AS employee_code,
		       f.nome_completo,
		       COALESCE(NULLIF(f.email, ''), au.email),
		       f.estado = 'ativo',
		       f.tenant_id
		  FROM rh.funcionarios f
		  LEFT JOIN auth.users au ON au.id = f.user_id
		 WHERE f.tenant_id = $1
		 ORDER BY f.nome_completo`, tenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []FuncionarioIntegracao{}
	for rows.Next() {
		var f FuncionarioIntegracao
		if rows.Scan(&f.ID, &f.EmployeeCode, &f.FullName, &f.Email, &f.IsActive, &f.TenantID) == nil {
			f.Role = "COLABORADOR"
			data = append(data, f)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// GET /api/hardware/assiduidade/funcionarios/{id}
// Obtém um único funcionário do tenant do device autenticado, no mesmo
// formato de ListarFuncionariosIntegracao — usado por sync_single_employee no FaceClock.
func (h *Handler) ObterFuncionarioIntegracao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := resolveSaasTenantID(h, r, user.TenantID)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}
	id := chi.URLParam(r, "id")

	var f FuncionarioIntegracao
	err = h.db.QueryRow(r.Context(), `
		SELECT f.id,
		       COALESCE(NULLIF(f.numero_funcionario, ''), 'F' || f.id) AS employee_code,
		       f.nome_completo,
		       COALESCE(NULLIF(f.email, ''), au.email),
		       f.estado = 'ativo',
		       f.tenant_id
		  FROM rh.funcionarios f
		  LEFT JOIN auth.users au ON au.id = f.user_id
		 WHERE f.tenant_id = $1 AND f.id = $2`, tenantID, id).
		Scan(&f.ID, &f.EmployeeCode, &f.FullName, &f.Email, &f.IsActive, &f.TenantID)
	if err != nil {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}
	f.Role = "COLABORADOR"
	jsonOK(w, f, http.StatusOK)
}

// GET /api/hardware/assiduidade/geofence/validar?unidade_id=&latitude=&longitude=
// Valida se as coordenadas recebidas estão dentro do raio permitido da
// unidade indicada. Se a unidade não tiver geofencing configurado
// (latitude/longitude/raio_metros nulos), a validação é permissiva
// (valid=true, reason=geofence_not_configured) — mantém o comportamento
// anterior do FaceClock como fallback explícito em vez de bloquear tenants
// que ainda não configuraram nenhuma unidade.
func (h *Handler) ValidarGeofenceDevice(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := resolveSaasTenantID(h, r, user.TenantID)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}

	unidadeID := r.URL.Query().Get("unidade_id")
	lat, errLat := strconv.ParseFloat(r.URL.Query().Get("latitude"), 64)
	lon, errLon := strconv.ParseFloat(r.URL.Query().Get("longitude"), 64)
	if unidadeID == "" || errLat != nil || errLon != nil {
		jsonErr(w, "unidade_id, latitude e longitude são obrigatórios", http.StatusBadRequest)
		return
	}

	var nome string
	var refLat, refLon, raio *float64
	err = h.db.QueryRow(r.Context(), `
		SELECT nome, latitude, longitude, raio_metros
		  FROM rh.unidades_organizacionais
		 WHERE id=$1 AND tenant_id=$2`, unidadeID, tenantID).
		Scan(&nome, &refLat, &refLon, &raio)
	if err != nil {
		jsonErr(w, "Unidade não encontrada", http.StatusNotFound)
		return
	}

	if refLat == nil || refLon == nil || raio == nil {
		jsonOK(w, map[string]any{
			"valid":     true,
			"unit_name": nome,
			"reason":    "geofence_not_configured",
		}, http.StatusOK)
		return
	}

	distance := haversineMeters(*refLat, *refLon, lat, lon)
	jsonOK(w, map[string]any{
		"valid":           distance <= *raio,
		"unit_name":       nome,
		"distance_meters": distance,
		"radius_meters":   *raio,
	}, http.StatusOK)
}

// haversineMeters calcula a distância em metros entre duas coordenadas
// geográficas (fórmula de Haversine, raio da Terra = 6371 km).
func haversineMeters(lat1, lon1, lat2, lon2 float64) float64 {
	const earthRadiusMeters = 6371000.0
	toRad := func(deg float64) float64 { return deg * math.Pi / 180 }

	dLat := toRad(lat2 - lat1)
	dLon := toRad(lon2 - lon1)
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(toRad(lat1))*math.Cos(toRad(lat2))*math.Sin(dLon/2)*math.Sin(dLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return earthRadiusMeters * c
}
