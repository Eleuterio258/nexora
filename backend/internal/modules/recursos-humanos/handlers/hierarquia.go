package handlers

import (
	"context"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/modules/auth/models"
)

// GetUserFuncionario resolve o id de funcionarios correspondente ao
// utilizador autenticado (auth.users.id), dentro do tenant indicado.
// Devolve nil se o utilizador não tiver um funcionário associado.
func (h *Handler) GetUserFuncionario(ctx context.Context, tenantID, userID int64) (*int64, error) {
	var funcionarioID int64
	err := h.db.QueryRow(ctx, `SELECT id FROM rh.funcionarios WHERE tenant_id=$1 AND user_id=$2`, tenantID, userID).Scan(&funcionarioID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &funcionarioID, nil
}

// IsResponsavelHierarquico verifica se funcionarioID é o responsável
// (direto ou de uma unidade ancestral, via parent_id) da unidade do
// funcionário-alvo targetFuncionarioID.
func (h *Handler) IsResponsavelHierarquico(ctx context.Context, tenantID, funcionarioID, targetFuncionarioID int64) (bool, error) {
	var ok bool
	err := h.db.QueryRow(ctx, `
		WITH RECURSIVE hierarquia AS (
			SELECT u.id, u.parent_id, u.responsavel_id
			  FROM rh.funcionarios f
			  JOIN rh.unidades_organizacionais u ON u.id = f.unit_id
			 WHERE f.id = $1 AND f.tenant_id = $2
			UNION ALL
			SELECT p.id, p.parent_id, p.responsavel_id
			  FROM rh.unidades_organizacionais p
			  JOIN hierarquia h ON p.id = h.parent_id
		)
		SELECT EXISTS (SELECT 1 FROM hierarquia WHERE responsavel_id = $3)`,
		targetFuncionarioID, tenantID, funcionarioID).Scan(&ok)
	return ok, err
}

// podeGerirFuncionario verifica se o utilizador autenticado pode gerir
// registos (ausências, avaliações, etc.) do funcionário targetFuncionarioID:
//   - superadmins têm sempre permissão;
//   - utilizadores com a permissão (recursos-humanos, gerir_funcionarios);
//   - o utilizador que criou o registo do funcionário (rh.funcionarios.criado_por);
//   - o responsável (direto ou hierárquico) da unidade do funcionário.
func (h *Handler) podeGerirFuncionario(r *http.Request, targetFuncionarioID int64) bool {
	user := mw.GetUser(r)
	if user.Tipo == "superadmin" {
		return true
	}

	// Permissão global de gestão de funcionários.
	access, err := models.LoadUserAccess(r.Context(), h.db, user.ID, user.MembershipID)
	if err == nil && access.Can("recursos-humanos", "gerir_funcionarios") {
		return true
	}

	// Regra de propriedade: quem criou o funcionário pode sempre geri-lo.
	var criadoPor int64
	err = h.db.QueryRow(r.Context(), `SELECT criado_por FROM rh.funcionarios WHERE id=$1 AND tenant_id=$2`, targetFuncionarioID, user.TenantID).Scan(&criadoPor)
	if err == nil && criadoPor == user.ID {
		return true
	}

	// Regra hierárquica: responsável direto ou de unidade ancestral.
	meuFuncionarioID, err := h.GetUserFuncionario(r.Context(), user.TenantID, user.ID)
	if err != nil || meuFuncionarioID == nil {
		return false
	}
	autorizado, err := h.IsResponsavelHierarquico(r.Context(), user.TenantID, *meuFuncionarioID, targetFuncionarioID)
	if err != nil {
		return false
	}
	return autorizado
}

// PodeVerSalarios indica se o utilizador autenticado pode visualizar dados
// salariais (RNF02 — confidencialidade salarial): superadmins e
// utilizadores com a permissão (recursos-humanos, processar_salarios).
func (h *Handler) PodeVerSalarios(r *http.Request) bool {
	user := mw.GetUser(r)
	if user.Tipo == "superadmin" {
		return true
	}
	access, err := models.LoadUserAccess(r.Context(), h.db, user.ID, user.MembershipID)
	if err != nil {
		return false
	}
	return access.Can("recursos-humanos", "processar_salarios")
}

// verificarPodeGerirFuncionario valida e converte o URL param {id} do
// funcionário-alvo e verifica se o utilizador autenticado pode geri-lo.
// Devolve o ID numérico e true em caso de sucesso; em caso de erro responde
// automaticamente ao cliente e devolve false.
func (h *Handler) verificarPodeGerirFuncionario(w http.ResponseWriter, r *http.Request, idParam string) (int64, bool) {
	idStr := chi.URLParam(r, idParam)
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		jsonErr(w, "ID inválido", http.StatusBadRequest)
		return 0, false
	}
	if !h.podeGerirFuncionario(r, id) {
		jsonErr(w, "Sem permissão para gerir este funcionário", http.StatusForbidden)
		return 0, false
	}
	return id, true
}
