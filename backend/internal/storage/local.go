package storage

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

// LocalProvider implementa Provider usando o sistema de ficheiros local.
type LocalProvider struct {
	baseDir       string
	publicBaseURL string
}

// NewLocalProvider cria um provider local.
// baseDir é o diretório raiz onde os ficheiros serão gravados (ex: ./uploads).
// publicBaseURL é o prefixo devolvido aos clientes (ex: http://localhost:8080/files).
func NewLocalProvider(baseDir, publicBaseURL string) (*LocalProvider, error) {
	baseDir = strings.TrimSpace(baseDir)
	if baseDir == "" {
		baseDir = "./uploads"
	}
	abs, err := filepath.Abs(baseDir)
	if err != nil {
		return nil, fmt.Errorf("local storage: %w", err)
	}
	if err := os.MkdirAll(abs, 0750); err != nil {
		return nil, fmt.Errorf("local storage: %w", err)
	}
	publicBaseURL = strings.TrimRight(publicBaseURL, "/")
	return &LocalProvider{baseDir: abs, publicBaseURL: publicBaseURL}, nil
}

// resolvePath devolve o caminho absoluto e garante que está dentro de baseDir.
func (p *LocalProvider) resolvePath(key string) (string, error) {
	key = NormalizeKey(key)
	if key == "" {
		return "", fmt.Errorf("local storage: key vazia")
	}
	abs, err := filepath.Abs(filepath.Join(p.baseDir, key))
	if err != nil {
		return "", err
	}
	if !strings.HasPrefix(abs, p.baseDir+string(filepath.Separator)) && abs != p.baseDir {
		return "", fmt.Errorf("local storage: key fora do diretorio base")
	}
	return abs, nil
}

// Put grava dados no disco.
func (p *LocalProvider) Put(ctx context.Context, key string, data []byte, contentType string) (string, error) {
	abs, err := p.resolvePath(key)
	if err != nil {
		return "", err
	}
	if err := os.MkdirAll(filepath.Dir(abs), 0750); err != nil {
		return "", err
	}
	if err := os.WriteFile(abs, data, 0640); err != nil {
		return "", err
	}
	return p.GetURL(ctx, key)
}

// Get devolve um reader para o ficheiro local.
func (p *LocalProvider) Get(ctx context.Context, key string) (io.ReadCloser, int64, error) {
	abs, err := p.resolvePath(key)
	if err != nil {
		return nil, 0, err
	}
	f, err := os.Open(abs)
	if err != nil {
		return nil, 0, err
	}
	stat, err := f.Stat()
	if err != nil {
		f.Close()
		return nil, 0, err
	}
	return f, stat.Size(), nil
}

// GetURL devolve URL pública para a key.
func (p *LocalProvider) GetURL(ctx context.Context, key string) (string, error) {
	key = NormalizeKey(key)
	if p.publicBaseURL != "" {
		return p.publicBaseURL + "/" + key, nil
	}
	return "/" + key, nil
}

// Delete remove o ficheiro.
func (p *LocalProvider) Delete(ctx context.Context, key string) error {
	abs, err := p.resolvePath(key)
	if err != nil {
		return err
	}
	return os.Remove(abs)
}

// Exists verifica se o ficheiro existe.
func (p *LocalProvider) Exists(ctx context.Context, key string) (bool, error) {
	abs, err := p.resolvePath(key)
	if err != nil {
		return false, err
	}
	_, err = os.Stat(abs)
	if os.IsNotExist(err) {
		return false, nil
	}
	return err == nil, err
}

// ServeHTTP serve ficheiros locais através de HTTP (útil para rota /files/*).
func (p *LocalProvider) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	key := strings.TrimPrefix(r.URL.Path, "/files/")
	key = NormalizeKey(key)
	abs, err := p.resolvePath(key)
	if err != nil || abs == "" {
		http.NotFound(w, r)
		return
	}
	f, err := os.Open(abs)
	if err != nil {
		http.NotFound(w, r)
		return
	}
	defer f.Close()
	stat, err := f.Stat()
	if err != nil {
		http.NotFound(w, r)
		return
	}
	http.ServeContent(w, r, stat.Name(), stat.ModTime(), f)
}
