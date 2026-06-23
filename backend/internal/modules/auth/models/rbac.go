package models

import (
	"context"
	"sort"

	"github.com/jackc/pgx/v5/pgxpool"
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
	"autorizacao":           "#F97316", // orange
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

type UserAccess struct {
	UserID    int64         `json:"user_id"`
	TenantID  int64         `json:"tenant_id"`
	Tipo      string        `json:"tipo"`
	CargoID   *int64        `json:"cargo_id,omitempty"`
	CargoNome *string       `json:"cargo_nome,omitempty"`
	Modulos   []ModuloAcesso `json:"modulos"` // organizado por módulo
	// lista plana interna — usada por Can(), não serializada
	permissoes []Permission
}

// Can verifica se o utilizador tem permissão. Superadmin tem acesso total.
func (ua *UserAccess) Can(modulo, acao string) bool {
	if ua.Tipo == "superadmin" {
		return true
	}
	for _, p := range ua.permissoes {
		if p.Modulo == modulo && p.Acao == acao {
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
		out = append(out, ModuloAcesso{Modulo: mod, Acoes: acoes})
	}
	return out
}

// LoadUserAccess carrega tipo + cargo + permissões mergeadas para um utilizador.
func LoadUserAccess(ctx context.Context, pool *pgxpool.Pool, userID int64) (*UserAccess, error) {
	ua := &UserAccess{UserID: userID, Modulos: []ModuloAcesso{}}

	err := pool.QueryRow(ctx, `
		SELECT u.tenant_id, u.tipo, u.cargo_id, c.nome
		  FROM users u
		  LEFT JOIN cargos c ON c.id = u.cargo_id
		 WHERE u.id = $1`, userID).
		Scan(&ua.TenantID, &ua.Tipo, &ua.CargoID, &ua.CargoNome)
	if err != nil {
		return nil, err
	}

	if ua.Tipo == "superadmin" {
		return ua, nil
	}

	set := map[string]struct{}{}

	// Permissões do cargo
	if ua.CargoID != nil {
		rows, err := pool.Query(ctx, `
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
	rows, err := pool.Query(ctx, `
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
	tipoRows, err := pool.Query(ctx, `
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

	ua.Modulos = buildModulos(ua.permissoes)
	return ua, nil
}
