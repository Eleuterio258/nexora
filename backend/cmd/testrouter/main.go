package main

import (
	"fmt"
	"os"

	"nexora/config"
	"nexora/internal/router"
)

func main() {
	cfg := &config.Config{
		JWTSecret:        "test-secret-32-characters-long!!",
		JWTRefreshSecret: "refresh-secret-32-characters-long!!",
		CORSOrigin:       "*",
		// Só um smoke test local de construção do router — não é produção.
		SignatureAllowInsecureProvider: true,
	}

	defer func() {
		if r := recover(); r != nil {
			fmt.Fprintf(os.Stderr, "PANIC: %v\n", r)
			os.Exit(1)
		}
	}()

	_ = router.New(nil, cfg)
	fmt.Println("Router created successfully")
}
