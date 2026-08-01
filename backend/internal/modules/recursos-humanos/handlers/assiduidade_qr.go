package handlers

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"time"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
	"nexora/internal/modules/recursos-humanos/service/funcionario"
	"nexora/internal/pkg/tenantid"
)

// ── QR Code de assiduidade (persistido centralmente) ────────────────────────
//
// Substitui o armazenamento em memória do processo que o FaceClock usava
// (_qr_store em methods.py): não sobrevivia a reinícios nem funcionava com
// múltiplos workers/instâncias, porque cada processo tinha o seu próprio
// dict.
//
// Suporta dois modos:
//   1. QR Fixo do gestor — token sem funcionario_id; qualquer funcionário pode
//      lê-lo para registar o seu ponto. Gerado por GerarQRDevice, autenticado
//      por JWT + permissão "recursos-humanos:ver_funcionarios" (só gestores),
//      ao contrário dos restantes endpoints de
//      assiduidade/{config,funcionarios,geofence,consentimentos}, que usam a
//      API Key de device partilhada por todas as instalações da app.
//   2. QR do funcionário — token vinculado a um funcionario_id; o gestor lê o
//      QR e o sistema identifica automaticamente o funcionário. Gerado por
//      GerarQRMe, também autenticado por JWT (o pedido tem de saber QUEM é o
//      funcionário, o que a API Key de device não distingue).
//
// A validação (ValidarQRDevice) continua na API Key de device: tem de ficar
// acessível a qualquer funcionário que leia o QR fixo (modo 1) ou a qualquer
// gestor que leia o QR de um funcionário (modo 2).

const (
	qrDuracaoPadraoSegundos = 60
	qrDuracaoMaximaSegundos = 300
)

type qrGenerateBody struct {
	LocationID      *string `json:"location_id"`
	DuracaoSegundos int     `json:"duracao_segundos"`
	FuncionarioID   *int64  `json:"funcionario_id,omitempty"`
}

// tenantIDQR devolve o tenant a usar nas tabelas de QR — o mesmo espaço de
// IDs de rh.funcionarios.tenant_id, que é saas.tenants.id (ver
// internal/pkg/tenantid: "rh.*, gestao_escolar.* e a generalidade dos módulos
// de negócio" usam esse espaço, não empresas.companies.id).
//
// Pedidos autenticados por sessão (JWT, GerarQRDevice/GerarQRMe) já trazem
// user.TenantID nesse espaço, porque auth.memberships.tenant_id referencia
// saas.tenants(id) directamente — usar sem tradução.
//
// Pedidos autenticados por device (X-API-Key, ValidarQRDevice) trazem em
// user.TenantID o tenant_id da EMPRESA (hardware.devices.tenant_id
// referencia empresas.companies(id)), um espaço de IDs diferente — por isso
// precisam de passar por tenantid.ResolveSaas antes de comparar com
// rh.qr_tokens/rh.funcionarios. Sem esta distinção, ValidarQRDevice nunca
// encontrava o token gerado por GerarQRDevice/GerarQRMe: os dois tenant_id
// vinham de espaços diferentes (ex.: empresa 7 -> tenant SaaS 5) e o
// WHERE/JOIN por tenant_id falhava sempre, respondendo "QR Code inválido"
// mesmo com o token certo.
func tenantIDQR(ctx context.Context, db tenantid.DB, r *http.Request, user *mw.AuthUser) (int64, error) {
	if mw.GetDevice(r) != nil {
		return tenantid.ResolveSaas(ctx, db, user.TenantID)
	}
	return user.TenantID, nil
}

// POST /api/rh/assiduidade/qr/gerar
func (h *Handler) GerarQRDevice(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := tenantIDQR(r.Context(), h.db, r, user)
	if err != nil {
		jsonErr(w, "Utilizador sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}

	var body qrGenerateBody
	json.NewDecoder(r.Body).Decode(&body)
	if body.DuracaoSegundos <= 0 {
		body.DuracaoSegundos = qrDuracaoPadraoSegundos
	}
	if body.DuracaoSegundos > qrDuracaoMaximaSegundos {
		body.DuracaoSegundos = qrDuracaoMaximaSegundos
	}

	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	token := "qr_" + hex.EncodeToString(b)
	expiresAt := time.Now().Add(time.Duration(body.DuracaoSegundos) * time.Second)

	if _, err := h.db.Exec(r.Context(), `
		INSERT INTO rh.qr_tokens (tenant_id, token, location_id, funcionario_id, expires_at)
		VALUES ($1,$2,$3,$4,$5)`,
		tenantID, token, body.LocationID, body.FuncionarioID, expiresAt); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"qr_code":    token,
		"expires_at": expiresAt,
	}, http.StatusCreated)
}

