// Package faceclock é o cliente HTTP partilhado para o serviço de biometria
// FaceClock (assiduidade_system_backend).
//
// A autenticação é feita via HMAC Nexora (X-Nexora-*), usando credenciais
// serviço-a-serviço configuradas no ERP. O FaceClock valida a assinatura
// contra as credenciais armazenadas na sua base de dados (ApiCredential).
package faceclock

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"nexora/internal/pkg/nexorasign"
)

// Client comunica com o FaceClock usando assinatura HMAC Nexora.
type Client struct {
	baseURL string
	http    *http.Client
	signer  *nexorasign.Signer
}

// NewClient cria um cliente configurado com as credenciais Nexora.
func NewClient(baseURL, accessKeyID, secretAccessKey string) *Client {
	return &Client{
		baseURL: baseURL,
		http:    &http.Client{Timeout: 30 * time.Second},
		signer:  nexorasign.New(accessKeyID, secretAccessKey),
	}
}

// Post envia um POST assinado para o FaceClock e devolve a resposta como mapa.
func (c *Client) Post(
	ctx context.Context,
	path string,
	payload any,
) (map[string]any, int, error) {
	if c.signer == nil {
		return nil, 0, fmt.Errorf("faceclock client sem credenciais configuradas")
	}

	// Serializar uma única vez para garantir que o body enviado e o hash
	// assinado correspondam byte-a-byte.
	data, err := nexorasign.SerializeBody(payload)
	if err != nil {
		return nil, 0, fmt.Errorf("serializar payload FaceClock: %w", err)
	}
	headers := c.signer.SignBytes(http.MethodPost, path, "", data)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+path, bytes.NewReader(data))
	if err != nil {
		return nil, 0, err
	}

	for k, v := range headers {
		req.Header.Set(k, v)
	}

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
