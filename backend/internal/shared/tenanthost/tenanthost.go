// Package tenanthost resolve o tenant a que um pedido HTTP se dirige a partir
// do host pedido pelo cliente.
//
// Existem dois endereçamentos possíveis, por esta ordem:
//
//	1. domínio registado em saas.tenant_dominios  (ex.: mwanaafricaconsulting.com)
//	2. subdomínio da plataforma <codigo>.<base>   (ex.: acme.nexora.e258tech.tech)
//
// Um host que não corresponda a nenhum dos dois — o domínio principal, o host
// da API — não identifica tenant nenhum, e isso não é um erro: é o caso normal
// de quem acede pela via central.
package tenanthost

import (
	"context"
	"net"
	"strings"
	"sync"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// cacheTTL é quanto tempo se guarda a correspondência host→tenant. A
// resolução acontece em todos os pedidos autenticados, e os domínios de tenant
// mudam raramente; sem cache seria uma ida à base de dados por pedido.
const cacheTTL = 5 * time.Minute

type entrada struct {
	tenantID int64
	expiraEm time.Time
}

// Resolver traduz hosts em tenants. É seguro para uso concorrente.
type Resolver struct {
	db         *pgxpool.Pool
	baseDomain string

	mu    sync.RWMutex
	cache map[string]entrada
}

func New(db *pgxpool.Pool, baseDomain string) *Resolver {
	return &Resolver{
		db:         db,
		baseDomain: strings.ToLower(strings.TrimSpace(baseDomain)),
		cache:      make(map[string]entrada),
	}
}

// Normalizar reduz um host ao formato com que se compara: minúsculas, sem
// porta, sem ponto final e sem "www.". Espelha o requestHost do módulo de
// recrutamento, para que os dois caminhos concordem sobre o que é o mesmo host.
func Normalizar(host string) string {
	host = strings.ToLower(strings.TrimSpace(host))
	if host == "" {
		return ""
	}
	if i := strings.IndexByte(host, ','); i >= 0 {
		host = strings.TrimSpace(host[:i]) // o proxy encadeia valores; vale o primeiro
	}
	if h, _, err := net.SplitHostPort(host); err == nil {
		host = h
	}
	host = strings.TrimSuffix(host, ".")

	return strings.TrimPrefix(host, "www.")
}

// Subdominio devolve o código do tenant em <codigo>.<base>, ou "" se o host
// não for um subdomínio directo da base. Só um nível conta: "a.b.base" nunca é
// lido como tenant "a".
func Subdominio(host, base string) string {
	if base == "" || host == "" || host == base {
		return ""
	}
	sufixo := "." + base
	if !strings.HasSuffix(host, sufixo) {
		return ""
	}
	codigo := strings.TrimSuffix(host, sufixo)
	if codigo == "" || strings.Contains(codigo, ".") {
		return ""
	}

	return codigo
}

// Resolver devolve o tenant a que o host pertence. O segundo valor diz se o
// host identificou algum — um host desconhecido devolve (0, false) sem erro,
// porque aceder pelo domínio central é legítimo.
func (r *Resolver) Resolver(ctx context.Context, host string) (int64, bool) {
	host = Normalizar(host)
	if host == "" {
		return 0, false
	}

	if id, ok := r.doCache(host); ok {
		return id, id > 0
	}

	id := r.consultar(ctx, host)
	r.guardar(host, id)

	return id, id > 0
}

// consultar procura o host na base de dados. Devolve 0 quando o host não
// pertence a nenhum tenant activo — valor que também se guarda em cache, para
// que hosts sem tenant (o domínio central, a API) não repitam a consulta.
func (r *Resolver) consultar(ctx context.Context, host string) int64 {
	var id int64

	err := r.db.QueryRow(ctx, `
		SELECT t.id
		  FROM saas.tenant_dominios d
		  JOIN saas.tenants t ON t.id = d.tenant_id
		 WHERE d.dominio = $1 AND t.status = 'ativo'`, host,
	).Scan(&id)
	if err == nil && id > 0 {
		return id
	}

	if codigo := Subdominio(host, r.baseDomain); codigo != "" {
		if err := r.db.QueryRow(ctx,
			`SELECT id FROM saas.tenants WHERE codigo = $1 AND status = 'ativo'`, codigo,
		).Scan(&id); err == nil && id > 0 {
			return id
		}
	}

	return 0
}

func (r *Resolver) doCache(host string) (int64, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	e, ok := r.cache[host]
	if !ok || time.Now().After(e.expiraEm) {
		return 0, false
	}

	return e.tenantID, true
}

func (r *Resolver) guardar(host string, tenantID int64) {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.cache[host] = entrada{tenantID: tenantID, expiraEm: time.Now().Add(cacheTTL)}
}

// Esquecer remove um host da cache — para quando um domínio é registado ou
// removido e não se quer esperar pelo TTL.
func (r *Resolver) Esquecer(host string) {
	r.mu.Lock()
	defer r.mu.Unlock()

	delete(r.cache, Normalizar(host))
}
