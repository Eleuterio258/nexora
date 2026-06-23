package com.factpro.core.database;

import com.factpro.config.AppConfig;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * Gestor de conexões à base de dados (singleton).
 * Suporta SQLite, MySQL e PostgreSQL via HikariCP.
 */
public class DatabaseManager {
    
    private static final Logger logger = LoggerFactory.getLogger(DatabaseManager.class);
    private static DatabaseManager instance;
    private HikariDataSource dataSource;
    private AppConfig.DatabaseType type;
    
    private DatabaseManager() {
        AppConfig config = AppConfig.getInstance();
        this.type = config.getDatabaseType();
        initializeDataSource();
    }
    
    /**
     * Retorna a instância singleton.
     */
    public static synchronized DatabaseManager getInstance() {
        if (instance == null) {
            instance = new DatabaseManager();
        }
        return instance;
    }
    
    /**
     * Inicializa o HikariCP conforme o tipo de base de dados.
     */
    private void initializeDataSource() {
        HikariConfig config = new HikariConfig();
        AppConfig appConfig = AppConfig.getInstance();

        switch (type) {
            case SQLITE:
                // Ensure data directory exists
                File dbFile = new File(appConfig.getSqlitePath());
                File parentDir = dbFile.getParentFile();
                if (parentDir != null && !parentDir.exists()) {
                    parentDir.mkdirs();
                    logger.info("Diretório da base de dados criado: {}", parentDir.getAbsolutePath());
                }
                config.setJdbcUrl("jdbc:sqlite:" + appConfig.getSqlitePath());
                config.setDriverClassName("org.sqlite.JDBC");
                // SQLite-specific
                config.addDataSourceProperty("journal_mode", "WAL");
                config.addDataSourceProperty("foreign_keys", "true");
                config.setMaximumPoolSize(5);
                break;
                
            case MYSQL:
                config.setJdbcUrl(String.format(
                    "jdbc:mysql://%s:%d/%s?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true",
                    appConfig.getDbHost(),
                    appConfig.getDbPort(),
                    appConfig.getDbName()
                ));
                config.setUsername(appConfig.getDbUser());
                config.setPassword(appConfig.getDbPassword());
                config.setDriverClassName("com.mysql.cj.jdbc.Driver");
                config.setMaximumPoolSize(20);
                config.addDataSourceProperty("cachePrepStmts", "true");
                config.addDataSourceProperty("prepStmtCacheSize", "250");
                break;
                
            case POSTGRESQL:
                config.setJdbcUrl(String.format(
                    "jdbc:postgresql://%s:%d/%s",
                    appConfig.getDbHost(),
                    appConfig.getDbPort(),
                    appConfig.getDbName()
                ));
                config.setUsername(appConfig.getDbUser());
                config.setPassword(appConfig.getDbPassword());
                config.setDriverClassName("org.postgresql.Driver");
                config.setMaximumPoolSize(20);
                config.addDataSourceProperty("cachePrepStmts", "true");
                config.addDataSourceProperty("prepStmtCacheSize", "250");
                config.addDataSourceProperty("reWriteBatchedInserts", "true");
                break;
        }
        
        config.setMinimumIdle(2);
        config.setIdleTimeout(600000);
        config.setMaxLifetime(1800000);
        config.setConnectionTimeout(30000);
        
        this.dataSource = new HikariDataSource(config);
        logger.info("Base de dados inicializada: {} (pool size: {})", 
            type, config.getMaximumPoolSize());
    }
    
    /**
     * Obtém uma conexão da pool.
     */
    public Connection getConnection() throws SQLException {
        return dataSource.getConnection();
    }
    
    /**
     * Retorna o tipo de base de dados.
     */
    public AppConfig.DatabaseType getType() {
        return type;
    }
    
    /**
     * Verifica se está em modo servidor (MySQL/PostgreSQL).
     */
    public boolean isServerMode() {
        return type == AppConfig.DatabaseType.MYSQL || type == AppConfig.DatabaseType.POSTGRESQL;
    }
    
    /**
     * Testa a conexão com a base de dados.
     */
    public boolean testConnection() {
        try (Connection conn = getConnection()) {
            return conn.isValid(5);
        } catch (SQLException e) {
            logger.error("Teste de conexão falhou", e);
            return false;
        }
    }
    
    /**
     * Fecha todas as conexões.
     */
    public void close() {
        if (dataSource != null && !dataSource.isClosed()) {
            dataSource.close();
            logger.info("Pool de conexões fechado");
        }
    }
    
    /**
     * Retorna estatísticas da pool.
     */
    public String getPoolStats() {
        return String.format("Active: %d, Idle: %d, Total: %d, Waiting: %d",
            dataSource.getHikariPoolMXBean().getActiveConnections(),
            dataSource.getHikariPoolMXBean().getIdleConnections(),
            dataSource.getHikariPoolMXBean().getTotalConnections(),
            dataSource.getHikariPoolMXBean().getThreadsAwaitingConnection());
    }
}
