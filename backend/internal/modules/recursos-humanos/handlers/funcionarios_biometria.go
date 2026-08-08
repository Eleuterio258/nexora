package handlers

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"mime"
	"net/http"
	"strconv"
	"strings"
	"time"

	mw "nexora/internal/middleware"
	"nexora/internal/pkg/faceclock"
	"nexora/internal/storage"
)

// CaptureImage representa uma captura facial: base64 (legacy) ou URL MinIO.
type CaptureImage struct {
	ImageBase64 string `json:"image_base64,omitempty"`
	ImageURL    string `json:"image_url,omitempty"`
}

// EnrollFacialRequest é o payload JSON legacy para cadastro de biometria facial.
type EnrollFacialRequest struct {
	FuncionarioID int64          `json:"funcionario_id"`
	Captures      []CaptureImage `json:"captures"`
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
//  1. Aceita JSON legacy (capturas em base64) ou multipart/form-data (capturas como ficheiros).
//  2. Para multipart, faz upload das capturas para MinIO e envia image_url ao FaceClock.
//  3. Verifica se o funcionário existe e pertence ao tenant do gestor.
//  4. Verifica se existe consentimento LGPD ativo para biometria.
//  5. Verifica se o método "facial" está activo na configuração do tenant.
//  6. Envia as capturas para o FaceClock (/api/v1/biometric/enroll).
//  7. Devolve o resultado do enrollment.
func (h *Handler) EnrollFacial(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	if user == nil {
		jsonErr(w, "Não autenticado", http.StatusUnauthorized)
		return
	}

	var funcionarioID int64
	var captures []CaptureImage

	if strings.Contains(r.Header.Get("Content-Type"), "multipart/form-data") {
		var err error
		funcionarioID, captures, err = h.parseEnrollMultipart(r, w)
		if err != nil {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
	} else {
		var body EnrollFacialRequest
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			jsonErr(w, "Payload inválido", http.StatusBadRequest)
			return
		}
		funcionarioID = body.FuncionarioID
		captures = body.Captures
	}

	if funcionarioID <= 0 {
		jsonErr(w, "ID do funcionário inválido", http.StatusBadRequest)
		return
	}
	if !h.podeGerirFuncionario(r, funcionarioID) {
		jsonErr(w, "Sem permissão para gerir este funcionário", http.StatusForbidden)
		return
	}

	if len(captures) < 3 {
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

	// 4. Chamar FaceClock para criar o template facial usando credenciais
	// serviço-a-serviço Nexora HMAC (não mais Bearer do utilizador).
	faceClockReq := FaceClockEnrollRequest{
		UserID:   fmt.Sprintf("%d", erpUserID),
		Captures: captures,
	}
	client := faceclock.NewClient(h.cfg.FaceClockBaseURL, h.cfg.FaceClockAccessKeyID, h.cfg.FaceClockSecretAccessKey)
	faceClockResp, statusCode, err := client.Post(r.Context(), "/api/v1/biometric/enroll", faceClockReq)
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

// parseEnrollMultipart processa um pedido multipart/form-data de enrollment
// facial, fazendo upload de cada captura para MinIO e devolvendo as URLs.
func (h *Handler) parseEnrollMultipart(r *http.Request, w http.ResponseWriter) (int64, []CaptureImage, error) {
	const maxBytes = 30 * 1024 * 1024 // 30 MB
	r.Body = http.MaxBytesReader(w, r.Body, maxBytes+1024)
	if err := r.ParseMultipartForm(maxBytes); err != nil {
		return 0, nil, fmt.Errorf("falha ao processar multipart: %v", err)
	}

	funcionarioID, err := strconv.ParseInt(r.FormValue("funcionario_id"), 10, 64)
	if err != nil || funcionarioID <= 0 {
		return 0, nil, fmt.Errorf("funcionario_id inválido")
	}

	files := r.MultipartForm.File["captures"]
	if len(files) < 3 {
		return 0, nil, fmt.Errorf("São necessárias pelo menos 3 capturas faciais")
	}

	user := mw.GetUser(r)
	ctx := r.Context()
	now := time.Now().UTC().UnixMilli()
	captures := make([]CaptureImage, 0, len(files))

	for i, header := range files {
		file, err := header.Open()
		if err != nil {
			return 0, nil, fmt.Errorf("erro ao abrir captura %d: %v", i+1, err)
		}
		data, err := io.ReadAll(file)
		file.Close()
		if err != nil {
			return 0, nil, fmt.Errorf("erro ao ler captura %d: %v", i+1, err)
		}
		if len(data) == 0 {
			return 0, nil, fmt.Errorf("captura %d está vazia", i+1)
		}

		contentType := header.Header.Get("Content-Type")
		if contentType == "" {
			contentType = http.DetectContentType(data)
		}
		if !strings.HasPrefix(contentType, "image/") {
			return 0, nil, fmt.Errorf("captura %d não é uma imagem", i+1)
		}

		exts, _ := mime.ExtensionsByType(contentType)
		ext := ".jpg"
		if len(exts) > 0 {
			ext = exts[0]
		}

		key := storage.JoinPath(
			"uploads",
			fmt.Sprintf("tenant-%d", user.TenantID),
			"biometria",
			"enroll",
			fmt.Sprintf("func-%d", funcionarioID),
			fmt.Sprintf("%d-%d-%d%s", now, i, header.Size, ext),
		)
		url, err := h.storage.Put(ctx, key, data, contentType)
		if err != nil {
			return 0, nil, fmt.Errorf("erro ao guardar captura %d: %v", i+1, err)
		}
		// Enviar base64 ao FaceClock para evitar 403 em URLs públicas do MinIO.
		// A URL pública mantém-se disponível para auditoria/consulta directa.
		captures = append(captures, CaptureImage{ImageBase64: base64.StdEncoding.EncodeToString(data)})
		_ = url
	}

	return funcionarioID, captures, nil
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
