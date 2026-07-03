package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"path/filepath"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
	"nexora/internal/storage"
)

func main() {
	cfg := config.Load()

	src, err := storage.New(storage.Config{
		Provider:      "local",
		LocalDir:      cfg.UploadsDir,
		PublicBaseURL: cfg.StoragePublicURL,
	})
	if err != nil {
		log.Fatalf("storage local: %v", err)
	}

	dst, err := storage.New(storage.Config{
		Provider:       cfg.StorageProvider,
		LocalDir:       cfg.StorageLocalDir,
		PublicBaseURL:  cfg.StoragePublicURL,
		MinioEndpoint:  cfg.MinioEndpoint,
		MinioAccessKey: cfg.MinioAccessKey,
		MinioSecretKey: cfg.MinioSecretKey,
		MinioBucket:    cfg.MinioBucket,
		MinioUseSSL:    cfg.MinioUseSSL,
		MinioRegion:    cfg.MinioRegion,
	})
	if err != nil {
		log.Fatalf("storage destino: %v", err)
	}

	db, err := pgxpool.New(context.Background(), cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("db: %v", err)
	}
	defer db.Close()

	ctx := context.Background()

	// 1. Migrar CVs e cartas de candidaturas
	if err := migrarCandidaturas(ctx, db, src, dst); err != nil {
		log.Fatalf("migrar candidaturas: %v", err)
	}

	// 2. Migrar ficheiros custom de candidaturas
	if err := migrarCustom(ctx, db, src, dst); err != nil {
		log.Fatalf("migrar custom: %v", err)
	}

	// 3. Migrar respostas de vaga
	if err := migrarVagaRespostas(ctx, db, src, dst); err != nil {
		log.Fatalf("migrar vaga respostas: %v", err)
	}

	// 4. Migrar avatares
	if err := migrarAvatares(ctx, db, src, dst, cfg.AvatarDir); err != nil {
		log.Fatalf("migrar avatares: %v", err)
	}

	log.Println("Migracao concluida.")
}

func migrarCandidaturas(ctx context.Context, db *pgxpool.Pool, src, dst storage.Provider) error {
	rows, err := db.Query(ctx, `
		SELECT id, tenant_id, cv_ficheiro, carta_ficheiro
		FROM recrutamento.candidaturas
		WHERE cv_ficheiro IS NOT NULL OR carta_ficheiro IS NOT NULL
	`)
	if err != nil {
		return err
	}
	defer rows.Close()

	for rows.Next() {
		var id, tenantID int64
		var cv, carta *string
		if err := rows.Scan(&id, &tenantID, &cv, &carta); err != nil {
			return err
		}
		if cv != nil && *cv != "" {
			newKey, err := migrateFile(ctx, src, dst, *cv, tenantID)
			if err != nil {
				log.Printf("[cv] candidatura %d: %v", id, err)
			} else if newKey != *cv {
				_, _ = db.Exec(ctx, "UPDATE recrutamento.candidaturas SET cv_ficheiro=$1 WHERE id=$2", newKey, id)
			}
		}
		if carta != nil && *carta != "" {
			newKey, err := migrateFile(ctx, src, dst, *carta, tenantID)
			if err != nil {
				log.Printf("[carta] candidatura %d: %v", id, err)
			} else if newKey != *carta {
				_, _ = db.Exec(ctx, "UPDATE recrutamento.candidaturas SET carta_ficheiro=$1 WHERE id=$2", newKey, id)
			}
		}
	}
	return rows.Err()
}

func migrarCustom(ctx context.Context, db *pgxpool.Pool, src, dst storage.Provider) error {
	rows, err := db.Query(ctx, `
		SELECT cvc.id, c.tenant_id, cvc.ficheiro
		FROM recrutamento.candidatura_valores_custom cvc
		JOIN recrutamento.candidaturas c ON c.id = cvc.candidatura_id
		WHERE cvc.ficheiro IS NOT NULL AND cvc.ficheiro <> ''
	`)
	if err != nil {
		return err
	}
	defer rows.Close()

	for rows.Next() {
		var id, tenantID int64
		var ficheiro string
		if err := rows.Scan(&id, &tenantID, &ficheiro); err != nil {
			return err
		}
		newKey, err := migrateFile(ctx, src, dst, ficheiro, tenantID)
		if err != nil {
			log.Printf("[custom] id %d: %v", id, err)
		} else if newKey != ficheiro {
			_, _ = db.Exec(ctx, "UPDATE recrutamento.candidatura_valores_custom SET ficheiro=$1 WHERE id=$2", newKey, id)
		}
	}
	return rows.Err()
}

