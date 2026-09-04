// cmd/worker é o processo separado dos jobs recorrentes (dispatch de
// notificações, reminders, cálculos diários) — Fase 2, item 7, de
// docs/analise-transactional-outbox-backends.md. Primeiro daemon de longa
// duração do projecto: os restantes binários em backend/cmd/ são ferramentas
// CLI pontuais (migração, diagnóstico), não processos que ficam vivos.
//
// Corre exactamente o mesmo background.StartJobs que o processo da API já
// arranca por omissão — ver main.go e config.RunBackgroundJobs. Um operador
// que ligue este worker deve pôr RUN_BACKGROUND_JOBS=false na API para não
// terem os dois a despachar notificações em paralelo (não é inseguro, graças
// à reserva atómica em internal/background/jobs.go, só desperdiça trabalho).
package main

import (
	"context"
	"log"
	"os/signal"
	"syscall"

	"nexora/config"
	"nexora/internal/background"
	"nexora/internal/db"
	hardwareservice "nexora/internal/modules/hardware/service"
	"nexora/internal/pkg/nexorapay"
	"nexora/internal/push"
	"nexora/internal/shared/adapters"
	"nexora/internal/storage"
)

func main() {
	cfg := config.Load()
	if err := cfg.AssertProductionSecrets(); err != nil {
		log.Fatal(err)
	}
	pool := db.Connect(cfg.DatabaseURL)
	defer pool.Close()

	store, err := storage.New(storage.Config{
		Provider:          cfg.StorageProvider,
		LocalDir:          cfg.StorageLocalDir,
		PublicBaseURL:     cfg.StoragePublicURL,
		MinioEndpoint:     cfg.MinioEndpoint,
		MinioAccessKey:    cfg.MinioAccessKey,
		MinioSecretKey:    cfg.MinioSecretKey,
		MinioBucket:       cfg.MinioBucket,
		MinioUseSSL:       cfg.MinioUseSSL,
		MinioRegion:       cfg.MinioRegion,
		MinioBucketLookup: cfg.MinioBucketLookup,
	})
	if err != nil {
		log.Fatalf("[nexora-worker] storage init: %v", err)
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	paySvc := nexorapay.NewPaymentService(pool, nexorapay.NewClient(cfg.NexoraPayBaseURL, cfg.NexoraPayAPIKey, cfg.NexoraPayPublicKey))

	log.Println("[nexora-worker] a arrancar jobs em background")
	background.StartJobs(ctx, pool, adapters.NewNotificationAdapter(pool), push.New(pool, cfg.FirebaseCredentialsFile), paySvc, hardwareservice.NewProcessor(pool), cfg, store)

	<-ctx.Done()
	log.Println("[nexora-worker] sinal recebido, a parar")
}
