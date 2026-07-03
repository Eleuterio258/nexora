package storage

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/url"
	"path"
	"strings"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// MinioProvider implementa Provider usando MinIO/S3-compatible API.
type MinioProvider struct {
	client        *minio.Client
	bucket        string
	publicBaseURL string
}

// NewMinioProvider cria um provider MinIO.
func NewMinioProvider(cfg Config) (*MinioProvider, error) {
	client, err := minio.New(cfg.MinioEndpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.MinioAccessKey, cfg.MinioSecretKey, ""),
		Secure: cfg.MinioUseSSL,
		Region: cfg.MinioRegion,
	})
	if err != nil {
		return nil, fmt.Errorf("minio: %w", err)
	}

	// Verificar/criar bucket
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	exists, err := client.BucketExists(ctx, cfg.MinioBucket)
	if err != nil {
		return nil, fmt.Errorf("minio bucket check: %w", err)
	}
	if !exists {
		if err := client.MakeBucket(ctx, cfg.MinioBucket, minio.MakeBucketOptions{Region: cfg.MinioRegion}); err != nil {
			return nil, fmt.Errorf("minio make bucket: %w", err)
		}
	}

	publicBaseURL := strings.TrimRight(cfg.PublicBaseURL, "/")
	if publicBaseURL == "" {
		scheme := "http"
		if cfg.MinioUseSSL {
			scheme = "https"
		}
		publicBaseURL = fmt.Sprintf("%s://%s/%s", scheme, cfg.MinioEndpoint, cfg.MinioBucket)
	}

	return &MinioProvider{
		client:        client,
		bucket:        cfg.MinioBucket,
		publicBaseURL: publicBaseURL,
	}, nil
}

// Put faz upload de dados para o MinIO.
func (p *MinioProvider) Put(ctx context.Context, key string, data []byte, contentType string) (string, error) {
	key = NormalizeKey(key)
	if key == "" {
		return "", fmt.Errorf("minio: key vazia")
	}
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	_, err := p.client.PutObject(ctx, p.bucket, key, bytes.NewReader(data), int64(len(data)), minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return "", fmt.Errorf("minio put: %w", err)
	}
	return p.GetURL(ctx, key)
}

// Get devolve um reader para o objecto MinIO.
func (p *MinioProvider) Get(ctx context.Context, key string) (io.ReadCloser, int64, error) {
	key = NormalizeKey(key)
	obj, err := p.client.GetObject(ctx, p.bucket, key, minio.GetObjectOptions{})
	if err != nil {
		return nil, 0, err
	}
	stat, err := obj.Stat()
	if err != nil {
		obj.Close()
		return nil, 0, err
	}
	return obj, stat.Size, nil
}

// GetURL devolve URL pública para o objecto.
func (p *MinioProvider) GetURL(ctx context.Context, key string) (string, error) {
	key = NormalizeKey(key)
	return p.publicBaseURL + "/" + key, nil
}

// Delete remove o objecto.
func (p *MinioProvider) Delete(ctx context.Context, key string) error {
	key = NormalizeKey(key)
	return p.client.RemoveObject(ctx, p.bucket, key, minio.RemoveObjectOptions{})
}

// Exists verifica se o objecto existe.
func (p *MinioProvider) Exists(ctx context.Context, key string) (bool, error) {
	key = NormalizeKey(key)
	_, err := p.client.StatObject(ctx, p.bucket, key, minio.StatObjectOptions{})
	if err != nil {
		errResp, ok := err.(minio.ErrorResponse)
		if ok && errResp.Code == "NoSuchKey" {
			return false, nil
		}
		return false, err
	}
	return true, nil
}

// PresignedURL devolve uma URL temporária de acesso ao objecto.
func (p *MinioProvider) PresignedURL(ctx context.Context, key string, expiry time.Duration) (*url.URL, error) {
	key = NormalizeKey(key)
	return p.client.PresignedGetObject(ctx, p.bucket, key, expiry, nil)
}

// JoinPath ajuda a construir keys com prefixos.
func JoinPath(parts ...string) string {
	return path.Join(parts...)
}
