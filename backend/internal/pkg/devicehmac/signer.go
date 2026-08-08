package devicehmac

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
)

// Signer mantém as credenciais fixas de um device e assina pedidos.
type Signer struct {
	AccessKeyID     string
	SecretAccessKey string
	AuthVersion     string
}

// New cria um signer com as credenciais fornecidas.
func New(accessKeyID, secretAccessKey string) *Signer {
	authVersion := DefaultAuthVersion
	if accessKeyID == "" || secretAccessKey == "" {
		return nil
	}
	return &Signer{
		AccessKeyID:     accessKeyID,
		SecretAccessKey: secretAccessKey,
		AuthVersion:     authVersion,
	}
}

// Sign assina um pedido HTTP e devolve os headers a adicionar.
// path deve ser o caminho absoluto (ex.: /api/hardware/events/generic).
// query pode ser vazio ou a query string raw (sem o ? inicial).
func (s *Signer) Sign(method, path, query string, payload any) (map[string]string, error) {
	body, err := SerializeBody(payload)
	if err != nil {
		return nil, fmt.Errorf("serializar body: %w", err)
	}
	return s.SignBytes(method, path, query, body), nil
}

// SignBytes assina um body já serializado.
func (s *Signer) SignBytes(method, path, query string, body []byte) map[string]string {
	bodyHash := sha256Hash(body)
	timestamp := strconv.FormatInt(time.Now().Unix(), 10)
	nonce := uuid.New().String()

	canonical := canonicalString(method, path, query, timestamp, nonce, bodyHash)
	signature := hmacSHA256(s.SecretAccessKey, canonical)

	return map[string]string{
		AccessKeyHeader:     s.AccessKeyID,
		TimestampHeader:     timestamp,
		NonceHeader:         nonce,
		ContentSHA256Header: bodyHash,
		SignatureHeader:     signature,
		AuthVersionHeader:   s.AuthVersion,
	}
}

// SerializeBody converte um payload em JSON determinístico.
func SerializeBody(payload any) ([]byte, error) {
	if payload == nil {
		return []byte{}, nil
	}
	switch v := payload.(type) {
	case []byte:
		return v, nil
	case string:
		return []byte(v), nil
	}
	var raw any
	buf, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}
	if err := json.Unmarshal(buf, &raw); err != nil {
		return nil, err
	}
	return marshalSorted(raw), nil
}

func marshalSorted(v any) []byte {
	var b strings.Builder
	writeSorted(&b, v)
	return []byte(b.String())
}

func writeSorted(b *strings.Builder, v any) {
	switch val := v.(type) {
	case nil:
		b.WriteString("null")
	case bool:
		b.WriteString(strconv.FormatBool(val))
	case float64:
		b.WriteString(strconv.FormatFloat(val, 'f', -1, 64))
	case string:
		b.WriteString(marshalString(val))
	case []any:
		b.WriteByte('[')
		for i, item := range val {
			if i > 0 {
				b.WriteByte(',')
			}
			writeSorted(b, item)
		}
		b.WriteByte(']')
	case map[string]any:
		keys := make([]string, 0, len(val))
		for k := range val {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		b.WriteByte('{')
		for i, k := range keys {
			if i > 0 {
				b.WriteByte(',')
			}
			b.WriteString(marshalString(k))
			b.WriteByte(':')
			writeSorted(b, val[k])
		}
		b.WriteByte('}')
	default:
		buf, _ := json.Marshal(val)
		b.Write(buf)
	}
}

func marshalString(s string) string {
	buf, _ := json.Marshal(s)
	return string(buf)
}

func canonicalString(method, path, query, timestamp, nonce, bodyHash string) string {
	return strings.Join([]string{
		strings.ToUpper(method),
		path,
		canonicalQueryString(query),
		timestamp,
		nonce,
		bodyHash,
	}, "\n")
}

func canonicalQueryString(query string) string {
	if query == "" {
		return ""
	}
	values, err := url.ParseQuery(query)
	if err != nil {
		return ""
	}

	keys := make([]string, 0, len(values))
	for k := range values {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	var parts []string
	for _, k := range keys {
		vals := values[k]
		sort.Strings(vals)
		for _, v := range vals {
			parts = append(parts, fmt.Sprintf("%s=%s", url.QueryEscape(k), url.QueryEscape(v)))
		}
	}
	return strings.Join(parts, "&")
}

func sha256Hash(data []byte) string {
	sum := sha256.Sum256(data)
	return hex.EncodeToString(sum[:])
}

func hmacSHA256(secret, message string) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(message))
	return hex.EncodeToString(mac.Sum(nil))
}
