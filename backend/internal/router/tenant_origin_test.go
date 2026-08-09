package router

import "testing"

func TestHostDaOrigem(t *testing.T) {
	validos := map[string]string{
		"https://acme.nexora.e258tech.tech": "acme.nexora.e258tech.tech",
		"http://localhost:8000":             "localhost:8000",
		"https://exemplo.com":               "exemplo.com",
	}
	for origem, esperado := range validos {
		got, err := hostDaOrigem(origem)
		if err != nil {
			t.Errorf("hostDaOrigem(%q) devolveu erro: %v", origem, err)
			continue
		}
		if got != esperado {
			t.Errorf("hostDaOrigem(%q) = %q, esperado %q", origem, got, esperado)
		}
	}

	// "null" é o que o browser envia de contextos opacos (sandbox, file://);
	// aceitá-lo abriria CORS a qualquer página.
	invalidos := []string{"", "null", "file:///etc/passwd", "javascript:alert(1)", "https://"}
	for _, origem := range invalidos {
		if _, err := hostDaOrigem(origem); err == nil {
			t.Errorf("hostDaOrigem(%q) devia falhar, mas passou", origem)
		}
	}
}
