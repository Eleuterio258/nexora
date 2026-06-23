package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

type Candidatura struct {
	ID              int64      `json:"id"`
	VagaID          *int64     `json:"vaga_id"`
	Nome            string     `json:"nome"`
	Email           string     `json:"email"`
	Telefone        *string    `json:"telefone"`
	VagaTitulo      string     `json:"vaga_titulo"`
	Carta           *string    `json:"carta"`
	CVFicheiro      *string    `json:"cv_ficheiro"`
	CartaFicheiro   *string    `json:"carta_ficheiro"`
	IP              string     `json:"ip"`
	Estado          string     `json:"estado"`
	Score           *int16     `json:"score"`
	Responsavel     *string    `json:"responsavel"`
	EntrevistaData  *time.Time `json:"entrevista_data"`
	EntrevistaLocal *string    `json:"entrevista_local"`
	EntrevistaLink  *string    `json:"entrevista_link"`
	EntrevistaNotas *string    `json:"entrevista_notas"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

type CandidaturaNota struct {
	ID            int64     `json:"id"`
	CandidaturaID int64     `json:"candidatura_id"`
	Autor         string    `json:"autor"`
	Tipo          string    `json:"tipo"`
	Conteudo      string    `json:"conteudo"`
	CreatedAt     time.Time `json:"created_at"`
}

type candidaturaDetalhe struct {
	*Candidatura
	Notas []CandidaturaNota `json:"notas"`
}

const candidaturaSelectCols = `id, vaga_id, nome, email, telefone, vaga_titulo, carta,
	cv_ficheiro, carta_ficheiro, ip, estado, score, responsavel,
	entrevista_data, entrevista_local, entrevista_link, entrevista_notas,
	created_at, updated_at`

func scanCandidatura(row pgx.Row) (*Candidatura, error) {
	var c Candidatura
	if err := row.Scan(&c.ID, &c.VagaID, &c.Nome, &c.Email, &c.Telefone, &c.VagaTitulo, &c.Carta,
		&c.CVFicheiro, &c.CartaFicheiro, &c.IP, &c.Estado, &c.Score, &c.Responsavel,
		&c.EntrevistaData, &c.EntrevistaLocal, &c.EntrevistaLink, &c.EntrevistaNotas,
		&c.CreatedAt, &c.UpdatedAt); err != nil {
		return nil, err
	}
	return &c, nil
}

var estadoLabels = map[string]string{
	"recebida":   "Recebida",
	"em_analise": "Em Análise",
	"entrevista": "Entrevista",
	"aprovada":   "Aprovada",
	"rejeitada":  "Rejeitada",
}

var scoreLabels = map[int16]string{
	1: "Fraco",
	2: "Abaixo da média",
	3: "Médio",
	4: "Bom",
	5: "Excelente",
}

func nullIfEmpty(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

// parseEntrevistaData aceita RFC3339 ou "YYYY-MM-DDTHH:MM" (formato de <input type="datetime-local">).
func parseEntrevistaData(s string) (time.Time, error) {
	if t, err := time.Parse(time.RFC3339, s); err == nil {
		return t, nil
	}
	if t, err := time.Parse("2006-01-02T15:04", s); err == nil {
		return t, nil
	}
	return time.Time{}, fmt.Errorf("formato de data inválido")
}

// ── Listagem / detalhe ───────────────────────────────────────────────────────

func (h *Handler) ListarCandidaturas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)

	where := "tenant_id=$1"
	args := []any{user.TenantID}

	if estado := q.Get("estado"); estado != "" {
		args = append(args, estado)
		where += " AND estado=$" + strconv.Itoa(len(args))
	}
	if vagaIDStr := q.Get("vaga_id"); vagaIDStr != "" {
		if vagaID, err := strconv.ParseInt(vagaIDStr, 10, 64); err == nil {
			args = append(args, vagaID)
			where += " AND vaga_id=$" + strconv.Itoa(len(args))
		}
	}
	if s := q.Get("search"); s != "" {
		args = append(args, "%"+s+"%")
		n := strconv.Itoa(len(args))
		where += " AND (nome ILIKE $" + n + " OR email ILIKE $" + n + ")"
	}

	countArgs := append([]any{}, args...)
	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(),
		"SELECT "+candidaturaSelectCols+" FROM candidaturas WHERE "+where+
			" ORDER BY created_at DESC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []*Candidatura{}
	for rows.Next() {
		c, err := scanCandidatura(rows)
		if err == nil {
			data = append(data, c)
		}
	}

	var total int
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM candidaturas WHERE "+where, countArgs...).Scan(&total)
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 {
		page = 1
	}
	jsonOK(w, map[string]any{"data": data, "meta": map[string]int{"total": total, "page": page, "limit": limit}}, http.StatusOK)
}

func (h *Handler) ObterCandidatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	ctx := r.Context()

	row := h.db.QueryRow(ctx, "SELECT "+candidaturaSelectCols+" FROM candidaturas WHERE id=$1 AND tenant_id=$2", id, user.TenantID)
	c, err := scanCandidatura(row)
	if err != nil {
		jsonErr(w, "Candidatura não encontrada.", http.StatusNotFound)
		return
	}

	notas := []CandidaturaNota{}
	rows, err := h.db.Query(ctx,
		"SELECT id, candidatura_id, autor, tipo, conteudo, created_at FROM candidatura_notas WHERE candidatura_id=$1 ORDER BY created_at DESC", id)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var n CandidaturaNota
			if rows.Scan(&n.ID, &n.CandidaturaID, &n.Autor, &n.Tipo, &n.Conteudo, &n.CreatedAt) == nil {
				notas = append(notas, n)
			}
		}
	}

	jsonOK(w, candidaturaDetalhe{Candidatura: c, Notas: notas}, http.StatusOK)
}

// ── Pipeline ─────────────────────────────────────────────────────────────────

// MoverCandidatura altera o estado e regista uma nota de sistema com a transição,
// replicando admin/api/candidatura_mover.php.
func (h *Handler) MoverCandidatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Estado string `json:"estado"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	novoLabel, ok := estadoLabels[body.Estado]
	if !ok {
		jsonErr(w, "Estado inválido.", http.StatusUnprocessableEntity)
		return
	}

	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	var oldEstado string
	if err := tx.QueryRow(ctx, "SELECT estado FROM candidaturas WHERE id=$1 AND tenant_id=$2 FOR UPDATE", id, user.TenantID).Scan(&oldEstado); err != nil {
		jsonErr(w, "Candidatura não encontrada.", http.StatusNotFound)
		return
	}

	if _, err := tx.Exec(ctx, "UPDATE candidaturas SET estado=$1, updated_at=NOW() WHERE id=$2", body.Estado, id); err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}

	if oldEstado != body.Estado {
		texto := fmt.Sprintf("Estado alterado: %s → %s", estadoLabels[oldEstado], novoLabel)
		if _, err := tx.Exec(ctx,
			"INSERT INTO candidatura_notas (candidatura_id, autor, tipo, conteudo) VALUES ($1,'sistema','sistema',$2)",
			id, texto); err != nil {
			jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// AvaliarCandidatura grava a pontuação (1-5) e, se houver comentário, regista uma
// nota de avaliação, replicando admin/api/candidatura_avaliar.php.
func (h *Handler) AvaliarCandidatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Score *int16  `json:"score"`
		Nota  *string `json:"nota"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	if body.Score != nil && (*body.Score < 1 || *body.Score > 5) {
		jsonErr(w, "Avaliação inválida.", http.StatusUnprocessableEntity)
		return
	}

	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	tag, err := tx.Exec(ctx, "UPDATE candidaturas SET score=$1, updated_at=NOW() WHERE id=$2 AND tenant_id=$3", body.Score, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Candidatura não encontrada.", http.StatusNotFound)
		return
	}

	nota := ""
	if body.Nota != nil {
		nota = strings.TrimSpace(*body.Nota)
	}
	if body.Score != nil && nota != "" {
		texto := fmt.Sprintf("Avaliação: %s (%d/5)\n%s", scoreLabels[*body.Score], *body.Score, nota)
		if _, err := tx.Exec(ctx,
			"INSERT INTO candidatura_notas (candidatura_id, autor, tipo, conteudo) VALUES ($1,'admin','avaliacao',$2)",
			id, texto); err != nil {
			jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// AgendarEntrevista grava os dados da entrevista, avança o estado de "em_analise"
// para "entrevista" e regista uma nota com o resumo, replicando admin/api/entrevista_save.php.
func (h *Handler) AgendarEntrevista(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Data    string  `json:"data"`
		Formato *string `json:"formato"`
		Local   *string `json:"local"`
		Link    *string `json:"link"`
		Notas   *string `json:"notas"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}

	dataStr := strings.TrimSpace(body.Data)
	if dataStr == "" {
		jsonErr(w, "A data da entrevista é obrigatória.", http.StatusUnprocessableEntity)
		return
	}
	entrevistaData, err := parseEntrevistaData(dataStr)
	if err != nil {
		jsonErr(w, "Formato de data inválido.", http.StatusUnprocessableEntity)
		return
	}

	formato := strDefault(body.Formato, "Presencial")
	local := ""
	if body.Local != nil {
		local = strings.TrimSpace(*body.Local)
	}
	link := ""
	if body.Link != nil {
		link = strings.TrimSpace(*body.Link)
	}
	notas := ""
	if body.Notas != nil {
		notas = strings.TrimSpace(*body.Notas)
	}

	ctx := r.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	tag, err := tx.Exec(ctx, `
		UPDATE candidaturas SET
			entrevista_data=$1, entrevista_local=$2, entrevista_link=$3, entrevista_notas=$4,
			estado = CASE WHEN estado='em_analise' THEN 'entrevista' ELSE estado END,
			updated_at=NOW()
		WHERE id=$5 AND tenant_id=$6`,
		entrevistaData, nullIfEmpty(local), nullIfEmpty(link), nullIfEmpty(notas), id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Candidatura não encontrada.", http.StatusNotFound)
		return
	}

	resumo := fmt.Sprintf("Entrevista agendada: %s (%s)", entrevistaData.Format("02/01/2006 15:04"), formato)
	if local != "" {
		resumo += "\nLocal: " + local
	}
	if link != "" {
		resumo += "\nLink: " + link
	}
	if notas != "" {
		resumo += "\n" + notas
	}
	if _, err := tx.Exec(ctx,
		"INSERT INTO candidatura_notas (candidatura_id, autor, tipo, conteudo) VALUES ($1,'admin','entrevista',$2)",
		id, resumo); err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// AdicionarNota acrescenta uma nota livre ao histórico da candidatura, replicando
// admin/api/nota_save.php. O autor é o nome do utilizador autenticado.
func (h *Handler) AdicionarNota(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	ctx := r.Context()

	var body struct {
		Conteudo string `json:"conteudo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	conteudo := strings.TrimSpace(body.Conteudo)
	if conteudo == "" {
		jsonErr(w, "O conteúdo da nota é obrigatório.", http.StatusUnprocessableEntity)
		return
	}

	var exists bool
	if err := h.db.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM candidaturas WHERE id=$1 AND tenant_id=$2)", id, user.TenantID).Scan(&exists); err != nil || !exists {
		jsonErr(w, "Candidatura não encontrada.", http.StatusNotFound)
		return
	}

	autor := "admin"
	var nome string
	if err := h.db.QueryRow(ctx, "SELECT nome FROM auth.users WHERE id=$1", user.ID).Scan(&nome); err == nil {
		if nome = strings.TrimSpace(nome); nome != "" {
			autor = nome
		}
	}

	var nota CandidaturaNota
	err := h.db.QueryRow(ctx, `
		INSERT INTO candidatura_notas (candidatura_id, autor, tipo, conteudo)
		VALUES ($1,$2,'nota',$3)
		RETURNING id, candidatura_id, autor, tipo, conteudo, created_at`,
		id, autor, conteudo,
	).Scan(&nota.ID, &nota.CandidaturaID, &nota.Autor, &nota.Tipo, &nota.Conteudo, &nota.CreatedAt)
	if err != nil {
		jsonErr(w, "Erro ao guardar.", http.StatusInternalServerError)
		return
	}
	jsonOK(w, nota, http.StatusCreated)
}

// ── Downloads ────────────────────────────────────────────────────────────────

func (h *Handler) downloadFicheiro(coluna string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user := mw.GetUser(r)
		id := chi.URLParam(r, "id")

		var ficheiro *string
		err := h.db.QueryRow(r.Context(),
			"SELECT "+coluna+" FROM candidaturas WHERE id=$1 AND tenant_id=$2", id, user.TenantID,
		).Scan(&ficheiro)
		if err != nil || ficheiro == nil || *ficheiro == "" {
			jsonErr(w, "Ficheiro não encontrado.", http.StatusNotFound)
			return
		}

		path := filepath.Join(h.cfg.UploadsDir, strings.TrimPrefix(*ficheiro, "uploads/"))
		if _, err := os.Stat(path); err != nil {
			jsonErr(w, "Ficheiro não encontrado.", http.StatusNotFound)
			return
		}

		w.Header().Set("Content-Disposition", `attachment; filename="`+filepath.Base(path)+`"`)
		http.ServeFile(w, r, path)
	}
}

func (h *Handler) DownloadCV(w http.ResponseWriter, r *http.Request) {
	h.downloadFicheiro("cv_ficheiro")(w, r)
}

func (h *Handler) DownloadCarta(w http.ResponseWriter, r *http.Request) {
	h.downloadFicheiro("carta_ficheiro")(w, r)
}
