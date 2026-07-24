package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	"nexora/config"
	"nexora/internal/db"
)

func main() {
	cfg := config.Load()
	pool := db.Connect(cfg.DatabaseURL)
	defer pool.Close()

	ctx := context.Background()

	// Aplicar as migrações de assinatura digital manualmente
	migrationsDir := "migrations"
	entries, err := os.ReadDir(migrationsDir)
	if err != nil {
		log.Fatalf("read dir: %v", err)
	}

	var files []string
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		if strings.HasPrefix(e.Name(), "20260701000114_") || strings.HasPrefix(e.Name(), "20260701000115_") || strings.HasPrefix(e.Name(), "20260701000116_") || strings.HasPrefix(e.Name(), "20260701000117_") || strings.HasPrefix(e.Name(), "20260701000118_") {
			if strings.HasSuffix(e.Name(), ".up.sql") {
				files = append(files, e.Name())
			}
		}
	}
	sort.Strings(files)

	for _, f := range files {
		var exists bool
		version := strings.Split(f, "_")[0]
		versionInt, err := strconv.ParseInt(version, 10, 64)
		if err != nil {
			log.Fatalf("invalid version %s: %v", version, err)
		}
		err = pool.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM schema_migrations WHERE version=$1)", versionInt).Scan(&exists)
		if err != nil {
			log.Fatalf("check version %s: %v", version, err)
		}
		if exists {
			log.Printf("[migrate] %s already applied", version)
			continue
		}

		content, err := os.ReadFile(filepath.Join(migrationsDir, f))
		if err != nil {
			log.Fatalf("read file %s: %v", f, err)
		}

		if _, err := pool.Exec(ctx, string(content)); err != nil {
			log.Fatalf("exec %s: %v", f, err)
		}

		// Registar migração aplicada
		if _, err := pool.Exec(ctx, "INSERT INTO schema_migrations (version, dirty) VALUES ($1, false)", versionInt); err != nil {
			log.Fatalf("register %s: %v", version, err)
		}
		log.Printf("[migrate] applied %s", f)
	}

	fmt.Println("Migrations applied successfully")
}
