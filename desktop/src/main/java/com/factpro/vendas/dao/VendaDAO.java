package com.factpro.vendas.dao;

import com.factpro.auth.PermissionChecker;
import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;
import com.factpro.vendas.model.Venda;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class VendaDAO extends BaseDAO<Venda> {

    private static final String TABLE = "vendas";

    private Venda mapResultSet(ResultSet rs) throws SQLException {
        Venda venda = new Venda();
        venda.setId(rs.getLong("id"));
        venda.setTenantId(rs.getObject("tenant_id") != null ? rs.getLong("tenant_id") : null);
        venda.setUserId(rs.getObject("user_id") != null ? rs.getLong("user_id") : null);
        venda.setClienteId(rs.getObject("cliente_id") != null ? rs.getLong("cliente_id") : null);
        venda.setTerminal(rs.getString("terminal"));
        venda.setSubtotal(rs.getObject("subtotal") != null ? rs.getDouble("subtotal") : 0.0);
        venda.setDesconto(rs.getObject("desconto") != null ? rs.getDouble("desconto") : 0.0);
        venda.setImposto(rs.getObject("imposto") != null ? rs.getDouble("imposto") : 0.0);
        venda.setTotal(rs.getObject("total") != null ? rs.getDouble("total") : 0.0);
        venda.setMetodoPagamento(rs.getString("metodo_pagamento"));
        venda.setStatus(rs.getString("status"));
        venda.setTipoDocumento(rs.getString("tipo_documento"));
        venda.setSerieDocumento(rs.getString("serie_documento"));
        venda.setNumeroDocumento(rs.getObject("numero_documento") != null ? rs.getInt("numero_documento") : null);
        venda.setReferencia(rs.getString("referencia"));
        venda.setObservacoes(rs.getString("observacoes"));
        venda.setCanceladaPor(rs.getObject("cancelada_por") != null ? rs.getLong("cancelada_por") : null);
        venda.setCanceladaMotivo(rs.getString("cancelada_motivo"));
        venda.setCanceladaEm(rs.getString("cancelada_em"));
        venda.setCriadaEm(rs.getString("criada_em"));
        return venda;
    }

    @Override
    public Venda findById(Long id) {
        String sql = "SELECT * FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar venda por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<Venda> findAll() {
        String sql = "SELECT * FROM " + TABLE + " ORDER BY criada_em DESC";
        List<Venda> vendas = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                vendas.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar vendas", e);
        }
        return vendas;
    }

    public List<Venda> findByDateRange(String startDate, String endDate) {
        String sql = "SELECT * FROM " + TABLE + " WHERE criada_em >= ? AND criada_em <= ? ORDER BY criada_em DESC";
        List<Venda> vendas = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, startDate);
            stmt.setString(2, endDate);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    vendas.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar vendas por periodo: {} ate {}", startDate, endDate, e);
        }
        return vendas;
    }

    public List<Venda> findByStatus(String status) {
        String sql = "SELECT * FROM " + TABLE + " WHERE status = ? ORDER BY criada_em DESC";
        List<Venda> vendas = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    vendas.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar vendas por status: {}", status, e);
        }
        return vendas;
    }

    @Override
    public Long save(Venda venda) {
        // Validar permissao
        PermissionChecker.requireCreate("vendas");
        
        String sql = "INSERT INTO " + TABLE + " (tenant_id, user_id, cliente_id, terminal, subtotal, desconto, " +
                     "imposto, total, metodo_pagamento, status, tipo_documento, serie_documento, numero_documento, " +
                     "referencia, observacoes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            if (venda.getTenantId() != null) stmt.setLong(idx++, venda.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (venda.getUserId() != null) stmt.setLong(idx++, venda.getUserId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (venda.getClienteId() != null) stmt.setLong(idx++, venda.getClienteId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, venda.getTerminal());
            stmt.setDouble(idx++, venda.getSubtotal() != null ? venda.getSubtotal() : 0.0);
            stmt.setDouble(idx++, venda.getDesconto() != null ? venda.getDesconto() : 0.0);
            stmt.setDouble(idx++, venda.getImposto() != null ? venda.getImposto() : 0.0);
            stmt.setDouble(idx++, venda.getTotal() != null ? venda.getTotal() : 0.0);
            stmt.setString(idx++, venda.getMetodoPagamento());
            stmt.setString(idx++, venda.getStatus() != null ? venda.getStatus() : "finalizada");
            stmt.setString(idx++, venda.getTipoDocumento());
            stmt.setString(idx++, venda.getSerieDocumento());
            if (venda.getNumeroDocumento() != null) stmt.setInt(idx++, venda.getNumeroDocumento());
            else stmt.setNull(idx++, Types.INTEGER);
            stmt.setString(idx++, venda.getReferencia());
            stmt.setString(idx++, venda.getObservacoes());
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar venda", e);
            return null;
        }
    }

    @Override
    public boolean update(Venda venda) {
        // Validar permissao
        PermissionChecker.requireUpdate("vendas");
        
        String sql = "UPDATE " + TABLE + " SET tenant_id = ?, user_id = ?, cliente_id = ?, terminal = ?, " +
                     "subtotal = ?, desconto = ?, imposto = ?, total = ?, metodo_pagamento = ?, status = ?, " +
                     "tipo_documento = ?, serie_documento = ?, numero_documento = ?, referencia = ?, " +
                     "observacoes = ? WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int idx = 1;
            if (venda.getTenantId() != null) stmt.setLong(idx++, venda.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (venda.getUserId() != null) stmt.setLong(idx++, venda.getUserId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (venda.getClienteId() != null) stmt.setLong(idx++, venda.getClienteId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, venda.getTerminal());
            stmt.setDouble(idx++, venda.getSubtotal() != null ? venda.getSubtotal() : 0.0);
            stmt.setDouble(idx++, venda.getDesconto() != null ? venda.getDesconto() : 0.0);
            stmt.setDouble(idx++, venda.getImposto() != null ? venda.getImposto() : 0.0);
            stmt.setDouble(idx++, venda.getTotal() != null ? venda.getTotal() : 0.0);
            stmt.setString(idx++, venda.getMetodoPagamento());
            stmt.setString(idx++, venda.getStatus());
            stmt.setString(idx++, venda.getTipoDocumento());
            stmt.setString(idx++, venda.getSerieDocumento());
            if (venda.getNumeroDocumento() != null) stmt.setInt(idx++, venda.getNumeroDocumento());
            else stmt.setNull(idx++, Types.INTEGER);
            stmt.setString(idx++, venda.getReferencia());
            stmt.setString(idx++, venda.getObservacoes());
            stmt.setLong(idx++, venda.getId());
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar venda: {}", venda.getId(), e);
            return false;
        }
    }

    @Override
    public boolean delete(Long id) {
        // Validar permissao
        PermissionChecker.requireDelete("vendas");
        
        String sql = "DELETE FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao eliminar venda: {}", id, e);
            return false;
        }
    }

    public boolean cancel(Long id, Long userId, String motivo) {
        String sql = "UPDATE " + TABLE + " SET status = 'cancelada', cancelada_por = ?, " +
                     "cancelada_motivo = ?, cancelada_em = datetime('now') WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, userId);
            stmt.setString(2, motivo);
            stmt.setLong(3, id);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao cancelar venda: {}", id, e);
            return false;
        }
    }

    public int getNextNumeroDocumento(String serieDocumento) {
        String sql = "SELECT COALESCE(MAX(numero_documento), 0) + 1 FROM " + TABLE + " WHERE serie_documento = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, serieDocumento);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 1;
            }
        } catch (SQLException e) {
            logger.error("Erro ao obter proximo numero_documento para serie: {}", serieDocumento, e);
            return 1;
        }
    }

    public int countToday() {
        String sql = "SELECT COUNT(*) FROM " + TABLE + " WHERE date(criada_em) = date('now')";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            logger.error("Erro ao contar vendas de hoje", e);
            return 0;
        }
    }

    public double sumTodayTotal() {
        String sql = "SELECT COALESCE(SUM(total), 0) FROM " + TABLE + " WHERE date(criada_em) = date('now') AND status != 'cancelada'";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            return rs.next() ? rs.getDouble(1) : 0.0;
        } catch (SQLException e) {
            logger.error("Erro ao somar total de vendas de hoje", e);
            return 0.0;
        }
    }
}
