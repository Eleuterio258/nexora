package com.factpro.notificacoes.dao;

import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;
import com.factpro.notificacoes.model.Notificacao;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class NotificacaoDAO extends BaseDAO<Notificacao> {

    private static final String TABLE = "notificacoes";

    private Notificacao mapResultSet(ResultSet rs) throws SQLException {
        Notificacao n = new Notificacao();
        n.setId(rs.getLong("id"));
        n.setUserId(rs.getObject("user_id") != null ? rs.getLong("user_id") : null);
        n.setTipo(rs.getString("tipo"));
        n.setTitulo(rs.getString("titulo"));
        n.setMensagem(rs.getString("mensagem"));
        n.setLida(rs.getObject("lida") != null ? rs.getInt("lida") == 1 : false);
        n.setLidaEm(rs.getString("lida_em"));
        n.setCriadoEm(rs.getString("criado_em"));
        return n;
    }

    @Override
    public Notificacao findById(Long id) {
        String sql = "SELECT * FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar notificacao por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<Notificacao> findAll() {
        String sql = "SELECT * FROM " + TABLE + " ORDER BY criado_em DESC LIMIT 200";
        List<Notificacao> lista = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                lista.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar notificacoes", e);
        }
        return lista;
    }

    @Override
    public Long save(Notificacao n) {
        String sql = "INSERT INTO " + TABLE + " (user_id, tipo, titulo, mensagem, lida) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            if (n.getUserId() != null) stmt.setLong(idx++, n.getUserId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, n.getTipo());
            stmt.setString(idx++, n.getTitulo());
            stmt.setString(idx++, n.getMensagem());
            stmt.setBoolean(idx++, n.getLida() != null ? n.getLida() : false);
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar notificacao: {}", n.getTitulo(), e);
            return null;
        }
    }

    @Override
    public boolean update(Notificacao n) {
        String sql = "UPDATE " + TABLE + " SET user_id = ?, tipo = ?, titulo = ?, mensagem = ?, " +
                     "lida = ?, lida_em = ? WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int idx = 1;
            if (n.getUserId() != null) stmt.setLong(idx++, n.getUserId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, n.getTipo());
            stmt.setString(idx++, n.getTitulo());
            stmt.setString(idx++, n.getMensagem());
            stmt.setBoolean(idx++, n.getLida() != null ? n.getLida() : false);
            stmt.setString(idx++, n.getLidaEm());
            stmt.setLong(idx++, n.getId());
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar notificacao: {}", n.getId(), e);
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
            logger.error("Erro ao eliminar notificacao: {}", id, e);
            return false;
        }
    }

    /**
     * Finds notifications for a specific user with a limit.
     */
    public List<Notificacao> findByUserId(Long userId, int limit) {
        String sql = "SELECT * FROM " + TABLE + " WHERE user_id = ? ORDER BY criado_em DESC LIMIT ?";
        List<Notificacao> lista = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, userId);
            stmt.setInt(2, limit);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar notificacoes por userId: {}", userId, e);
        }
        return lista;
    }

    /**
     * Finds unread notifications for a specific user.
     */
    public List<Notificacao> findUnreadByUserId(Long userId) {
        String sql = "SELECT * FROM " + TABLE + " WHERE user_id = ? AND lida = 0 ORDER BY criado_em DESC";
        List<Notificacao> lista = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar notificacoes nao lidas por userId: {}", userId, e);
        }
        return lista;
    }

    /**
     * Marks a notification as read.
     */
    public boolean markAsRead(Long notificacaoId) {
        String sql = "UPDATE " + TABLE + " SET lida = 1, lida_em = CURRENT_TIMESTAMP WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, notificacaoId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao marcar notificao como lida: {}", notificacaoId, e);
            return false;
        }
    }

    /**
     * Marks all notifications as read for a user.
     */
    public boolean markAllAsRead(Long userId) {
        String sql = "UPDATE " + TABLE + " SET lida = 1, lida_em = CURRENT_TIMESTAMP WHERE user_id = ? AND lida = 0";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, userId);
            stmt.executeUpdate();
            return true;
        } catch (SQLException e) {
            logger.error("Erro ao marcar todas notificacoes como lidas para userId: {}", userId, e);
            return false;
        }
    }

    /**
     * Gets the count of unread notifications for a user.
     */
    public int getUnreadCount(Long userId) {
        String sql = "SELECT COUNT(*) FROM " + TABLE + " WHERE user_id = ? AND lida = 0";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            logger.error("Erro ao contar notificacoes nao lidas para userId: {}", userId, e);
            return 0;
        }
    }

    /**
     * Deletes notifications older than the given number of days.
     */
    public boolean deleteOlderThan(int days) {
        String sql = "DELETE FROM " + TABLE + " WHERE criado_em < datetime('now', '-' || ? || ' days')";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, days);
            stmt.executeUpdate();
            return true;
        } catch (SQLException e) {
            logger.error("Erro ao eliminar notificacoes antigas ({} dias)", days, e);
            return false;
        }
    }
}
