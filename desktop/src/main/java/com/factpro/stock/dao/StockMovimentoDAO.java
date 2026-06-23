package com.factpro.stock.dao;

import com.factpro.auth.PermissionChecker;
import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;
import com.factpro.stock.model.StockMovimento;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class StockMovimentoDAO extends BaseDAO<StockMovimento> {

    private static final String TABLE = "stock_movimentos";

    private StockMovimento mapResultSet(ResultSet rs) throws SQLException {
        StockMovimento movimento = new StockMovimento();
        movimento.setId(rs.getLong("id"));
        movimento.setTenantId(rs.getObject("tenant_id") != null ? rs.getLong("tenant_id") : null);
        movimento.setProdutoId(rs.getObject("produto_id") != null ? rs.getLong("produto_id") : null);
        movimento.setTipo(rs.getString("tipo"));
        movimento.setQuantidade(rs.getObject("quantidade") != null ? rs.getInt("quantidade") : 0);
        movimento.setMotivo(rs.getString("motivo"));
        movimento.setReferencia(rs.getString("referencia"));
        movimento.setUserId(rs.getObject("user_id") != null ? rs.getLong("user_id") : null);
        movimento.setCriadoEm(rs.getString("criado_em"));
        return movimento;
    }

    @Override
    public StockMovimento findById(Long id) {
        String sql = "SELECT * FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar stock_movimento por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<StockMovimento> findAll() {
        String sql = "SELECT * FROM " + TABLE + " ORDER BY criado_em DESC";
        List<StockMovimento> movimentos = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                movimentos.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar stock_movimentos", e);
        }
        return movimentos;
    }

    public List<StockMovimento> findByProdutoId(Long produtoId) {
        String sql = "SELECT * FROM " + TABLE + " WHERE produto_id = ? ORDER BY criado_em DESC";
        List<StockMovimento> movimentos = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, produtoId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    movimentos.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar stock_movimentos por produto_id: {}", produtoId, e);
        }
        return movimentos;
    }

    public List<StockMovimento> findLowStockAlerts() {
        String sql = "SELECT sm.*, p.nome as produto_nome, p.stock_atual, p.stock_minimo " +
                     "FROM " + TABLE + " sm " +
                     "INNER JOIN produtos p ON sm.produto_id = p.id " +
                     "WHERE p.stock_atual <= p.stock_minimo " +
                     "ORDER BY sm.criado_em DESC";
        List<StockMovimento> movimentos = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                movimentos.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar alertas de stock baixo", e);
        }
        return movimentos;
    }

    @Override
    public Long save(StockMovimento movimento) {
        PermissionChecker.requireCreate("stock");
        String sql = "INSERT INTO " + TABLE + " (tenant_id, produto_id, tipo, quantidade, motivo, referencia, user_id) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            if (movimento.getTenantId() != null) stmt.setLong(idx++, movimento.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setLong(idx++, movimento.getProdutoId());
            stmt.setString(idx++, movimento.getTipo());
            stmt.setInt(idx++, movimento.getQuantidade() != null ? movimento.getQuantidade() : 0);
            stmt.setString(idx++, movimento.getMotivo());
            stmt.setString(idx++, movimento.getReferencia());
            if (movimento.getUserId() != null) stmt.setLong(idx++, movimento.getUserId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar stock_movimento", e);
            return null;
        }
    }

    @Override
    public boolean update(StockMovimento movimento) {
        PermissionChecker.requireUpdate("stock");
        String sql = "UPDATE " + TABLE + " SET tenant_id = ?, produto_id = ?, tipo = ?, quantidade = ?, " +
                     "motivo = ?, referencia = ?, user_id = ? WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int idx = 1;
            if (movimento.getTenantId() != null) stmt.setLong(idx++, movimento.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setLong(idx++, movimento.getProdutoId());
            stmt.setString(idx++, movimento.getTipo());
            stmt.setInt(idx++, movimento.getQuantidade() != null ? movimento.getQuantidade() : 0);
            stmt.setString(idx++, movimento.getMotivo());
            stmt.setString(idx++, movimento.getReferencia());
            if (movimento.getUserId() != null) stmt.setLong(idx++, movimento.getUserId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setLong(idx++, movimento.getId());
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar stock_movimento: {}", movimento.getId(), e);
            return false;
        }
    }

    @Override
    public boolean delete(Long id) {
        PermissionChecker.requireDelete("stock");
        String sql = "DELETE FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao eliminar stock_movimento: {}", id, e);
            return false;
        }
    }
}
