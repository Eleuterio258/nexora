package com.factpro.auth.service;

import com.factpro.config.AppConfig;
import com.factpro.core.database.DatabaseManager;
import com.factpro.core.database.DatabaseMigration;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AuthServiceIntegrationTest {

    @AfterAll
    static void cleanup() {
        DatabaseManager.getInstance().close();
    }

    @Test
    void shouldAuthenticateSeededAdminInSqlite() {
        AppConfig config = AppConfig.getInstance();
        config.setDatabaseType(AppConfig.DatabaseType.SQLITE);
        config.setSqlitePath("./data/factpro.db");

        DatabaseMigration.runMigrations();

        AuthService authService = new AuthService();
        assertTrue(authService.authenticate("admin@factpro.local", "admin123"));
    }

    @Test
    void shouldRejectInvalidPasswordForSeededAdmin() {
        AppConfig config = AppConfig.getInstance();
        config.setDatabaseType(AppConfig.DatabaseType.SQLITE);
        config.setSqlitePath("./data/factpro.db");

        DatabaseMigration.runMigrations();

        AuthService authService = new AuthService();
        assertFalse(authService.authenticate("admin@factpro.local", "senha-errada"));
    }
}
