package com.terminar.assiduidade.util;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.exception.AssiduidadeException;
import lombok.extern.slf4j.Slf4j;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
public class DatabaseManager {

    private static HikariDataSourceHolder dataSource;

    public static void initialize() {
        try {
            createDatabaseDirectory(AppConfig.getDatabaseUrl());
            dataSource = new HikariDataSourceHolder(AppConfig.getDatabaseUrl());
            createSchema();
            log.info("Base de dados inicializada.");
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao inicializar base de dados", e);
        }
    }

    private static void createDatabaseDirectory(String jdbcUrl) throws Exception {
        String prefix = "jdbc:sqlite:";
        if (jdbcUrl == null || !jdbcUrl.startsWith(prefix)) {
            return;
        }
        String databasePath = jdbcUrl.substring(prefix.length());
        if (databasePath.isBlank() || ":memory:".equals(databasePath)
            || databasePath.startsWith("file:")) {
            return;
        }
        Path parent = Path.of(databasePath).toAbsolutePath().normalize().getParent();
        if (parent != null) {
            Files.createDirectories(parent);
        }
    }

    public static Connection getConnection() throws SQLException {
        if (dataSource == null) {
            throw new AssiduidadeException("DataSource não inicializado");
        }
        return dataSource.getConnection();
    }

    private static void createSchema() throws SQLException {
        String schema = new BufferedReader(new InputStreamReader(
            DatabaseManager.class.getResourceAsStream("/db/schema.sql")))
            .lines().collect(Collectors.joining("\n"));

        try (Connection conn = getConnection(); Statement stmt = conn.createStatement()) {
            for (String sql : schema.split(";")) {
                String trimmed = sql.trim();
                if (!trimmed.isEmpty()) {
                    stmt.execute(trimmed);
                }
            }
            migrateSchema(stmt);
        }
    }

    /**
     * Ajustes que não podem ser expressos de forma idempotente em schema.sql — o SQLite não
     * suporta "ALTER TABLE ... ADD COLUMN IF NOT EXISTS", por isso a existência da coluna é
     * verificada em código antes de a adicionar a bases de dados criadas antes desta versão.
     */
    private static void migrateSchema(Statement stmt) throws SQLException {
        if (!columnExists(stmt, "employee", "nfc_uid")) {
            log.info("A adicionar coluna employee.nfc_uid a uma base de dados existente.");
            stmt.execute("ALTER TABLE employee ADD COLUMN nfc_uid TEXT");
        }
        stmt.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_employee_nfc_uid ON employee(nfc_uid)");

        // QR fixo do funcionário (Modo 1) — bases de dados criadas numa versão intermédia
        // desta app (Modo 2 ainda não existia, "Ver QR" tentou usar geração no ERP) ficaram
        // sem esta coluna; recuperá-la para o Modo 1 voltar a funcionar.
        if (!columnExists(stmt, "employee", "qr_code_token")) {
            log.info("A adicionar coluna employee.qr_code_token a uma base de dados existente.");
            stmt.execute("ALTER TABLE employee ADD COLUMN qr_code_token TEXT");
        }
        stmt.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_employee_qr_code_token ON employee(qr_code_token)");
        preencherQrCodeTokenEmFalta(stmt);

        // O terminal deixou de classificar a marcação como entrada/saída/pausa — o
        // ERP passa a interpretar isso a partir da sequência do dia. Bases de dados
        // criadas antes desta versão ainda têm a coluna "tipo"; removê-la em vez de
        // a deixar ali morta (SQLite 3.35+, incluído no driver deste projecto,
        // suporta DROP COLUMN).
        if (columnExists(stmt, "registo_ponto", "tipo")) {
            log.info("A remover coluna registo_ponto.tipo de uma base de dados existente.");
            stmt.execute("ALTER TABLE registo_ponto DROP COLUMN tipo");
        }
    }

    /**
     * "ALTER TABLE ADD COLUMN" não faz backfill — funcionários criados antes da coluna
     * qr_code_token existir (ou apanhados na janela em que esteve removida) ficam sem QR
     * fixo nenhum. Sem isto, abrir "Ver QR Code" (admin) para um deles rebentava com o
     * qr_code_token nulo em vez de mostrar um código válido.
     */
    private static void preencherQrCodeTokenEmFalta(Statement stmt) throws SQLException {
        try (ResultSet rs = stmt.executeQuery(
                "SELECT id FROM employee WHERE qr_code_token IS NULL OR qr_code_token = ''")) {
            java.util.List<Long> semToken = new java.util.ArrayList<>();
            while (rs.next()) {
                semToken.add(rs.getLong("id"));
            }
            if (semToken.isEmpty()) {
                return;
            }
            log.info("A atribuir qr_code_token a {} funcionário(s) sem QR fixo.", semToken.size());
            try (PreparedStatement ps = stmt.getConnection()
                    .prepareStatement("UPDATE employee SET qr_code_token = ? WHERE id = ?")) {
                for (Long id : semToken) {
                    ps.setString(1, UUID.randomUUID().toString());
                    ps.setLong(2, id);
                    ps.addBatch();
                }
                ps.executeBatch();
            }
        }
    }

    private static boolean columnExists(Statement stmt, String table, String column) throws SQLException {
        try (ResultSet rs = stmt.executeQuery("PRAGMA table_info(" + table + ")")) {
            while (rs.next()) {
                if (column.equalsIgnoreCase(rs.getString("name"))) {
                    return true;
                }
            }
        }
        return false;
    }

    public static void shutdown() {
        if (dataSource != null) {
            dataSource.close();
            dataSource = null;
        }
    }
}
