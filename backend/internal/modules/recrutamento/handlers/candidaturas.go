package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/storage"
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

type RespostaVaga struct {
	CampoID  int64   `json:"campo_id"`
	Codigo   string  `json:"codigo"`
	Label    string  `json:"label"`
	Tipo     string  `json:"tipo"`
	Valor    *string `json:"valor"`
	Ficheiro *string `json:"ficheiro"`
}

type candidaturaDetalhe struct {
	*Candidatura
	Notas          []CandidaturaNota `json:"notas"`
	RespostasVaga  []RespostaVaga    `json:"respostas_vaga"`
	VagaArea       *string           `json:"vaga_area"`
	VagaCargoID    *int64            `json:"vaga_cargo_id"`
	VagaCargoNome  *string           `json:"vaga_cargo_nome"`
	VagaSalarioMin *float64          `json:"vaga_salario_min"`
	VagaSalarioMax *float64          `json:"vaga_salario_max"`
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

// parseEntrevistaData aceita RFC3339 ou "YYYY-MM-DDTHH:MM" (formato de <input type="datetime-local">).
// Datas sem timezone são interpretadas como UTC.
func parseEntrevistaData(s string) (time.Time, error) {
	if t, err := time.Parse(time.RFC3339, s); err == nil {
		return t.UTC(), nil
	}
	if t, err := time.Parse("2006-01-02T15:04", s); err == nil {
		return t.UTC(), nil
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
	if scoreStr := q.Get("score"); scoreStr != "" {
		if score, err := strconv.ParseInt(scoreStr, 10, 16); err == nil && score >= 1 && score <= 5 {
			args = append(args, int16(score))
			where += " AND score=$" + strconv.Itoa(len(args))
		}
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
	id := h.decodeID(chi.URLParam(r, "id"))
	ctx := r.Context()

	row := h.db.QueryRow(ctx, "SELECT "+candidaturaSelectCols+" FROM candidaturas WHERE id=$1 AND tenant_id=$2", id, user.TenantID)
	c, err := scanCandidatura(row)
	if err != nil {
		jsonErr(w, "Candidatura não encontrada.", http.StatusNotFound)
		return
	}

	// Área, cargo e faixa salarial definidos na vaga — o cargo é a fonte
	// autoritativa que o backend aplica automaticamente ao funcionário ao
	// contratar (ver ContratarCandidato); o frontend mostra-o aqui só como
	// informação, e usa a faixa salarial para sugerir o salário base.
	var vagaArea, vagaCargoNome *string
	var vagaCargoID *int64
	var vagaSalarioMin, vagaSalarioMax *float64
	_ = h.db.QueryRow(ctx, `
		SELECT v.area, v.cargo_id, rc.nome, rc.salario_min, rc.salario_max
		FROM candidaturas c
		LEFT JOIN vagas v ON v.id = c.vaga_id
		LEFT JOIN rh.cargos rc ON rc.id = v.cargo_id
		WHERE c.id = $1`, id,
	).Scan(&vagaArea, &vagaCargoID, &vagaCargoNome, &vagaSalarioMin, &vagaSalarioMax)

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

	// Respostas dos campos por vaga
	respostasVaga := []RespostaVaga{}
	rowsRV, err := h.db.Query(ctx, `
		SELECT vc.id, vc.codigo, vc.label, vc.tipo, rv.valor, rv.ficheiro
		  FROM candidatura_respostas_vaga rv
		  JOIN vaga_campos vc ON vc.id = rv.campo_id
		 WHERE rv.candidatura_id = $1
		 ORDER BY vc.ordem, vc.id`, id)
	if err == nil {
		defer rowsRV.Close()
		for rowsRV.Next() {
			var r RespostaVaga
			if rowsRV.Scan(&r.CampoID, &r.Codigo, &r.Label, &r.Tipo, &r.Valor, &r.Ficheiro) == nil {
				respostasVaga = append(respostasVaga, r)
			}
		}
	}

	jsonOK(w, candidaturaDetalhe{
		Candidatura: c, Notas: notas, RespostasVaga: respostasVaga,
		VagaArea: vagaArea, VagaCargoID: vagaCargoID, VagaCargoNome: vagaCargoNome,
		VagaSalarioMin: vagaSalarioMin, VagaSalarioMax: vagaSalarioMax,
	}, http.StatusOK)
}

// ── Pipeline ─────────────────────────────────────────────────────────────────

// MoverCandidatura altera o estado e regista uma nota de sistema com a transição,
// replicando admin/api/candidatura_mover.php.
func (h *Handler) MoverCandidatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := h.decodeID(chi.URLParam(r, "id"))

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

	idInt, _ := strconv.ParseInt(id, 10, 64)
	estadoMudou := oldEstado != body.Estado
	var texto string

	if estadoMudou {
		texto = fmt.Sprintf("Estado alterado: %s → %s", estadoLabels[oldEstado], novoLabel)
		if _, err := tx.Exec(ctx,
			"INSERT INTO candidatura_notas (candidatura_id, autor, tipo, conteudo) VALUES ($1,'sistema','sistema',$2)",
			id, texto); err != nil {
			jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
			return
		}

		// Disparar notificação automática conforme novo estado
		if evento := eventoParaEstado(body.Estado); evento != "" {
			if err := h.notificarCandidatura(ctx, tx, user.TenantID, idInt, evento, nil); err != nil {
				// Não falhar a transição se a notificação falhar; registar erro silenciosamente
			}
		}
	}

	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}

	// Push só depois do commit — antes disso a mudança de estado ainda não
	// é visível a outras queries (ex.: a que lê vaga_titulo/candidato_id).
	if estadoMudou {
		h.notificarCandidatoPush(ctx, idInt, "Sistema", texto)
	}

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// AvaliarCandidatura grava a pontuação (1-5) e, se houver comentário, regista uma
// nota de avaliação, replicando admin/api/candidatura_avaliar.php.
func (h *Handler) AvaliarCandidatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := h.decodeID(chi.URLParam(r, "id"))

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
	if body.Score != nil {
		var texto string
		if nota != "" {
			texto = fmt.Sprintf("Avaliação: %s (%d/5)\n%s", scoreLabels[*body.Score], *body.Score, nota)
		} else {
			texto = fmt.Sprintf("Avaliação: %s (%d/5)", scoreLabels[*body.Score], *body.Score)
		}
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
	id := h.decodeID(chi.URLParam(r, "id"))

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

	idInt, _ := strconv.ParseInt(id, 10, 64)
	if err := h.notificarCandidatura(ctx, tx, user.TenantID, idInt, "entrevista_agendada", nil); err != nil {
		// Não bloquear o agendamento se a notificação falhar
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
	id := h.decodeID(chi.URLParam(r, "id"))
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

	// Notifica o candidato por push — a nota do recrutador é, para o
	// candidato, uma mensagem na conversa da candidatura.
	h.notificarCandidatoPush(ctx, nota.CandidaturaID, autor, conteudo)
	h.realtime.EmitNovaMensagem(nota)

	jsonOK(w, nota, http.StatusCreated)
}

// ── Downloads ────────────────────────────────────────────────────────────────

func (h *Handler) downloadFicheiro(coluna string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user := mw.GetUser(r)
		id := h.decodeID(chi.URLParam(r, "id"))

		var ficheiro *string
		err := h.db.QueryRow(r.Context(),
			"SELECT "+coluna+" FROM candidaturas WHERE id=$1 AND tenant_id=$2", id, user.TenantID,
		).Scan(&ficheiro)
		if err != nil || ficheiro == nil || *ficheiro == "" {
			jsonErr(w, "Ficheiro não encontrado.", http.StatusNotFound)
			return
		}

		key := storage.JoinPath("uploads", fmt.Sprintf("tenant-%d", user.TenantID), *ficheiro)
		reader, size, err := h.storage.Get(r.Context(), key)
		if err != nil {
			jsonErr(w, "Ficheiro não encontrado.", http.StatusNotFound)
			return
		}
		defer reader.Close()

		filename := filepath.Base(*ficheiro)
		w.Header().Set("Content-Disposition", `attachment; filename="`+filename+`"`)
		w.Header().Set("Content-Length", fmt.Sprintf("%d", size))
		io.Copy(w, reader)
	}
}

func (h *Handler) DownloadCV(w http.ResponseWriter, r *http.Request) {
	h.downloadFicheiro("cv_ficheiro")(w, r)
}

func (h *Handler) DownloadCarta(w http.ResponseWriter, r *http.Request) {
	h.downloadFicheiro("carta_ficheiro")(w, r)
}

func eventoParaEstado(estado string) string {
	switch estado {
	case "aprovada":
		return "aprovada"
	case "rejeitada":
		return "rejeitada"
	default:
		return ""
	}
}
