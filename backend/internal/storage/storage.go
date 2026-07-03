// Package storage providencia uma camada de abstração para object storage.
// Suporta storage local em disco e MinIO/S3-compatible via adapter pattern.
package storage

import (
	"context"
	"fmt"
	"io"
	"strings"
)

// Provider define as operações suportadas por qualquer backend de storage.
type Provider interface {
	// Put armazena dados numa key e devolve a URL/endpoint para acesso.
	Put(ctx context.Context, key string, data []byte, contentType string) (string, error)
	// Get devolve um reader para o objecto e o seu tamanho em bytes.
	Get(ctx context.Context, key string) (io.ReadCloser, int64, error)
	// GetURL devolve uma URL para aceder ao objecto. Pode ser pública ou presigned.
	GetURL(ctx context.Context, key string) (string, error)
	// Delete remove o objecto.
	Delete(ctx context.Context, key string) error
	// Exists verifica se o objecto existe.
	Exists(ctx context.Context, key string) (bool, error)
}

// Config agrupa as configurações necessárias para criar um Provider.
type Config struct {
	Provider    string // "local" ou "minio"
	LocalDir    string // diretório base para provider local
	MinioEndpoint string
	MinioAccessKey string
	MinioSecretKey string
	MinioBucket    string
	MinioUseSSL    bool
	MinioRegion    string
	PublicBaseURL  string // URL base devolvida para clientes (ex: http://localhost:9004/nexora)
}

// New cria um Provider consoante a configuração.
func New(cfg Config) (Provider, error) {
	switch strings.ToLower(cfg.Provider) {
	case "", "local":
		return NewLocalProvider(cfg.LocalDir, cfg.PublicBaseURL)
	case "minio":
		return NewMinioProvider(cfg)
	default:
		return nil, fmt.Errorf("storage provider desconhecido: %s", cfg.Provider)
	}
}

// NormalizeKey remove barras iniciais/finais e garante separador consistente.
func NormalizeKey(key string) string {
	key = strings.TrimSpace(key)
	key = strings.Trim(key, "/")
	key = strings.ReplaceAll(key, "\\", "/")
	for strings.Contains(key, "//") {
		key = strings.ReplaceAll(key, "//", "/")
	}
	return key
}
