package migrations_test

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
)

// TestAssinaturaDigitalHardening aplica a migration num schema isolado.
//
// O teste é opt-in porque precisa de PostgreSQL real (triggers, FKs compostas
// e constraints não são exercitados por pgxmock):
//
//	TEST_DATABASE_URL=postgres://... go test ./migrations -run Hardening
func TestAssinaturaDigitalHardening(t *testing.T) {
	up := readMigration(t, "20260724000001_assinatura_digital_fase1_hardening.up.sql")
	down := readMigration(t, "20260724000001_assinatura_digital_fase1_hardening.down.sql")

	databaseURL := os.Getenv("TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("TEST_DATABASE_URL não configurada; teste de integração PostgreSQL ignorado")
	}

	ctx := context.Background()
	conn, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		t.Fatalf("ligar ao PostgreSQL: %v", err)
	}
	defer conn.Close(ctx)

	schema := fmt.Sprintf("assdig_hardening_test_%d", time.Now().UnixNano())
	if _, err := conn.Exec(ctx, "CREATE SCHEMA "+schema); err != nil {
		t.Fatalf("criar schema de teste: %v", err)
	}
	defer func() {
		_, _ = conn.Exec(context.Background(), "DROP SCHEMA "+schema+" CASCADE")
	}()

	setup := fmt.Sprintf(`
		CREATE TABLE %[1]s.documentos (
			id BIGSERIAL PRIMARY KEY,
			tenant_id BIGINT NOT NULL,
			status VARCHAR(30) NOT NULL DEFAULT 'rascunho',
			updated_at TIMESTAMPTZ DEFAULT NOW(),
			CONSTRAINT documentos_status_check
				CHECK (status IN ('rascunho','pendente','assinado','cancelado','expirado'))
		);
		CREATE TABLE %[1]s.signatarios (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT signatarios_documento_id_fkey
				REFERENCES %[1]s.documentos(id) ON DELETE CASCADE,
			tenant_id BIGINT NOT NULL
		);
		CREATE TABLE %[1]s.versoes_assinadas (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT versoes_assinadas_documento_id_fkey
				REFERENCES %[1]s.documentos(id) ON DELETE CASCADE,
			tenant_id BIGINT NOT NULL,
			signatario_id BIGINT
				CONSTRAINT versoes_assinadas_signatario_id_fkey
				REFERENCES %[1]s.signatarios(id),
			hash_sha256 VARCHAR(64)
		);
		CREATE TABLE %[1]s.logs (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT logs_documento_id_fkey REFERENCES %[1]s.documentos(id),
			tenant_id BIGINT NOT NULL,
			signatario_id BIGINT
				CONSTRAINT logs_signatario_id_fkey REFERENCES %[1]s.signatarios(id)
		);
		CREATE TABLE %[1]s.convites (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT convites_documento_id_fkey REFERENCES %[1]s.documentos(id),
			signatario_id BIGINT NOT NULL
				CONSTRAINT convites_signatario_id_fkey REFERENCES %[1]s.signatarios(id),
			tenant_id BIGINT NOT NULL
		);
		CREATE TABLE %[1]s.validacoes (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT validacoes_documento_id_fkey
				REFERENCES %[1]s.documentos(id) ON DELETE CASCADE,
			tenant_id BIGINT NOT NULL,
			versao_id BIGINT
				CONSTRAINT validacoes_versao_id_fkey REFERENCES %[1]s.versoes_assinadas(id)
		);
	`, schema)
	if _, err := conn.Exec(ctx, setup); err != nil {
		t.Fatalf("preparar schema legado: %v", err)
	}

	up = strings.ReplaceAll(up, "assinatura_digital", schema)
	if _, err := conn.Exec(ctx, up); err != nil {
		t.Fatalf("aplicar migration up: %v", err)
	}

	var documentoID, signatarioID, versaoID int64
	if err := conn.QueryRow(ctx,
		"INSERT INTO "+schema+".documentos (tenant_id, status) VALUES (10, 'parcialmente_assinado') RETURNING id",
	).Scan(&documentoID); err != nil {
		t.Fatalf("estado parcialmente_assinado não aceite: %v", err)
	}
	if err := conn.QueryRow(ctx,
		"INSERT INTO "+schema+".signatarios (documento_id, tenant_id) VALUES ($1, 10) RETURNING id",
		documentoID,
	).Scan(&signatarioID); err != nil {
		t.Fatalf("inserir signatário válido: %v", err)
	}
	if err := conn.QueryRow(ctx,
		"INSERT INTO "+schema+".versoes_assinadas (documento_id, tenant_id, signatario_id) VALUES ($1, 10, $2) RETURNING id",
		documentoID, signatarioID,
	).Scan(&versaoID); err != nil {
		t.Fatalf("inserir versão válida: %v", err)
	}

	assertExecFails(t, conn, ctx,
		"INSERT INTO "+schema+".signatarios (documento_id, tenant_id) VALUES ($1, 99)",
		documentoID,
	)
	assertExecFails(t, conn, ctx,
		"UPDATE "+schema+".versoes_assinadas SET hash_sha256='alterado' WHERE id=$1",
		versaoID,
	)
	assertExecFails(t, conn, ctx,
		"INSERT INTO "+schema+".versoes_assinadas (documento_id, tenant_id, signatario_id) VALUES ($1, 10, $2)",
		documentoID, signatarioID,
	)

	var validacaoID int64
	if err := conn.QueryRow(ctx,
		"INSERT INTO "+schema+".validacoes (documento_id, tenant_id, versao_id) VALUES ($1, 10, $2) RETURNING id",
		documentoID, versaoID,
	).Scan(&validacaoID); err != nil {
		t.Fatalf("inserir validação válida: %v", err)
	}
	assertExecFails(t, conn, ctx,
		"DELETE FROM "+schema+".validacoes WHERE id=$1",
		validacaoID,
	)
	assertExecFails(t, conn, ctx,
		"DELETE FROM "+schema+".documentos WHERE id=$1",
		documentoID,
	)

	down = strings.ReplaceAll(down, "assinatura_digital", schema)
	if _, err := conn.Exec(ctx, down); err != nil {
		t.Fatalf("aplicar migration down: %v", err)
	}

	if _, err := conn.Exec(ctx,
		"UPDATE "+schema+".versoes_assinadas SET hash_sha256='permitido-apos-down' WHERE id=$1",
		versaoID,
	); err != nil {
		t.Fatalf("trigger append-only permaneceu após down: %v", err)
	}
}

