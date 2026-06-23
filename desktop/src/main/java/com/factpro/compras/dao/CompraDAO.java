package com.factpro.compras.dao;

import com.factpro.auth.PermissionChecker;
import com.factpro.compras.model.Compra;
import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CompraDAO extends BaseDAO<Compra> {

    private static final String TABLE = "compras";

    private Compra mapResultSet(ResultSet rs) throws SQLException {
        Compra compra = new Compra();
        compra.setId(rs.getLong("id"));
        compra.setTenantId(rs.getObject("tenant_id") != null ? rs.getLong("tenant_id") : null);
        compra.setFornecedorId(rs.getObject("fornecedor_id") != null ? rs.getLong("fornecedor_id") : null);
        compra.setUserId(rs.getObject("user_id") != null ? rs.getLong("user_id") : null);
        compra.setTotal(rs.getObject("total") != null ? rs.getDouble("total") : 0.0);
        compra.setStatus(rs.getString("status"));
        compra.setDataCompra(rs.getString("data_compra"));
        compra.setObservacoes(rs.getString("observacoes"));
        compra.setCriadoEm(rs.getString("criado_em"));
        return compra;
    }

    @Override
    public Compra findById(Long id) {
        String sql = "SELECT * FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar compra por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<Compra> findAll() {
        String sql = "SELECT * FROM " + TABLE + " ORDER BY criado_em DESC";
        List<Compra> compras = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                compras.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar compras", e);
        }
        return compras;
    }

    @Override
    public Long save(Compra compra) {
        PermissionChecker.requireCreate("compras");
        String sql = "INSERT INTO " + TABLE + " (tenant_id, fornecedor_id, user_id, total, status, data_compra, observacoes) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            if (compra.getTenantId() != null) stmt.setLong(idx++, compra.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (compra.getFornecedorId() != null) stmt.setLong(idx++, compra.getFornecedorId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (compra.getUserId() != null) stmt.setLong(idx++, compra.getUserId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setDouble(idx++, compra.getTotal() != null ? compra.getTotal() : 0.0);
            stmt.setString(idx++, compra.getStatus() != null ? compra.getStatus() : "pendente");
            stmt.setString(idx++, compra.getDataCompra());
            stmt.setString(idx++, compra.getObservacoes());
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar compra", e);
            return null;
        }
    }

    @Override
    public boolean update(Compra compra) {
        PermissionChecker.requireUpdate("compras");
        String sql = "UPDATE " + TABLE + " SET tenant_id = ?, fornecedor_id = ?, user_id = ?, " +
                     "total = ?, status = ?, data_compra = ?, observacoes = ? WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int idx = 1;
            if (compra.getTenantId() != null) stmt.setLong(idx++, compra.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (compra.getFornecedorId() != null) stmt.setLong(idx++, compra.getFornecedorId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (compra.getUserId() != null) stmt.setLong(idx++, compra.getUserId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setDouble(idx++, compra.getTotal() != null ? compra.getTotal() : 0.0);
            stmt.setString(idx++, compra.getStatus());
            stmt.setString(idx++, compra.getDataCompra());
            stmt.setString(idx++, compra.getObservacoes());
            stmt.setLong(idx++, compra.getId());
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar compra: {}", compra.getId(), e);
            return false;
        }
    }

    @Override
    public boolean delete(Long id) {
        PermissionChecker.requireDelete("compras");
        String sql = "DELETE FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao eliminar compra: {}", id, e);
            return false;
        }
    }

    public boolean receive(Long id) {
        String sql = "UPDATE " + TABLE + " SET status = 'recebida' WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao receber compra: {}", id, e);
            return false;
        }
    }
}
