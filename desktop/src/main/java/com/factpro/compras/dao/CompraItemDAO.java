package com.factpro.compras.dao;

import com.factpro.compras.model.CompraItem;
import com.factpro.core.database.BaseDAO;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO para gestão de itens de compra.
 */
public class CompraItemDAO extends BaseDAO<CompraItem> {

    @Override
    public CompraItem findById(Long id) {
        String sql = "SELECT * FROM compra_items WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return mapResultSetToCompraItem(rs);
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar compra item: {}", id, e);
        }
        return null;
    }

    @Override
    public List<CompraItem> findAll() {
        return findByCriteria("");
    }

    public List<CompraItem> findByCompraId(Long compraId) {
        String sql = "SELECT * FROM compra_items WHERE compra_id = ? ORDER BY id";
        List<CompraItem> items = new ArrayList<>();
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, compraId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                items.add(mapResultSetToCompraItem(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar itens da compra: {}", compraId, e);
        }
        return items;
    }

    @Override
    public Long save(CompraItem item) {
        String sql = "INSERT INTO compra_items (compra_id, produto_id, quantidade, preco_unitario, total) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setLong(1, item.getCompraId());
            stmt.setLong(2, item.getProdutoId());
            stmt.setDouble(3, item.getQuantidade());
            stmt.setDouble(4, item.getPrecoUnitario());
            stmt.setDouble(5, item.getTotal());
            stmt.executeUpdate();
            Long id = getLastInsertedId(stmt);
            logger.info("Compra item guardado: ID={}", id);
            return id;
        } catch (SQLException e) {
            logger.error("Erro ao guardar compra item", e);
            return null;
        }
    }

    @Override
    public boolean update(CompraItem item) {
        String sql = "UPDATE compra_items SET produto_id=?, quantidade=?, preco_unitario=?, total=? WHERE id=?";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, item.getProdutoId());
            stmt.setDouble(2, item.getQuantidade());
            stmt.setDouble(3, item.getPrecoUnitario());
            stmt.setDouble(4, item.getTotal());
            stmt.setLong(5, item.getId());
            boolean success = stmt.executeUpdate() > 0;
            if (success) logger.info("Compra item atualizado: ID={}", item.getId());
            return success;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar compra item", e);
            return false;
        }
    }

    @Override
    public boolean delete(Long id) {
        String sql = "DELETE FROM compra_items WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            boolean success = stmt.executeUpdate() > 0;
            if (success) logger.info("Compra item eliminado: ID={}", id);
            return success;
        } catch (SQLException e) {
            logger.error("Erro ao eliminar compra item", e);
            return false;
        }
    }

    public boolean deleteByCompraId(Long compraId) {
        String sql = "DELETE FROM compra_items WHERE compra_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, compraId);
            stmt.executeUpdate();
            return true;
        } catch (SQLException e) {
            logger.error("Erro ao eliminar itens da compra: {}", compraId, e);
            return false;
        }
    }

    public List<CompraItem> findByCriteria(String criteria, Object... params) {
        String sql = "SELECT * FROM compra_items " + (criteria.isEmpty() ? "" : "WHERE " + criteria) + " ORDER BY id DESC";
        List<CompraItem> items = new ArrayList<>();
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            setParameters(stmt, params);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                items.add(mapResultSetToCompraItem(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar compra items", e);
        }
        return items;
    }

    private CompraItem mapResultSetToCompraItem(ResultSet rs) throws SQLException {
        CompraItem item = new CompraItem();
        item.setId(rs.getLong("id"));
        item.setCompraId(rs.getLong("compra_id"));
        item.setProdutoId(rs.getLong("produto_id"));
        item.setQuantidade(rs.getDouble("quantidade"));
        item.setPrecoUnitario(rs.getDouble("preco_unitario"));
        item.setTotal(rs.getDouble("total"));
        item.setCriadoEm(rs.getString("criado_em"));
        return item;
    }
}
