package com.factpro.auth.dao;

import com.factpro.auth.model.Permission;
import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PermissionDAO extends BaseDAO<Permission> {

    private static final String TABLE = "permissions";

    private Permission mapResultSet(ResultSet rs) throws SQLException {
        Permission permission = new Permission();
        permission.setId(rs.getLong("id"));
        permission.setNome(rs.getString("nome"));
        permission.setRecurso(rs.getString("recurso"));
        permission.setAcao(rs.getString("acao"));
        permission.setDescricao(rs.getString("descricao"));
        return permission;
    }

    @Override
    public Permission findById(Long id) {
        String sql = "SELECT * FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar permissao por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<Permission> findAll() {
        String sql = "SELECT * FROM " + TABLE + " ORDER BY recurso, acao";
        List<Permission> permissions = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                permissions.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar permissoes", e);
        }
        return permissions;
    }

    @Override
    public Long save(Permission permission) {
        String sql = "INSERT INTO " + TABLE + " (nome, recurso, acao, descricao) VALUES (?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            stmt.setString(idx++, permission.getNome());
            stmt.setString(idx++, permission.getRecurso());
            stmt.setString(idx++, permission.getAcao());
            stmt.setString(idx++, permission.getDescricao());
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar permissao: {}", permission.getNome(), e);
            return null;
        }
    }

    @Override
    public boolean update(Permission permission) {
        String sql = "UPDATE " + TABLE + " SET nome = ?, recurso = ?, acao = ?, descricao = ? WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int idx = 1;
            stmt.setString(idx++, permission.getNome());
            stmt.setString(idx++, permission.getRecurso());
            stmt.setString(idx++, permission.getAcao());
            stmt.setString(idx++, permission.getDescricao());
            stmt.setLong(idx++, permission.getId());
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar permissao: {}", permission.getId(), e);
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
            logger.error("Erro ao eliminar permissao: {}", id, e);
            return false;
        }
    }

    public Permission findByNome(String nome) {
        String sql = "SELECT * FROM " + TABLE + " WHERE nome = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, nome);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar permissao por nome: {}", nome, e);
            return null;
        }
    }

    public List<Permission> findByRecurso(String recurso) {
        String sql = "SELECT * FROM " + TABLE + " WHERE recurso = ? ORDER BY acao";
        List<Permission> permissions = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, recurso);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    permissions.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar permissoes por recurso: {}", recurso, e);
        }
        return permissions;
    }

    public List<String> findPermissionNamesByRoleId(Long roleId) {
        String sql = "SELECT p.nome FROM permissions p " +
                     "INNER JOIN role_permissions rp ON p.id = rp.permission_id " +
                     "WHERE rp.role_id = ? ORDER BY p.nome";
        List<String> names = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, roleId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    names.add(rs.getString("nome"));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar nomes de permissoes por role_id: {}", roleId, e);
        }
        return names;
    }

    public boolean assignPermissionToRole(Long roleId, Long permissionId) {
        String sql = "INSERT OR IGNORE INTO role_permissions (role_id, permission_id) VALUES (?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, roleId);
            stmt.setLong(2, permissionId);
            stmt.executeUpdate();
            return true;
        } catch (SQLException e) {
            logger.error("Erro ao atribuir permissao {} ao role {}", permissionId, roleId, e);
            return false;
        }
    }

    public boolean removePermissionFromRole(Long roleId, Long permissionId) {
        String sql = "DELETE FROM role_permissions WHERE role_id = ? AND permission_id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, roleId);
            stmt.setLong(2, permissionId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao remover permissao {} do role {}", permissionId, roleId, e);
            return false;
        }
    }

    public boolean syncRolePermissions(Long roleId, List<Long> permissionIds) {
        String deleteSql = "DELETE FROM role_permissions WHERE role_id = ?";
        String insertSql = "INSERT INTO role_permissions (role_id, permission_id) VALUES (?, ?)";
        
        try (Connection conn = DatabaseManager.getInstance().getConnection()) {
            conn.setAutoCommit(false);
            
            // Delete all existing permissions for this role
            try (PreparedStatement deleteStmt = conn.prepareStatement(deleteSql)) {
                deleteStmt.setLong(1, roleId);
                deleteStmt.executeUpdate();
            }
            
            // Insert new permissions
            try (PreparedStatement insertStmt = conn.prepareStatement(insertSql)) {
                for (Long permId : permissionIds) {
                    insertStmt.setLong(1, roleId);
                    insertStmt.setLong(2, permId);
                    insertStmt.addBatch();
                }
                insertStmt.executeBatch();
            }
            
            conn.commit();
            return true;
        } catch (SQLException e) {
            logger.error("Erro ao sincronizar permissoes do role {}", roleId, e);
            return false;
        }
    }
}
