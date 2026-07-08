// Comando pontual: envia uma notificação push a todos os candidatos que
// submeteram pelo menos uma candidatura num tenant.
//
// Uso:
//
//	go run ./cmd/broadcast_push -tenant=5 -title="..." -body="..."
package main

import (
	"context"
	"flag"
	"fmt"
	"log"

	"nexora/config"
	"nexora/internal/db"
	"nexora/internal/push"
)

func main() {
	tenantID := flag.Int64("tenant", 0, "tenant_id cujos candidatos vão receber a notificação")
	title := flag.String("title", "", "título da notificação")
	body := flag.String("body", "", "corpo da notificação")
	flag.Parse()

	if *tenantID == 0 || *title == "" || *body == "" {
		log.Fatal("uso: go run ./cmd/broadcast_push -tenant=<id> -title=\"...\" -body=\"...\"")
	}

	cfg := config.Load()
	pool := db.Connect(cfg.DatabaseURL)
	defer pool.Close()

	pushSvc := push.New(pool, cfg.FirebaseCredentialsFile)

	ctx := context.Background()
	rows, err := pool.Query(ctx, `
		SELECT DISTINCT c.user_id
		  FROM recrutamento.candidaturas a
		  JOIN recrutamento.candidatos c ON c.id = a.candidato_id
		 WHERE a.tenant_id = $1 AND c.user_id IS NOT NULL`,
		*tenantID)
	if err != nil {
		log.Fatalf("erro ao consultar candidatos: %v", err)
	}
	defer rows.Close()

	var userIDs []int64
	for rows.Next() {
		var id int64
		if rows.Scan(&id) == nil {
			userIDs = append(userIDs, id)
		}
	}

	fmt.Printf("Candidatos encontrados no tenant %d: %d\n", *tenantID, len(userIDs))
	for _, id := range userIDs {
		pushSvc.SendToUser(ctx, id, *title, *body, map[string]string{
			"tipo": "broadcast_candidaturas",
		})
	}
	fmt.Println("Concluído.")
}
