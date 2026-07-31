// Comando pontual: testa o envio de email via AWS SES, sem subir o servidor.
//
// Uso:
//
//	go run ./cmd/send-test-email -to=alguem@exemplo.com
package main

import (
	"flag"
	"fmt"
	"log"

	"nexora/config"
	"nexora/internal/background"
)

func main() {
	to := flag.String("to", "", "endereço de destino")
	subject := flag.String("subject", "Teste Nexora ERP — AWS SES", "assunto do email")
	body := flag.String("body", "Este é um email de teste enviado via AWS SES.", "corpo do email")
	flag.Parse()

	if *to == "" {
		log.Fatal("uso: go run ./cmd/send-test-email -to=alguem@exemplo.com")
	}

	cfg := config.Load()
	if err := background.SendTestEmail(cfg, *to, *subject, *body); err != nil {
		log.Fatalf("falha ao enviar: %v", err)
	}
	fmt.Println("Email enviado com sucesso via SES.")
}
