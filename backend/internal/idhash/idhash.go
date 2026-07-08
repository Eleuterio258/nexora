// Package idhash obfuscates integer IDs for public URLs.
// Uses a bijective XOR + rotation cipher on 32-bit values so raw sequential
// database IDs are never exposed in browser URLs or API paths.
// The same algorithm is mirrored in PHP (IdHasher.php) using JWT_SECRET as salt.
package idhash

import (
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
)

// Hasher encodes/decodes integer IDs.
type Hasher struct {
	k1, k2 uint32
}

// New creates a Hasher from a shared secret string.
func New(secret string) *Hasher {
	h := sha256.Sum256([]byte("nexora:idhash:v1:" + secret))
	return &Hasher{
		k1: binary.BigEndian.Uint32(h[0:4]),
		k2: binary.BigEndian.Uint32(h[4:8]),
	}
}

// Encode turns a positive integer into a short opaque URL-safe string.
func (h *Hasher) Encode(id int64) string {
	if id <= 0 {
		return "0"
	}
	v := rotl32(uint32(id)^h.k1, 13) ^ h.k2
	return toBase36(uint64(v))
}

// Decode reverses Encode. Returns error on invalid input.
func (h *Hasher) Decode(s string) (int64, error) {
	if s == "0" || s == "" {
		return 0, nil
	}
	n, err := fromBase36(s)
	if err != nil {
		return 0, err
	}
	v := rotl32(uint32(n)^h.k2, 19) ^ h.k1
	return int64(v), nil
}

// decodeOrInt tries to decode as a hash; falls back to integer parsing.
// This allows backward compatibility during a gradual migration.
func (h *Hasher) decodeOrInt(s string) (int64, error) {
	if s == "" {
		return 0, errors.New("empty id")
	}
	if id, err := strconv.ParseInt(s, 10, 64); err == nil {
		return id, nil
	}
	return h.Decode(s)
}

// Middleware returns a chi middleware that transparently decodes hashed path
// and query-string params named "id" or ending in "_id".
// After this middleware, chi.URLParam(r, "id") and r.URL.Query().Get("vaga_id")
// return the decoded integer strings — handlers need no changes.
func (h *Hasher) Middleware() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Decode URL path params in chi route context.
			if rctx := chi.RouteContext(r.Context()); rctx != nil {
				for i, key := range rctx.URLParams.Keys {
					if !isIDKey(key) {
						continue
					}
					val := rctx.URLParams.Values[i]
					if _, err := strconv.ParseInt(val, 10, 64); err == nil {
						continue // already an integer
					}
					if decoded, err := h.Decode(val); err == nil && decoded > 0 {
						rctx.URLParams.Values[i] = strconv.FormatInt(decoded, 10)
					}
				}
			}

			// Decode query-string params ending in _id (e.g. vaga_id, customer_id).
			q := r.URL.Query()
			changed := false
			for key, vals := range q {
				if !isIDKey(key) {
					continue
				}
				for i, val := range vals {
					if _, err := strconv.ParseInt(val, 10, 64); err == nil {
						continue
					}
					if decoded, err := h.Decode(val); err == nil && decoded > 0 {
						q[key][i] = strconv.FormatInt(decoded, 10)
						changed = true
					}
				}
			}
			if changed {
				r.URL.RawQuery = q.Encode()
			}

			next.ServeHTTP(w, r)
		})
	}
}

func isIDKey(key string) bool {
	return key == "id" || strings.HasSuffix(key, "_id")
}

func rotl32(x uint32, n int) uint32 {
	return (x << uint(n)) | (x >> uint(32-n))
}

const base36Alphabet = "0123456789abcdefghijklmnopqrstuvwxyz"

func toBase36(n uint64) string {
	if n == 0 {
		return "0"
	}
	var buf [13]byte
	pos := len(buf)
	for n > 0 {
		pos--
		buf[pos] = base36Alphabet[n%36]
		n /= 36
	}
	return string(buf[pos:])
}

func fromBase36(s string) (uint64, error) {
	var n uint64
	for _, c := range s {
		idx := strings.IndexRune(base36Alphabet, c)
		if idx < 0 {
			return 0, fmt.Errorf("invalid char %q in id hash", c)
		}
		n = n*36 + uint64(idx)
	}
	return n, nil
}
