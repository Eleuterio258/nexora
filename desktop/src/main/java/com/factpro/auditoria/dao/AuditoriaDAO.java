package com.factpro.auditoria.dao;

import com.factpro.auditoria.model.AuditoriaLog;
import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO para acesso a registos de auditoria (auditoria_logs).
 */
public class AuditoriaDAO extends BaseDAO<AuditoriaLog> {

    private static final String TABLE = "auditoria_logs";

    private AuditoriaLog mapResultSet(ResultSet rs) throws SQLException {
        AuditoriaLog log = new AuditoriaLog();
        log.setId(rs.getLong("id"));
        log.setUserId(rs.getObject("user_id") != null ? rs.getLong("user_id") : null);
        log.setAcao(rs.getString("acao"));
        log.setRecurso(rs.getString("recurso"));
        log.setRecursoId(rs.getObject("recurso_id") != null ? rs.getLong("recurso_id") : null);
        log.setDescricao(rs.getString("descricao"));
        log.setIpAddress(rs.getString("ip_address"));
        log.setCriadoEm(rs.getString("criado_em"));
        return log;
    }

    @Override
    public AuditoriaLog findById(Long id) {
        String sql = "SELECT * FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar auditoria_log por id: {}", id, e);
            return null;
        }
    }

    /**
     * Retorna os ultimos N registos de auditoria (limitado a 1000 por defeito).
     */
    @Override
    public List<AuditoriaLog> findAll() {
        return findAll(1000);
    }

    /**
     * Retorna os ultimos N registos de auditoria.
     */
    public List<AuditoriaLog> findAll(int limit) {
        String sql = "SELECT * FROM " + TABLE + " ORDER BY criado_em DESC LIMIT ?";
        List<AuditoriaLog> logs = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, limit);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    logs.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar auditoria_logs", e);
        }
        return logs;
    }

    /**
     * Filtra registos de auditoria por utilizador.
     */
    public List<AuditoriaLog> findByUserId(Long userId) {
        return findByUserId(userId, 500);
    }

    /**
     * Filtra registos de auditoria por utilizador com limite.
     */
    public List<AuditoriaLog> findByUserId(Long userId, int limit) {
        String sql = "SELECT * FROM " + TABLE + " WHERE user_id = ? ORDER BY criado_em DESC LIMIT ?";
        List<AuditoriaLog> logs = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, userId);
            stmt.setInt(2, limit);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    logs.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar auditoria_logs por user_id: {}", userId, e);
        }
        return logs;
    }

    /**
     * Filtra registos de auditoria por tipo de recurso.
     */
    public List<AuditoriaLog> findByRecurso(String recurso) {
        String sql = "SELECT * FROM " + TABLE + " WHERE recurso = ? ORDER BY criado_em DESC LIMIT 500";
        List<AuditoriaLog> logs = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, recurso);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    logs.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar auditoria_logs por recurso: {}", recurso, e);
        }
        return logs;
    }

    /**
     * Filtra registos de auditoria por intervalo de datas.
     */
    public List<AuditoriaLog> findByDateRange(String start, String end) {
        String sql = "SELECT * FROM " + TABLE + " WHERE criado_em >= ? AND criado_em <= ? ORDER BY criado_em DESC LIMIT 1000";
        List<AuditoriaLog> logs = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, start);
            stmt.setString(2, end);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    logs.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar auditoria_logs por periodo: {} ate {}", start, end, e);
        }
        return logs;
    }

    /**
     * Filtra registos de auditoria por tipo de acao.
     */
    public List<AuditoriaLog> findByAcao(String acao) {
        String sql = "SELECT * FROM " + TABLE + " WHERE acao = ? ORDER BY criado_em DESC LIMIT 500";
        List<AuditoriaLog> logs = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, acao);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    logs.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar auditoria_logs por acao: {}", acao, e);
        }
        return logs;
    }

    /**
     * Elimina registos de auditoria anteriores a N dias.
     */
    public boolean deleteOlderThan(int days) {
        String sql = "DELETE FROM " + TABLE + " WHERE criado_em < datetime('now', '-' || ? || ' days')";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, days);
            int affected = stmt.executeUpdate();
            logger.info("Eliminados {} registos de auditoria com mais de {} dias", affected, days);
            return true;
        } catch (SQLException e) {
            logger.error("Erro ao eliminar registos de auditoria antigos ({} dias)", days, e);
            return false;
        }
    }

    @Override
    public Long save(AuditoriaLog entity) {
        String sql = "INSERT INTO " + TABLE + " (user_id, acao, recurso, recurso_id, descricao, ip_address) " +
                     "VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            if (entity.getUserId() != null) stmt.setLong(idx++, entity.getUserId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, entity.getAcao());
            stmt.setString(idx++, entity.getRecurso());
            if (entity.getRecursoId() != null) stmt.setLong(idx++, entity.getRecursoId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, entity.getDescricao());
            stmt.setString(idx++, entity.getIpAddress());
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar auditoria_log", e);
            return null;
        }
    }

    @Override
    public boolean update(AuditoriaLog entity) {
        // Registos de auditoria sao imutaveis - nao se atualizam.
        logger.warn("Tentativa de atualizar registo de auditoria (id={}) - operacao nao suportada", entity.getId());
        return false;
    }

    @Override
    public boolean delete(Long id) {
        String sql = "DELETE FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao eliminar auditoria_log: {}", id, e);
            return false;
        }
    }
}