func migrarVagaRespostas(ctx context.Context, db *pgxpool.Pool, src, dst storage.Provider) error {
	rows, err := db.Query(ctx, `
		SELECT crv.id, c.tenant_id, crv.ficheiro
		FROM recrutamento.candidatura_respostas_vaga crv
		JOIN recrutamento.candidaturas c ON c.id = crv.candidatura_id
		WHERE crv.ficheiro IS NOT NULL AND crv.ficheiro <> ''
	`)
	if err != nil {
		return err
	}
	defer rows.Close()

	for rows.Next() {
		var id, tenantID int64
		var ficheiro string
		if err := rows.Scan(&id, &tenantID, &ficheiro); err != nil {
			return err
		}
		newKey, err := migrateFile(ctx, src, dst, ficheiro, tenantID)
		if err != nil {
			log.Printf("[vaga] id %d: %v", id, err)
		} else if newKey != ficheiro {
			_, _ = db.Exec(ctx, "UPDATE recrutamento.candidatura_respostas_vaga SET ficheiro=$1 WHERE id=$2", newKey, id)
		}
	}
	return rows.Err()
}

func migrarAvatares(ctx context.Context, db *pgxpool.Pool, src, dst storage.Provider, avatarDir string) error {
	rows, err := db.Query(ctx, `SELECT user_id, ficheiro_url FROM utilizadores.user_avatar`)
	if err != nil {
		return err
	}
	defer rows.Close()

	for rows.Next() {
		var userID int64
		var url string
		if err := rows.Scan(&userID, &url); err != nil {
			return err
		}
		// Ignorar URLs ja externas (ex: MinIO)
		if strings.HasPrefix(url, "http://") || strings.HasPrefix(url, "https://") {
			continue
		}
		filename := filepath.Base(url)
		oldKey := strings.TrimPrefix(url, "/")
		newKey := storage.JoinPath("avatars", fmt.Sprintf("user-%d", userID), filename)

		if err := copyObject(ctx, src, dst, oldKey, newKey); err != nil {
			log.Printf("[avatar] user %d: %v", userID, err)
			continue
		}
		newURL, _ := dst.GetURL(ctx, newKey)
		_, _ = db.Exec(ctx, "UPDATE utilizadores.user_avatar SET ficheiro_url=$1 WHERE user_id=$2", newURL, userID)
	}
	return rows.Err()
}

// migrateFile copia um ficheiro do storage local para o destino e devolve a nova key relativa.
func migrateFile(ctx context.Context, src, dst storage.Provider, oldRel string, tenantID int64) (string, error) {
	oldRel = strings.TrimPrefix(oldRel, "uploads/")
	oldRel = strings.TrimPrefix(oldRel, "/")
	oldKey := oldRel // provider local baseDir=./uploads, logo key=cv/nome.pdf
	newKey := storage.JoinPath("uploads", fmt.Sprintf("tenant-%d", tenantID), oldRel)

	if err := copyObject(ctx, src, dst, oldKey, newKey); err != nil {
		return oldRel, err
	}
	// Devolver path relativo retrocompativel (cv/nome.pdf)
	return oldRel, nil
}

func copyObject(ctx context.Context, src, dst storage.Provider, oldKey, newKey string) error {
	reader, size, err := src.Get(ctx, oldKey)
	if err != nil {
		return fmt.Errorf("ler origem %s: %w", oldKey, err)
	}
	defer reader.Close()

	data := make([]byte, size)
	if _, err := io.ReadFull(reader, data); err != nil {
		return fmt.Errorf("ler bytes %s: %w", oldKey, err)
	}

	contentType := "application/octet-stream"
	if strings.HasSuffix(newKey, ".pdf") {
		contentType = "application/pdf"
	} else if strings.HasSuffix(newKey, ".jpg") || strings.HasSuffix(newKey, ".jpeg") {
		contentType = "image/jpeg"
	} else if strings.HasSuffix(newKey, ".png") {
		contentType = "image/png"
	}

	_, err = dst.Put(ctx, newKey, data, contentType)
	if err != nil {
		return fmt.Errorf("escrever destino %s: %w", newKey, err)
	}
	return nil
}
