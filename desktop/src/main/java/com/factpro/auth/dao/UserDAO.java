package com.factpro.auth.dao;

import com.factpro.auth.model.User;
import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UserDAO extends BaseDAO<User> {

    private static final String TABLE = "users";

    private User mapResultSet(ResultSet rs) throws SQLException {
        User user = new User();
        user.setId(rs.getLong("id"));
        user.setTenantId(rs.getObject("tenant_id") != null ? rs.getLong("tenant_id") : null);
        user.setRoleId(rs.getObject("role_id") != null ? rs.getLong("role_id") : null);
        user.setNome(rs.getString("nome"));
        user.setEmail(rs.getString("email"));
        user.setSenhaHash(rs.getString("senha_hash"));
        user.setTelefone(rs.getString("telefone"));
        user.setAtivo(rs.getObject("ativo") != null ? rs.getBoolean("ativo") : true);
        user.setUltimoLogin(rs.getString("ultimo_login"));
        user.setTentativasFalhas(rs.getObject("tentativas_falhas") != null ? rs.getInt("tentativas_falhas") : 0);
        user.setBloqueadoAte(rs.getString("bloqueado_ate"));
        user.setCriadoEm(rs.getString("criado_em"));
        return user;
    }

    @Override
    public User findById(Long id) {
        String sql = "SELECT * FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar user por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<User> findAll() {
        String sql = "SELECT * FROM " + TABLE + " ORDER BY nome";
        List<User> users = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                users.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar users", e);
        }
        return users;
    }

    public User findByEmail(String email) {
        String sql = "SELECT * FROM " + TABLE + " WHERE email = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, email);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar user por email: {}", email, e);
            return null;
        }
    }

    @Override
    public Long save(User user) {
        String sql = "INSERT INTO " + TABLE + " (tenant_id, role_id, nome, email, senha_hash, telefone, ativo, tentativas_falhas) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            if (user.getTenantId() != null) stmt.setLong(idx++, user.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (user.getRoleId() != null) stmt.setLong(idx++, user.getRoleId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, user.getNome());
            stmt.setString(idx++, user.getEmail());
            stmt.setString(idx++, user.getSenhaHash());
            stmt.setString(idx++, user.getTelefone());
            stmt.setBoolean(idx++, user.getAtivo() != null ? user.getAtivo() : true);
            stmt.setInt(idx++, user.getTentativasFalhas() != null ? user.getTentativasFalhas() : 0);
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar user: {}", user.getEmail(), e);
            return null;
        }
    }

    @Override
    public boolean update(User user) {
        String sql = "UPDATE " + TABLE + " SET tenant_id = ?, role_id = ?, nome = ?, email = ?, " +
                     "senha_hash = ?, telefone = ?, ativo = ?, tentativas_falhas = ?, bloqueado_ate = ? WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int idx = 1;
            if (user.getTenantId() != null) stmt.setLong(idx++, user.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (user.getRoleId() != null) stmt.setLong(idx++, user.getRoleId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, user.getNome());
            stmt.setString(idx++, user.getEmail());
            stmt.setString(idx++, user.getSenhaHash());
            stmt.setString(idx++, user.getTelefone());
            stmt.setBoolean(idx++, user.getAtivo() != null ? user.getAtivo() : true);
            stmt.setInt(idx++, user.getTentativasFalhas() != null ? user.getTentativasFalhas() : 0);
            stmt.setString(idx++, user.getBloqueadoAte());
            stmt.setLong(idx++, user.getId());
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar user: {}", user.getId(), e);
            return false;
        }
    }

    @Override
    public boolean delete(Long id) {
        String sql = "DELETE FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao eliminar user: {}", id, e);
            return false;
        }
    }

    public boolean incrementFailedAttempts(Long id) {
        String sql = "UPDATE " + TABLE + " SET tentativas_falhas = tentativas_falhas + 1 WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao incrementar tentativas falhas: {}", id, e);
            return false;
        }
    }

    public boolean resetFailedAttempts(Long id) {
        String sql = "UPDATE " + TABLE + " SET tentativas_falhas = 0, bloqueado_ate = NULL WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao resetar tentativas falhas: {}", id, e);
            return false;
        }
    }

    public boolean updateLastLogin(Long id) {
        String sql = "UPDATE " + TABLE + " SET ultimo_login = datetime('now'), tentativas_falhas = 0, bloqueado_ate = NULL WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar ultimo login: {}", id, e);
            return false;
        }
    }

    public List<User> findByCriteria(String search) {
        String sql = "SELECT * FROM " + TABLE + " WHERE nome LIKE ? OR email LIKE ? ORDER BY nome";
        List<User> users = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            String pattern = "%" + search + "%";
            stmt.setString(1, pattern);
            stmt.setString(2, pattern);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    users.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar users por criteria: {}", search, e);
        }
        return users;
    }
}
