package models

import (
	"context"
	"sort"

	"github.com/jackc/pgx/v5"
)

type Permission struct {
	Modulo string `json:"modulo"`
	Acao   string `json:"acao"`
}

// ModuloAcesso agrupa as acções por módulo para o retorno da API.
type ModuloAcesso struct {
	Modulo string   `json:"modulo"`
	Cor    string   `json:"cor"`
	Acoes  []string `json:"acoes"`
}

// moduloCores define a cor de cada módulo do ERP.
var moduloCores = map[string]string{
	"auth":                  "#6366F1", // indigo
	"empresa":               "#2563EB", // blue
	"clientes":              "#8B5CF6", // violet
	"vendas":                "#3B82F6", // blue
	"faturacao":             "#6366F1", // indigo
	"pos":                   "#EF4444", // red
	"stock":                 "#10B981", // emerald
	"compras":               "#F59E0B", // amber
	"logistica":             "#84CC16", // lime
	"financeiro":            "#14B8A6", // teal
	"tesouraria":            "#059669", // green
	"contabilidade":         "#06B6D4", // cyan
	"impostos":              "#EAB308", // yellow
	"multi-moeda":           "#D97706", // amber-dark
	"centros-custo":         "#78716C", // stone
	"recursos-humanos":      "#EC4899", // pink
	"pedido-ferias":         "#F472B6", // pink-light
	"crm":                   "#A855F7", // purple
	"assinaturas":           "#9333EA", // purple-dark
	"gestao-escolar":        "#0D9488", // teal-dark
	"notificacoes":          "#0EA5E9", // sky
	"auditoria":             "#64748B", // slate
	"seguranca":             "#DC2626", // red-dark
	"sistema-configuracao":  "#475569", // slate-dark
}

func corDoModulo(modulo string) string {
	if cor, ok := moduloCores[modulo]; ok {
		return cor
	}
	return "#64748B" // slate — fallback para módulos não mapeados
}

// DBQuerier define as operações mínimas de base de dados usadas pelo RBAC.
// Permite testar a lógica com mocks (pgxmock) sem depender de *pgxpool.Pool.
type DBQuerier interface {
	QueryRow(ctx context.Context, sql string, args ...interface{}) pgx.Row
	Query(ctx context.Context, sql string, args ...interface{}) (pgx.Rows, error)
}

type UserAccess struct {
	UserID    int64          `json:"user_id"`
	TenantID  int64          `json:"tenant_id"`
	Tipo      string         `json:"tipo"`
	Escopo    string         `json:"escopo"`
	CargoID   *int64         `json:"cargo_id,omitempty"`
	CargoNome *string        `json:"cargo_nome,omitempty"`
	Modulos   []ModuloAcesso `json:"modulos"`
	Features  []string       `json:"features"`
	// lista plana interna — usada por Can(), não serializada
	permissoes []Permission
}

// Can verifica se o utilizador tem permissão. Superadmin tem acesso total.
func (ua *UserAccess) Can(modulo, acao string) bool {
	if ua.Tipo == "superadmin" {
		return true
	}
	for _, p := range ua.permissoes {
		if p.Modulo == modulo && (p.Acao == acao || p.Acao == "*") {
			return true
		}
	}
	return false
}

// buildModulos converte a lista plana em []ModuloAcesso ordenada.
func buildModulos(perms []Permission) []ModuloAcesso {
	m := map[string][]string{}
	order := []string{}
	for _, p := range perms {
		if _, exists := m[p.Modulo]; !exists {
			order = append(order, p.Modulo)
		}
		m[p.Modulo] = append(m[p.Modulo], p.Acao)
	}
	sort.Strings(order)
	out := make([]ModuloAcesso, 0, len(order))
	for _, mod := range order {
		acoes := m[mod]
		sort.Strings(acoes)
		out = append(out, ModuloAcesso{Modulo: mod, Cor: corDoModulo(mod), Acoes: acoes})
	}
	return out
}

