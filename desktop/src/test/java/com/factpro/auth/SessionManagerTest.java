package com.factpro.auth;

import com.factpro.auth.model.User;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class SessionManagerTest {

    @BeforeEach
    void setUp() {
        SessionManager.resetInstance();
    }

    @AfterEach
    void tearDown() {
        SessionManager.getInstance().logout();
    }

    @Test
    void shouldReturnSameInstance() {
        SessionManager s1 = SessionManager.getInstance();
        SessionManager s2 = SessionManager.getInstance();
        assertSame(s1, s2);
    }

    @Test
    void shouldNotBeAuthenticatedByDefault() {
        SessionManager sm = SessionManager.getInstance();
        assertFalse(sm.isAuthenticated());
        assertNull(sm.getCurrentUserId());
    }

    @Test
    void shouldAuthenticateAfterLogin() {
        SessionManager sm = SessionManager.getInstance();
        User user = createUser(1L, "Joao", "joao@test.com");

        sm.login(user);

        assertTrue(sm.isAuthenticated());
        assertEquals(1L, sm.getCurrentUserId());
        assertEquals("Joao", sm.getCurrentUserName());
        assertEquals("joao@test.com", sm.getCurrentUserEmail());
    }

    @Test
    void shouldLogoutCorrectly() {
        SessionManager sm = SessionManager.getInstance();
        sm.login(createUser(1L, "Joao", "joao@test.com"));
        assertTrue(sm.isAuthenticated());

        sm.logout();

        assertFalse(sm.isAuthenticated());
        assertNull(sm.getCurrentUser());
        assertNull(sm.getCurrentUserId());
        assertEquals("Desconhecido", sm.getCurrentUserName());
        assertEquals("", sm.getCurrentUserEmail());
    }

    @Test
    void shouldReturnTenantId() {
        SessionManager sm = SessionManager.getInstance();
        User user = createUser(1L, "Joao", "joao@test.com");
        user.setTenantId(10L);
        user.setRoleId(2L);

        sm.login(user);

        assertEquals(10L, sm.getCurrentTenantId());
        assertEquals(2L, sm.getCurrentRoleId());
    }

    @Test
    void shouldReturnDefaultValuesWhenNotAuthenticated() {
        SessionManager sm = SessionManager.getInstance();

        assertEquals("Desconhecido", sm.getCurrentUserName());
        assertEquals("", sm.getCurrentUserEmail());
        assertNull(sm.getCurrentTenantId());
        assertNull(sm.getCurrentRoleId());
    }

    private User createUser(Long id, String nome, String email) {
        User user = new User();
        user.setId(id);
        user.setNome(nome);
        user.setEmail(email);
        user.setAtivo(true);
        return user;
    }
}
