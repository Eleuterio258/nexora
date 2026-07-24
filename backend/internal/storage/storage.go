// Package storage providencia uma camada de abstração para object storage.
// Suporta storage local em disco e MinIO/S3-compatible via adapter pattern.
package storage

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"strings"
)

// ErrImmutableObjectExists indica uma tentativa de substituir uma key
// imutável por conteúdo diferente.
var ErrImmutableObjectExists = errors.New("storage: objeto imutável já existe com conteúdo diferente")

// ErrEvidenceDeleteForbidden indica uma tentativa de remover, através da
// aplicação, um objeto de evidência do módulo assinatura-digital (PDF
// original ou versão assinada, endereçados por hash). Estes objetos só podem
// ser removidos por um processo administrativo fora da aplicação, sujeito à
// política de retenção documentada no README do módulo — nunca por um
// pedido HTTP normal, de nenhum módulo.
var ErrEvidenceDeleteForbidden = errors.New("storage: remoção de evidências de assinatura digital não é permitida pela aplicação")

// evidenceKeyPrefix identifica as keys geridas pelo módulo assinatura-digital
// (ver contentKey em internal/modules/assinatura-digital/handlers).
const evidenceKeyPrefix = "assinatura-digital/"

// isEvidenceKey reporta se a key pertence ao módulo assinatura-digital e
// nunca deve poder ser eliminada via Provider.Delete.
func isEvidenceKey(key string) bool {
	return strings.HasPrefix(NormalizeKey(key), evidenceKeyPrefix)
}

// Provider define as operações suportadas por qualquer backend de storage.
type Provider interface {
	// Put armazena dados numa key e devolve a URL/endpoint para acesso.
	Put(ctx context.Context, key string, data []byte, contentType string) (string, error)
	// PutImmutable cria um objeto sem permitir que conteúdo diferente substitua
	// uma key existente. Repetir a operação com os mesmos bytes é idempotente.
	PutImmutable(ctx context.Context, key string, data []byte, contentType string) (string, error)
	// Get devolve um reader para o objecto e o seu tamanho em bytes.
	Get(ctx context.Context, key string) (io.ReadCloser, int64, error)
	// GetURL devolve uma URL para aceder ao objecto. Pode ser pública ou presigned.
	GetURL(ctx context.Context, key string) (string, error)
	// Delete remove o objecto.
	Delete(ctx context.Context, key string) error
	// Exists verifica se o objecto existe.
	Exists(ctx context.Context, key string) (bool, error)
}

// immutableObjectMatches confirma se uma key imutável já contém exatamente os
// mesmos bytes. É partilhado pelos providers local e MinIO.
func immutableObjectMatches(ctx context.Context, provider Provider, key string, expected []byte) (bool, error) {
	reader, _, err := provider.Get(ctx, key)
	if err != nil {
		return false, err
	}
	defer reader.Close()

	actual, err := io.ReadAll(reader)
	if err != nil {
		return false, err
	}
	return bytes.Equal(actual, expected), nil
}

// Config agrupa as configurações necessárias para criar um Provider.
type Config struct {
	Provider       string // "local" ou "minio"
	LocalDir       string // diretório base para provider local
	MinioEndpoint  string
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
