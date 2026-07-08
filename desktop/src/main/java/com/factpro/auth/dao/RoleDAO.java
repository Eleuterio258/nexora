package com.factpro.auth.dao;

import com.factpro.auth.model.Role;
import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class RoleDAO extends BaseDAO<Role> {

    private static final String TABLE = "roles";

    private Role mapResultSet(ResultSet rs) throws SQLException {
        Role role = new Role();
        role.setId(rs.getLong("id"));
        role.setTenantId(rs.getObject("tenant_id") != null ? rs.getLong("tenant_id") : null);
        role.setNome(rs.getString("nome"));
        role.setDescricao(rs.getString("descricao"));
        role.setResponsabilidades(rs.getString("responsabilidades"));
        role.setCriadoEm(rs.getString("criado_em"));
        return role;
    }

    @Override
    public Role findById(Long id) {
        String sql = "SELECT * FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar role por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<Role> findAll() {
        String sql = "SELECT * FROM " + TABLE + " ORDER BY nome";
        List<Role> roles = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                roles.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar roles", e);
        }
        return roles;
    }

    @Override
    public Long save(Role role) {
        String sql = "INSERT INTO " + TABLE + " (tenant_id, nome, descricao, responsabilidades) VALUES (?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            if (role.getTenantId() != null) stmt.setLong(idx++, role.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, role.getNome());
            stmt.setString(idx++, role.getDescricao());
            stmt.setString(idx++, role.getResponsabilidades());
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar role: {}", role.getNome(), e);
            return null;
        }
    }

    @Override
    public boolean update(Role role) {
        String sql = "UPDATE " + TABLE + " SET tenant_id = ?, nome = ?, descricao = ?, responsabilidades = ? WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int idx = 1;
            if (role.getTenantId() != null) stmt.setLong(idx++, role.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, role.getNome());
            stmt.setString(idx++, role.getDescricao());
            stmt.setString(idx++, role.getResponsabilidades());
            stmt.setLong(idx++, role.getId());
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar role: {}", role.getId(), e);
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
            logger.error("Erro ao eliminar role: {}", id, e);
            return false;
        }
    }

    public List<String> findPermissionsByRoleId(Long roleId) {
        String sql = "SELECT p.nome FROM permissions p " +
                     "INNER JOIN role_permissions rp ON p.id = rp.permission_id " +
                     "WHERE rp.role_id = ? ORDER BY p.nome";
        List<String> permissions = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, roleId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    permissions.add(rs.getString("nome"));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar permissoes por role_id: {}", roleId, e);
        }
        return permissions;
    }
}