// TestAssinaturaDigitalFase0Estabilizacao aplica a migration de Fase 0 sobre
// o schema já endurecido pela Fase 1 e confirma que os novos estados são
// aceites e que o down reverte para a constraint anterior sem deixar dados
// incompatíveis (ver TestAssinaturaDigitalHardening para o porquê de ser
// opt-in via TEST_DATABASE_URL).
func TestAssinaturaDigitalFase0Estabilizacao(t *testing.T) {
	fase1Up := readMigration(t, "20260724000001_assinatura_digital_fase1_hardening.up.sql")
	fase0Up := readMigration(t, "20260724000002_assinatura_digital_fase0_estabilizacao.up.sql")
	fase0Down := readMigration(t, "20260724000002_assinatura_digital_fase0_estabilizacao.down.sql")

	databaseURL := os.Getenv("TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("TEST_DATABASE_URL não configurada; teste de integração PostgreSQL ignorado")
	}

	ctx := context.Background()
	conn, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		t.Fatalf("ligar ao PostgreSQL: %v", err)
	}
	defer conn.Close(ctx)

	schema := fmt.Sprintf("assdig_fase0_test_%d", time.Now().UnixNano())
	if _, err := conn.Exec(ctx, "CREATE SCHEMA "+schema); err != nil {
		t.Fatalf("criar schema de teste: %v", err)
	}
	defer func() {
		_, _ = conn.Exec(context.Background(), "DROP SCHEMA "+schema+" CASCADE")
	}()

	setup := fmt.Sprintf(`
		CREATE TABLE %[1]s.documentos (
			id BIGSERIAL PRIMARY KEY,
			tenant_id BIGINT NOT NULL,
			status VARCHAR(30) NOT NULL DEFAULT 'rascunho',
			updated_at TIMESTAMPTZ DEFAULT NOW(),
			CONSTRAINT documentos_status_check
				CHECK (status IN ('rascunho','pendente','assinado','cancelado','expirado'))
		);
		CREATE TABLE %[1]s.signatarios (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT signatarios_documento_id_fkey
				REFERENCES %[1]s.documentos(id) ON DELETE CASCADE,
			tenant_id BIGINT NOT NULL,
			status VARCHAR(30) NOT NULL DEFAULT 'pendente'
				CONSTRAINT signatarios_status_check
				CHECK (status IN ('pendente','convidado','assinado','recusado'))
		);
		CREATE TABLE %[1]s.versoes_assinadas (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT versoes_assinadas_documento_id_fkey
				REFERENCES %[1]s.documentos(id) ON DELETE CASCADE,
			tenant_id BIGINT NOT NULL,
			signatario_id BIGINT
				CONSTRAINT versoes_assinadas_signatario_id_fkey
				REFERENCES %[1]s.signatarios(id),
			hash_sha256 VARCHAR(64)
		);
		CREATE TABLE %[1]s.logs (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT logs_documento_id_fkey REFERENCES %[1]s.documentos(id),
			tenant_id BIGINT NOT NULL,
			signatario_id BIGINT
				CONSTRAINT logs_signatario_id_fkey REFERENCES %[1]s.signatarios(id)
		);
		CREATE TABLE %[1]s.convites (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT convites_documento_id_fkey REFERENCES %[1]s.documentos(id),
			signatario_id BIGINT NOT NULL
				CONSTRAINT convites_signatario_id_fkey REFERENCES %[1]s.signatarios(id),
			tenant_id BIGINT NOT NULL
		);
		CREATE TABLE %[1]s.validacoes (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT validacoes_documento_id_fkey
				REFERENCES %[1]s.documentos(id) ON DELETE CASCADE,
			tenant_id BIGINT NOT NULL,
			versao_id BIGINT
				CONSTRAINT validacoes_versao_id_fkey REFERENCES %[1]s.versoes_assinadas(id)
		);
	`, schema)
	if _, err := conn.Exec(ctx, setup); err != nil {
		t.Fatalf("preparar schema legado: %v", err)
	}

	fase1Up = strings.ReplaceAll(fase1Up, "assinatura_digital", schema)
	if _, err := conn.Exec(ctx, fase1Up); err != nil {
		t.Fatalf("aplicar migration fase1 up: %v", err)
	}

	fase0Up = strings.ReplaceAll(fase0Up, "assinatura_digital", schema)
	if _, err := conn.Exec(ctx, fase0Up); err != nil {
		t.Fatalf("aplicar migration fase0 up: %v", err)
	}

	var documentoID int64
	if err := conn.QueryRow(ctx,
		"INSERT INTO "+schema+".documentos (tenant_id, status) VALUES (10, 'aceite_eletronicamente') RETURNING id",
	).Scan(&documentoID); err != nil {
		t.Fatalf("estado aceite_eletronicamente não aceite em documentos: %v", err)
	}
	var signatarioID int64
	if err := conn.QueryRow(ctx,
		"INSERT INTO "+schema+".signatarios (documento_id, tenant_id, status) VALUES ($1, 10, 'aceite_eletronicamente') RETURNING id",
		documentoID,
	).Scan(&signatarioID); err != nil {
		t.Fatalf("estado aceite_eletronicamente não aceite em signatarios: %v", err)
	}

	assertExecFails(t, conn, ctx,
		"UPDATE "+schema+".documentos SET status='estado_inexistente' WHERE id=$1",
		documentoID,
	)

	fase0Down = strings.ReplaceAll(fase0Down, "assinatura_digital", schema)
	if _, err := conn.Exec(ctx, fase0Down); err != nil {
		t.Fatalf("aplicar migration fase0 down: %v", err)
	}

	var statusAposDown string
	if err := conn.QueryRow(ctx,
		"SELECT status FROM "+schema+".documentos WHERE id=$1", documentoID,
	).Scan(&statusAposDown); err != nil {
		t.Fatalf("ler documento após down: %v", err)
	}
	if statusAposDown != "assinado" {
		t.Fatalf("esperava conversão defensiva para 'assinado' após down, obteve %q", statusAposDown)
	}

	assertExecFails(t, conn, ctx,
		"INSERT INTO "+schema+".documentos (tenant_id, status) VALUES (10, 'aceite_eletronicamente')",
	)
}

