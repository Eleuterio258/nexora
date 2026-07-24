package handlers

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"time"

	"github.com/digitorus/pdfsign/sign"
	"github.com/jackc/pgx/v5"
)

var (
	errDocumentoIndisponivel = errors.New("documento não está disponível para assinatura")
	errSignatarioConcluido   = errors.New("signatário não encontrado ou já concluído")
	errAssinaturaTerceiro    = errors.New("signatário não pertence ao utilizador autenticado")
	errOrdemAssinatura       = errors.New("existem signatários anteriores que ainda não assinaram")
	errConviteConcorrente    = errors.New("convite expirado, já utilizado ou OTP inválido")
	errGeracaoPAdES          = errors.New("falha ao gerar a versão criptograficamente assinada")
)

// marcarAssinado executa todo o fluxo crítico numa única transação. O lock do
// documento serializa assinaturas do mesmo processo; a versão assinada é
// persistida antes de o signatário/documento mudarem de estado.
func (h *Handler) marcarAssinado(
	ctx context.Context,
	r *http.Request,
	tenantID, docID, sigID int64,
	nome, email string,
	expectedUserID, conviteID, auditUserID *int64,
	auditDetalhes map[string]any,
) (hashStr string, concluido bool, padesGerado bool, err error) {
	tx, err := h.db.Begin(ctx)
	if err != nil {
		return "", false, false, fmt.Errorf("iniciar transação: %w", err)
	}
	defer tx.Rollback(ctx)

	var docStatus string
	if err := tx.QueryRow(ctx, `
		SELECT status
		FROM assinatura_digital.documentos
		WHERE id=$1 AND tenant_id=$2
		FOR UPDATE`, docID, tenantID).Scan(&docStatus); err != nil {
		return "", false, false, errDocumentoIndisponivel
	}
	if docStatus != "pendente" && docStatus != "parcialmente_assinado" {
		return "", false, false, errDocumentoIndisponivel
	}

	var sigUserID *int64
	var ordem int
	var sigStatus string
	if err := tx.QueryRow(ctx, `
		SELECT user_id, ordem, status
		FROM assinatura_digital.signatarios
		WHERE id=$1 AND documento_id=$2 AND tenant_id=$3
		FOR UPDATE`, sigID, docID, tenantID).Scan(&sigUserID, &ordem, &sigStatus); err != nil {
		return "", false, false, errSignatarioConcluido
	}
	if sigStatus != "pendente" && sigStatus != "convidado" {
		return "", false, false, errSignatarioConcluido
	}
	if expectedUserID != nil && (sigUserID == nil || *sigUserID != *expectedUserID) {
		return "", false, false, errAssinaturaTerceiro
	}

	ordemOK, err := verificarOrdemComDB(ctx, tx, docID, ordem)
	if err != nil {
		return "", false, false, fmt.Errorf("verificar ordem: %w", err)
	}
	if !ordemOK {
		return "", false, false, errOrdemAssinatura
	}

	if conviteID != nil {
		tag, err := tx.Exec(ctx, `
			UPDATE assinatura_digital.convites
			SET usado_em=NOW()
			WHERE id=$1 AND documento_id=$2 AND signatario_id=$3 AND tenant_id=$4
			  AND usado_em IS NULL AND expira_em > NOW()
			  AND otp_confirmado_em >= NOW() - ($5 || ' minutes')::interval`,
			*conviteID, docID, sigID, tenantID, otpConfirmacaoValidadeMinutos)
		if err != nil {
			return "", false, false, fmt.Errorf("consumir convite: %w", err)
		}
		if tag.RowsAffected() != 1 {
			return "", false, false, errConviteConcorrente
		}
	}

	if err := h.gerarVersaoPAdESTx(ctx, tx, tenantID, docID, sigID, nome, email); err != nil {
		return "", false, false, fmt.Errorf("%w: %v", errGeracaoPAdES, err)
	}

	nonce := make([]byte, 32)
	if _, err := rand.Read(nonce); err != nil {
		return "", false, false, fmt.Errorf("gerar evidência: %w", err)
	}
	hashInput := fmt.Sprintf(
		"%s|%s|%d|%d|%s|%x",
		nome, email, sigID, docID, time.Now().UTC().Format(time.RFC3339Nano), nonce,
	)
	hash := sha256.Sum256([]byte(hashInput))
	hashStr = hex.EncodeToString(hash[:])

	ip := r.RemoteAddr
	if host, _, splitErr := net.SplitHostPort(ip); splitErr == nil {
		ip = host
	}
	tag, err := tx.Exec(ctx, `
		UPDATE assinatura_digital.signatarios
		SET status='assinado', assinado_em=NOW(), assinatura_hash=$1, assinatura_ip=$2
		WHERE id=$3 AND documento_id=$4 AND tenant_id=$5
		  AND status IN ('pendente','convidado')`,
		hashStr, ip, sigID, docID, tenantID)
	if err != nil {
		return "", false, false, fmt.Errorf("atualizar signatário: %w", err)
	}
	if tag.RowsAffected() != 1 {
		return "", false, false, errSignatarioConcluido
	}

	var pendentes, naoCriptografados int
	if err := tx.QueryRow(ctx, `
		SELECT COUNT(*) FILTER (WHERE status NOT IN ('assinado','aceite_eletronicamente')),
		       COUNT(*) FILTER (WHERE status='aceite_eletronicamente')
		FROM assinatura_digital.signatarios
		WHERE documento_id=$1 AND tenant_id=$2`,
		docID, tenantID).Scan(&pendentes, &naoCriptografados); err != nil {
		return "", false, false, fmt.Errorf("contar signatários pendentes: %w", err)
	}
	concluido = pendentes == 0
	novoStatus := "parcialmente_assinado"
	if concluido {
		// Só "assinado" (criptograficamente) se nenhum signatário concluiu
		// apenas por aceitação eletrónica externa (via webhook, sem
		// evidência PAdES gerada/verificada localmente).
		novoStatus = "assinado"
		if naoCriptografados > 0 {
			novoStatus = "aceite_eletronicamente"
		}
	}
	if _, err := tx.Exec(ctx, `
		UPDATE assinatura_digital.documentos
		SET status=$1,
		    data_conclusao=CASE WHEN $1='assinado' THEN NOW() ELSE NULL END,
		    updated_at=NOW()
		WHERE id=$2 AND tenant_id=$3`,
		novoStatus, docID, tenantID); err != nil {
		return "", false, false, fmt.Errorf("atualizar documento: %w", err)
	}

	if err := h.logComDB(ctx, tx, docID, &sigID, "assinado", auditDetalhes, tenantID, auditUserID, r); err != nil {
		return "", false, false, fmt.Errorf("registar auditoria: %w", err)
	}
	if err := tx.Commit(ctx); err != nil {
		return "", false, false, fmt.Errorf("confirmar assinatura: %w", err)
	}
	return hashStr, concluido, true, nil
}

