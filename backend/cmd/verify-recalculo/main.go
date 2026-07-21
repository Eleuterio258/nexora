// Comando one-off: verifica que assiduidade.RecalcularDia funciona
// end-to-end sobre dados reais migrados por cmd/migrate-presencas-eventos.
//
// Uso:
//
//	DATABASE_URL=postgres://... go run ./cmd/verify-recalculo <tenant_id> <funcionario_id> <data:2006-01-02>
package main

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"strconv"
	"time"

	"nexora/config"
	"nexora/internal/db"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
)

func main() {
	if len(os.Args) != 4 {
		log.Fatal("uso: verify-recalculo <tenant_id> <funcionario_id> <data:2006-01-02>")
	}
	tenantID, err := strconv.ParseInt(os.Args[1], 10, 64)
	if err != nil {
		log.Fatalf("tenant_id inválido: %v", err)
	}
	funcionarioID, err := strconv.ParseInt(os.Args[2], 10, 64)
	if err != nil {
		log.Fatalf("funcionario_id inválido: %v", err)
	}
	data, err := time.Parse("2006-01-02", os.Args[3])
	if err != nil {
		log.Fatalf("data inválida: %v", err)
	}

	cfg := config.Load()
	pool := db.Connect(cfg.DatabaseURL)
	defer pool.Close()

	svc := assiduidade.NewService(pool)
	resultado, err := svc.RecalcularDia(context.Background(), tenantID, funcionarioID, data)
	if err != nil {
		log.Fatalf("RecalcularDia: %v", err)
	}

	out, _ := json.MarshalIndent(resultado, "", "  ")
	log.Println(string(out))
}
