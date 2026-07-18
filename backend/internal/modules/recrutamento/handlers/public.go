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
	"log"
	"net"
	"net/http"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"

	"nexora/internal/shared/pessoas"
	"nexora/internal/storage"
)

var emailRe = regexp.MustCompile(`^[^\s@]+@[^\s@]+\.[^\s@]+$`)

// requestHost devolve o host do pedido normalizado: minúsculas, sem porta, sem
// ponto final e sem "www.".
//
// Atenção: só é de confiança porque o container da API não tem porta publicada
// — o único caminho até cá é o Traefik, que apenas encaminha hosts que casem
// com uma regra configurada. Se a API alguma vez ficar directamente acessível,
// um "Host:" forjado passa a valer o mesmo que o antigo ?tenant_id e esta
// resolução deixa de ser uma fronteira.
func requestHost(r *http.Request) string {
	host := r.Header.Get("X-Forwarded-Host")
	if i := strings.IndexByte(host, ','); i >= 0 {
		host = host[:i] // o proxy encadeia valores; o primeiro é o original
	}
	if strings.TrimSpace(host) == "" {
		host = r.Host
	}
	host = strings.ToLower(strings.TrimSpace(host))
	if h, _, err := net.SplitHostPort(host); err == nil {
		host = h
	}
	host = strings.TrimSuffix(host, ".")
	return strings.TrimPrefix(host, "www.")
}

// subdominioTenant extrai o código do tenant de <codigo>.<base>. Devolve ""
// se o host não for um subdomínio directo da base — só um nível conta, para
// que "a.b.base" nunca seja lido como tenant "a".
func subdominioTenant(host, base string) string {
	if base == "" || host == base {
		return ""
	}
	sufixo := "." + base
	if !strings.HasSuffix(host, sufixo) {
		return ""
	}
	label := strings.TrimSuffix(host, sufixo)
	if label == "" || strings.Contains(label, ".") {
		return ""
	}
	return label
}

// resolveTenantID devolve o tenant a usar para endpoints públicos.
//
// O tenant é derivado do domínio do pedido, nunca escolhido por quem chama:
//  1. match exacto num domínio registado em saas.tenant_dominios
//  2. subdomínio da plataforma — <codigo>.<PLATFORM_BASE_DOMAIN>
//  3. settings.recrutamento_tenant_id  (portal partilhado / instalação single-tenant)
//  4. RECRUITMENT_TENANT_ID da config  (fallback env/.env)
//
// Não existe query param: aceitar ?tenant_id deixaria qualquer visitante
// dirigir escritas (contactos, registos) a qualquer tenant.
func (h *Handler) resolveTenantID(r *http.Request) int64 {
	ctx := r.Context()
	host := requestHost(r)
	var id int64

	if host != "" {
		if err := h.db.QueryRow(ctx, `
			SELECT t.id FROM saas.tenant_dominios d
			  JOIN saas.tenants t ON t.id = d.tenant_id
			 WHERE d.dominio = $1 AND t.status = 'ativo'`, host,
		).Scan(&id); err == nil && id > 0 {
			return id
		}

		if codigo := subdominioTenant(host, h.cfg.PlatformBaseDomain); codigo != "" {
			if err := h.db.QueryRow(ctx,
				`SELECT id FROM saas.tenants WHERE codigo=$1 AND status='ativo'`, codigo,
			).Scan(&id); err == nil && id > 0 {
				return id
			}
		}
	}

	if err := h.db.QueryRow(ctx,
		`SELECT valor::bigint FROM settings WHERE chave='recrutamento_tenant_id' AND escopo='global' LIMIT 1`,
	).Scan(&id); err == nil && id > 0 {
		return id
	}

	return h.cfg.RecruitmentTenantID
}

// clean apara espaços e limita o numero de runes, replicando clean() de config/security.php.
func clean(s string, max int) string {
	s = strings.TrimSpace(s)
	r := []rune(s)
	if len(r) > max {
		r = r[:max]
	}
	return string(r)
}

// cleanEmail normaliza e valida um endereco de email; devolve "" se invalido.
func cleanEmail(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	if !emailRe.MatchString(s) {
		return ""
	}
	return s
}

