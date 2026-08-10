package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestGerar(t *testing.T) {
	yaml := gerar([]dominio{
		{nome: "exemplo.com", tenant: "acme", aponta: true, comWWW: true},
		{nome: "outro.co.mz", tenant: "beta", aponta: true, comWWW: false},
	}, "web", "security-headers@file", "le")

	deveConter := []string{
		"tenant-exemplo-com:",
		"Host(`exemplo.com`) || Host(`www.exemplo.com`)",
		"tenant-outro-co-mz:",
		"Host(`outro.co.mz`)",
		"certResolver: le",
		"service: web",
	}
	for _, s := range deveConter {
		if !strings.Contains(yaml, s) {
			t.Errorf("configuração gerada não contém %q\n%s", s, yaml)
		}
	}

	// Sem www no DNS, o nome não pode entrar na regra: o ACME pediria um
	// certificado para ele e falharia o pedido inteiro.
	if strings.Contains(yaml, "www.outro.co.mz") {
		t.Error("www.outro.co.mz não devia estar na regra — não aponta para o servidor")
	}
}

func TestGerarSemDominios(t *testing.T) {
	yaml := gerar(nil, "web", "", "le")
	if !strings.Contains(yaml, "routers:") || !strings.Contains(yaml, "{}") {
		t.Errorf("sem domínios devia gerar um mapa vazio válido, gerou:\n%s", yaml)
	}
	if strings.Contains(yaml, "middlewares:") {
		t.Error("não devia emitir middlewares quando a lista está vazia")
	}
}

func TestEscreverSeMudou(t *testing.T) {
	caminho := filepath.Join(t.TempDir(), "tenants.yml")

	alterado, err := escreverSeMudou(caminho, "conteudo-a")
	if err != nil || !alterado {
		t.Fatalf("primeira escrita: alterado=%v err=%v", alterado, err)
	}

	// Reescrever o mesmo conteúdo não pode tocar no ficheiro: o Traefik está
	// a vigiar o directório e recarregaria a cada passagem do cron.
	alterado, err = escreverSeMudou(caminho, "conteudo-a")
	if err != nil || alterado {
		t.Fatalf("conteúdo igual não devia reescrever: alterado=%v err=%v", alterado, err)
	}

	alterado, err = escreverSeMudou(caminho, "conteudo-b")
	if err != nil || !alterado {
		t.Fatalf("conteúdo diferente devia reescrever: alterado=%v err=%v", alterado, err)
	}

	lido, err := os.ReadFile(caminho)
	if err != nil || string(lido) != "conteudo-b" {
		t.Fatalf("ficheiro final = %q, err=%v", string(lido), err)
	}

	// A escrita é atómica via ficheiro temporário; nenhum deve sobrar.
	entradas, _ := os.ReadDir(filepath.Dir(caminho))
	for _, e := range entradas {
		if strings.HasPrefix(e.Name(), ".tenants-") {
			t.Errorf("ficheiro temporário não foi removido: %s", e.Name())
		}
	}
}
