package handlers

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

type Vaga struct {
	ID                int64     `json:"id"`
	Titulo            string    `json:"titulo"`
	Area              string    `json:"area"`
	Local             string    `json:"local"`
	Regime            string    `json:"regime"`
	Tipo              string    `json:"tipo"`
	Descricao         string    `json:"descricao"`
	SobreFuncao       *string   `json:"sobre_funcao"`
	Responsabilidades []string  `json:"responsabilidades"`
	ReqObrigatorios   []string  `json:"req_obrigatorios"`
	ReqPreferenciais  []string  `json:"req_preferenciais"`
	Oferece           []string  `json:"oferece"`
	Ativa             bool      `json:"ativa"`
	NumVagas          int16     `json:"num_vagas"`
	Prazo             *string   `json:"prazo"`
	PermitePublica    bool      `json:"permite_publica"`
	PermiteConta      bool      `json:"permite_conta"`
	CargoID           *int64    `json:"cargo_id"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

type vagaInput struct {
	Titulo            string   `json:"titulo"`
	Area              string   `json:"area"`
	Local             *string  `json:"local"`
	Regime            *string  `json:"regime"`
	Tipo              *string  `json:"tipo"`
	Descricao         string   `json:"descricao"`
	SobreFuncao       *string  `json:"sobre_funcao"`
	Responsabilidades []string `json:"responsabilidades"`
	ReqObrigatorios   []string `json:"req_obrigatorios"`
	ReqPreferenciais  []string `json:"req_preferenciais"`
	Oferece           []string `json:"oferece"`
	Ativa             *bool    `json:"ativa"`
	NumVagas          *int16   `json:"num_vagas"`
	Prazo             *string  `json:"prazo"`
	PermitePublica    *bool    `json:"permite_publica"`
	PermiteConta      *bool    `json:"permite_conta"`
	CargoID           *int64   `json:"cargo_id"`
}

var dateFormatRe = regexp.MustCompile(`^\d{4}-\d{2}-\d{2}$`)

// parsePrazo valida e converte "YYYY-MM-DD" em *time.Time.
// Devolve ok=false se o formato for inválido ou a data for anterior a hoje.
func parsePrazo(s *string) (*time.Time, bool) {
	if s == nil || strings.TrimSpace(*s) == "" {
		return nil, true
	}
	if !dateFormatRe.MatchString(*s) {
		return nil, false
	}
	t, err := time.Parse("2006-01-02", *s)
	if err != nil {
		return nil, false
	}
	today := time.Now().UTC().Truncate(24 * time.Hour)
	if t.UTC().Before(today) {
		return nil, false
	}
	return &t, true
}

func strDefault(s *string, def string) string {
	if s == nil {
		return def
	}
	v := strings.TrimSpace(*s)
	if v == "" {
		return def
	}
	return v
}

const vagaSelectCols = `id, titulo, area, local, regime, tipo, descricao, sobre_funcao,
	responsabilidades, req_obrigatorios, req_preferenciais, oferece, ativa, num_vagas,
	to_char(prazo, 'YYYY-MM-DD'), permite_publica, permite_conta, cargo_id, created_at, updated_at`

func scanVaga(row pgx.Row, extra ...any) (*Vaga, error) {
	var v Vaga
	dest := []any{&v.ID, &v.Titulo, &v.Area, &v.Local, &v.Regime, &v.Tipo, &v.Descricao,
		&v.SobreFuncao, &v.Responsabilidades, &v.ReqObrigatorios, &v.ReqPreferenciais, &v.Oferece,
		&v.Ativa, &v.NumVagas, &v.Prazo, &v.PermitePublica, &v.PermiteConta, &v.CargoID, &v.CreatedAt, &v.UpdatedAt}
	if err := row.Scan(append(dest, extra...)...); err != nil {
		return nil, err
	}
	return &v, nil
}

// validarCargoVaga confirma que o cargo indicado existe e está activo no tenant.
func (h *Handler) validarCargoVaga(ctx context.Context, tenantID int64, cargoID *int64) bool {
	if cargoID == nil || *cargoID <= 0 {
		return false
	}
	var existe bool
	if err := h.db.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM rh.cargos WHERE id=$1 AND tenant_id=$2 AND ativo)`, *cargoID, tenantID).Scan(&existe); err != nil {
		return false
	}
	return existe
}

// ── Listagem / CRUD ──────────────────────────────────────────────────────────