func clientIP(r *http.Request) string {
	if host, _, err := net.SplitHostPort(r.RemoteAddr); err == nil {
		return host
	}
	return r.RemoteAddr
}

func randomHex(n int) string {
	b := make([]byte, n)
	rand.Read(b)
	return hex.EncodeToString(b)
}

// codigoAcompanhamento gera um código curto e único para a candidatura.
func (h *Handler) codigoAcompanhamento(ctx context.Context, tenantID int64) (string, error) {
	const charset = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // sem I, O, 0, 1 para evitar confusão
	for i := 0; i < 20; i++ {
		b := make([]byte, 10)
		if _, err := rand.Read(b); err != nil {
			return "", err
		}
		code := make([]byte, 10)
		for j := range b {
			code[j] = charset[int(b[j])%len(charset)]
		}
		codigo := string(code)
		var existe int
		err := h.db.QueryRow(ctx, `SELECT 1 FROM candidaturas WHERE tenant_id=$1 AND codigo_acompanhamento=$2`, tenantID, codigo).Scan(&existe)
		if err == pgx.ErrNoRows {
			return codigo, nil
		}
		if err != nil {
			return "", err
		}
	}
	return "", errors.New("não foi possível gerar código de acompanhamento")
}

// ── Vagas públicas ───────────────────────────────────────────────────────────

func (h *Handler) ListarVagasPublicas(w http.ResponseWriter, r *http.Request) {
	limit, offset := pageParams(r)
	tenantID := h.resolveTenantID(r)

	rows, err := h.db.Query(r.Context(),
		"SELECT "+vagaSelectCols+` FROM vagas
		 WHERE tenant_id=$1 AND ativa=TRUE AND (prazo IS NULL OR prazo >= CURRENT_DATE)
		 ORDER BY created_at DESC LIMIT $2 OFFSET $3`, tenantID, limit, offset)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []*Vaga{}
	for rows.Next() {
		v, err := scanVaga(rows)
		if err == nil {
			data = append(data, v)
		}
	}

	var total int
	h.db.QueryRow(r.Context(),
		`SELECT COUNT(*) FROM vagas WHERE tenant_id=$1 AND ativa=TRUE AND (prazo IS NULL OR prazo >= CURRENT_DATE)`,
		tenantID).Scan(&total)

	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}
	jsonOK(w, map[string]any{"data": data, "meta": map[string]int{"total": total, "page": page, "limit": limit}}, http.StatusOK)
}

func (h *Handler) ObterVagaPublica(w http.ResponseWriter, r *http.Request) {
	id := h.decodeID(chi.URLParam(r, "id"))
	tenantID := h.resolveTenantID(r)
	row := h.db.QueryRow(r.Context(), "SELECT "+vagaSelectCols+` FROM vagas
		WHERE id=$1 AND tenant_id=$2 AND ativa=TRUE AND (prazo IS NULL OR prazo >= CURRENT_DATE)`,
		id, tenantID)
	v, err := scanVaga(row)
	if err != nil {
		jsonErr(w, "Vaga não encontrada.", http.StatusNotFound)
		return
	}

	// Incluir campos do formulário específicos desta vaga
	campos, _ := h.vagaCamposAtivos(r.Context(), v.ID)

	jsonOK(w, map[string]any{
		"vaga":   v,
		"campos": campos,
	}, http.StatusOK)
}

