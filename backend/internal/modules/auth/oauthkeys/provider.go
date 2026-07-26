// Package oauthkeys gere o par (ou pares, durante rotação) de chaves RSA que
// assinam os access tokens do Authorization Server OAuth2 (RS256). Segue o
// precedente de internal/modules/assinatura-digital/pki.DevProvider: chave
// persistida em ficheiro fora do controlo de versões, gerada na primeira
// utilização se o directório estiver vazio — mas ao contrário do provider de
// assinatura (uso interno, ECDSA, um único ficheiro), aqui cada chave é um
// ficheiro próprio nomeado pelo seu kid, para suportar rotação: uma chave
// nova assina tokens novos, chaves antigas continuam publicadas em
// /oauth/jwks até serem removidas manualmente, permitindo que tokens já
// emitidos com elas continuem verificáveis até expirarem.
package oauthkeys

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/hex"
	"encoding/pem"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

const keyBits = 2048

// Provider mantém em memória todas as chaves RSA carregadas de disco. Nunca
// cai num segredo por omissão inseguro (ao contrário de config.JWTSecret) —
// NewProvider falha explicitamente se não houver chave válida e a geração
// automática não tiver sido explicitamente autorizada.
type Provider struct {
	keys      map[string]*rsa.PrivateKey // kid -> chave privada
	activeKID string                     // kid da chave mais recente (mtime), usada para assinar
}

// NewProvider carrega todas as chaves *.pem de dir. Se dir estiver vazio (ou
// não existir), só gera uma chave nova quando allowGenerated=true — caso
// contrário falha, forçando quem arranca o processo em produção a reconhecer
// explicitamente que está a confiar numa chave auto-gerada localmente (mesmo
// padrão de reconhecimento explícito de config.SignatureAllowInsecureProvider).
func NewProvider(dir string, allowGenerated bool) (*Provider, error) {
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return nil, fmt.Errorf("oauthkeys: criar directório %q: %w", dir, err)
	}

	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, fmt.Errorf("oauthkeys: ler directório %q: %w", dir, err)
	}

	p := &Provider{keys: map[string]*rsa.PrivateKey{}}
	type keyFile struct {
		kid   string
		mtime int64
	}
	var loaded []keyFile

	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".pem") {
			continue
		}
		path := filepath.Join(dir, entry.Name())
		key, err := loadKey(path)
		if err != nil {
			return nil, fmt.Errorf("oauthkeys: carregar %q: %w", path, err)
		}
		kid := fingerprint(&key.PublicKey)
		p.keys[kid] = key
		info, err := entry.Info()
		if err != nil {
			return nil, fmt.Errorf("oauthkeys: stat %q: %w", path, err)
		}
		loaded = append(loaded, keyFile{kid: kid, mtime: info.ModTime().UnixNano()})
	}

	if len(loaded) == 0 {
		if !allowGenerated {
			return nil, fmt.Errorf(
				"oauthkeys: nenhuma chave em %q e geração automática desactivada — "+
					"gere uma chave (ver oauthkeys.GenerateAndSave) ou defina "+
					"OAUTH_ALLOW_GENERATED_KEY=true apenas fora de produção", dir)
		}
		key, kid, err := GenerateAndSave(dir)
		if err != nil {
			return nil, err
		}
		p.keys[kid] = key
		p.activeKID = kid
		return p, nil
	}

	sort.Slice(loaded, func(i, j int) bool { return loaded[i].mtime > loaded[j].mtime })
	p.activeKID = loaded[0].kid
	return p, nil
}

// GenerateAndSave cria uma nova chave RSA-2048, grava-a em dir/<kid>.pem
// (0o600) e devolve a chave e o seu kid. Usada tanto pelo arranque em modo
// "geração permitida" como por uma futura rotina de rotação manual.
func GenerateAndSave(dir string) (*rsa.PrivateKey, string, error) {
	key, err := rsa.GenerateKey(rand.Reader, keyBits)
	if err != nil {
		return nil, "", fmt.Errorf("oauthkeys: gerar chave: %w", err)
	}
	kid := fingerprint(&key.PublicKey)
	path := filepath.Join(dir, kid+".pem")
	if err := saveKey(path, key); err != nil {
		return nil, "", fmt.Errorf("oauthkeys: gravar %q: %w", path, err)
	}
	return key, kid, nil
}

func loadKey(path string) (*rsa.PrivateKey, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	block, _ := pem.Decode(data)
	if block == nil || block.Type != "RSA PRIVATE KEY" {
		return nil, fmt.Errorf("PEM inválido ou tipo inesperado (%v)", block)
	}
	return x509.ParsePKCS1PrivateKey(block.Bytes)
}

func saveKey(path string, key *rsa.PrivateKey) error {
	der := x509.MarshalPKCS1PrivateKey(key)
	buf := pem.EncodeToMemory(&pem.Block{Type: "RSA PRIVATE KEY", Bytes: der})
	return os.WriteFile(path, buf, 0o600)
}

// fingerprint deriva um kid determinístico e não sequencial a partir da
// chave pública (SHA256 truncado a 16 bytes, hex) — identifica a chave sem
// expor nada sobre a chave privada.
func fingerprint(pub *rsa.PublicKey) string {
	der, _ := x509.MarshalPKIXPublicKey(pub)
	sum := sha256.Sum256(der)
	return hex.EncodeToString(sum[:16])
}

// ActiveKID devolve o kid da chave usada para assinar novos tokens.
func (p *Provider) ActiveKID() string { return p.activeKID }

// SigningKey devolve a chave privada activa, para assinar novos tokens.
func (p *Provider) SigningKey() *rsa.PrivateKey { return p.keys[p.activeKID] }

// PublicKey devolve a chave pública associada a um kid, para verificação —
// usada pelo próprio ERP (RequireAuth) para validar tokens sem round-trip.
func (p *Provider) PublicKey(kid string) (*rsa.PublicKey, bool) {
	key, ok := p.keys[kid]
	if !ok {
		return nil, false
	}
	return &key.PublicKey, true
}

// KIDs devolve todos os kids conhecidos (activo + antigos ainda válidos),
// para publicar em /oauth/jwks.
func (p *Provider) KIDs() []string {
	out := make([]string, 0, len(p.keys))
	for kid := range p.keys {
		out = append(out, kid)
	}
	sort.Strings(out)
	return out
}
