package middleware

import (
	"net"
	"net/http"
	"sync"
	"time"
)

// RateLimit limita pedidos por IP a `max` ocorrencias por `window`.
// Pensado para rotas publicas sem sessao (candidaturas/contacto).
func RateLimit(max int, window time.Duration) func(http.Handler) http.Handler {
	var mu sync.Mutex
	hits := map[string][]time.Time{}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ip := r.RemoteAddr
			if host, _, err := net.SplitHostPort(ip); err == nil {
				ip = host
			}
			now := time.Now()

			mu.Lock()
			recent := hits[ip][:0]
			for _, t := range hits[ip] {
				if now.Sub(t) < window {
					recent = append(recent, t)
				}
			}
			if len(recent) >= max {
				hits[ip] = recent
				mu.Unlock()
				JSONErr(w, "Demasiadas tentativas. Tente novamente mais tarde.", http.StatusTooManyRequests)
				return
			}
			hits[ip] = append(recent, now)
			mu.Unlock()

			next.ServeHTTP(w, r)
		})
	}
}
