package handlers

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"fmt"
	"math/big"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"golang.org/x/crypto/bcrypt"
	mw "nexora/internal/middleware"
	"nexora/internal/shared/contracts"
)

const (
	otpValidadeMinutos            = 10
	otpConfirmacaoValidadeMinutos = 15
	otpMaxTentativas              = 5
)

// conviteInfo agrega os dados de convite, signatário e documento necessários
// para validar e processar o fluxo de convite sem sessão ERP.
type conviteInfo struct {
	ID              int64
	DocumentoID     int64
	SignatarioID    int64
	TenantID        int64
	ExpiraEm        time.Time
	UsadoEm         *time.Time
	OTPHash         *string
	OTPExpiraEm     *time.Time
	OTPTentativas   int
	OTPConfirmadoEm *time.Time
	SigNome         string
	SigEmail        *string
	SigTelefone     *string
	SigOrdem        int
	SigTipo         string
	SigStatus       string
	DocStatus       string
}

// obterConviteValido valida o token (por hash), a expiração e o uso único.
func (h *Handler) obterConviteValido(ctx context.Context, token string) (*conviteInfo, error) {
	tokenHash := mw.HashToken(token)
	var c conviteInfo
	err := h.db.QueryRow(ctx, `
		SELECT c.id, c.documento_id, c.signatario_id, c.tenant_id, c.expira_em, c.usado_em,
		       c.otp_hash, c.otp_expira_em, c.otp_tentativas, c.otp_confirmado_em,
		       s.nome, s.email, s.telefone, s.ordem, s.tipo, s.status, d.status
		FROM assinatura_digital.convites c
		JOIN assinatura_digital.signatarios s ON s.id = c.signatario_id
		JOIN assinatura_digital.documentos d ON d.id = c.documento_id
		WHERE c.token_hash = $1`, tokenHash).Scan(
		&c.ID, &c.DocumentoID, &c.SignatarioID, &c.TenantID, &c.ExpiraEm, &c.UsadoEm,
		&c.OTPHash, &c.OTPExpiraEm, &c.OTPTentativas, &c.OTPConfirmadoEm,
		&c.SigNome, &c.SigEmail, &c.SigTelefone, &c.SigOrdem, &c.SigTipo, &c.SigStatus, &c.DocStatus)
	if err != nil {
		return nil, err
	}
	if c.UsadoEm != nil || time.Now().After(c.ExpiraEm) {
		return nil, fmt.Errorf("convite inválido ou expirado")
	}
	return &c, nil
}

func gerarCodigoOTP() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

