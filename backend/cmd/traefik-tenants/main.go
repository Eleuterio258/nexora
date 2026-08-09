// Comando traefik-tenants: gera a configuração dinâmica do Traefik com um
// router por domínio próprio de tenant, a partir de saas.tenant_dominios.
//
// O Traefik não lê a base de dados. Os domínios de tenant vivem lá, e é este
// comando que os transforma em rotas — escrevendo um ficheiro que o provider
// `file` do Traefik está a vigiar (`--providers.file.watch=true`), pelo que a
// recarga é automática e não é preciso reiniciar nada.
//
// Uso:
//
//	go run ./cmd/traefik-tenants -out /root/traefik/dynamic/tenants.yml -ip 209.126.86.55
//	go run ./cmd/traefik-tenants -out ... -ip ... -dry-run
//
// Pensado para correr periodicamente (cron/systemd timer) ou à mão depois de
// registar um domínio novo.
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// dominio é um domínio próprio de tenant e o veredicto sobre se pode ser
// servido a partir deste servidor.
type dominio struct {
	nome     string
	tenant   string
	aponta   bool
	apontaPa []string // para onde aponta de facto, quando não é para nós
	comWWW   bool     // se www.<nome> também vem para aqui
}

func main() {
	out := flag.String("out", "/root/traefik/dynamic/tenants.yml", "ficheiro de configuração dinâmica a escrever")
	ip := flag.String("ip", "", "IP público deste servidor (obrigatório): só se geram rotas para domínios que apontem para aqui")
	servico := flag.String("service", "e258tech", "serviço Traefik que serve os domínios de tenant")
	middlewares := flag.String("middlewares", "security-headers@file", "middlewares a aplicar, separados por vírgula")
	resolver := flag.String("certresolver", "le", "resolver ACME (le = TLS-01, um certificado por domínio)")
	dryRun := flag.Bool("dry-run", false, "mostra o que seria escrito, sem escrever")
	flag.Parse()

	if *ip == "" {
		log.Fatal("-ip é obrigatório: sem ele não há como saber que domínios este servidor pode servir")
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL não definido")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		log.Fatalf("ligar à base de dados: %v", err)
	}
	defer pool.Close()

	dominios, err := carregar(ctx, pool, *ip)
	if err != nil {
		log.Fatalf("carregar domínios: %v", err)
	}

	var servidos []dominio
	for _, d := range dominios {
		if d.aponta {
			servidos = append(servidos, d)
			log.Printf("  %-38s tenant %-24s → rota gerada", d.nome, d.tenant)
			continue
		}
		// Gerar a rota sem o DNS apontar para cá seria pedir um certificado
		// condenado a falhar: o Let's Encrypt valida ligando-se ao domínio, que
		// responderia noutro servidor. E falhas repetidas gastam o limite de
		// tentativas do domínio.
		log.Printf("  %-38s tenant %-24s → IGNORADO, aponta para %s",
			d.nome, d.tenant, strings.Join(d.apontaPa, ", "))
	}

	yaml := gerar(servidos, *servico, *middlewares, *resolver)

	if *dryRun {
		fmt.Print(yaml)
		log.Printf("dry-run: %d de %d domínios seriam servidos", len(servidos), len(dominios))
		return
	}

	alterado, err := escreverSeMudou(*out, yaml)
	if err != nil {
		log.Fatalf("escrever %s: %v", *out, err)
	}
	if alterado {
		log.Printf("%s actualizado — %d domínios; o Traefik recarrega sozinho", *out, len(servidos))
	} else {
		log.Printf("%s já estava correcto — nada a fazer", *out)
	}
}

