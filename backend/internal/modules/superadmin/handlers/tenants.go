package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"nexora/internal/middleware"
	"nexora/internal/modules/auth/audit"
)

type tenantResponse struct {
	ID                   int64      `json:"id"`
	Codigo               string     `json:"codigo"`
	Nome                 string     `json:"nome"`
	CompanyID            *int64     `json:"company_id"`
	Status               string     `json:"status"`
	Dominio              *string    `json:"dominio"`
	PlanoID              *int64     `json:"plano_id"`
	PlanoNome            *string    `json:"plano_nome"`
	LimiteUtilizadores   *int       `json:"limite_utilizadores"`
	LimiteArmazenamento  *int       `json:"limite_armazenamento_gb"`
	ValidadePlano        *time.Time `json:"validade_plano"`
	Metadata             map[string]any `json:"metadata"`
	CreatedAt            time.Time  `json:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at"`
}

func (h *Handler) ListarTenants(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	status := q.Get("status")
	search := q.Get("search")
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 { page = 1 }
	limit, _ := strconv.Atoi(q.Get("limit"))
	if limit < 1 || limit > 100 { limit = 20 }
	offset := (page - 1) * limit

	where := "1=1"
	args := []interface{}{}

	if status != "" {
		args = append(args, status)
		where += " AND t.status = $" + strconv.Itoa(len(args))
	}
	if search != "" {
		args = append(args, "%"+search+"%")
		idx := strconv.Itoa(len(args))
		where += " AND (t.nome ILIKE $" + idx + " OR t.codigo ILIKE $" + idx + ")"
	}

	countArgs := make([]interface{}, len(args))
	copy(countArgs, args)

	args = append(args, limit, offset)
	dataQ := `
		SELECT t.id, t.codigo, t.nome, t.company_id, t.status, t.dominio, t.plano_id, p.nome,
		       t.limite_utilizadores, t.limite_armazenamento_gb, t.validade_plano, t.metadata,
		       t.created_at, t.updated_at
		  FROM saas.tenants t
		  LEFT JOIN saas.plans p ON p.id = t.plano_id
		 WHERE ` + where + `
		 ORDER BY t.created_at DESC
		 LIMIT $` + strconv.Itoa(len(args)-1) + ` OFFSET $` + strconv.Itoa(len(args))

	rows, err := h.db.Query(r.Context(), dataQ, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []tenantResponse{}
	for rows.Next() {
		var t tenantResponse
		var validade *time.Time
		if err := rows.Scan(&t.ID, &t.Codigo, &t.Nome, &t.CompanyID, &t.Status, &t.Dominio,
			&t.PlanoID, &t.PlanoNome, &t.LimiteUtilizadores, &t.LimiteArmazenamento,
			&validade, &t.Metadata, &t.CreatedAt, &t.UpdatedAt); err == nil {
			t.ValidadePlano = validade
			data = append(data, t)
		}
	}

	var total int
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM saas.tenants t WHERE "+where, countArgs...).Scan(&total)

	jsonOK(w, map[string]interface{}{
		"data": data,
		"meta": map[string]int{"total": total, "page": page, "limit": limit},
	}, http.StatusOK)
}

func (h *Handler) ObterTenant(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var t tenantResponse
	var validade *time.Time
	err := h.db.QueryRow(r.Context(), `
		SELECT t.id, t.codigo, t.nome, t.company_id, t.status, t.dominio, t.plano_id, p.nome,
		       t.limite_utilizadores, t.limite_armazenamento_gb, t.validade_plano, t.metadata,
		       t.created_at, t.updated_at
		  FROM saas.tenants t
		  LEFT JOIN saas.plans p ON p.id = t.plano_id
		 WHERE t.id = $1`, id).
		Scan(&t.ID, &t.Codigo, &t.Nome, &t.CompanyID, &t.Status, &t.Dominio,
			&t.PlanoID, &t.PlanoNome, &t.LimiteUtilizadores, &t.LimiteArmazenamento,
			&validade, &t.Metadata, &t.CreatedAt, &t.UpdatedAt)
	if err != nil {
		jsonErr(w, "Tenant não encontrado", http.StatusNotFound)
		return
	}
	t.ValidadePlano = validade
	jsonOK(w, t, http.StatusOK)
}

func (h *Handler) CriarTenant(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Codigo              string         `json:"codigo"`
		Nome                string         `json:"nome"`
		Dominio             *string        `json:"dominio"`
		PlanoID             *int64         `json:"plano_id"`
		LimiteUtilizadores  *int           `json:"limite_utilizadores"`
		LimiteArmazenamento *int           `json:"limite_armazenamento_gb"`
		ValidadePlano       *string        `json:"validade_plano"`
		Metadata            map[string]any `json:"metadata"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	// Cria a company associada
	var companyID int64
	err = tx.QueryRow(r.Context(), `
		INSERT INTO empresas.companies (codigo, nome, status, moeda_base, timezone)
		VALUES ($1, $2, 'ativa', 'MZN', 'Africa/Maputo')
		RETURNING id`, body.Codigo, body.Nome).
		Scan(&companyID)
	if err != nil {
		if isPgUniqueViolation(err) {
			jsonErr(w, "Código de tenant/empresa já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro ao criar empresa", http.StatusInternalServerError)
		return
	}

	// Cria o tenant
	var tenantID int64
	var planoID interface{}
	if body.PlanoID != nil { planoID = *body.PlanoID }

	err = tx.QueryRow(r.Context(), `
		INSERT INTO saas.tenants (codigo, nome, company_id, status, dominio, plano_id,
			limite_utilizadores, limite_armazenamento_gb, validade_plano, metadata)
		VALUES ($1, $2, $3, 'ativo', $4, $5, $6, $7, $8, $9)
		RETURNING id`,
		body.Codigo, body.Nome, companyID, body.Dominio, planoID,
		body.LimiteUtilizadores, body.LimiteArmazenamento, body.ValidadePlano, body.Metadata).
		Scan(&tenantID)
	if err != nil {
		if isPgUniqueViolation(err) {
			jsonErr(w, "Código de tenant já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro ao criar tenant", http.StatusInternalServerError)
		return
	}

	// Liga company ao tenant
	_, err = tx.Exec(r.Context(), `UPDATE empresas.companies SET tenant_id = $1 WHERE id = $2`, tenantID, companyID)
	if err != nil {
		jsonErr(w, "Erro ao ligar empresa ao tenant", http.StatusInternalServerError)
		return
	}

	// Cria subscrição inicial se houver plano
	if body.PlanoID != nil {
		_, err = tx.Exec(r.Context(), `
			INSERT INTO saas.tenant_subscriptions (tenant_id, plano_id, numero, starts_at, status, unit_price, moeda, auto_renew)
			SELECT $1, $2, 'SUB-' || $1, CURRENT_DATE, 'activa', COALESCE(preco_mensal, 0), moeda, TRUE
			  FROM saas.plans WHERE id = $2`, tenantID, *body.PlanoID)
		if err != nil {
			jsonErr(w, "Erro ao criar subscrição", http.StatusInternalServerError)
			return
		}

		// Auto-activar todos os módulos do plano para este tenant
		_, err = tx.Exec(r.Context(), `
			INSERT INTO saas.tenant_modules (tenant_id, modulo, ativo)
			SELECT $1, modulo, TRUE FROM saas.plan_modules WHERE plan_id = $2
			ON CONFLICT (tenant_id, modulo) DO UPDATE SET ativo = TRUE, updated_at = NOW()`,
			tenantID, *body.PlanoID)
		if err != nil {
			jsonErr(w, "Erro ao activar módulos do plano", http.StatusInternalServerError)
			return
		}
	}

	// Criar cargos-padrão para o novo tenant
	_, err = tx.Exec(r.Context(), `SELECT auth.criar_cargos_padrao($1)`, tenantID)
	if err != nil {
		jsonErr(w, "Erro ao criar cargos padrão", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro ao guardar", http.StatusInternalServerError)
		return
	}

	user := middleware.GetUser(r)
	if user != nil {
		_ = audit.LogRequest(r, h.db, audit.Entry{
			UserID:    user.ID,
			TenantID:  tenantID,
			Acao:      "criar",
			Modulo:    "superadmin",
			Recurso:   "tenant",
			RecursoID: itoa(tenantID),
			Detalhes: map[string]any{"codigo": body.Codigo, "nome": body.Nome},
		})
	}

	h.ObterTenant(w, r)
}

func (h *Handler) ActualizarTenant(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var body struct {
		Nome                *string        `json:"nome"`
		Dominio             *string        `json:"dominio"`
		PlanoID             *int64         `json:"plano_id"`
		LimiteUtilizadores  *int           `json:"limite_utilizadores"`
		LimiteArmazenamento *int           `json:"limite_armazenamento_gb"`
		ValidadePlano       *string        `json:"validade_plano"`
		Metadata            map[string]any `json:"metadata"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	// Obter plano anterior (para detectar mudança de plano)
	var planoAnterior *int64
	h.db.QueryRow(r.Context(), `SELECT plano_id FROM saas.tenants WHERE id = $1`, id).Scan(&planoAnterior)

	var t tenantResponse
	var validade *time.Time
	// CTE para incluir plano_nome no RETURNING sem query extra
	err := h.db.QueryRow(r.Context(), `
		WITH updated AS (
			UPDATE saas.tenants SET
				nome                    = COALESCE($1, nome),
				dominio                 = COALESCE($2, dominio),
				plano_id                = COALESCE($3, plano_id),
				limite_utilizadores     = COALESCE($4, limite_utilizadores),
				limite_armazenamento_gb = COALESCE($5, limite_armazenamento_gb),
				validade_plano          = COALESCE($6, validade_plano),
				metadata                = COALESCE($7, metadata),
				updated_at              = NOW()
			WHERE id = $8
			RETURNING *
		)
		SELECT u.id, u.codigo, u.nome, u.company_id, u.status, u.dominio,
		       u.plano_id, p.nome,
		       u.limite_utilizadores, u.limite_armazenamento_gb,
		       u.validade_plano, u.metadata, u.created_at, u.updated_at
		  FROM updated u
		  LEFT JOIN saas.plans p ON p.id = u.plano_id`,
		body.Nome, body.Dominio, body.PlanoID, body.LimiteUtilizadores,
		body.LimiteArmazenamento, body.ValidadePlano, body.Metadata, id).
		Scan(&t.ID, &t.Codigo, &t.Nome, &t.CompanyID, &t.Status, &t.Dominio,
			&t.PlanoID, &t.PlanoNome,
			&t.LimiteUtilizadores, &t.LimiteArmazenamento, &validade,
			&t.Metadata, &t.CreatedAt, &t.UpdatedAt)
	if err != nil {
		jsonErr(w, "Tenant não encontrado", http.StatusNotFound)
		return
	}
	t.ValidadePlano = validade

	// #4 — Se o plano mudou, activar os módulos do novo plano
	planoNovo := t.PlanoID
	if body.PlanoID != nil && planoNovo != nil &&
		(planoAnterior == nil || *planoAnterior != *planoNovo) {
		_, _ = h.db.Exec(r.Context(), `
			INSERT INTO saas.tenant_modules (tenant_id, modulo, ativo)
			SELECT $1, modulo, TRUE FROM saas.plan_modules WHERE plan_id = $2
			ON CONFLICT (tenant_id, modulo) DO UPDATE SET ativo = TRUE, updated_at = NOW()`,
			t.ID, *planoNovo)
	}

	user := middleware.GetUser(r)
	if user != nil {
		_ = audit.LogRequest(r, h.db, audit.Entry{
			UserID:    user.ID,
			Acao:      "editar",
			Modulo:    "superadmin",
			Recurso:   "tenant",
			RecursoID: itoa(t.ID),
			Detalhes: map[string]any{"id": t.ID, "codigo": t.Codigo, "nome": t.Nome},
		})
	}

	jsonOK(w, t, http.StatusOK)
}

func (h *Handler) alterarStatusTenant(status string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		var t tenantResponse
		var validade *time.Time
		err := h.db.QueryRow(r.Context(), `
			WITH updated AS (
				UPDATE saas.tenants SET status = $1, updated_at = NOW()
				WHERE id = $2
				RETURNING *
			)
			SELECT u.id, u.codigo, u.nome, u.company_id, u.status, u.dominio,
			       u.plano_id, p.nome,
			       u.limite_utilizadores, u.limite_armazenamento_gb,
			       u.validade_plano, u.metadata, u.created_at, u.updated_at
			  FROM updated u
			  LEFT JOIN saas.plans p ON p.id = u.plano_id`,
			status, id).
			Scan(&t.ID, &t.Codigo, &t.Nome, &t.CompanyID, &t.Status, &t.Dominio,
				&t.PlanoID, &t.PlanoNome,
				&t.LimiteUtilizadores, &t.LimiteArmazenamento, &validade,
				&t.Metadata, &t.CreatedAt, &t.UpdatedAt)
		if err != nil {
			jsonErr(w, "Tenant não encontrado", http.StatusNotFound)
			return
		}
		t.ValidadePlano = validade
		jsonOK(w, t, http.StatusOK)
	}
}

