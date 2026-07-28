package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// CaptureImage representa uma captura facial em base64.
type CaptureImage struct {
	ImageBase64 string `json:"image_base64"`
}

// EnrollFacialRequest é o payload para cadastro de biometria facial.
type EnrollFacialRequest struct {
	Captures []CaptureImage `json:"captures"`
}

// FaceClockEnrollRequest é o formato esperado pelo FaceClock.
type FaceClockEnrollRequest struct {
	UserID   string         `json:"user_id"`
	Captures []CaptureImage `json:"captures"`
}

// EnrollFacialResponse é a resposta do FaceClock para enrollment.
type EnrollFacialResponse struct {
	TemplateID   string `json:"template_id"`
	UserID       int64  `json:"user_id"`
	ModelVersion string `json:"model_version"`
	Status       string `json:"status"`
}

// EnrollFacial permite que um gestor RH cadastre o rosto de um funcionário.
//
// Permissão: recursos-humanos:gerir_funcionarios
//
// Fluxo:
//  1. Verifica se o funcionário existe e pertence ao tenant do gestor.
//  2. Verifica se existe consentimento LGPD ativo para biometria.
//  3. Verifica se o método "facial" está activo na configuração do tenant.
//  4. Envia as capturas para o FaceClock (/api/v1/biometric/enroll).
//  5. Devolve o resultado do enrollment.
func (h *Handler) EnrollFacial(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	if user == nil {
		jsonErr(w, "Não autenticado", http.StatusUnauthorized)
		return
	}

	funcionarioIDStr := chi.URLParam(r, "id")
	var funcionarioID int64
	if _, err := fmt.Sscan(funcionarioIDStr, &funcionarioID); err != nil || funcionarioID <= 0 {
		jsonErr(w, "ID do funcionário inválido", http.StatusBadRequest)
		return
	}
	if !h.podeGerirFuncionario(r, funcionarioID) {
		jsonErr(w, "Sem permissão para gerir este funcionário", http.StatusForbidden)
		return
	}

	var body EnrollFacialRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}
	if len(body.Captures) < 3 {
		jsonErr(w, "São necessárias pelo menos 3 capturas faciais", http.StatusBadRequest)
		return
	}

	// 1. Funcionário existe, está activo e pertence ao tenant.
	var erpUserID int64
	var tenantID int64
	err := h.db.QueryRow(r.Context(), `
		SELECT f.user_id, f.tenant_id
		  FROM rh.funcionarios f
		  JOIN auth.users u ON u.id = f.user_id
		 WHERE f.id = $1 AND f.tenant_id = $2 AND u.estado = 'ativo'`,
		funcionarioID, user.TenantID,
	).Scan(&erpUserID, &tenantID)
	if err != nil {
		jsonErr(w, "Funcionário não encontrado ou inativo", http.StatusNotFound)
		return
	}

	// 2. Consentimento LGPD activo para biometria.
	var consentimentoID int64
	err = h.db.QueryRow(r.Context(), `
		SELECT id
		  FROM lgpd.consentimentos
		 WHERE funcionario_id = $1 AND tenant_id = $2 AND revogado_em IS NULL
		 ORDER BY aceite_em DESC LIMIT 1`,
		funcionarioID, tenantID,
	).Scan(&consentimentoID)
	if err != nil {
		jsonErr(w, "Consentimento de dados biométricos não encontrado ou revogado", http.StatusForbidden)
		return
	}

	// 3. Método facial activo para o tenant.
	ativo, err := h.metodoFacialAtivo(r.Context(), tenantID)
	if err != nil {
		jsonErr(w, "Erro ao verificar configuração de assiduidade", http.StatusInternalServerError)
		return
	}
	if !ativo {
		jsonErr(w, "Método de reconhecimento facial não está activo para este tenant", http.StatusForbidden)
		return
	}

	// 4. Chamar FaceClock para criar o template facial.
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		jsonErr(w, "Cabeçalho Authorization em falta", http.StatusUnauthorized)
		return
	}

	faceClockReq := FaceClockEnrollRequest{
		UserID:   fmt.Sprintf("%d", erpUserID),
		Captures: body.Captures,
	}
	faceClockResp, statusCode, err := h.callFaceClockEnroll(r, authHeader, faceClockReq)
	if err != nil {
		jsonErr(w, fmt.Sprintf("Erro ao comunicar com FaceClock: %s", err.Error()), http.StatusBadGateway)
		return
	}
	if statusCode >= 400 {
		jsonErr(w, fmt.Sprintf("FaceClock rejeitou o enrollment: %s", faceClockResp), statusCode)
		return
	}

	jsonOK(w, faceClockResp, http.StatusCreated)
}

// metodoFacialAtivo verifica se o método "facial" está activo na configuração
// de assiduidade do tenant. Falha aberta (permite) se a configuração estiver
// ausente ou mal-formada, para não bloquear tenants sem configuração completa.
func (h *Handler) metodoFacialAtivo(ctx context.Context, tenantID int64) (bool, error) {
	var activo bool
	var configuracao []byte
	err := h.db.QueryRow(ctx, `
		SELECT COALESCE(tf.activo, fc.ativo_por_defeito), COALESCE(tf.configuracao, '{}'::jsonb)
		  FROM saas.feature_catalog fc
		  LEFT JOIN sistema_configuracao.tenant_feature_flags tf
		    ON tf.tenant_id = $1 AND tf.codigo = fc.key
		 WHERE fc.key = 'rh.assiduidade'`, tenantID).
		Scan(&activo, &configuracao)
	if err != nil {
		return true, nil // feature não existe — falha aberta
	}
	if !activo {
		return true, nil // feature desactivada — falha aberta
	}

	var cfg struct {
		Metodos map[string]struct {
			Ativo *bool `json:"ativo"`
		} `json:"metodos"`
	}
	if err := json.Unmarshal(configuracao, &cfg); err != nil {
		return true, nil // configuração mal-formada — falha aberta
	}

	metodoCfg, ok := cfg.Metodos["facial"]
	if !ok || metodoCfg.Ativo == nil {
		return true, nil // método não configurado explicitamente — falha aberta
	}
	return *metodoCfg.Ativo, nil
}

// callFaceClockEnroll faz o proxy do enrollment para o FaceClock.
func (h *Handler) callFaceClockEnroll(r *http.Request, authHeader string, req FaceClockEnrollRequest) (map[string]interface{}, int, error) {
	payload, err := json.Marshal(req)
	if err != nil {
		return nil, 0, err
	}

	url := fmt.Sprintf("%s/api/v1/biometric/enroll", h.cfg.FaceClockBaseURL)
	httpReq, err := http.NewRequestWithContext(r.Context(), http.MethodPost, url, bytes.NewReader(payload))
	if err != nil {
		return nil, 0, err
	}
	httpReq.Header.Set("Authorization", authHeader)
	httpReq.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(httpReq)
	if err != nil {
		return nil, 0, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, resp.StatusCode, err
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return map[string]interface{}{"raw": string(body)}, resp.StatusCode, nil
	}
	return result, resp.StatusCode, nil
}
