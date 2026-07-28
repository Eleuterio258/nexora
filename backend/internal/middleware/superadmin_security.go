package middleware

import (
	"net"
	"net/http"
	"time"
)

// RequireSuperadminIPAllowlist restringe pedidos de superadmin aos IPs/CIDRs
// registados em auth.superadmin_ip_allowlist. Se a allowlist estiver vazia,
// permite o acesso (modo transição) para não brickar o acesso durante a
// configuração inicial.
func RequireSuperadminIPAllowlist(pool DBPool) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			u := GetUser(r)
			if u == nil {
				JSONErr(w, "Utilizador não autenticado", http.StatusUnauthorized)
				return
			}
			if u.Tipo != "superadmin" {
				next.ServeHTTP(w, r)
				return
			}

			var count int
			if err := pool.QueryRow(r.Context(), `
				SELECT COUNT(*) FROM auth.superadmin_ip_allowlist WHERE ativo = true`,
			).Scan(&count); err != nil {
				JSONErr(w, "Erro interno ao validar IP", http.StatusInternalServerError)
				return
			}
			if count == 0 {
				next.ServeHTTP(w, r)
				return
			}

			clientIP, _, err := net.SplitHostPort(r.RemoteAddr)
			if err != nil {
				clientIP = r.RemoteAddr
			}
			client := net.ParseIP(clientIP)
			if client == nil {
				JSONErr(w, "IP do cliente inválido", http.StatusForbidden)
				return
			}

			rows, err := pool.Query(r.Context(), `
				SELECT ip_cidr::text FROM auth.superadmin_ip_allowlist WHERE ativo = true`,
			)
			if err != nil {
				JSONErr(w, "Erro interno ao validar IP", http.StatusInternalServerError)
				return
			}
			defer rows.Close()

			for rows.Next() {
				var cidr string
				if err := rows.Scan(&cidr); err != nil {
					continue
				}
				_, ipNet, err := net.ParseCIDR(cidr)
				if err != nil {
					// Tentar como IP simples.
					if ip := net.ParseIP(cidr); ip != nil && ip.Equal(client) {
						next.ServeHTTP(w, r)
						return
					}
					continue
				}
				if ipNet.Contains(client) {
					next.ServeHTTP(w, r)
					return
				}
			}

			JSONErr(w, "Acesso negado a partir deste IP", http.StatusForbidden)
		})
	}
}

// RequireSuperadminReauth exige que o token de superadmin tenha um claim
// reauth_at recente (dentro de maxAge). Destina-se a proteger operações
// críticas de superadmin com step-up authentication.
func RequireSuperadminReauth(maxAge time.Duration) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			u := GetUser(r)
			if u == nil {
				JSONErr(w, "Utilizador não autenticado", http.StatusUnauthorized)
				return
			}
			if u.Tipo != "superadmin" {
				next.ServeHTTP(w, r)
				return
			}
			if u.ReauthAt.IsZero() || time.Since(u.ReauthAt) > maxAge {
				JSONErr(w, "Reautenticação necessária", http.StatusForbidden)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
