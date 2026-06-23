package db

import (
	"context"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
)

func Connect(dsn string) *pgxpool.Pool {
	pool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		log.Fatalf("[db] connect: %v", err)
	}
	if err = pool.Ping(context.Background()); err != nil {
		log.Fatalf("[db] ping: %v", err)
	}
	log.Println("[db] connected")
	return pool
}