// POST /api/hardware/assiduidade/qr/gerar-terminal
// Modo 2 (QR dinâmico do terminal): o próprio terminal pede um código de curta duração
// (60s, uso único, sem funcionario_id — o mesmo "QR fixo do gestor" que GerarQRDevice
// gera, só que aqui é o terminal a pedi-lo directamente, autenticado por X-API-Key em
// vez de JWT de gestor) e mostra-o no ecrã, renovando a cada ciclo. O funcionário lê
// esse código com a app Nexo (já sabe quem é, pela sessão) e é a app + servidor que
// completam a marcação — o terminal não identifica ninguém nem regista nada aqui.
func (h *Handler) GerarQRTerminal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := tenantIDQR(r.Context(), h.db, r, user)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}
	device := mw.GetDevice(r)

	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	token := "qr_" + hex.EncodeToString(b)
	expiresAt := time.Now().Add(time.Duration(qrDuracaoPadraoSegundos) * time.Second)

	var locationID *string
	if device != nil {
		nome := device.Nome
		locationID = &nome
	}

	if _, err := h.db.Exec(r.Context(), `
		INSERT INTO rh.qr_tokens (tenant_id, token, location_id, expires_at)
		VALUES ($1,$2,$3,$4)`,
		tenantID, token, locationID, expiresAt); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"qr_code":    token,
		"expires_at": expiresAt,
	}, http.StatusCreated)
}

// GET /api/self-service/assiduidade/qr/me
// Gera um token QR vinculado ao funcionário autenticado. Usado pelo
// funcionário para mostrar o seu QR pessoal ao gestor.
func (h *Handler) GerarQRMe(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := tenantIDQR(r.Context(), h.db, r, user)
	if err != nil {
		jsonErr(w, "Utilizador sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}

	var funcionarioID int64
	// user_id, não utilizador_id: rh.funcionarios não tem nenhuma coluna com
	// esse nome, por isso a query falhava sempre e este endpoint respondia
	// 404 a toda a gente.
	err = h.db.QueryRow(r.Context(), `
		SELECT id FROM rh.funcionarios
		 WHERE tenant_id=$1 AND user_id=$2
		 LIMIT 1`,
		tenantID, user.ID).Scan(&funcionarioID)
	if err != nil {
		jsonErr(w, "Funcionário não encontrado para este utilizador", http.StatusNotFound)
		return
	}

	duracao := qrDuracaoPadraoSegundos
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	token := "qr_" + hex.EncodeToString(b)
	expiresAt := time.Now().Add(time.Duration(duracao) * time.Second)

	if _, err := h.db.Exec(r.Context(), `
		INSERT INTO rh.qr_tokens (tenant_id, token, funcionario_id, expires_at)
		VALUES ($1,$2,$3,$4)`,
		tenantID, token, funcionarioID, expiresAt); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"qr_code":        token,
		"expires_at":     expiresAt,
		"funcionario_id": funcionarioID,
	}, http.StatusCreated)
}

