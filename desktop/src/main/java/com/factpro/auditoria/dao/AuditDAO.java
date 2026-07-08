package com.factpro.auditoria;

import com.factpro.auditoria.model.AuditLog;
import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AuditDAO extends BaseDAO<AuditLog> {

    private static final String TABLE = "auditoria_logs";

    private AuditLog mapResultSet(ResultSet rs) throws SQLException {
        AuditLog log = new AuditLog();
        log.setId(rs.getLong("id"));
        log.setTenantId(rs.getObject("tenant_id") != null ? rs.getLong("tenant_id") : null);
        log.setUserId(rs.getObject("user_id") != null ? rs.getLong("user_id") : null);
        log.setAcao(rs.getString("acao"));
        log.setRecurso(rs.getString("recurso"));
        log.setRecursoId(rs.getObject("recurso_id") != null ? rs.getLong("recurso_id") : null);
        log.setDescricao(rs.getString("descricao"));
        log.setIpAddress(rs.getString("ip_address"));
        log.setSucesso(rs.getObject("sucesso") != null ? rs.getBoolean("sucesso") : true);
        log.setUsuarioNome(rs.getString("usuario_nome"));
        log.setCriadoEm(rs.getString("criado_em"));
        return log;
    }

    @Override
    public AuditLog findById(Long id) {
        String sql = "SELECT a.*, u.nome as usuario_nome FROM " + TABLE + " a " +
                     "LEFT JOIN users u ON a.user_id = u.id WHERE a.id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar log de auditoria por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<AuditLog> findAll() {
        return findByFilters(null, null, null, null, 100);
    }

    public List<AuditLog> findByFilters(String acao, String recurso, 
                                         String dateFrom, String dateTo, int limit) {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT a.*, u.nome as usuario_nome FROM ").append(TABLE).append(" a ");
        sql.append("LEFT JOIN users u ON a.user_id = u.id WHERE 1=1 ");
        
        List<Object> params = new ArrayList<>();
        
        if (acao != null) {
            sql.append("AND a.acao = ? ");
            params.add(acao);
        }
        
        if (recurso != null) {
            sql.append("AND a.recurso = ? ");
            params.add(recurso);
        }
        
        if (dateFrom != null) {
            sql.append("AND a.criado_em >= ? ");
            params.add(dateFrom);
        }
        
        if (dateTo != null) {
            sql.append("AND a.criado_em <= ? ");
            params.add(dateTo + " 23:59:59");
        }
        
        sql.append("ORDER BY a.criado_em DESC LIMIT ?");
        params.add(limit);
        
        List<AuditLog> logs = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                stmt.setObject(i + 1, params.get(i));
            }
            
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    logs.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar logs de auditoria com filtros", e);
        }
        return logs;
    }

    @Override
    public Long save(AuditLog log) {
        String sql = "INSERT INTO " + TABLE + 
                     " (tenant_id, user_id, acao, recurso, recurso_id, descricao, ip_address, sucesso, criado_em) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            if (log.getTenantId() != null) stmt.setLong(idx++, log.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (log.getUserId() != null) stmt.setLong(idx++, log.getUserId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, log.getAcao());
            stmt.setString(idx++, log.getRecurso());
            if (log.getRecursoId() != null) stmt.setLong(idx++, log.getRecursoId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, log.getDescricao());
            stmt.setString(idx++, log.getIpAddress());
            stmt.setBoolean(idx++, log.getSucesso() != null ? log.getSucesso() : true);
            stmt.setString(idx++, log.getCriadoEm());
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar log de auditoria", e);
            return null;
        }
    }

    @Override
    public boolean update(AuditLog log) {
        // Logs de auditoria sao imutaveis
        return false;
    }

    @Override
    public boolean delete(Long id) {
        // Logs de auditoria nao devem ser eliminados (compliance)
        logger.warn("Tentativa de eliminar log de auditoria ID: {}", id);
        return false;
    }
}