func (h *Handler) SuspenderTenant(w http.ResponseWriter, r *http.Request) {
	h.alterarStatusTenant("suspenso")(w, r)
}

func (h *Handler) ReativarTenant(w http.ResponseWriter, r *http.Request) {
	h.alterarStatusTenant("ativo")(w, r)
}

func (h *Handler) InativarTenant(w http.ResponseWriter, r *http.Request) {
	h.alterarStatusTenant("inativo")(w, r)
}

func (h *Handler) EliminarTenant(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), `DELETE FROM saas.tenants WHERE id = $1`, id)
	if err != nil {
		jsonErr(w, "Erro ao eliminar tenant", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Tenant não encontrado", http.StatusNotFound)
		return
	}

	user := middleware.GetUser(r)
	if user != nil {
		_ = audit.LogRequest(r, h.db, audit.Entry{
			UserID:    user.ID,
			Acao:      "eliminar",
			Modulo:    "superadmin",
			Recurso:   "tenant",
			RecursoID: id,
		})
	}

	jsonOK(w, map[string]string{"message": "Tenant eliminado"}, http.StatusOK)
}

// ProvisionarCargosPadrao cria os cargos-padrão para um tenant existente.
// Idempotente: cargos já existentes são ignorados; novas permissões são adicionadas.
func (h *Handler) ProvisionarCargosPadrao(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var tenantID int64
	err := h.db.QueryRow(r.Context(), `SELECT id FROM saas.tenants WHERE id = $1`, id).Scan(&tenantID)
	if err != nil {
		jsonErr(w, "Tenant não encontrado", http.StatusNotFound)
		return
	}

	_, err = h.db.Exec(r.Context(), `SELECT auth.criar_cargos_padrao($1)`, tenantID)
	if err != nil {
		jsonErr(w, "Erro ao criar cargos padrão", http.StatusInternalServerError)
		return
	}

	user := middleware.GetUser(r)
	if user != nil {
		_ = audit.LogRequest(r, h.db, audit.Entry{
			UserID:    user.ID,
			TenantID:  tenantID,
			Acao:      "provisionar_cargos",
			Modulo:    "superadmin",
			Recurso:   "tenant",
			RecursoID: id,
		})
	}

	jsonOK(w, map[string]string{"message": "Cargos padrão criados com sucesso"}, http.StatusOK)
}
