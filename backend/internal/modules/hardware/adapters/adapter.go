package adapters

import (
	"net/http"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/hardware/models"
)

// Adapter é a interface que cada driver de hardware deve implementar.
type Adapter interface {
	// Name retorna o nome identificador do driver.
	Name() string

	// ParseEvent extrai e normaliza um evento a partir do pedido HTTP.
	ParseEvent(r *http.Request) (*models.NormalizedEvent, error)

	// ValidateAuth valida a autenticação específica do driver (ex: HMAC, headers).
	// O dispositivo já foi autenticado por API Key antes desta chamada.
	ValidateAuth(r *http.Request, device *mw.DeviceInfo, configs map[string]string) error
}
