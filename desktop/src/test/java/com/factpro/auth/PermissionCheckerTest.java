package com.factpro.auth;

import com.factpro.auth.model.User;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class PermissionCheckerTest {

    @BeforeEach
    void setUp() {
        SessionManager.resetInstance();
        PermissionChecker.setTestBypass(false);
    }

    @AfterEach
    void tearDown() {
        SessionManager.getInstance().logout();
        PermissionChecker.setTestBypass(false);
    }

    @Test
    void shouldThrowWhenNotAuthenticated() {
        SecurityException ex = assertThrows(SecurityException.class,
                () -> PermissionChecker.require("vendas:create"));
        assertEquals("Utilizador nao autenticado.", ex.getMessage());
    }

    @Test
    void shouldThrowWhenMissingPermission() {
        User user = new User();
        user.setId(1L);
        user.setNome("Test");
        user.setRoleId(2L);
        SessionManager.getInstance().login(user);
        // No permissions loaded (empty list)

        SecurityException ex = assertThrows(SecurityException.class,
                () -> PermissionChecker.require("vendas:create"));
        assertTrue(ex.getMessage().contains("Acesso negado"));
    }

    @Test
    void shouldPassWhenBypassActive() {
        PermissionChecker.setTestBypass(true);
        assertDoesNotThrow(() -> PermissionChecker.require("vendas:create"));
    }

    @Test
    void shouldPassWhenUserHasPermission() {
        User user = new User();
        user.setId(1L);
        user.setNome("Test");
        user.setRoleId(2L);
        SessionManager.getInstance().login(user);
        // Manually set permissions
        SessionManager.getInstance().getUserPermissions().add("vendas:create");

        assertDoesNotThrow(() -> PermissionChecker.require("vendas:create"));
    }
}
