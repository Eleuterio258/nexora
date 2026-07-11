package middleware

import (
	"context"
	"net"
	"net/http"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

// deviceContextKey permite injectar o dispositivo autenticado no contexto.
type deviceContextKey string

const DeviceKey deviceContextKey = "authDevice"

// DeviceInfo contém os dados do dispositivo autenticado.
type DeviceInfo struct {
	ID       int64
	TenantID int64
	BranchID *int64
	Nome     string
	Modelo   string
	Driver   string
	Serial   *string
}

// GetDevice devolve o dispositivo autenticado, se existir.
func GetDevice(r *http.Request) *DeviceInfo {
	d, _ := r.Context().Value(DeviceKey).(*DeviceInfo)
	return d
}

// RequireDeviceAuth valida o header X-API-Key contra a tabela hardware.devices.
// Se válido, injecta DeviceInfo e AuthUser (com tipo=device) no contexto,
// permitindo reutilizar GetUser e o isolamento por tenant_id.
func RequireDeviceAuth(pool *pgxpool.Pool) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			apiKey := r.Header.Get("X-API-Key")
			if apiKey == "" {
				JSONErr(w, "API Key em falta", http.StatusUnauthorized)
				return
			}

			var (
				deviceID int64
				tenantID int64
				branchID pgtype.Int8
				nome     string
				modelo   string
				driver   string
				serial   *string
				ativo    bool
				ipDB     pgtype.Text
			)

			err := pool.QueryRow(r.Context(), `
				SELECT id, tenant_id, branch_id, nome, modelo, driver, serial_number, ativo, COALESCE(ip_permitido::text, '')
				  FROM hardware.devices
				 WHERE api_key_hash = $1`,
				HashToken(apiKey),
			).Scan(&deviceID, &tenantID, &branchID, &nome, &modelo, &driver, &serial, &ativo, &ipDB)

			if err != nil || !ativo {
				JSONErr(w, "Dispositivo não autorizado", http.StatusUnauthorized)
				return
			}

			// Validação opcional de IP de origem.
			if ipDB.Valid && ipDB.String != "" {
				if !ipMatches(r, ipDB.String) {
					JSONErr(w, "IP não autorizado", http.StatusForbidden)
					return
				}
			}

			// Atualiza último uso (fire-and-forget).
			go pool.Exec(r.Context(),
				`UPDATE hardware.devices SET ultimo_uso_em = NOW() WHERE id = $1`,
				deviceID,
			)

			var bID *int64
			if branchID.Valid {
				bid := branchID.Int64
				bID = &bid
			}

			device := &DeviceInfo{
				ID:       deviceID,
				TenantID: tenantID,
				BranchID: bID,
				Nome:     nome,
				Modelo:   modelo,
				Driver:   driver,
				Serial:   serial,
			}

			ctx := context.WithValue(r.Context(), DeviceKey, device)
			ctx = context.WithValue(ctx, UserKey, &AuthUser{
				ID:       deviceID,
				TenantID: tenantID,
				Tipo:     "device",
				Escopo:   "erp",
			})

			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// ipMatches verifica se o IP remoto do pedido corresponde ao CIDR/IP configurado.
func ipMatches(r *http.Request, allowed string) bool {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		host = r.RemoteAddr
	}
	ip := net.ParseIP(host)
	if ip == nil {
		return false
	}

	_, ipNet, err := net.ParseCIDR(allowed)
	if err == nil {
		return ipNet.Contains(ip)
	}

	allowedIP := net.ParseIP(allowed)
	if allowedIP == nil {
		return false
	}
	return allowedIP.Equal(ip)
}