// POST /api/hardware/assiduidade/qr/validar
func (h *Handler) ValidarQRDevice(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := tenantIDQR(r.Context(), h.db, r, user)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}

	var body struct {
		QRCode string `json:"qr_code"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.QRCode == "" {
		jsonErr(w, "qr_code é obrigatório", http.StatusBadRequest)
		return
	}

	var tokenID int64
	var locationID *string
	var funcionarioID *int64
	var employeeNo *string
	var expiresAt time.Time
	// Marca como usado atomicamente (evita corrida entre dois pedidos
	// concorrentes a validar o mesmo QR): só actualiza, e só é "válido", se
	// ainda estava por usar e dentro do prazo — RowsAffected()==0 cobre os
	// dois casos de invalidade (já usado, ou não encontrado) e o expirado é
	// verificado à parte para dar uma mensagem mais específica.
	err = h.db.QueryRow(r.Context(), `
		SELECT t.id, t.location_id, t.funcionario_id, f.numero_funcionario, t.expires_at
		  FROM rh.qr_tokens t
		  LEFT JOIN rh.funcionarios f ON f.id = t.funcionario_id AND f.tenant_id = t.tenant_id
		 WHERE t.token=$1 AND t.tenant_id=$2`,
		body.QRCode, tenantID).Scan(&tokenID, &locationID, &funcionarioID, &employeeNo, &expiresAt)
	if err != nil {
		jsonErr(w, "QR Code inválido", http.StatusBadRequest)
		return
	}
	if time.Now().After(expiresAt) {
		jsonErr(w, "QR Code expirado", http.StatusBadRequest)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.qr_tokens SET used_at = NOW() WHERE token=$1 AND tenant_id=$2 AND used_at IS NULL`,
		body.QRCode, tenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "QR Code já utilizado", http.StatusBadRequest)
		return
	}

	jsonOK(w, map[string]any{
		"valid":          true,
		"token_id":       tokenID,
		"location_id":    locationID,
		"funcionario_id": funcionarioID,
		"employee_no":    employeeNo,
	}, http.StatusOK)
}

// POST /api/hardware/assiduidade/qr/registar
// Modo 1 (QR pessoal do funcionário): o terminal lê o QR Code do funcionário,
// valida-o e regista o ponto num único passo. O QR token deve estar vinculado
// a um funcionario_id (gerado por GET /api/self-service/assiduidade/qr/me).
func (h *Handler) RegistarQRDevice(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := tenantIDQR(r.Context(), h.db, r, user)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}

	var body struct {
		QRCode           string `json:"qr_code"`
		TipoEventoCodigo string `json:"tipo_evento_codigo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.QRCode == "" {
		jsonErr(w, "qr_code é obrigatório", http.StatusBadRequest)
		return
	}

	qr, err := h.assiduidade.ValidarEUsarQRToken(r.Context(), tenantID, body.QRCode)
	if err != nil {
		switch {
		case errors.Is(err, assiduidade.ErrQRExpirado):
			jsonErr(w, "QR Code expirado", http.StatusBadRequest)
		case errors.Is(err, assiduidade.ErrQRUsado):
			jsonErr(w, "QR Code já utilizado", http.StatusBadRequest)
		default:
			jsonErr(w, "QR Code inválido", http.StatusBadRequest)
		}
		return
	}
	if qr.FuncionarioID == nil {
		jsonErr(w, "QR Code de terminal não pode ser usado neste endpoint", http.StatusBadRequest)
		return
	}

	colab, err := funcionario.NewService(h.db).PorID(r.Context(), tenantID, *qr.FuncionarioID)
	if err != nil {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}
	if err := colab.VerificarAtivo(); err != nil {
		jsonErr(w, "Funcionário inativo", http.StatusForbidden)
		return
	}

	agora := time.Now()
	tipoEvento := body.TipoEventoCodigo
	if tipoEvento == "" {
		tipoEvento = h.assiduidade.InferirEntradaOuSaida(r.Context(), tenantID, colab.ID, agora)
	}
	if !tiposEventoManual[tipoEvento] {
		jsonErr(w, "tipo_evento_codigo não permitido em marcações por QR", http.StatusBadRequest)
		return
	}

	metodo := "qr"
	origem := "qr"
	observacoes := fmt.Sprintf("QR lido por terminal | location_id=%s", valueOrEmpty(qr.LocationID))

	ev, err := h.assiduidade.RegistarEvento(r.Context(), tenantID, assiduidade.RegistarEventoInput{
		FuncionarioID:    colab.ID,
		TipoEventoCodigo: tipoEvento,
		MetodoCodigo:     &metodo,
		OcorridoEm:       agora,
		DataReferencia:   &agora,
		Origem:           origem,
		QRTokenID:        &qr.TokenID,
		Observacoes:      &observacoes,
	})
	if err != nil {
		if errors.Is(err, assiduidade.ErrTipoEventoDesconhecido) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro ao registar o ponto", http.StatusInternalServerError)
		return
	}

	jsonOK(w, ev, http.StatusCreated)
}

func valueOrEmpty(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}
