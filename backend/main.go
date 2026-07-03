package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"nexora/config"
	"nexora/internal/background"
	"nexora/internal/db"
	"nexora/internal/router"
	"nexora/internal/shared/adapters"
)

func main() {
	cfg := config.Load()
	pool := db.Connect(cfg.DatabaseURL)
	defer pool.Close()

	// Context para graceful shutdown de jobs em background
	ctx, cancelJobs := context.WithCancel(context.Background())
	defer cancelJobs()

	// Arrancar jobs recorrentes (notificações, reminders, etc.)
	background.StartJobs(ctx, pool, adapters.NewNotificationAdapter(pool), cfg)

	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      router.New(pool, cfg),
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		log.Printf("[nexora] listening on :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("[nexora] %v", err)
		}
	}()

	<-quit
	cancelJobs() // Parar jobs antes do shutdown
	shutCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	srv.Shutdown(shutCtx)
	log.Println("[nexora] stopped")
}
