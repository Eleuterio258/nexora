package middleware

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
)

// resolverFalso devolve o tenant configurado para qualquer host, ou
// (0, false) quando o host não identifica tenant nenhum.
type resolverFalso struct {
	tenantID int64
	conhece  bool
}

func (r resolverFalso) Resolver(context.Context, string) (int64, bool) {
	return r.tenantID, r.conhece
}

func pedidoCom(user *AuthUser, host string) *http.Request {
	req := httptest.NewRequest(http.MethodGet, "http://interno/api/rh/funcionarios", nil)
	req.Header.Set("X-Forwarded-Host", host)
	if user != nil {
		req = req.WithContext(context.WithValue(req.Context(), UserKey, user))
	}

	return req
}

func TestEnforceTenantHost(t *testing.T) {
	casos := []struct {
		nome     string
		user     *AuthUser
		resolver resolverFalso
		esperado int
		porque   string
	}{
		{
			nome:     "host sem tenant deixa passar",
			user:     &AuthUser{TenantID: 7, Tipo: "funcionario"},
			resolver: resolverFalso{conhece: false},
			esperado: http.StatusOK,
			porque:   "é o caso de todo o tráfego pelo domínio central; bloquear aqui fecharia o ERP a toda a gente",
		},
		{
			nome:     "host do próprio tenant deixa passar",
			user:     &AuthUser{TenantID: 11, Tipo: "funcionario"},
			resolver: resolverFalso{tenantID: 11, conhece: true},
			esperado: http.StatusOK,
		},
		{
			nome:     "host de outro tenant é recusado",
			user:     &AuthUser{TenantID: 7, Tipo: "funcionario"},
			resolver: resolverFalso{tenantID: 11, conhece: true},
			esperado: http.StatusForbidden,
			porque:   "é exactamente o que torna o domínio uma garantia e não uma decoração",
		},
		{
			nome:     "superadmin atravessa tenants",
			user:     &AuthUser{TenantID: 0, Tipo: "superadmin"},
			resolver: resolverFalso{tenantID: 11, conhece: true},
			esperado: http.StatusOK,
			porque:   "não tem membership e é quem opera a plataforma",
		},
		{
			nome:     "sem sessão deixa passar",
			user:     nil,
			resolver: resolverFalso{tenantID: 11, conhece: true},
			esperado: http.StatusOK,
			porque:   "quem autentica é o RequireAuth; aqui não há sessão para comparar",
		},
	}

	for _, c := range casos {
		t.Run(c.nome, func(t *testing.T) {
			handler := EnforceTenantHost(c.resolver)(http.HandlerFunc(
				func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) },
			))

			rec := httptest.NewRecorder()
			handler.ServeHTTP(rec, pedidoCom(c.user, "acme.nexora.e258tech.tech"))

			if rec.Code != c.esperado {
				t.Errorf("status = %d, esperado %d (%s)", rec.Code, c.esperado, c.porque)
			}
		})
	}
}

func TestHostDoPedidoPrefereForwarded(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "http://interno/x", nil)
	if got := hostDoPedido(req); got != "interno" {
		t.Errorf("sem X-Forwarded-Host devia usar r.Host, devolveu %q", got)
	}

	req.Header.Set("X-Forwarded-Host", "acme.nexora.e258tech.tech")
	if got := hostDoPedido(req); got != "acme.nexora.e258tech.tech" {
		t.Errorf("X-Forwarded-Host devia ganhar, devolveu %q", got)
	}
}
