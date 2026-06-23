package com.factpro.vendas.dao;

import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;
import com.factpro.vendas.model.VendaItem;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class VendaItemDAO extends BaseDAO<VendaItem> {

    private static final String TABLE = "venda_itens";

    private VendaItem mapResultSet(ResultSet rs) throws SQLException {
        VendaItem item = new VendaItem();
        item.setId(rs.getLong("id"));
        item.setVendaId(rs.getObject("venda_id") != null ? rs.getLong("venda_id") : null);
        item.setProdutoId(rs.getObject("produto_id") != null ? rs.getLong("produto_id") : null);
        item.setQuantidade(rs.getObject("quantidade") != null ? rs.getDouble("quantidade") : 0.0);
        item.setPrecoUnitario(rs.getObject("preco_unitario") != null ? rs.getDouble("preco_unitario") : 0.0);
        item.setDesconto(rs.getObject("desconto") != null ? rs.getDouble("desconto") : 0.0);
        item.setTotal(rs.getObject("total") != null ? rs.getDouble("total") : 0.0);
        item.setCriadoEm(rs.getString("criado_em"));
        return item;
    }

    @Override
    public VendaItem findById(Long id) {
        String sql = "SELECT * FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar venda_item por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<VendaItem> findAll() {
        String sql = "SELECT * FROM " + TABLE + " ORDER BY id";
        List<VendaItem> items = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                items.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar venda_itens", e);
        }
        return items;
    }

    public List<VendaItem> findByVendaId(Long vendaId) {
        String sql = "SELECT * FROM " + TABLE + " WHERE venda_id = ? ORDER BY id";
        List<VendaItem> items = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, vendaId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    items.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar itens da venda: {}", vendaId, e);
        }
        return items;
    }

    @Override
    public Long save(VendaItem item) {
        String sql = "INSERT INTO " + TABLE + " (venda_id, produto_id, quantidade, preco_unitario, desconto, total) " +
                     "VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            stmt.setLong(idx++, item.getVendaId());
            stmt.setLong(idx++, item.getProdutoId());
            stmt.setDouble(idx++, item.getQuantidade() != null ? item.getQuantidade() : 0.0);
            stmt.setDouble(idx++, item.getPrecoUnitario() != null ? item.getPrecoUnitario() : 0.0);
            stmt.setDouble(idx++, item.getDesconto() != null ? item.getDesconto() : 0.0);
            stmt.setDouble(idx++, item.getTotal() != null ? item.getTotal() : 0.0);
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar venda_item", e);
            return null;
        }
    }

    @Override
    public boolean update(VendaItem item) {
        String sql = "UPDATE " + TABLE + " SET venda_id = ?, produto_id = ?, quantidade = ?, " +
                     "preco_unitario = ?, desconto = ?, total = ? WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int idx = 1;
            stmt.setLong(idx++, item.getVendaId());
            stmt.setLong(idx++, item.getProdutoId());
            stmt.setDouble(idx++, item.getQuantidade() != null ? item.getQuantidade() : 0.0);
            stmt.setDouble(idx++, item.getPrecoUnitario() != null ? item.getPrecoUnitario() : 0.0);
            stmt.setDouble(idx++, item.getDesconto() != null ? item.getDesconto() : 0.0);
            stmt.setDouble(idx++, item.getTotal() != null ? item.getTotal() : 0.0);
            stmt.setLong(idx++, item.getId());
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar venda_item: {}", item.getId(), e);
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
            logger.error("Erro ao eliminar venda_item: {}", id, e);
            return false;
        }
    }

    public boolean deleteByVendaId(Long vendaId) {
        String sql = "DELETE FROM " + TABLE + " WHERE venda_id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, vendaId);
            stmt.executeUpdate();
            return true;
        } catch (SQLException e) {
            logger.error("Erro ao eliminar itens da venda: {}", vendaId, e);
            return false;
        }
    }
}