// TestAssinaturaDigitalLogsAppendOnly confirma que a migration
// 20260724000003 torna assinatura_digital.logs append-only (tal como
// versoes_assinadas e validacoes já ficaram na Fase 1) e que o down reverte
// esse comportamento.
func TestAssinaturaDigitalLogsAppendOnly(t *testing.T) {
	fase1Up := readMigration(t, "20260724000001_assinatura_digital_fase1_hardening.up.sql")
	logsUp := readMigration(t, "20260724000003_assinatura_digital_fase1_logs_append_only.up.sql")
	logsDown := readMigration(t, "20260724000003_assinatura_digital_fase1_logs_append_only.down.sql")

	databaseURL := os.Getenv("TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("TEST_DATABASE_URL não configurada; teste de integração PostgreSQL ignorado")
	}

	ctx := context.Background()
	conn, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		t.Fatalf("ligar ao PostgreSQL: %v", err)
	}
	defer conn.Close(ctx)

	schema := fmt.Sprintf("assdig_logs_test_%d", time.Now().UnixNano())
	if _, err := conn.Exec(ctx, "CREATE SCHEMA "+schema); err != nil {
		t.Fatalf("criar schema de teste: %v", err)
	}
	defer func() {
		_, _ = conn.Exec(context.Background(), "DROP SCHEMA "+schema+" CASCADE")
	}()

	setup := fmt.Sprintf(`
		CREATE TABLE %[1]s.documentos (
			id BIGSERIAL PRIMARY KEY,
			tenant_id BIGINT NOT NULL,
			status VARCHAR(30) NOT NULL DEFAULT 'rascunho',
			updated_at TIMESTAMPTZ DEFAULT NOW(),
			CONSTRAINT documentos_status_check
				CHECK (status IN ('rascunho','pendente','assinado','cancelado','expirado'))
		);
		CREATE TABLE %[1]s.signatarios (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT signatarios_documento_id_fkey
				REFERENCES %[1]s.documentos(id) ON DELETE CASCADE,
			tenant_id BIGINT NOT NULL
		);
		CREATE TABLE %[1]s.versoes_assinadas (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT versoes_assinadas_documento_id_fkey
				REFERENCES %[1]s.documentos(id) ON DELETE CASCADE,
			tenant_id BIGINT NOT NULL,
			signatario_id BIGINT
				CONSTRAINT versoes_assinadas_signatario_id_fkey
				REFERENCES %[1]s.signatarios(id),
			hash_sha256 VARCHAR(64)
		);
		CREATE TABLE %[1]s.logs (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT logs_documento_id_fkey REFERENCES %[1]s.documentos(id),
			tenant_id BIGINT NOT NULL,
			signatario_id BIGINT
				CONSTRAINT logs_signatario_id_fkey REFERENCES %[1]s.signatarios(id),
			acao VARCHAR(50)
		);
		CREATE TABLE %[1]s.convites (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT convites_documento_id_fkey REFERENCES %[1]s.documentos(id),
			signatario_id BIGINT NOT NULL
				CONSTRAINT convites_signatario_id_fkey REFERENCES %[1]s.signatarios(id),
			tenant_id BIGINT NOT NULL
		);
		CREATE TABLE %[1]s.validacoes (
			id BIGSERIAL PRIMARY KEY,
			documento_id BIGINT NOT NULL
				CONSTRAINT validacoes_documento_id_fkey
				REFERENCES %[1]s.documentos(id) ON DELETE CASCADE,
			tenant_id BIGINT NOT NULL,
			versao_id BIGINT
				CONSTRAINT validacoes_versao_id_fkey REFERENCES %[1]s.versoes_assinadas(id)
		);
	`, schema)
	if _, err := conn.Exec(ctx, setup); err != nil {
		t.Fatalf("preparar schema legado: %v", err)
	}

	fase1Up = strings.ReplaceAll(fase1Up, "assinatura_digital", schema)
	if _, err := conn.Exec(ctx, fase1Up); err != nil {
		t.Fatalf("aplicar migration fase1 up: %v", err)
	}

	logsUp = strings.ReplaceAll(logsUp, "assinatura_digital", schema)
	if _, err := conn.Exec(ctx, logsUp); err != nil {
		t.Fatalf("aplicar migration logs append-only up: %v", err)
	}

	var documentoID, logID int64
	if err := conn.QueryRow(ctx,
		"INSERT INTO "+schema+".documentos (tenant_id, status) VALUES (10, 'pendente') RETURNING id",
	).Scan(&documentoID); err != nil {
		t.Fatalf("inserir documento: %v", err)
	}
	if err := conn.QueryRow(ctx,
		"INSERT INTO "+schema+".logs (documento_id, tenant_id, acao) VALUES ($1, 10, 'criado') RETURNING id",
		documentoID,
	).Scan(&logID); err != nil {
		t.Fatalf("inserir log: %v", err)
	}

	assertExecFails(t, conn, ctx,
		"UPDATE "+schema+".logs SET acao='alterado' WHERE id=$1", logID,
	)
	assertExecFails(t, conn, ctx,
		"DELETE FROM "+schema+".logs WHERE id=$1", logID,
	)

	logsDown = strings.ReplaceAll(logsDown, "assinatura_digital", schema)
	if _, err := conn.Exec(ctx, logsDown); err != nil {
		t.Fatalf("aplicar migration logs append-only down: %v", err)
	}

	if _, err := conn.Exec(ctx,
		"UPDATE "+schema+".logs SET acao='permitido-apos-down' WHERE id=$1", logID,
	); err != nil {
		t.Fatalf("trigger append-only permaneceu após down: %v", err)
	}
}

func readMigration(t *testing.T, name string) string {
	t.Helper()
	data, err := os.ReadFile(filepath.Join(".", name))
	if err != nil {
		t.Fatalf("ler %s: %v", name, err)
	}
	return string(data)
}

func assertExecFails(t *testing.T, conn *pgx.Conn, ctx context.Context, query string, args ...any) {
	t.Helper()
	if _, err := conn.Exec(ctx, query, args...); err == nil {
		t.Fatalf("operação deveria ter sido rejeitada: %s", query)
	}
}
