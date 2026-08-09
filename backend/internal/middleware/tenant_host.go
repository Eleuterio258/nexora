package middleware

import (
	"context"
	"net/http"
)

// TenantResolver diz a que tenant pertence um host. É satisfeito pelo
// tenanthost.Resolver; existe como interface para que a decisão de bloquear
// possa ser testada sem base de dados.
type TenantResolver interface {
	Resolver(ctx context.Context, host string) (int64, bool)
}

// EnforceTenantHost recusa uma sessão que não pertença ao tenant do endereço
// por onde entrou. Sem isto o domínio é decorativo: um utilizador do tenant A
// que abra o endereço do tenant B entra na mesma e vê o tenant A, o que torna
// "o ERP no teu domínio" uma promessa que o sistema não cumpre.
//
// A regra só se aplica quando o host identifica um tenant. Um host que não
// identifica nenhum — o domínio central, o host da API, um pedido sem
// X-Forwarded-Host — passa sem restrição, que é como todo o tráfego actual
// funciona. Isto é deliberado: a alternativa (recusar o que não se reconhece)
// fecharia o acesso a toda a gente à primeira falha de propagação do host.
//
// Superadmins ficam de fora: não têm membership nem tenant fixo, e são eles
// quem precisa de atravessar tenants para operar a plataforma.
func EnforceTenantHost(resolver TenantResolver) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			user := GetUser(r)
			if user == nil || user.Tipo == "superadmin" {
				next.ServeHTTP(w, r)
				return
			}

			tenantDoHost, identificado := resolver.Resolver(r.Context(), hostDoPedido(r))
			if !identificado || tenantDoHost == user.TenantID {
				next.ServeHTTP(w, r)
				return
			}

			JSONErr(w, "Esta sessão não pertence ao domínio por onde acedeu.", http.StatusForbidden)
		})
	}
}

// hostDoPedido devolve o host que o cliente pediu. X-Forwarded-Host tem
// prioridade porque o pedido chega através do proxy PHP e do Traefik, e o
// r.Host nesse ponto é já o do salto interno.
func hostDoPedido(r *http.Request) string {
	if h := r.Header.Get("X-Forwarded-Host"); h != "" {
		return h
	}

	return r.Host
}
