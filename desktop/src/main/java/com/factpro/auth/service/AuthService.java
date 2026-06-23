package com.factpro.auth.service;

import com.factpro.auth.SessionManager;
import com.factpro.auth.model.User;
import com.factpro.core.database.DatabaseManager;
import org.mindrot.jbcrypt.BCrypt;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Servico de autenticacao. Valida credenciais e gere sessoes.
 */
public class AuthService {

    private static final Logger logger = LoggerFactory.getLogger(AuthService.class);

    /**
     * Valida email e senha. Se corretos, faz login e retorna true.
     */
    public boolean authenticate(String email, String password) {
        if (email == null || email.isBlank() || password == null || password.isBlank()) {
            logger.warn("Tentativa de login com credenciais vazias");
            return false;
        }

        User user = findUserByEmail(email.trim());
        if (user == null) {
            logger.warn("Utilizador nao encontrado: {}", email);
            return false;
        }

        if (!Boolean.TRUE.equals(user.getAtivo())) {
            logger.warn("Utilador desativado: {}", email);
            return false;
        }

        // Check if account is blocked
        if (isBlocked(user)) {
            logger.warn("Utilador bloqueado: {}", email);
            return false;
        }

        // Verify password
        if (user.getSenhaHash() == null || !BCrypt.checkpw(password, user.getSenhaHash())) {
            incrementFailedAttempts(user);
            logger.warn("Senha incorreta para: {}", email);
            return false;
        }

        // Reset failed attempts on successful login
        resetFailedAttempts(user);

        // Update last login
        updateLastLogin(user);

        // Start session
        SessionManager.getInstance().login(user);
        logger.info("Login bem-sucedido: {} ({})", user.getNome(), email);
        return true;
    }

    private User findUserByEmail(String email) {
        String sql = "SELECT * FROM users WHERE email = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, email);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapUser(rs);
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar utilizador por email: {}", email, e);
        }
        return null;
    }

    private User mapUser(ResultSet rs) throws SQLException {
        User user = new User();
        user.setId(rs.getLong("id"));
        user.setTenantId(rs.getObject("tenant_id") != null ? rs.getLong("tenant_id") : null);
        user.setRoleId(rs.getObject("role_id") != null ? rs.getLong("role_id") : null);
        user.setNome(rs.getString("nome"));
        user.setEmail(rs.getString("email"));
        user.setSenhaHash(rs.getString("senha_hash"));
        user.setTelefone(rs.getString("telefone"));
        user.setAtivo(rs.getInt("ativo") == 1);
        user.setUltimoLogin(rs.getString("ultimo_login"));
        user.setTentativasFalhas(rs.getInt("tentativas_falhas"));
        user.setBloqueadoAte(rs.getString("bloqueado_ate"));
        user.setCriadoEm(rs.getString("criado_em"));
        return user;
    }

    private boolean isBlocked(User user) {
        if (user.getBloqueadoAte() == null || user.getBloqueadoAte().isBlank()) {
            return false;
        }
        try {
            LocalDateTime blockedUntil = LocalDateTime.parse(user.getBloqueadoAte(),
                    DateTimeFormatter.ISO_LOCAL_DATE_TIME);
            return LocalDateTime.now().isBefore(blockedUntil);
        } catch (Exception e) {
            return false;
        }
    }

    private void incrementFailedAttempts(User user) {
        int attempts = (user.getTentativasFalhas() != null ? user.getTentativasFalhas() : 0) + 1;

        // Block after 5 failed attempts for 30 minutes
        if (attempts >= 5) {
            String sql = "UPDATE users SET tentativas_falhas = ?, bloqueado_ate = ? WHERE id = ?";
            LocalDateTime blockedUntil = LocalDateTime.now().plusMinutes(30);
            try (Connection conn = DatabaseManager.getInstance().getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, attempts);
                stmt.setString(2, blockedUntil.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
                stmt.setLong(3, user.getId());
                stmt.execute();
            } catch (SQLException e) {
                logger.error("Erro ao bloquear utilizador", e);
            }
        } else {
            String sql = "UPDATE users SET tentativas_falhas = ? WHERE id = ?";
            try (Connection conn = DatabaseManager.getInstance().getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, attempts);
                stmt.setLong(2, user.getId());
                stmt.execute();
            } catch (SQLException e) {
                logger.error("Erro ao atualizar tentativas falhas", e);
            }
        }
        user.setTentativasFalhas(attempts);
    }

    private void resetFailedAttempts(User user) {
        String sql = "UPDATE users SET tentativas_falhas = 0, bloqueado_ate = NULL WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, user.getId());
            stmt.execute();
        } catch (SQLException e) {
            logger.error("Erro ao resetar tentativas falhas", e);
        }
        user.setTentativasFalhas(0);
        user.setBloqueadoAte(null);
    }

    private void updateLastLogin(User user) {
        String sql = "UPDATE users SET ultimo_login = ? WHERE id = ?";
        String now = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, now);
            stmt.setLong(2, user.getId());
            stmt.execute();
        } catch (SQLException e) {
            logger.error("Erro ao atualizar ultimo login", e);
        }
        user.setUltimoLogin(now);
    }
}
