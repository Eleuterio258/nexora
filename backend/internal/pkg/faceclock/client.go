// Package faceclock é o cliente HTTP partilhado para o serviço de biometria
// FaceClock (assiduidade_system_backend). Ao contrário do nexorapay (X-API-Key
// fixa), aqui a autenticação é sempre por Authorization (Bearer) do próprio
// utilizador autenticado, reenviado tal-e-qual — o FaceClock decide a
// identidade sozinho via JWKS local (ver CONTRATO-INTEGRACAO-ERP.md secção
// 11), nunca por API Key de device. Extraído de
// recursos-humanos/handlers/funcionarios_biometria.go (EnrollFacial) ao criar
// o segundo ponto de chamada (self-service/handlers/biometria.go,
// VerificarFacial), seguindo o mesmo padrão já usado para o nexorapay.
package faceclock

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"time"
)

type Client struct {
	baseURL string
	http    *http.Client
}

func NewClient(baseURL string) *Client {
	return &Client{baseURL: baseURL, http: &http.Client{Timeout: 30 * time.Second}}
}

// PostAsUser envia um POST autenticado com o Bearer token do utilizador
// autenticado e devolve a resposta do FaceClock tal-e-qual (mapa genérico,
// já que os payloads de enroll/verify têm formatos diferentes).
func (c *Client) PostAsUser(ctx context.Context, path, authHeader string, payload any) (map[string]any, int, error) {
	data, err := json.Marshal(payload)
	if err != nil {
		return nil, 0, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+path, bytes.NewReader(data))
	if err != nil {
		return nil, 0, err
	}
	req.Header.Set("Authorization", authHeader)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.http.Do(req)
	if err != nil {
		return nil, 0, err
	}
	defer resp.Body.Close()

	raw, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, resp.StatusCode, err
	}

	var result map[string]any
	if err := json.Unmarshal(raw, &result); err != nil {
		return map[string]any{"raw": string(raw)}, resp.StatusCode, nil
	}
	return result, resp.StatusCode, nil
}
