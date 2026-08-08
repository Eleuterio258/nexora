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

	return c.do(ctx, http.MethodPost, path, headers, bytes.NewReader(data))
}

// Get envia um GET assinado para o FaceClock e devolve a resposta como mapa.
// query é a query string raw (sem o "?" inicial), ou "" se não houver.
func (c *Client) Get(
	ctx context.Context,
	path string,
	query string,
) (map[string]any, int, error) {
	if c.signer == nil {
		return nil, 0, fmt.Errorf("faceclock client sem credenciais configuradas")
	}
	headers := c.signer.SignBytes(http.MethodGet, path, query, nil)
	return c.do(ctx, http.MethodGet, requestPath(path, query), headers, nil)
}

// Delete envia um DELETE assinado para o FaceClock e devolve a resposta como mapa.
// query é a query string raw (sem o "?" inicial), ou "" se não houver.
func (c *Client) Delete(
	ctx context.Context,
	path string,
	query string,
) (map[string]any, int, error) {
	if c.signer == nil {
		return nil, 0, fmt.Errorf("faceclock client sem credenciais configuradas")
	}
	headers := c.signer.SignBytes(http.MethodDelete, path, query, nil)
	return c.do(ctx, http.MethodDelete, requestPath(path, query), headers, nil)
}

// requestPath junta path e query (já não assinados separadamente) para
// construir o URL real do pedido HTTP.
func requestPath(path, query string) string {
	if query == "" {
		return path
	}
	return path + "?" + query
}

func (c *Client) do(
	ctx context.Context,
	method, path string,
	headers map[string]string,
	body io.Reader,
) (map[string]any, int, error) {
	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, body)
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
