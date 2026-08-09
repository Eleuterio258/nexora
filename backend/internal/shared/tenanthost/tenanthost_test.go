package tenanthost

import "testing"

func TestNormalizar(t *testing.T) {
	casos := map[string]string{
		"Acme.Nexora.E258tech.Tech":  "acme.nexora.e258tech.tech",
		"acme.nexora.e258tech.tech.": "acme.nexora.e258tech.tech",
		"www.exemplo.com":            "exemplo.com",
		"exemplo.com:8443":           "exemplo.com",
		"  exemplo.com  ":            "exemplo.com",
		"a.exemplo.com, proxy.local": "a.exemplo.com",
		"":                           "",
	}

	for entrada, esperado := range casos {
		if got := Normalizar(entrada); got != esperado {
			t.Errorf("Normalizar(%q) = %q, esperado %q", entrada, got, esperado)
		}
	}
}

func TestSubdominio(t *testing.T) {
	const base = "nexora.e258tech.tech"

	casos := []struct {
		host, esperado, porque string
	}{
		{"acme.nexora.e258tech.tech", "acme", "subdomínio directo"},
		{"nexora.e258tech.tech", "", "a própria base não é tenant"},
		{"api.nexora.e258tech.tech", "api", "um nível conta, mesmo sendo um serviço"},
		{"a.b.nexora.e258tech.tech", "", "dois níveis não contam"},
		{"outro.dominio.com", "", "fora da base"},
		{"", "", "host vazio"},
	}

	for _, c := range casos {
		if got := Subdominio(c.host, base); got != c.esperado {
			t.Errorf("Subdominio(%q) = %q, esperado %q (%s)", c.host, got, c.esperado, c.porque)
		}
	}

	if got := Subdominio("acme.qualquer.tech", ""); got != "" {
		t.Errorf("sem base configurada devia devolver \"\", devolveu %q", got)
	}
}
