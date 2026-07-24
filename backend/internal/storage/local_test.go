package storage

import (
	"context"
	"errors"
	"io"
	"sync"
	"testing"
)

func TestLocalProviderPutImmutable(t *testing.T) {
	provider, err := NewLocalProvider(t.TempDir(), "https://files.example")
	if err != nil {
		t.Fatalf("criar provider: %v", err)
	}

	ctx := context.Background()
	key := "assinatura-digital/1/hash.pdf"
	original := []byte("conteudo-original")

	url, err := provider.PutImmutable(ctx, key, original, "application/pdf")
	if err != nil {
		t.Fatalf("primeira gravação: %v", err)
	}
	if url != "https://files.example/"+key {
		t.Fatalf("URL inesperada: %s", url)
	}

	if _, err := provider.PutImmutable(ctx, key, original, "application/pdf"); err != nil {
		t.Fatalf("repetição idempotente: %v", err)
	}

	if _, err := provider.PutImmutable(ctx, key, []byte("conteudo-alterado"), "application/pdf"); !errors.Is(err, ErrImmutableObjectExists) {
		t.Fatalf("esperava ErrImmutableObjectExists, recebeu %v", err)
	}

	reader, _, err := provider.Get(ctx, key)
	if err != nil {
		t.Fatalf("ler objeto: %v", err)
	}
	defer reader.Close()
	actual, err := io.ReadAll(reader)
	if err != nil {
		t.Fatalf("ler conteúdo: %v", err)
	}
	if string(actual) != string(original) {
		t.Fatalf("objeto foi sobrescrito: %q", actual)
	}
}

func TestLocalProviderDeleteRecusaEvidencia(t *testing.T) {
	provider, err := NewLocalProvider(t.TempDir(), "")
	if err != nil {
		t.Fatalf("criar provider: %v", err)
	}

	ctx := context.Background()
	key := "assinatura-digital/1/hash.pdf"
	if _, err := provider.PutImmutable(ctx, key, []byte("evidencia"), "application/pdf"); err != nil {
		t.Fatalf("gravar evidência: %v", err)
	}

	if err := provider.Delete(ctx, key); !errors.Is(err, ErrEvidenceDeleteForbidden) {
		t.Fatalf("esperava ErrEvidenceDeleteForbidden, recebeu %v", err)
	}

	reader, _, err := provider.Get(ctx, key)
	if err != nil {
		t.Fatalf("evidência deveria continuar acessível: %v", err)
	}
	reader.Close()
}

func TestLocalProviderDeletePermiteChavesNormais(t *testing.T) {
	provider, err := NewLocalProvider(t.TempDir(), "")
	if err != nil {
		t.Fatalf("criar provider: %v", err)
	}

	ctx := context.Background()
	key := "avatares/1/foto.png"
	if _, err := provider.Put(ctx, key, []byte("foto"), "image/png"); err != nil {
		t.Fatalf("gravar ficheiro: %v", err)
	}
	if err := provider.Delete(ctx, key); err != nil {
		t.Fatalf("apagar ficheiro normal não deveria falhar: %v", err)
	}
}

func TestLocalProviderPutImmutableConcorrente(t *testing.T) {
	provider, err := NewLocalProvider(t.TempDir(), "")
	if err != nil {
		t.Fatalf("criar provider: %v", err)
	}

	ctx := context.Background()
	key := "assinatura-digital/1/concorrente.pdf"
	payloads := [][]byte{[]byte("versao-a"), []byte("versao-b")}
	errs := make([]error, len(payloads))

	var wg sync.WaitGroup
	for i := range payloads {
		wg.Add(1)
		go func(index int) {
			defer wg.Done()
			_, errs[index] = provider.PutImmutable(ctx, key, payloads[index], "application/pdf")
		}(i)
	}
	wg.Wait()

	successes := 0
	conflicts := 0
	for _, err := range errs {
		switch {
		case err == nil:
			successes++
		case errors.Is(err, ErrImmutableObjectExists):
			conflicts++
		default:
			t.Fatalf("erro concorrente inesperado: %v", err)
		}
	}
	if successes != 1 || conflicts != 1 {
		t.Fatalf("resultado inesperado: sucessos=%d conflitos=%d", successes, conflicts)
	}
}