// ObterConvite devolve os dados mínimos do documento/signatário para o portal
// de assinatura apresentar antes de pedir o código.
// GET /api/assinatura-digital/convites/{token}
func (h *Handler) ObterConvite(w http.ResponseWriter, r *http.Request) {
	token := chi.URLParam(r, "token")
	c, err := h.obterConviteValido(r.Context(), token)
	if err != nil {
		jsonErr(w, "Convite inválido ou expirado", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{
		"documento_id":      c.DocumentoID,
		"documento_status":  c.DocStatus,
		"signatario_nome":   c.SigNome,
		"signatario_status": c.SigStatus,
		"signatario_tipo":   c.SigTipo,
		"tem_email":         c.SigEmail != nil && *c.SigEmail != "",
		"tem_telefone":      c.SigTelefone != nil && *c.SigTelefone != "",
		"expira_em":         c.ExpiraEm,
	}, http.StatusOK)
}

// EnviarOTP gera e despacha um código de confirmação de 6 dígitos por email
// ou SMS. O canal pode ser solicitado no corpo do pedido; se omitido, usa
// email quando disponível, senão SMS se houver telefone configurado.
// POST /api/assinatura-digital/convites/{token}/otp/enviar
func (h *Handler) EnviarOTP(w http.ResponseWriter, r *http.Request) {
	token := chi.URLParam(r, "token")
	c, err := h.obterConviteValido(r.Context(), token)
	if err != nil {
		jsonErr(w, "Convite inválido ou expirado", http.StatusNotFound)
		return
	}
	if c.DocStatus != "pendente" {
		jsonErr(w, "Documento não está disponível para assinatura", http.StatusConflict)
		return
	}
	if c.SigStatus != "pendente" && c.SigStatus != "convidado" {
		jsonErr(w, "Signatário já concluiu este processo", http.StatusConflict)
		return
	}

	var body struct {
		Canal string `json:"canal"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)
	canal := strings.ToLower(strings.TrimSpace(body.Canal))

	hasEmail := c.SigEmail != nil && *c.SigEmail != ""
	hasTelefone := c.SigTelefone != nil && *c.SigTelefone != ""

	// Se canal não especificado, escolhe automaticamente.
	switch canal {
	case "email":
		if !hasEmail {
			jsonErr(w, "Signatário sem email para receber o código", http.StatusBadRequest)
			return
		}
	case "sms":
		if !hasTelefone {
			jsonErr(w, "Signatário sem telefone para receber o código por SMS", http.StatusBadRequest)
			return
		}
	default:
		if hasEmail {
			canal = "email"
		} else if hasTelefone {
			canal = "sms"
		} else {
			jsonErr(w, "Signatário sem email nem telefone para receber o código", http.StatusBadRequest)
			return
		}
	}

	codigo, err := gerarCodigoOTP()
	if err != nil {
		jsonErr(w, "Erro ao gerar código", http.StatusInternalServerError)
		return
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(codigo), bcrypt.DefaultCost)
	if err != nil {
		jsonErr(w, "Erro ao gerar código", http.StatusInternalServerError)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
		UPDATE assinatura_digital.convites
		SET otp_hash=$1, otp_expira_em=NOW() + ($2 || ' minutes')::interval, otp_tentativas=0, otp_confirmado_em=NULL
		WHERE id=$3`, string(hash), otpValidadeMinutos, c.ID); err != nil {
		jsonErr(w, "Erro ao gerar código", http.StatusInternalServerError)
		return
	}

	if h.notif != nil {
		var destinatario, assunto string
		corpo := fmt.Sprintf("O seu código de confirmação é %s. Válido por %d minutos.", codigo, otpValidadeMinutos)
		switch canal {
		case "email":
			destinatario = *c.SigEmail
			assunto = "Código de confirmação para assinatura"
		case "sms":
			destinatario = *c.SigTelefone
			assunto = "Código OTP"
		}
		h.notif.Send(r.Context(), contracts.Notification{
			TenantID:       c.TenantID,
			CanalTipo:      canal,
			Destinatario:   destinatario,
			Assunto:        assunto,
			Corpo:          corpo,
			ReferenciaTipo: "assinatura-digital.otp",
			ReferenciaID:   &c.SignatarioID,
		})
	}

	jsonOK(w, map[string]any{"ok": true, "msg": "Código enviado", "canal": canal}, http.StatusOK)
}

// ValidarOTP confirma o código enviado, com limite de tentativas.
// POST /api/assinatura-digital/convites/{token}/otp/validar
func (h *Handler) ValidarOTP(w http.ResponseWriter, r *http.Request) {
	token := chi.URLParam(r, "token")
	c, err := h.obterConviteValido(r.Context(), token)
	if err != nil {
		jsonErr(w, "Convite inválido ou expirado", http.StatusNotFound)
		return
	}

	var body struct {
		Codigo string `json:"codigo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" {
		jsonErr(w, "codigo é obrigatório", http.StatusBadRequest)
		return
	}

	if c.OTPHash == nil || c.OTPExpiraEm == nil || time.Now().After(*c.OTPExpiraEm) {
		jsonErr(w, "Código expirado ou não solicitado. Peça um novo código.", http.StatusBadRequest)
		return
	}
	if c.OTPTentativas >= otpMaxTentativas {
		jsonErr(w, "Demasiadas tentativas. Peça um novo código.", http.StatusTooManyRequests)
		return
	}

	if bcrypt.CompareHashAndPassword([]byte(*c.OTPHash), []byte(body.Codigo)) != nil {
		h.db.Exec(r.Context(), `UPDATE assinatura_digital.convites SET otp_tentativas = otp_tentativas + 1 WHERE id=$1`, c.ID)
		jsonErr(w, "Código inválido", http.StatusUnauthorized)
		return
	}

	h.db.Exec(r.Context(), `UPDATE assinatura_digital.convites SET otp_confirmado_em=NOW() WHERE id=$1`, c.ID)

	jsonOK(w, map[string]any{"ok": true, "confirmado": true}, http.StatusOK)
}

// AssinarViaConvite conclui a assinatura do signatário externo, exigindo OTP
// confirmado recentemente e respeitando a ordem declarada dos signatários.
// POST /api/assinatura-digital/convites/{token}/assinar
func (h *Handler) AssinarViaConvite(w http.ResponseWriter, r *http.Request) {
	token := chi.URLParam(r, "token")
	c, err := h.obterConviteValido(r.Context(), token)
	if err != nil {
		jsonErr(w, "Convite inválido ou expirado", http.StatusNotFound)
		return
	}
	if c.DocStatus != "pendente" {
		jsonErr(w, "Documento não está disponível para assinatura", http.StatusConflict)
		return
	}
	if c.SigStatus != "pendente" && c.SigStatus != "convidado" {
		jsonErr(w, "Signatário já concluiu este processo", http.StatusConflict)
		return
	}
	if c.OTPConfirmadoEm == nil || time.Now().After(c.OTPConfirmadoEm.Add(otpConfirmacaoValidadeMinutos*time.Minute)) {
		jsonErr(w, "Confirme o código de acesso antes de assinar", http.StatusForbidden)
		return
	}

	ordemOK, err := h.verificarOrdem(r.Context(), c.DocumentoID, c.SigOrdem)
	if err != nil {
		jsonErr(w, "Erro ao verificar ordem de assinatura", http.StatusInternalServerError)
		return
	}
	if !ordemOK {
		jsonErr(w, "Existem signatários anteriores que ainda não assinaram", http.StatusConflict)
		return
	}

	email := ""
	if c.SigEmail != nil {
		email = *c.SigEmail
	}
	hashStr, concluido, padesGerado, err := h.marcarAssinado(r.Context(), r, c.TenantID, c.DocumentoID, c.SignatarioID, c.SigNome, email)
	if err != nil {
		jsonErr(w, "Erro ao registar assinatura", http.StatusInternalServerError)
		return
	}
	h.db.Exec(r.Context(), `UPDATE assinatura_digital.convites SET usado_em=NOW() WHERE id=$1`, c.ID)

	h.log(r.Context(), c.DocumentoID, &c.SignatarioID, "assinado", map[string]any{"nome": c.SigNome, "email": email, "via": "convite"}, c.TenantID, nil, r)

	jsonOK(w, map[string]any{"ok": true, "assinatura_hash": hashStr, "concluido": concluido, "pades_gerado": padesGerado}, http.StatusOK)
}

// RecusarViaConvite marca a recusa de assinatura de um signatário externo.
// POST /api/assinatura-digital/convites/{token}/recusar
func (h *Handler) RecusarViaConvite(w http.ResponseWriter, r *http.Request) {
	token := chi.URLParam(r, "token")
	c, err := h.obterConviteValido(r.Context(), token)
	if err != nil {
		jsonErr(w, "Convite inválido ou expirado", http.StatusNotFound)
		return
	}
	if c.SigStatus != "pendente" && c.SigStatus != "convidado" {
		jsonErr(w, "Signatário já concluiu este processo", http.StatusConflict)
		return
	}

	var body struct {
		Motivo string `json:"motivo"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	if _, err := h.db.Exec(r.Context(), `
		UPDATE assinatura_digital.signatarios
		SET status='recusado', recusado_em=NOW(), motivo_recusa=$1
		WHERE id=$2`, body.Motivo, c.SignatarioID); err != nil {
		jsonErr(w, "Erro ao registar recusa", http.StatusInternalServerError)
		return
	}
	h.db.Exec(r.Context(), `UPDATE assinatura_digital.convites SET usado_em=NOW() WHERE id=$1`, c.ID)

	h.log(r.Context(), c.DocumentoID, &c.SignatarioID, "recusado", map[string]any{"motivo": body.Motivo, "via": "convite"}, c.TenantID, nil, r)

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// PreviewDocumentoConvite serve o PDF original de um convite para pré-visualização
// no portal de assinatura. Não exige OTP prévio (o signatário precisa de ver o
// documento antes de solicitar o código), mas valida o convite e o estado do
// documento. O PDF é servido inline para visualização no browser.
// GET /api/assinatura-digital/convites/{token}/preview
func (h *Handler) PreviewDocumentoConvite(w http.ResponseWriter, r *http.Request) {
	token := chi.URLParam(r, "token")
	c, err := h.obterConviteValido(r.Context(), token)
	if err != nil {
		jsonErr(w, "Convite inválido ou expirado", http.StatusNotFound)
		return
	}
	if c.DocStatus != "pendente" {
		jsonErr(w, "Documento não está disponível para assinatura", http.StatusConflict)
		return
	}

	var key, hashEsperado string
	if err := h.db.QueryRow(r.Context(), `
		SELECT storage_key, hash_sha256
		FROM assinatura_digital.documentos
		WHERE id=$1 AND tenant_id=$2`, c.DocumentoID, c.TenantID).Scan(&key, &hashEsperado); err != nil {
		jsonErr(w, "Documento não encontrado", http.StatusNotFound)
		return
	}

	h.servirPDFVerificado(w, r, c.DocumentoID, c.TenantID, nil, key, hashEsperado, true)
}