// LoadUserAccess carrega tipo + cargo + permissões mergeadas para um
// utilizador, na membership indicada. membershipID deve vir de um JWT já
// validado (claim "mid", ver middleware.AuthUser.MembershipID) — 0 devolve
// o mesmo resultado de um utilizador sem membership (ex.: superadmin).
//
// Filtrar por membership_id (em vez de só user_id) é o que torna esta
// query determinística agora que auth.memberships permite mais de um
// vínculo por utilizador (ver migration 20260713000002): sem este filtro,
// um LEFT JOIN só por user_id passaria a devolver uma linha arbitrária
// entre as várias memberships possíveis.
func LoadUserAccess(ctx context.Context, db DBQuerier, userID, membershipID int64) (*UserAccess, error) {
	ua := &UserAccess{UserID: userID, Modulos: []ModuloAcesso{}, Features: []string{}}

	err := db.QueryRow(ctx, `
		SELECT COALESCE(m.tenant_id, 0), u.tipo, COALESCE(NULLIF(m.escopo, ''), 'erp'), m.cargo_id, c.nome
		  FROM users u
		  LEFT JOIN auth.memberships m ON m.id = $2 AND m.user_id = u.id AND m.ativo = true
		  LEFT JOIN cargos c ON c.id = m.cargo_id
		 WHERE u.id = $1`, userID, membershipID).
		Scan(&ua.TenantID, &ua.Tipo, &ua.Escopo, &ua.CargoID, &ua.CargoNome)
	if err != nil {
		return nil, err
	}

	if ua.Tipo == "superadmin" {
		return ua, nil
	}

	set := map[string]struct{}{}

	// Permissões do cargo
	if ua.CargoID != nil {
		rows, err := db.Query(ctx, `
			SELECT modulo, acao FROM permissoes_cargo WHERE cargo_id = $1
			ORDER BY modulo, acao`, *ua.CargoID)
		if err != nil {
			return nil, err
		}
		defer rows.Close()
		for rows.Next() {
			var p Permission
			if rows.Scan(&p.Modulo, &p.Acao) == nil {
				key := p.Modulo + ":" + p.Acao
				if _, exists := set[key]; !exists {
					set[key] = struct{}{}
					ua.permissoes = append(ua.permissoes, p)
				}
			}
		}
	}

	// Permissões diretas (extendem o cargo)
	rows, err := db.Query(ctx, `
		SELECT modulo, acao FROM permissoes_diretas WHERE user_id = $1
		ORDER BY modulo, acao`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var p Permission
		if rows.Scan(&p.Modulo, &p.Acao) == nil {
			key := p.Modulo + ":" + p.Acao
			if _, exists := set[key]; !exists {
				set[key] = struct{}{}
				ua.permissoes = append(ua.permissoes, p)
			}
		}
	}

	// permissões padrão por tipo (tabela auth.permissoes_tipo)
	tipoRows, err := db.Query(ctx, `
		SELECT modulo, acao FROM auth.permissoes_tipo WHERE tipo=$1
		ORDER BY modulo, acao`, ua.Tipo)
	if err == nil {
		defer tipoRows.Close()
		for tipoRows.Next() {
			var p Permission
			if tipoRows.Scan(&p.Modulo, &p.Acao) == nil {
				key := p.Modulo + ":" + p.Acao
				if _, exists := set[key]; !exists {
					set[key] = struct{}{}
					ua.permissoes = append(ua.permissoes, p)
				}
			}
		}
	}

	// Filtrar módulos que o superadmin desactivou para este tenant.
	// Se saas.tenant_modules.ativo = FALSE, remove todas as permissões desse módulo.
	if disabled, err := loadModulosDesativados(ctx, db, ua.TenantID); err == nil && len(disabled) > 0 {
		filtered := make([]Permission, 0, len(ua.permissoes))
		for _, p := range ua.permissoes {
			if !disabled[p.Modulo] {
				filtered = append(filtered, p)
			}
		}
		ua.permissoes = filtered
	}

	// Filtrar módulos pelo escopo do utilizador.
	// Contas 'escola' e professores só devem ver o módulo 'gestao-escolar'.
	if ua.Tipo != "superadmin" && (ua.Escopo == "escola" || ua.Escopo == "portal_professor") {
		filtered := make([]Permission, 0, len(ua.permissoes))
		for _, p := range ua.permissoes {
			if p.Modulo == "gestao-escolar" {
				filtered = append(filtered, p)
			}
		}
		ua.permissoes = filtered
	}

	ua.Modulos = buildModulos(ua.permissoes)

	// Carregar features activas para este tenant (catálogo + overrides do tenant).
	ua.Features = loadFeaturesTenant(ctx, db, ua.TenantID)

	return ua, nil
}

// loadFeaturesTenant devolve as chaves das features activas para um tenant.
// Para cada feature do catálogo: usa override de tenant_feature_flags se existir,
// caso contrário usa o valor ativo_por_defeito — e só inclui se o módulo estiver activo.
func loadFeaturesTenant(ctx context.Context, db DBQuerier, tenantID int64) []string {
	rows, err := db.Query(ctx, `
		SELECT fc.key
		  FROM saas.feature_catalog fc
		  JOIN saas.tenant_modules tm
		    ON tm.tenant_id = $1 AND tm.modulo = fc.modulo AND tm.ativo = TRUE
		  LEFT JOIN sistema_configuracao.tenant_feature_flags tf
		    ON tf.tenant_id = $1 AND tf.codigo = fc.key
		 WHERE COALESCE(tf.activo, fc.ativo_por_defeito) = TRUE
		 ORDER BY fc.key`, tenantID, tenantID)
	if err != nil {
		return []string{}
	}
	defer rows.Close()
	out := []string{}
	for rows.Next() {
		var k string
		if rows.Scan(&k) == nil {
			out = append(out, k)
		}
	}
	return out
}

// loadModulosDesativados devolve o conjunto de módulos com ativo=FALSE para um tenant.
func loadModulosDesativados(ctx context.Context, db DBQuerier, tenantID int64) (map[string]bool, error) {
	rows, err := db.Query(ctx,
		`SELECT modulo FROM saas.tenant_modules WHERE tenant_id = $1 AND ativo = FALSE`,
		tenantID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	disabled := map[string]bool{}
	for rows.Next() {
		var mod string
		if rows.Scan(&mod) == nil {
			disabled[mod] = true
		}
	}
	return disabled, rows.Err()
}
