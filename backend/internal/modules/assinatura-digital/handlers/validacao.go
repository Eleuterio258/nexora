package handlers

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/digitorus/pdf"
	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	pkimod "nexora/internal/modules/assinatura-digital/pki"
)

// EvidenciasResponse agrega o pacote de evidências de um documento.
type EvidenciasResponse struct {
	Documento   DocumentoEvidencia    `json:"documento"`
	Signatarios []SignatarioEvidencia `json:"signatarios"`
	Versoes     []VersaoEvidencia     `json:"versoes"`
	Logs        []LogEvidencia        `json:"logs"`
	Validacoes  []ValidacaoEvidencia  `json:"validacoes"`
}

type DocumentoEvidencia struct {
	ID           int64     `json:"id"`
	TenantID     int64     `json:"tenant_id"`
	Titulo       string    `json:"titulo"`
	Status       string    `json:"status"`
	HashOriginal string    `json:"hash_original"`
	CriadoEm     time.Time `json:"criado_em"`
	OrigemModulo *string   `json:"origem_modulo,omitempty"`
	OrigemID     *int64    `json:"origem_id,omitempty"`
}

type SignatarioEvidencia struct {
	ID       int64   `json:"id"`
	Nome     string  `json:"nome"`
	Email    *string `json:"email,omitempty"`
	Telefone *string `json:"telefone,omitempty"`
	Tipo     string  `json:"tipo"`
	Ordem    int     `json:"ordem"`
	Status   string  `json:"status"`
}

type VersaoEvidencia struct {
	ID         int64      `json:"id"`
	StorageKey string     `json:"storage_key"`
	FicheiroURL *string   `json:"ficheiro_url,omitempty"`
	Hash       *string    `json:"hash,omitempty"`
	SignatarioID *int64   `json:"signatario_id,omitempty"`
	CriadoEm   time.Time  `json:"criado_em"`
}

type LogEvidencia struct {
	ID           int64           `json:"id"`
	SignatarioID *int64          `json:"signatario_id,omitempty"`
	Acao         string          `json:"acao"`
	Detalhes     json.RawMessage `json:"detalhes,omitempty"`
	UserID       *int64          `json:"user_id,omitempty"`
	IPAddress    *string         `json:"ip_address,omitempty"`
	CreatedAt    time.Time       `json:"created_at"`
}

type ValidacaoEvidencia struct {
	ID                int64           `json:"id"`
	VersaoID          *int64          `json:"versao_id,omitempty"`
	HashVerificado    *string         `json:"hash_verificado,omitempty"`
	Assinaturas       int             `json:"assinaturas"`
	CertificadoValido *bool           `json:"certificado_valido,omitempty"`
	CertificadoMotivo *string         `json:"certificado_motivo,omitempty"`
	Resultado         string          `json:"resultado"`
	Detalhes          json.RawMessage `json:"detalhes,omitempty"`
	UserID            *int64          `json:"user_id,omitempty"`
	CreatedAt         time.Time       `json:"created_at"`
}

// Evidencias devolve o pacote completo de evidências de um documento:
// dados do documento, signatários, versões assinadas, logs e validações.
// GET /api/assinatura-digital/documentos/{id}/evidencias
func (h *Handler) Evidencias(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var doc DocumentoEvidencia
	if err := h.db.QueryRow(r.Context(), `
		SELECT id, tenant_id, titulo, status, hash_sha256, created_at, origem_modulo, origem_id
		FROM assinatura_digital.documentos
		WHERE id=$1 AND tenant_id=$2`, docID, user.TenantID).Scan(
		&doc.ID, &doc.TenantID, &doc.Titulo, &doc.Status, &doc.HashOriginal, &doc.CriadoEm, &doc.OrigemModulo, &doc.OrigemID); err != nil {
		jsonErr(w, "Documento não encontrado", http.StatusNotFound)
		return
	}

	signatarios, err := h.listarSignatariosEvidencia(r.Context(), docID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao carregar signatários", http.StatusInternalServerError)
		return
	}
	versoes, err := h.listarVersoesEvidencia(r.Context(), docID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao carregar versões", http.StatusInternalServerError)
		return
	}
	logs, err := h.listarLogsEvidencia(r.Context(), docID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao carregar logs", http.StatusInternalServerError)
		return
	}
	validacoes, err := h.listarValidacoesEvidencia(r.Context(), docID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao carregar validações", http.StatusInternalServerError)
		return
	}

	resp := EvidenciasResponse{
		Documento:   doc,
		Signatarios: signatarios,
		Versoes:     versoes,
		Logs:        logs,
		Validacoes:  validacoes,
	}
	jsonOK(w, resp, http.StatusOK)
}

