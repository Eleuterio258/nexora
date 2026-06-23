package com.factpro.core.database;

import com.factpro.config.AppConfig;
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.output.MigrateResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Gestor de migrações da base de dados via Flyway.
 */
public class DatabaseMigration {
    
    private static final Logger logger = LoggerFactory.getLogger(DatabaseMigration.class);
    
    /**
     * Executa todas as migrações pendentes.
     */
    public static void runMigrations() {
        DatabaseManager dbManager = DatabaseManager.getInstance();
        String jdbcUrl;
        
        switch (dbManager.getType()) {
            case SQLITE:
                jdbcUrl = "jdbc:sqlite:" + AppConfig.getInstance().getSqlitePath();
                break;
            case MYSQL:
                jdbcUrl = String.format(
                    "jdbc:mysql://%s:%d/%s?useSSL=true&serverTimezone=UTC",
                    AppConfig.getInstance().getDbHost(),
                    AppConfig.getInstance().getDbPort(),
                    AppConfig.getInstance().getDbName()
                );
                break;
            case POSTGRESQL:
                jdbcUrl = String.format(
                    "jdbc:postgresql://%s:%d/%s",
                    AppConfig.getInstance().getDbHost(),
                    AppConfig.getInstance().getDbPort(),
                    AppConfig.getInstance().getDbName()
                );
                break;
            default:
                throw new IllegalStateException("Tipo de BD não suportado");
        }
        
        Flyway flyway = Flyway.configure()
            .dataSource(jdbcUrl, 
                dbManager.getType() == AppConfig.DatabaseType.SQLITE ? null : AppConfig.getInstance().getDbUser(),
                dbManager.getType() == AppConfig.DatabaseType.SQLITE ? null : AppConfig.getInstance().getDbPassword())
            .locations("classpath:db/migration")
            .baselineOnMigrate(true)
            .baselineVersion("0")
            .outOfOrder(true)
            .load();
        
        logger.info("A executar migrações da base de dados...");
        MigrateResult result = flyway.migrate();

        if (result != null && result.migrationsExecuted > 0) {
            logger.info("{} migração(ões) executada(s) com sucesso", result.migrationsExecuted);
        } else {
            logger.info("Base de dados atualizada. Nenhuma migração pendente.");
        }
    }
    
    /**
     * Repara o schema de migrações (útil após erros).
     */
    public static void repair() {
        String jdbcUrl = "jdbc:sqlite:" + AppConfig.getInstance().getSqlitePath();
        
        Flyway flyway = Flyway.configure()
            .dataSource(jdbcUrl, null, null)
            .locations("classpath:db/migration")
            .load();
        
        flyway.repair();
        logger.info("Schema de migrações reparado");
    }
}
