package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
)

var emailRe = regexp.MustCompile(`^[^\s@]+@[^\s@]+\.[^\s@]+$`)

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

// ── Vagas públicas ───────────────────────────────────────────────────────────

func (h *Handler) ListarVagasPublicas(w http.ResponseWriter, r *http.Request) {
	limit, offset := pageParams(r)
	tenantID := h.cfg.RecruitmentTenantID

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
	id := chi.URLParam(r, "id")
	row := h.db.QueryRow(r.Context(), "SELECT "+vagaSelectCols+` FROM vagas
		WHERE id=$1 AND tenant_id=$2 AND ativa=TRUE AND (prazo IS NULL OR prazo >= CURRENT_DATE)`,
		id, h.cfg.RecruitmentTenantID)
	v, err := scanVaga(row)
	if err != nil {
		jsonErr(w, "Vaga não encontrada.", http.StatusNotFound)
		return
	}
	jsonOK(w, v, http.StatusOK)
}

// VagasAbertasCount replica api/vagas_abertas.php.
func (h *Handler) VagasAbertasCount(w http.ResponseWriter, r *http.Request) {
	var count int
	h.db.QueryRow(r.Context(),
		`SELECT COUNT(*) FROM vagas WHERE tenant_id=$1 AND ativa=TRUE AND (prazo IS NULL OR prazo >= CURRENT_DATE)`,
		h.cfg.RecruitmentTenantID).Scan(&count)
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

// saveUpload grava um ficheiro multipart opcional em dir, validando tamanho,
// extensao e Content-Type. Devolve nil se o campo nao foi enviado.
func (h *Handler) saveUpload(r *http.Request, dir string, spec uploadSpec) (*string, error) {
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
	dest := filepath.Join(dir, filename)
	out, err := os.Create(dest)
	if err != nil {
		return nil, errors.New("Erro ao guardar ficheiro.")
	}
	defer out.Close()
	if _, err := io.Copy(out, file); err != nil {
		return nil, errors.New("Erro ao guardar ficheiro.")
	}

	rel := "cv/" + filename
	return &rel, nil
}

// SubmeterCandidatura recebe uma candidatura (multipart/form-data) e os respectivos
// ficheiros, replicando api/candidatura.php.
func (h *Handler) SubmeterCandidatura(w http.ResponseWriter, r *http.Request) {
	maxBytes := h.cfg.UploadMaxMB*1024*1024*2 + 1024*1024
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

	var vagaID *int64
	if v, err := strconv.ParseInt(r.FormValue("vaga_id"), 10, 64); err == nil && v > 0 {
		vagaID = &v
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

	uploadDir := filepath.Join(h.cfg.UploadsDir, "cv")
	if err := os.MkdirAll(uploadDir, 0750); err != nil {
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	}

	cvPath, err := h.saveUpload(r, uploadDir, uploadSpec{
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

	cartaPath, err := h.saveUpload(r, uploadDir, uploadSpec{
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

	_, err = h.db.Exec(r.Context(), `
		INSERT INTO candidaturas
			(tenant_id, vaga_id, nome, email, telefone, vaga_titulo, carta, cv_ficheiro, carta_ficheiro, ip, estado)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'recebida')`,
		h.cfg.RecruitmentTenantID, vagaID, nome, email, nullIfEmpty(telefone), vagaTitulo, nullIfEmpty(carta),
		cvPath, cartaPath, clientIP(r))
	if err != nil {
		jsonErr(w, "Erro ao guardar candidatura. Tente novamente.", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]string{"sucesso": "Candidatura recebida! Entraremos em contacto em breve."}, http.StatusOK)
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
		h.cfg.RecruitmentTenantID, nome, email, assunto, mensagem, clientIP(r))
	if err != nil {
		jsonErr(w, "Erro ao guardar. Tente novamente.", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]string{"sucesso": "Mensagem recebida! Entraremos em contacto em breve."}, http.StatusOK)
}