func (h *Handler) ListarVagas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)

	where := "tenant_id=$1"
	args := []any{user.TenantID}

	if a := q.Get("ativa"); a != "" {
		args = append(args, a == "1" || a == "true")
		where += " AND ativa=$" + strconv.Itoa(len(args))
	}
	if area := q.Get("area"); area != "" {
		args = append(args, area)
		where += " AND area=$" + strconv.Itoa(len(args))
	}
	if s := q.Get("search"); s != "" {
		args = append(args, "%"+s+"%")
		n := strconv.Itoa(len(args))
		where += " AND (titulo ILIKE $" + n + " OR area ILIKE $" + n + ")"
	}

	countArgs := append([]any{}, args...)
	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(),
		"SELECT "+vagaSelectCols+", (SELECT COUNT(*) FROM candidaturas c WHERE c.vaga_id=vagas.id) FROM vagas WHERE "+where+
			" ORDER BY created_at DESC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []map[string]any{}
	for rows.Next() {
		var totalCandidaturas int
		v, err := scanVaga(rows, &totalCandidaturas)
		if err == nil {
			b, _ := json.Marshal(v)
			var item map[string]any
			json.Unmarshal(b, &item)
			item["total_candidaturas"] = totalCandidaturas
			data = append(data, item)
		}
	}

	var total int
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM vagas WHERE "+where, countArgs...).Scan(&total)
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 {
		page = 1
	}
	jsonOK(w, map[string]any{"data": data, "meta": map[string]int{"total": total, "page": page, "limit": limit}}, http.StatusOK)
}

