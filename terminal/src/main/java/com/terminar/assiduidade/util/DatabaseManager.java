package com.terminar.assiduidade.util;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.exception.AssiduidadeException;
import lombok.extern.slf4j.Slf4j;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
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

        if (!columnExists(stmt, "employee", "qr_totp_secret")) {
            log.info("A adicionar coluna employee.qr_totp_secret a uma base de dados existente.");
            stmt.execute("ALTER TABLE employee ADD COLUMN qr_totp_secret TEXT");
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
