// Package nexorapay é o cliente HTTP partilhado para o microserviço externo
// Nexora-Pay (M-Pesa/eMola/mKesh). Extraído de
// internal/modules/gestao-escolar/handlers/portal_pagamento.go (item 5 do
// plano-mudancas-backend-paycore-mobile.md) para poder ser reaproveitado
// pelo módulo pos, sem duplicar a lógica de chamada HTTP.
package nexorapay

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
)

// Client faz chamadas HTTP ao nexora-pay com X-API-Key.
type Client struct {
	baseURL string
	apiKey  string
}

func NewClient(baseURL, apiKey string) *Client {
	return &Client{baseURL: baseURL, apiKey: apiKey}
}

func (c *Client) Post(ctx context.Context, path string, idempotencyKey string, body any) (map[string]any, int, error) {
	data, _ := json.Marshal(body)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+path, bytes.NewReader(data))
	if err != nil {
		return nil, 0, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-Key", c.apiKey)
	if idempotencyKey != "" {
		req.Header.Set("Idempotency-Key", idempotencyKey)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, 0, err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	var result map[string]any
	json.Unmarshal(raw, &result)
	return result, resp.StatusCode, nil
}

func (c *Client) Get(ctx context.Context, path string) (map[string]any, int, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+path, nil)
	if err != nil {
		return nil, 0, err
	}
	req.Header.Set("X-API-Key", c.apiKey)
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, 0, err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	var result map[string]any
	json.Unmarshal(raw, &result)
	return result, resp.StatusCode, nil
}