func (h *Handler) listarSignatariosEvidencia(ctx context.Context, docID, tenantID int64) ([]SignatarioEvidencia, error) {
	rows, err := h.db.Query(ctx, `
		SELECT id, nome, email, telefone, tipo, ordem, status
		FROM assinatura_digital.signatarios
		WHERE documento_id=$1 AND tenant_id=$2
		ORDER BY ordem, id`, docID, tenantID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var res []SignatarioEvidencia
	for rows.Next() {
		var s SignatarioEvidencia
		if err := rows.Scan(&s.ID, &s.Nome, &s.Email, &s.Telefone, &s.Tipo, &s.Ordem, &s.Status); err != nil {
			return nil, err
		}
		res = append(res, s)
	}
	return res, rows.Err()
}

func (h *Handler) listarVersoesEvidencia(ctx context.Context, docID, tenantID int64) ([]VersaoEvidencia, error) {
	rows, err := h.db.Query(ctx, `
		SELECT id, storage_key, ficheiro_url, hash_sha256, signatario_id, created_at
		FROM assinatura_digital.versoes_assinadas
		WHERE documento_id=$1 AND tenant_id=$2
		ORDER BY created_at`, docID, tenantID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var res []VersaoEvidencia
	for rows.Next() {
		var v VersaoEvidencia
		if err := rows.Scan(&v.ID, &v.StorageKey, &v.FicheiroURL, &v.Hash, &v.SignatarioID, &v.CriadoEm); err != nil {
			return nil, err
		}
		res = append(res, v)
	}
	return res, rows.Err()
}

func (h *Handler) listarLogsEvidencia(ctx context.Context, docID, tenantID int64) ([]LogEvidencia, error) {
	rows, err := h.db.Query(ctx, `
		SELECT id, signatario_id, acao, detalhes, user_id, ip_address, created_at
		FROM assinatura_digital.logs
		WHERE documento_id=$1 AND tenant_id=$2
		ORDER BY created_at DESC`, docID, tenantID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var res []LogEvidencia
	for rows.Next() {
		var l LogEvidencia
		var ip *string
		if err := rows.Scan(&l.ID, &l.SignatarioID, &l.Acao, &l.Detalhes, &l.UserID, &ip, &l.CreatedAt); err != nil {
			return nil, err
		}
		if ip != nil {
			l.IPAddress = ip
		}
		res = append(res, l)
	}
	return res, rows.Err()
}

func (h *Handler) listarValidacoesEvidencia(ctx context.Context, docID, tenantID int64) ([]ValidacaoEvidencia, error) {
	rows, err := h.db.Query(ctx, `
		SELECT id, versao_id, hash_verificado, assinaturas, certificado_valido, certificado_motivo,
		       resultado, detalhes, user_id, created_at
		FROM assinatura_digital.validacoes
		WHERE documento_id=$1 AND tenant_id=$2
		ORDER BY created_at DESC`, docID, tenantID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var res []ValidacaoEvidencia
	for rows.Next() {
		var v ValidacaoEvidencia
		if err := rows.Scan(&v.ID, &v.VersaoID, &v.HashVerificado, &v.Assinaturas, &v.CertificadoValido,
			&v.CertificadoMotivo, &v.Resultado, &v.Detalhes, &v.UserID, &v.CreatedAt); err != nil {
			return nil, err
		}
		res = append(res, v)
	}
	return res, rows.Err()
}

// ValidacaoResponse representa o resultado de uma validação de documento.
type ValidacaoResponse struct {
	DocumentoID       int64      `json:"documento_id"`
	Status            string     `json:"status"`
	HashVerificado    string     `json:"hash_verificado"`
	Assinaturas       int        `json:"assinaturas"`
	CertificadoValido bool       `json:"certificado_valido"`
	CertificadoMotivo string     `json:"certificado_motivo,omitempty"`
	Resultado         string     `json:"resultado"`
	Aviso             string     `json:"aviso,omitempty"`
	ValidadoEm        time.Time  `json:"validado_em"`
}

// Validacao valida o documento e a(s) assinatura(s) da versão mais recente.
// GET /api/assinatura-digital/documentos/{id}/validacao
func (h *Handler) Validacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	result, err := h.validarDocumento(r.Context(), docID, user.TenantID, &user.ID, r)
	if err != nil {
		jsonErr(w, err.Error(), http.StatusNotFound)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// Revalidar força uma nova validação do documento e regista o resultado na
// tabela de validações.
// POST /api/assinatura-digital/documentos/{id}/revalidar
func (h *Handler) Revalidar(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	result, err := h.validarDocumento(r.Context(), docID, user.TenantID, &user.ID, r)
	if err != nil {
		jsonErr(w, err.Error(), http.StatusNotFound)
		return
	}

	detalhes := map[string]any{
		"status_documento": result.Status,
		"assinaturas":      result.Assinaturas,
	}
	detalhesJSON, _ := json.Marshal(detalhes)

	var versaoID *int64
	// Guarda a validação associada à versão mais recente, se existir.
	if err := h.db.QueryRow(r.Context(), `
		SELECT id FROM assinatura_digital.versoes_assinadas
		WHERE documento_id=$1 AND tenant_id=$2
		ORDER BY created_at DESC LIMIT 1`, docID, user.TenantID).Scan(&versaoID); err != nil {
		// Nenhuma versão assinada; versaoID fica nil.
	}

	if _, err := h.db.Exec(r.Context(), `
		INSERT INTO assinatura_digital.validacoes
		(documento_id, tenant_id, versao_id, hash_verificado, assinaturas, certificado_valido,
		 certificado_motivo, resultado, detalhes, user_id, ip_address)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
		docID, user.TenantID, versaoID, result.HashVerificado, result.Assinaturas,
		result.CertificadoValido, result.CertificadoMotivo, result.Resultado,
		detalhesJSON, &user.ID, ipString(r)); err != nil {
		jsonErr(w, "Erro ao registar validação", http.StatusInternalServerError)
		return
	}

	jsonOK(w, result, http.StatusOK)
}

func (h *Handler) validarDocumento(ctx context.Context, docID, tenantID int64, userID *int64, r *http.Request) (*ValidacaoResponse, error) {
	var doc struct {
		Status       string
		StorageKey   string
		HashOriginal string
	}
	if err := h.db.QueryRow(ctx, `
		SELECT status, storage_key, hash_sha256
		FROM assinatura_digital.documentos
		WHERE id=$1 AND tenant_id=$2`, docID, tenantID).Scan(&doc.Status, &doc.StorageKey, &doc.HashOriginal); err != nil {
		return nil, fmt.Errorf("Documento não encontrado")
	}

	reader, _, err := h.storage.Get(ctx, doc.StorageKey)
	if err != nil {
		return nil, fmt.Errorf("Documento não disponível")
	}
	defer reader.Close()

	data, err := io.ReadAll(reader)
	if err != nil {
		return nil, fmt.Errorf("Erro ao ler documento")
	}

	hash := sha256.Sum256(data)
	hashHex := hex.EncodeToString(hash[:])
	if hashHex != doc.HashOriginal {
		h.log(ctx, docID, nil, "validacao_integridade_falhou", map[string]any{"hash_esperado": doc.HashOriginal, "hash_obtido": hashHex}, tenantID, userID, r)
		return &ValidacaoResponse{
			DocumentoID:       docID,
			Status:            doc.Status,
			HashVerificado:    hashHex,
			Assinaturas:       0,
			CertificadoValido: false,
			Resultado:         "invalido",
			Aviso:             "Hash do documento original não corresponde ao registado.",
			ValidadoEm:        time.Now(),
		}, nil
	}

	// Versão mais recente assinada.
	var versao struct {
		StorageKey *string
		Hash       *string
	}
	if err := h.db.QueryRow(ctx, `
		SELECT storage_key, hash_sha256
		FROM assinatura_digital.versoes_assinadas
		WHERE documento_id=$1 AND tenant_id=$2
		ORDER BY created_at DESC LIMIT 1`, docID, tenantID).Scan(&versao.StorageKey, &versao.Hash); err != nil {
		// Nenhuma versão assinada ainda.
		return &ValidacaoResponse{
			DocumentoID:       docID,
			Status:            doc.Status,
			HashVerificado:    hashHex,
			Assinaturas:       0,
			CertificadoValido: false,
			Resultado:         "parcial",
			Aviso:             "Documento ainda não possui versão assinada.",
			ValidadoEm:        time.Now(),
		}, nil
	}

	var versaoData []byte
	if versao.StorageKey != nil && *versao.StorageKey != "" {
		vr, _, err := h.storage.Get(ctx, *versao.StorageKey)
		if err != nil {
			return nil, fmt.Errorf("Versão assinada não disponível")
		}
		defer vr.Close()
		versaoData, err = io.ReadAll(vr)
		if err != nil {
			return nil, fmt.Errorf("Erro ao ler versão assinada")
		}
		if versao.Hash != nil && sha256.Sum256(versaoData) != mustParseHash(*versao.Hash) {
			h.log(ctx, docID, nil, "validacao_integridade_versao_falhou", map[string]any{"hash_esperado": *versao.Hash}, tenantID, userID, r)
			return &ValidacaoResponse{
				DocumentoID:       docID,
				Status:            doc.Status,
				HashVerificado:    hashHex,
				Assinaturas:       0,
				CertificadoValido: false,
				Resultado:         "invalido",
				Aviso:             "Hash da versão assinada não corresponde ao registado.",
				ValidadoEm:        time.Now(),
			}, nil
		}
	}

	if len(versaoData) == 0 {
		versaoData = data
	}

	assinaturas := contarAssinaturasPDF(versaoData)

	// Validação temporal do certificado (limitada ao provider dev por omissão).
	certOK, certMotivo := true, ""
	if h.sigProvider != nil {
		cert, _, _, err := h.sigProvider.Signer(ctx)
		if err == nil && cert != nil {
			validator := pkimod.NewBasicValidator()
			var vok bool
			vok, certMotivo, err = validator.Validar(cert)
			if err != nil || !vok {
				certOK = false
			}
		}
	}

	resultado := "valido"
	if assinaturas == 0 {
		resultado = "parcial"
		certMotivo = "Não foi detetada assinatura PAdES no PDF."
	} else if !certOK {
		resultado = "invalido"
	}

	return &ValidacaoResponse{
		DocumentoID:       docID,
		Status:            doc.Status,
		HashVerificado:    hashHex,
		Assinaturas:       assinaturas,
		CertificadoValido: certOK && assinaturas > 0,
		CertificadoMotivo: certMotivo,
		Resultado:         resultado,
		Aviso:             "Validação estrutural PAdES requer verificação criptográfica completa quando houver provider real.",
		ValidadoEm:        time.Now(),
	}, nil
}

func mustParseHash(s string) [32]byte {
	b, _ := hex.DecodeString(s)
	var h [32]byte
	copy(h[:], b)
	return h
}

// contarAssinaturasPDF faz uma contagem heurística de assinaturas PAdES no PDF
// procurando objetos de assinatura (/Type /Sig). Não substitui uma validação
// criptográfica completa, mas é suficiente para este estágio do módulo.
func contarAssinaturasPDF(data []byte) int {
	if !bytes.HasPrefix(data, []byte("%PDF-")) {
		return 0
	}
	// A biblioteca digitorus/pdf permite ler a estrutura mas não expõe
	// contagem directa de assinaturas. Usamos uma heurística robusta no texto.
	_ = pdf.NewReader
	n := strings.Count(string(data), "/Type /Sig")
	if n == 0 {
		n = strings.Count(string(data), "/Type/Sig")
	}
	return n
}

func ipString(r *http.Request) *string {
	ip, _, _ := net.SplitHostPort(r.RemoteAddr)
	if ip == "" {
		ip = r.RemoteAddr
	}
	return &ip
}