// carregar lê os domínios dos tenants activos e verifica, para cada um, se o
// DNS o traz para este servidor.
func carregar(ctx context.Context, pool *pgxpool.Pool, ip string) ([]dominio, error) {
	rows, err := pool.Query(ctx, `
		SELECT d.dominio, t.codigo
		  FROM saas.tenant_dominios d
		  JOIN saas.tenants t ON t.id = d.tenant_id
		 WHERE t.status = 'ativo'
		 ORDER BY d.dominio`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []dominio
	for rows.Next() {
		var d dominio
		if err := rows.Scan(&d.nome, &d.tenant); err != nil {
			return nil, err
		}
		d.aponta, d.apontaPa = apontaPara(d.nome, ip)
		// O www só entra na regra se existir e vier para aqui. Pô-lo às cegas
		// faria o ACME pedir um certificado para os dois nomes e falhar
		// inteiro quando o www não resolve — deixando também o domínio
		// principal sem certificado.
		d.comWWW, _ = apontaPara("www."+d.nome, ip)
		out = append(out, d)
	}

	return out, rows.Err()
}

// apontaPara diz se o domínio resolve para o IP dado, devolvendo também os IPs
// encontrados para que a mensagem de diagnóstico seja útil.
func apontaPara(host, ip string) (bool, []string) {
	ips, err := net.LookupHost(host)
	if err != nil {
		return false, []string{"sem registo DNS"}
	}
	for _, encontrado := range ips {
		if encontrado == ip {
			return true, ips
		}
	}
	sort.Strings(ips)

	return false, ips
}

// gerar produz a configuração dinâmica. Cada domínio recebe o seu router e o
// seu certificado — o wildcard da plataforma não cobre domínios de terceiros.
func gerar(dominios []dominio, servico, middlewares, resolver string) string {
	var b strings.Builder

	b.WriteString("# GERADO POR `go run ./cmd/traefik-tenants` — NÃO EDITAR À MÃO.\n")
	b.WriteString("# A fonte é saas.tenant_dominios; qualquer alteração aqui é perdida\n")
	b.WriteString("# na próxima execução. Para acrescentar um domínio, registe-o na\n")
	b.WriteString("# base de dados e volte a correr o comando.\n")
	b.WriteString("http:\n  routers:\n")

	if len(dominios) == 0 {
		b.WriteString("    {}\n")
		return b.String()
	}

	var mws []string
	for _, m := range strings.Split(middlewares, ",") {
		if m = strings.TrimSpace(m); m != "" {
			mws = append(mws, m)
		}
	}

	for _, d := range dominios {
		nome := "tenant-" + strings.NewReplacer(".", "-", "*", "wildcard").Replace(d.nome)
		regra := fmt.Sprintf("Host(`%s`)", d.nome)
		if d.comWWW {
			regra += fmt.Sprintf(" || Host(`www.%s`)", d.nome)
		}
		fmt.Fprintf(&b, "    %s:\n", nome)
		fmt.Fprintf(&b, "      rule: \"%s\"\n", regra)
		b.WriteString("      entryPoints: [websecure]\n")
		fmt.Fprintf(&b, "      service: %s\n", servico)
		if len(mws) > 0 {
			fmt.Fprintf(&b, "      middlewares: [%s]\n", strings.Join(mws, ", "))
		}
		b.WriteString("      tls:\n")
		fmt.Fprintf(&b, "        certResolver: %s\n", resolver)
	}

	return b.String()
}

// escreverSeMudou grava o ficheiro apenas quando o conteúdo difere, para não
// provocar recargas do Traefik a cada execução do cron. A escrita é atómica:
// o Traefik está a vigiar o directório e não pode apanhar um ficheiro a meio.
func escreverSeMudou(caminho, conteudo string) (bool, error) {
	if actual, err := os.ReadFile(caminho); err == nil && string(actual) == conteudo {
		return false, nil
	}

	tmp, err := os.CreateTemp(filepath.Dir(caminho), ".tenants-*.yml")
	if err != nil {
		return false, err
	}
	defer os.Remove(tmp.Name())

	if _, err := tmp.WriteString(conteudo); err != nil {
		tmp.Close()
		return false, err
	}
	if err := tmp.Close(); err != nil {
		return false, err
	}
	if err := os.Chmod(tmp.Name(), 0o644); err != nil {
		return false, err
	}

	return true, os.Rename(tmp.Name(), caminho)
}