func verificarOrdemComDB(ctx context.Context, db dbQuerier, docID int64, ordem int) (bool, error) {
	var pendentesAntes int
	err := db.QueryRow(ctx, `
		SELECT COUNT(*) FROM assinatura_digital.signatarios
		WHERE documento_id=$1 AND tipo='assinatura' AND ordem < $2 AND status NOT IN ('assinado','aceite_eletronicamente')`,
		docID, ordem).Scan(&pendentesAntes)
	return pendentesAntes == 0, err
}

// gerarVersaoPAdESTx gera e persiste a nova versão usando a transação recebida.
// Qualquer erro é propagado e impede a alteração dos estados do processo.
func (h *Handler) gerarVersaoPAdESTx(
	ctx context.Context,
	db dbQuerier,
	tenantID, docID, sigID int64,
	nome, email string,
) error {
	if h.pdfSigner == nil || h.sigProvider == nil {
		return fmt.Errorf("provider de assinatura não configurado")
	}

	var storageKey string
	err := db.QueryRow(ctx, `
		SELECT storage_key FROM assinatura_digital.versoes_assinadas
		WHERE documento_id=$1 AND tenant_id=$2
		ORDER BY id DESC LIMIT 1`, docID, tenantID).Scan(&storageKey)
	if errors.Is(err, pgx.ErrNoRows) {
		err = db.QueryRow(ctx, `
			SELECT storage_key FROM assinatura_digital.documentos
			WHERE id=$1 AND tenant_id=$2`, docID, tenantID).Scan(&storageKey)
	}
	if err != nil {
		return fmt.Errorf("obter PDF atual: %w", err)
	}

	reader, _, err := h.storage.Get(ctx, storageKey)
	if err != nil {
		return fmt.Errorf("ler PDF do storage: %w", err)
	}
	pdfBytes, readErr := io.ReadAll(reader)
	closeErr := reader.Close()
	if readErr != nil {
		return fmt.Errorf("ler PDF do storage: %w", readErr)
	}
	if closeErr != nil {
		return fmt.Errorf("fechar PDF do storage: %w", closeErr)
	}

	reason := "Documento assinado eletronicamente."
	if !h.sigProvider.LegalmenteValido() {
		reason = "ASSINATURA DE DESENVOLVIMENTO - NAO valida juridicamente."
	}
	signedBytes, evidence, err := h.pdfSigner.Sign(ctx, pdfBytes, sign.SignDataSignatureInfo{
		Name:        nome,
		Location:    "Nexora ERP",
		Reason:      reason,
		ContactInfo: email,
	}, h.sigProvider)
	if err != nil {
		return fmt.Errorf("assinar PDF: %w", err)
	}

	hash := sha256.Sum256(signedBytes)
	hashStr := hex.EncodeToString(hash[:])
	key := contentKey(tenantID, hashStr, ".pdf")
	url, err := h.storage.PutImmutable(ctx, key, signedBytes, "application/pdf")
	if err != nil {
		return fmt.Errorf("gravar PDF assinado: %w", err)
	}

	if _, err := db.Exec(ctx, `
		INSERT INTO assinatura_digital.versoes_assinadas (
			documento_id, tenant_id, storage_key, ficheiro_url, hash_sha256, signatario_id,
			provider, legal_valido, nivel_assinatura, certificado_subject, certificado_emissor, certificado_serie,
			certificado_fingerprint, certificado_validade_inicio, certificado_validade_fim,
			algoritmo_digest, algoritmo_assinatura, timestamp_autoridade, motivo, localizacao)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20)`,
		docID, tenantID, key, url, hashStr, sigID,
		evidence.Provider, evidence.LegalValido, evidence.Nivel,
		evidence.CertificadoSubject, evidence.CertificadoEmissor, evidence.CertificadoSerie,
		evidence.CertificadoFingerprint, evidence.CertificadoValidadeInicio, evidence.CertificadoValidadeFim,
		evidence.AlgoritmoDigest, evidence.AlgoritmoAssinatura,
		evidence.TimestampAutoridade, evidence.Motivo, evidence.Localizacao,
	); err != nil {
		return fmt.Errorf("gravar versão assinada: %w", err)
	}
	return nil
}

