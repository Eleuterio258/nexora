package router

import (
	"errors"
	"net/url"
	"strings"
)

// hostDaOrigem extrai o host de um cabeçalho Origin ("https://acme.exemplo.com").
// Só http e https contam: uma Origin com outro esquema — ou a literal "null",
// que os browsers enviam a partir de contextos opacos — não identifica um
// endereço de tenant e não deve abrir CORS.
func hostDaOrigem(origin string) (string, error) {
	origin = strings.TrimSpace(origin)
	if origin == "" || origin == "null" {
		return "", errors.New("origem vazia")
	}

	u, err := url.Parse(origin)
	if err != nil {
		return "", err
	}
	if u.Scheme != "https" && u.Scheme != "http" {
		return "", errors.New("esquema não suportado")
	}
	if u.Host == "" {
		return "", errors.New("origem sem host")
	}

	return u.Host, nil
}