func (h *Handler) CriarVaga(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body vagaInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Titulo = strings.TrimSpace(body.Titulo)
	body.Area = strings.TrimSpace(body.Area)
	body.Descricao = strings.TrimSpace(body.Descricao)
	if body.Titulo == "" {
		jsonErr(w, "O título é obrigatório.", http.StatusUnprocessableEntity)
		return
	}
	if body.Area == "" {
		jsonErr(w, "A área é obrigatória.", http.StatusUnprocessableEntity)
		return
	}
	if !h.validarCargoVaga(r.Context(), user.TenantID, body.CargoID) {
		jsonErr(w, "O cargo a contratar é obrigatório e deve estar activo em Recursos Humanos.", http.StatusUnprocessableEntity)
		return
	}
	prazo, ok := parsePrazo(body.Prazo)
	if !ok {
		jsonErr(w, "Formato de prazo inválido.", http.StatusUnprocessableEntity)
		return
	}

	numVagas := int16(1)
	if body.NumVagas != nil && *body.NumVagas > 0 {
		numVagas = *body.NumVagas
	}
	ativa := true
	if body.Ativa != nil {
		ativa = *body.Ativa
	}
	permitePublica := true
	if body.PermitePublica != nil {
		permitePublica = *body.PermitePublica
	}
	permiteConta := true
	if body.PermiteConta != nil {
		permiteConta = *body.PermiteConta
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO vagas
			(tenant_id, titulo, area, local, regime, tipo, descricao, sobre_funcao,
			 responsabilidades, req_obrigatorios, req_preferenciais, oferece,
			 ativa, num_vagas, prazo, permite_publica, permite_conta, cargo_id)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18)
		RETURNING id`,
		user.TenantID, body.Titulo, body.Area,
		strDefault(body.Local, "Maputo, Moçambique"),
		strDefault(body.Regime, "Presencial / Híbrido"),
		strDefault(body.Tipo, "Estágio"),
		body.Descricao, body.SobreFuncao,
		filterList(body.Responsabilidades), filterList(body.ReqObrigatorios),
		filterList(body.ReqPreferenciais), filterList(body.Oferece),
		ativa, numVagas, prazo, permitePublica, permiteConta, body.CargoID,
	).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro ao guardar na base de dados.", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterVaga(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := h.decodeID(chi.URLParam(r, "id"))
	row := h.db.QueryRow(r.Context(), "SELECT "+vagaSelectCols+" FROM vagas WHERE id=$1 AND tenant_id=$2", id, user.TenantID)
	v, err := scanVaga(row)
	if err != nil {
		jsonErr(w, "Vaga não encontrada.", http.StatusNotFound)
		return
	}
	jsonOK(w, v, http.StatusOK)
}

func (h *Handler) ActualizarVaga(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := h.decodeID(chi.URLParam(r, "id"))

	var body vagaInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Titulo = strings.TrimSpace(body.Titulo)
	body.Area = strings.TrimSpace(body.Area)
	body.Descricao = strings.TrimSpace(body.Descricao)
	if body.Titulo == "" {
		jsonErr(w, "O título é obrigatório.", http.StatusUnprocessableEntity)
		return
	}
	if body.Area == "" {
		jsonErr(w, "A área é obrigatória.", http.StatusUnprocessableEntity)
		return
	}
	if !h.validarCargoVaga(r.Context(), user.TenantID, body.CargoID) {
		jsonErr(w, "O cargo a contratar é obrigatório e deve estar activo em Recursos Humanos.", http.StatusUnprocessableEntity)
		return
	}
	prazo, ok := parsePrazo(body.Prazo)
	if !ok {
		jsonErr(w, "Formato de prazo inválido.", http.StatusUnprocessableEntity)
		return
	}

	numVagas := int16(1)
	if body.NumVagas != nil && *body.NumVagas > 0 {
		numVagas = *body.NumVagas
	}
	ativa := true
	if body.Ativa != nil {
		ativa = *body.Ativa
	}
	permitePublica := true
	if body.PermitePublica != nil {
		permitePublica = *body.PermitePublica
	}
	permiteConta := true
	if body.PermiteConta != nil {
		permiteConta = *body.PermiteConta
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE vagas SET
			titulo=$1, area=$2, local=$3, regime=$4, tipo=$5, descricao=$6, sobre_funcao=$7,
			responsabilidades=$8, req_obrigatorios=$9, req_preferenciais=$10, oferece=$11,
			ativa=$12, num_vagas=$13, prazo=$14, permite_publica=$15, permite_conta=$16,
			cargo_id=$17, updated_at=NOW()
		WHERE id=$18 AND tenant_id=$19`,
		body.Titulo, body.Area,
		strDefault(body.Local, "Maputo, Moçambique"),
		strDefault(body.Regime, "Presencial / Híbrido"),
		strDefault(body.Tipo, "Estágio"),
		body.Descricao, body.SobreFuncao,
		filterList(body.Responsabilidades), filterList(body.ReqObrigatorios),
		filterList(body.ReqPreferenciais), filterList(body.Oferece),
		ativa, numVagas, prazo, permitePublica, permiteConta, body.CargoID, id, user.TenantID,
	)
	if err != nil {
		jsonErr(w, "Erro ao actualizar na base de dados.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Vaga não encontrada.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// RemoverVaga apaga a vaga, as candidaturas associadas e os respectivos ficheiros
// (CV / carta), replicando admin/api/vaga_delete.php.
func (h *Handler) RemoverVaga(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := h.decodeID(chi.URLParam(r, "id"))
	ctx := r.Context()

	tx, err := h.db.Begin(ctx)
	if err != nil {
		jsonErr(w, "Erro interno.", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(ctx)

	var exists bool
	if err := tx.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM vagas WHERE id=$1 AND tenant_id=$2)", id, user.TenantID).Scan(&exists); err != nil || !exists {
		jsonErr(w, "Vaga não encontrada.", http.StatusNotFound)
		return
	}

	rows, err := tx.Query(ctx, "SELECT cv_ficheiro, carta_ficheiro FROM candidaturas WHERE vaga_id=$1", id)
	if err != nil {
		jsonErr(w, "Erro ao eliminar.", http.StatusInternalServerError)
		return
	}
	var files []string
	for rows.Next() {
		var cv, carta *string
		if rows.Scan(&cv, &carta) == nil {
			if cv != nil {
				files = append(files, *cv)
			}
			if carta != nil {
				files = append(files, *carta)
			}
		}
	}
	rows.Close()

	if _, err := tx.Exec(ctx, "DELETE FROM candidaturas WHERE vaga_id=$1", id); err != nil {
		jsonErr(w, "Erro ao eliminar.", http.StatusInternalServerError)
		return
	}
	if _, err := tx.Exec(ctx, "DELETE FROM vagas WHERE id=$1", id); err != nil {
		jsonErr(w, "Erro ao eliminar.", http.StatusInternalServerError)
		return
	}
	if err := tx.Commit(ctx); err != nil {
		jsonErr(w, "Erro ao eliminar.", http.StatusInternalServerError)
		return
	}

	uploadsDir := filepath.Clean(h.cfg.UploadsDir)
	for _, f := range files {
		rel := filepath.Clean(strings.TrimPrefix(f, "uploads/"))
		abs := filepath.Join(uploadsDir, rel)
		// garantir que o ficheiro está dentro do directório de uploads
		if !strings.HasPrefix(abs, uploadsDir+string(filepath.Separator)) {
			log.Printf("RemoverVaga: path fora de uploads ignorado: %s", abs)
			continue
		}
		if err := os.Remove(abs); err != nil && !os.IsNotExist(err) {
			log.Printf("RemoverVaga: erro ao remover ficheiro %s: %v", abs, err)
		}
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) mudarEstadoVaga(ativa bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user := mw.GetUser(r)
		id := h.decodeID(chi.URLParam(r, "id"))
		tag, _ := h.db.Exec(r.Context(), "UPDATE vagas SET ativa=$1, updated_at=NOW() WHERE id=$2 AND tenant_id=$3", ativa, id, user.TenantID)
		if tag.RowsAffected() == 0 {
			jsonErr(w, "Vaga não encontrada.", http.StatusNotFound)
			return
		}
		jsonOK(w, map[string]any{"ok": true, "ativa": ativa}, http.StatusOK)
	}
}

func (h *Handler) ActivarVaga(w http.ResponseWriter, r *http.Request)    { h.mudarEstadoVaga(true)(w, r) }
func (h *Handler) DesactivarVaga(w http.ResponseWriter, r *http.Request) { h.mudarEstadoVaga(false)(w, r) }