// vagaCamposAtivos devolve os campos activos do formulário de uma vaga específica.
func (h *Handler) vagaCamposAtivos(ctx context.Context, vagaID int64) ([]campoCustom, error) {
	rows, err := h.db.Query(ctx, `
		SELECT id, codigo, label, tipo, opcoes, obrigatorio, ordem
		  FROM vaga_campos
		 WHERE vaga_id=$1 AND ativo=TRUE
		 ORDER BY ordem, id`, vagaID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	campos := []campoCustom{}
	for rows.Next() {
		var c campoCustom
		var opcoesJSON []byte
		if err := rows.Scan(&c.ID, &c.Codigo, &c.Label, &c.Tipo, &opcoesJSON, &c.Obrigatorio, &c.Ordem); err != nil {
			continue
		}
		json.Unmarshal(opcoesJSON, &c.Opcoes)
		campos = append(campos, c)
	}
	return campos, nil
}

// VagasAbertasCount replica api/vagas_abertas.php.
func (h *Handler) VagasAbertasCount(w http.ResponseWriter, r *http.Request) {
	var count int
	h.db.QueryRow(r.Context(),
		`SELECT COUNT(*) FROM vagas WHERE tenant_id=$1 AND ativa=TRUE AND (prazo IS NULL OR prazo >= CURRENT_DATE)`,
		h.resolveTenantID(r)).Scan(&count)
	jsonOK(w, map[string]int{"abertas": count}, http.StatusOK)
}

// ── Candidatura pública ──────────────────────────────────────────────────────

type uploadSpec struct {
	field        string
	prefix       string
	allowedExts  map[string]string // extensao -> Content-Type esperado
	tooLargeMsg  string
	wrongTypeMsg string
}

// saveUpload grava um ficheiro multipart opcional no storage configurado,
// validando tamanho, extensao e Content-Type. Devolve nil se o campo nao foi enviado.
// A key devolvida mantem o formato retrocompativel "cv/<filename>".
func (h *Handler) saveUpload(ctx context.Context, r *http.Request, tenantID int64, spec uploadSpec) (*string, error) {
	file, header, err := r.FormFile(spec.field)
	if err == http.ErrMissingFile {
		return nil, nil
	}
	if err != nil {
		return nil, errors.New("Erro ao processar o ficheiro.")
	}
	defer file.Close()

	maxSize := h.cfg.UploadMaxMB * 1024 * 1024
	if header.Size > maxSize {
		return nil, errors.New(spec.tooLargeMsg)
	}

	ext := strings.ToLower(strings.TrimPrefix(filepath.Ext(header.Filename), "."))
	expectedMime, ok := spec.allowedExts[ext]
	if !ok || header.Header.Get("Content-Type") != expectedMime {
		return nil, errors.New(spec.wrongTypeMsg)
	}

	filename := fmt.Sprintf("%s_%s_%s.%s", spec.prefix, time.Now().Format("20060102_150405"), randomHex(4), ext)
	key := storage.JoinPath("uploads", fmt.Sprintf("tenant-%d", tenantID), spec.prefix, filename)

	// Ler conteudo para memoria (ficheiros de upload sao pequenos, tipicamente < 3 MB)
	data := make([]byte, header.Size)
	if _, err := io.ReadFull(file, data); err != nil {
		return nil, errors.New("Erro ao ler ficheiro.")
	}

	if _, err := h.storage.Put(ctx, key, data, expectedMime); err != nil {
		return nil, errors.New("Erro ao guardar ficheiro.")
	}

	// Manter compatibilidade com paths antigos: cv/<filename>
	rel := spec.prefix + "/" + filename
	return &rel, nil
}

type campoCustom struct {
	ID          int64  `json:"id"`
	Codigo      string `json:"codigo"`
	Label       string `json:"label"`
	Tipo        string `json:"tipo"`
	Opcoes      []string `json:"opcoes"`
	Obrigatorio bool   `json:"obrigatorio"`
	Ordem       int    `json:"ordem"`
}

// camposCustomAtivos devolve os campos customizados ativos do tenant para o formulário.
func (h *Handler) camposCustomAtivos(ctx context.Context, tenantID int64) ([]campoCustom, error) {
	rows, err := h.db.Query(ctx, `
		SELECT id, codigo, label, tipo, opcoes, obrigatorio, ordem
		  FROM candidatura_campos_custom
		 WHERE tenant_id=$1 AND ativo=TRUE
		 ORDER BY ordem, id`, tenantID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	campos := []campoCustom{}
	for rows.Next() {
		var c campoCustom
		var opcoesJSON []byte
		if err := rows.Scan(&c.ID, &c.Codigo, &c.Label, &c.Tipo, &opcoesJSON, &c.Obrigatorio, &c.Ordem); err != nil {
			continue
		}
		json.Unmarshal(opcoesJSON, &c.Opcoes)
		campos = append(campos, c)
	}
	return campos, nil
}

// ListarCamposCustomPublicos expõe os campos customizados ativos para renderização do formulário público.
func (h *Handler) ListarCamposCustomPublicos(w http.ResponseWriter, r *http.Request) {
	campos, err := h.camposCustomAtivos(r.Context(), h.resolveTenantID(r))
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, campos, http.StatusOK)
}

// SubmeterCandidatura recebe uma candidatura (multipart/form-data) e os respectivos
// ficheiros, replicando api/candidatura.php.
func (h *Handler) SubmeterCandidatura(w http.ResponseWriter, r *http.Request) {
	maxBytes := h.cfg.UploadMaxMB*1024*1024*4 + 1024*1024
	r.Body = http.MaxBytesReader(w, r.Body, maxBytes)
	if err := r.ParseMultipartForm(maxBytes); err != nil {
		jsonErr(w, "Pedido demasiado grande.", http.StatusRequestEntityTooLarge)
		return
	}

	nome := clean(r.FormValue("nome"), 150)
	telefone := clean(r.FormValue("telefone"), 30)
	vagaTitulo := clean(r.FormValue("vaga_titulo"), 200)
	carta := clean(r.FormValue("carta"), 3000)
	email := cleanEmail(r.FormValue("email"))
	linkedin := clean(r.FormValue("linkedin"), 255)
	portfolio := clean(r.FormValue("portfolio"), 255)
	cidade := clean(r.FormValue("cidade"), 100)
	provincia := clean(r.FormValue("provincia"), 100)
	comoConheceu := clean(r.FormValue("como_conheceu"), 100)
	necessidadesEspeciais := clean(r.FormValue("necessidades_especiais"), 1000)
	disponibilidade := clean(r.FormValue("disponibilidade"), 50)
	pretensaoSalarial := parseOptionalFloat(r.FormValue("pretensao_salarial"))
	anosExperiencia := parseOptionalInt(r.FormValue("anos_experiencia"))

	var vagaID *int64
	if v, err := strconv.ParseInt(r.FormValue("vaga_id"), 10, 64); err == nil && v > 0 {
		vagaID = &v
	}

	// Tipo de candidatura: "publica" (default) ou "conta"
	tipoCandidatura := r.FormValue("tipo_candidatura")
	if tipoCandidatura == "" {
		tipoCandidatura = "publica"
	}

	var erros []string
	if len([]rune(nome)) < 2 {
		erros = append(erros, "Nome inválido.")
	}
	if email == "" {
		erros = append(erros, "Email inválido.")
	}
	if vagaTitulo == "" {
		erros = append(erros, "Vaga não identificada.")
	}
	if len(erros) > 0 {
		jsonErr(w, strings.Join(erros, " "), http.StatusUnprocessableEntity)
		return
	}

	// O tenant vem da própria vaga — é ela a fonte autoritativa. Só a
	// candidatura espontânea (sem vaga_id) depende do domínio do pedido.
	tenantID := h.resolveTenantID(r)
	if vagaID != nil {
		var permitePublica, permiteConta bool
		err := h.db.QueryRow(r.Context(),
			`SELECT tenant_id, permite_publica, permite_conta FROM vagas WHERE id=$1 AND ativa=TRUE`,
			*vagaID,
		).Scan(&tenantID, &permitePublica, &permiteConta)
		if err != nil {
			jsonErr(w, "Vaga não encontrada ou inactiva.", http.StatusUnprocessableEntity)
			return
		}
		if tipoCandidatura == "conta" && !permiteConta {
			jsonErr(w, "Esta vaga não aceita candidatura via conta.", http.StatusForbidden)
			return
		}
		if tipoCandidatura == "publica" && !permitePublica {
			jsonErr(w, "Esta vaga não aceita candidatura pública.", http.StatusForbidden)
			return
		}
	}

	cvPath, err := h.saveUpload(r.Context(), r, tenantID, uploadSpec{
		field:        "cv",
		prefix:       "cv",
		allowedExts:  map[string]string{"pdf": "application/pdf"},
		tooLargeMsg:  fmt.Sprintf("CV demasiado grande. Máximo %d MB.", h.cfg.UploadMaxMB),
		wrongTypeMsg: "O CV deve ser um ficheiro PDF.",
	})
	if err != nil {
		jsonErr(w, err.Error(), http.StatusUnprocessableEntity)
		return
	}

	cartaPath, err := h.saveUpload(r.Context(), r, tenantID, uploadSpec{
		field:  "carta_ficheiro",
		prefix: "carta",
		allowedExts: map[string]string{
			"pdf":  "application/pdf",
			"doc":  "application/msword",
			"docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
		},
		tooLargeMsg:  fmt.Sprintf("Carta de motivação demasiado grande. Máximo %d MB.", h.cfg.UploadMaxMB),
		wrongTypeMsg: "A carta deve ser PDF, DOC ou DOCX.",
	})
	if err != nil {
		jsonErr(w, err.Error(), http.StatusUnprocessableEntity)
		return
	}

	// Campos customizados ativos do tenant
	camposCustom, err := h.camposCustomAtivos(r.Context(), tenantID)
	if err != nil {
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	}

	// Validar e coletar valores dos campos de texto/select
	tipoValores := make(map[string]string)
	for _, c := range camposCustom {
		if c.Tipo == "ficheiro" {
			continue
		}
		val := r.FormValue("custom_" + c.Codigo)
		if c.Obrigatorio && strings.TrimSpace(val) == "" {
			erros = append(erros, fmt.Sprintf("%s é obrigatório.", c.Label))
			continue
		}
		tipoValores[c.Codigo] = val
	}
	if len(erros) > 0 {
		jsonErr(w, strings.Join(erros, " "), http.StatusUnprocessableEntity)
		return
	}

	// Fazer upload dos ficheiros custom ANTES da transação.
	// Em caso de erro posterior, limpamos todos os ficheiros enviados.
	type customFile struct {
		campoID int64
		path    string
	}
	var customFiles []customFile
	var uploadedPaths []string // rastrear para cleanup em caso de erro

	cleanupUploads := func() {
		for _, p := range uploadedPaths {
			key := storage.JoinPath("uploads", fmt.Sprintf("tenant-%d", tenantID), p)
			if err := h.storage.Delete(r.Context(), key); err != nil {
				log.Printf("SubmeterCandidatura: erro ao limpar ficheiro %s: %v", key, err)
			}
		}
	}

	for _, c := range camposCustom {
		if c.Tipo != "ficheiro" {
			continue
		}
		filePath, err := h.saveUpload(r.Context(), r, tenantID, uploadSpec{
			field:        "custom_" + c.Codigo,
			prefix:       "custom_" + c.Codigo,
			allowedExts:  map[string]string{"pdf": "application/pdf", "doc": "application/msword", "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "jpg": "image/jpeg", "jpeg": "image/jpeg", "png": "image/png"},
			tooLargeMsg:  fmt.Sprintf("Ficheiro %s demasiado grande. Máximo %d MB.", c.Label, h.cfg.UploadMaxMB),
			wrongTypeMsg: fmt.Sprintf("Ficheiro %s deve ser PDF, DOC, DOCX, JPG ou PNG.", c.Label),
		})
		if err != nil {
			cleanupUploads()
			jsonErr(w, err.Error(), http.StatusUnprocessableEntity)
			return
		}
		if filePath != nil {
			customFiles = append(customFiles, customFile{campoID: c.ID, path: *filePath})
			uploadedPaths = append(uploadedPaths, *filePath)
		}
	}

	codigo, err := h.codigoAcompanhamento(r.Context(), tenantID)
	if err != nil {
		cleanupUploads()
		jsonErr(w, "Erro ao gerar código de acompanhamento.", http.StatusInternalServerError)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		cleanupUploads()
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var candidaturaID int64
	err = tx.QueryRow(r.Context(), `
		INSERT INTO candidaturas
			(tenant_id, vaga_id, nome, email, telefone, vaga_titulo, carta, cv_ficheiro, carta_ficheiro, ip, estado,
			 codigo_acompanhamento, pretensao_salarial, disponibilidade, anos_experiencia, linkedin, portfolio,
			 cidade, provincia, como_conheceu, necessidades_especiais)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'recebida',$11,$12,$13,$14,$15,$16,$17,$18,$19,$20)
		RETURNING id`,
		tenantID, vagaID, nome, email, nullIfEmpty(telefone), vagaTitulo, nullIfEmpty(carta),
		cvPath, cartaPath, clientIP(r), codigo, pretensaoSalarial, nullIfEmpty(disponibilidade),
		anosExperiencia, nullIfEmpty(linkedin), nullIfEmpty(portfolio), nullIfEmpty(cidade),
		nullIfEmpty(provincia), nullIfEmpty(comoConheceu), nullIfEmpty(necessidadesEspeciais)).Scan(&candidaturaID)
	if err != nil {
		cleanupUploads()
		jsonErr(w, "Erro ao guardar candidatura. Tente novamente.", http.StatusInternalServerError)
		return
	}

	// Guardar ficheiros custom já feitos upload
	for _, cf := range customFiles {
		if _, err := tx.Exec(r.Context(), `
			INSERT INTO candidatura_valores_custom (candidatura_id, campo_id, ficheiro)
			VALUES ($1,$2,$3)`, candidaturaID, cf.campoID, cf.path); err != nil {
			cleanupUploads()
			jsonErr(w, "Erro ao guardar ficheiro customizado.", http.StatusInternalServerError)
			return
		}
	}

	// Guardar valores dos campos de texto/select (tenant-level)
	for _, c := range camposCustom {
		if c.Tipo == "ficheiro" {
			continue
		}
		val := tipoValores[c.Codigo]
		if val != "" {
			if _, err := tx.Exec(r.Context(), `
				INSERT INTO candidatura_valores_custom (candidatura_id, campo_id, valor)
				VALUES ($1,$2,$3)`, candidaturaID, c.ID, val); err != nil {
				cleanupUploads()
				jsonErr(w, "Erro ao guardar campo customizado.", http.StatusInternalServerError)
				return
			}
		}
	}

	// Guardar respostas dos campos por vaga (vaga_campos → candidatura_respostas_vaga)
	if vagaID != nil {
		vagaCampos, _ := h.vagaCamposAtivos(r.Context(), *vagaID)
		for _, c := range vagaCampos {
			if c.Tipo == "ficheiro" {
				filePath, err := h.saveUpload(r.Context(), r, tenantID, uploadSpec{
					field:        "vaga_" + c.Codigo,
					prefix:       "vaga_" + c.Codigo,
					allowedExts:  map[string]string{"pdf": "application/pdf", "doc": "application/msword", "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "jpg": "image/jpeg", "jpeg": "image/jpeg", "png": "image/png"},
					tooLargeMsg:  fmt.Sprintf("Ficheiro %s demasiado grande. Máximo %d MB.", c.Label, h.cfg.UploadMaxMB),
					wrongTypeMsg: fmt.Sprintf("Ficheiro %s deve ser PDF, DOC, DOCX, JPG ou PNG.", c.Label),
				})
				if err != nil {
					cleanupUploads()
					jsonErr(w, err.Error(), http.StatusUnprocessableEntity)
					return
				}
				if filePath != nil {
					uploadedPaths = append(uploadedPaths, *filePath)
					if _, err := tx.Exec(r.Context(), `
						INSERT INTO candidatura_respostas_vaga (candidatura_id, campo_id, ficheiro)
						VALUES ($1,$2,$3)`, candidaturaID, c.ID, filePath); err != nil {
						cleanupUploads()
						jsonErr(w, "Erro ao guardar ficheiro da vaga.", http.StatusInternalServerError)
						return
					}
				} else if c.Obrigatorio {
					cleanupUploads()
					jsonErr(w, fmt.Sprintf("%s é obrigatório.", c.Label), http.StatusUnprocessableEntity)
					return
				}
			} else {
				val := r.FormValue("vaga_" + c.Codigo)
				if c.Obrigatorio && strings.TrimSpace(val) == "" {
					cleanupUploads()
					jsonErr(w, fmt.Sprintf("%s é obrigatório.", c.Label), http.StatusUnprocessableEntity)
					return
				}
				if val != "" {
					if _, err := tx.Exec(r.Context(), `
						INSERT INTO candidatura_respostas_vaga (candidatura_id, campo_id, valor)
						VALUES ($1,$2,$3)`, candidaturaID, c.ID, val); err != nil {
						cleanupUploads()
						jsonErr(w, "Erro ao guardar resposta da vaga.", http.StatusInternalServerError)
						return
					}
				}
			}
		}
	}

	if err := tx.Commit(r.Context()); err != nil {
		cleanupUploads()
		jsonErr(w, "Erro ao guardar candidatura.", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]string{
		"sucesso":               "Candidatura recebida! Entraremos em contacto em breve.",
		"codigo_acompanhamento": codigo,
	}, http.StatusOK)
}

// ConsultarCandidaturaPorCodigo permite ao candidato consultar o estado público da candidatura.
//
// Sem filtro por tenant de propósito: codigo_acompanhamento é único global
// (uq_candidaturas_codigo_acompanhamento) e imprevisível (10 chars num alfabeto
// de 32 ≈ 50 bits), portanto é o próprio código que autoriza o acesso. Filtrar
// por tenant não acrescentaria segurança e partiria a consulta a partir de
// qualquer domínio que não fosse o do empregador.
func (h *Handler) ConsultarCandidaturaPorCodigo(w http.ResponseWriter, r *http.Request) {
	codigo := strings.ToUpper(strings.TrimSpace(chi.URLParam(r, "codigo")))
	if codigo == "" {
		jsonErr(w, "Código de acompanhamento em falta.", http.StatusBadRequest)
		return
	}

	var c struct {
		ID                    int64      `json:"id"`
		VagaTitulo            string     `json:"vaga_titulo"`
		Nome                  string     `json:"nome"`
		Estado                string     `json:"estado"`
		Score                 *int       `json:"score"`
		EntrevistaData        *time.Time `json:"entrevista_data"`
		EntrevistaLocal       *string    `json:"entrevista_local"`
		EntrevistaLink        *string    `json:"entrevista_link"`
		CreatedAt             time.Time  `json:"created_at"`
		CodigoAcompanhamento  string     `json:"codigo_acompanhamento"`
	}

	err := h.db.QueryRow(r.Context(), `
		SELECT id, vaga_titulo, nome, estado, score, entrevista_data, entrevista_local, entrevista_link, created_at, codigo_acompanhamento
		  FROM candidaturas
		 WHERE codigo_acompanhamento=$1`,
		codigo).Scan(
		&c.ID, &c.VagaTitulo, &c.Nome, &c.Estado, &c.Score, &c.EntrevistaData,
		&c.EntrevistaLocal, &c.EntrevistaLink, &c.CreatedAt, &c.CodigoAcompanhamento)
	if err != nil {
		jsonErr(w, "Candidatura não encontrada.", http.StatusNotFound)
		return
	}

	// Notas do tipo sistema = histórico de comunicações/estados visíveis ao candidato
	rows, err := h.db.Query(r.Context(), `
		SELECT conteudo, created_at FROM candidatura_notas
		 WHERE candidatura_id=$1 AND tipo='sistema'
		 ORDER BY created_at DESC`, c.ID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type notaPublica struct {
		Conteudo  string    `json:"conteudo"`
		CreatedAt time.Time `json:"created_at"`
	}
	var historico []notaPublica
	for rows.Next() {
		var n notaPublica
		if rows.Scan(&n.Conteudo, &n.CreatedAt) == nil {
			historico = append(historico, n)
		}
	}

	jsonOK(w, map[string]any{
		"candidatura": c,
		"historico":   historico,
	}, http.StatusOK)
}

// ── Conta do candidato (opcional) ────────────────────────────────────────────

func (h *Handler) RegistarCandidato(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Nome     string `json:"nome"`
		Email    string `json:"email"`
		Telefone string `json:"telefone"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}

	nome := clean(body.Nome, 150)
	email := cleanEmail(body.Email)
	telefone := clean(body.Telefone, 30)
	password := strings.TrimSpace(body.Password)

	var erros []string
	if len([]rune(nome)) < 2 {
		erros = append(erros, "Nome inválido.")
	}
	if email == "" {
		erros = append(erros, "Email inválido.")
	}
	if len(password) < 6 {
		erros = append(erros, "A palavra-passe deve ter pelo menos 6 caracteres.")
	}
	if len(erros) > 0 {
		jsonErr(w, strings.Join(erros, " "), http.StatusUnprocessableEntity)
		return
	}

	// Login unificado: a password vive em auth.users. Reaproveita a conta se já
	// existir (ex.: ex-funcionário desligado, ou candidatura noutro tenant).
	var userID int64
	var tipoExistente string
	errUser := h.db.QueryRow(r.Context(), `SELECT id, tipo FROM auth.users WHERE email = $1`, email).
		Scan(&userID, &tipoExistente)

	switch {
	case errUser == pgx.ErrNoRows:
		hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
		if err != nil {
			jsonErr(w, "Erro interno.", http.StatusInternalServerError)
			return
		}
		if err := h.db.QueryRow(r.Context(), `
			INSERT INTO auth.users (nome, email, password_hash, telefone, tipo)
			VALUES ($1,$2,$3,$4,'candidato') RETURNING id`,
			nome, email, string(hash), nullIfEmpty(telefone)).Scan(&userID); err != nil {
			jsonErr(w, "Erro ao criar conta.", http.StatusInternalServerError)
			return
		}
	case errUser != nil:
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	case tipoExistente != "candidato":
		jsonErr(w, "Já existe uma conta com este email. Inicie sessão em /api/auth/login.", http.StatusConflict)
		return
	}

	// Ligar a conta a uma pessoa desde o auto-registo (ver
	// docs/analise-modelo-pessoa-multi-tenant.md secção 9) — antes disto, um
	// candidato só ficava ligado a pessoas.pessoas se/quando fosse contratado.
	_, _ = pessoas.EnsureUserPessoa(r.Context(), h.db, userID, nome, nil)

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO candidatos (tenant_id, email, nome, telefone, user_id)
		VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		h.resolveTenantID(r), email, nome, nullIfEmpty(telefone), userID).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já tem uma conta neste empregador. Inicie sessão em /api/auth/login.", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro ao criar conta.", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"id": id, "sucesso": "Conta criada com sucesso. Inicie sessão em /api/auth/login."}, http.StatusCreated)
}

// LogoutCandidato revoga a sessão do candidato identificada pelo token Bearer.
// POST /api/portal/candidatos/logout
func (h *Handler) LogoutCandidato(w http.ResponseWriter, r *http.Request) {
	auth := r.Header.Get("Authorization")
	if !strings.HasPrefix(auth, "Bearer ") {
		jsonErr(w, "Token em falta.", http.StatusUnauthorized)
		return
	}
	rawToken := strings.TrimPrefix(auth, "Bearer ")
	sum := sha256.Sum256([]byte(rawToken))
	tokenHash := hex.EncodeToString(sum[:])

	tag, err := h.db.Exec(r.Context(), `
		UPDATE recrutamento.candidato_sessions
		   SET revogado_em = NOW()
		 WHERE token_hash = $1
		   AND revogado_em IS NULL
		   AND expira_em > NOW()`, tokenHash)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Sessão não encontrada ou já terminada.", http.StatusUnauthorized)
		return
	}

	jsonOK(w, map[string]string{"sucesso": "Sessão terminada."}, http.StatusOK)
}

// SubmeterContacto recebe uma mensagem de contacto (JSON), replicando api/contacto.php.
func (h *Handler) SubmeterContacto(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Nome     string `json:"nome"`
		Email    string `json:"email"`
		Assunto  string `json:"assunto"`
		Mensagem string `json:"mensagem"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}

	nome := clean(body.Nome, 150)
	email := cleanEmail(body.Email)
	assunto := clean(body.Assunto, 255)
	mensagem := clean(body.Mensagem, 2000)

	var erros []string
	if len([]rune(nome)) < 2 {
		erros = append(erros, "Nome inválido.")
	}
	if email == "" {
		erros = append(erros, "Email inválido.")
	}
	if len([]rune(assunto)) < 3 {
		erros = append(erros, "Assunto inválido.")
	}
	if len([]rune(mensagem)) < 10 {
		erros = append(erros, "Mensagem demasiado curta.")
	}
	if len(erros) > 0 {
		jsonErr(w, strings.Join(erros, " "), http.StatusUnprocessableEntity)
		return
	}

	_, err := h.db.Exec(r.Context(),
		`INSERT INTO contactos (tenant_id, nome, email, assunto, mensagem, ip) VALUES ($1,$2,$3,$4,$5,$6)`,
		h.resolveTenantID(r), nome, email, assunto, mensagem, clientIP(r))
	if err != nil {
		jsonErr(w, "Erro ao guardar. Tente novamente.", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]string{"sucesso": "Mensagem recebida! Entraremos em contacto em breve."}, http.StatusOK)
}