func (h *Handler) logComDB(
	ctx context.Context,
	db dbQuerier,
	docID int64,
	sigID *int64,
	acao string,
	detalhes map[string]any,
	tenantID int64,
	userID *int64,
	r *http.Request,
) error {
	detalhesJSON, err := json.Marshal(detalhes)
	if err != nil {
		return err
	}
	ip := ""
	if r != nil {
		ip = r.RemoteAddr
		if host, _, splitErr := net.SplitHostPort(ip); splitErr == nil {
			ip = host
		}
	}
	_, err = db.Exec(ctx, `
		INSERT INTO assinatura_digital.logs
			(documento_id, tenant_id, signatario_id, acao, detalhes, user_id, ip_address)
		VALUES ($1, $2, $3, $4, $5, $6, NULLIF($7,'')::inet)`,
		docID, tenantID, sigID, acao, detalhesJSON, userID, ip)
	return err
}

func (h *Handler) responderErroAssinatura(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, errAssinaturaTerceiro):
		jsonErr(w, "Este signatário não pertence ao utilizador autenticado", http.StatusForbidden)
	case errors.Is(err, errDocumentoIndisponivel),
		errors.Is(err, errSignatarioConcluido),
		errors.Is(err, errOrdemAssinatura),
		errors.Is(err, errConviteConcorrente):
		jsonErr(w, err.Error(), http.StatusConflict)
	case errors.Is(err, errGeracaoPAdES):
		jsonErr(w, "Não foi possível gerar a versão assinada; nenhuma assinatura foi registada", http.StatusInternalServerError)
	default:
		jsonErr(w, "Erro ao registar assinatura", http.StatusInternalServerError)
	}
}
