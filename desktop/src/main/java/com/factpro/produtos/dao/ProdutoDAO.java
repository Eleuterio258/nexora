package com.factpro.produtos.dao;

import com.factpro.auth.PermissionChecker;
import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;
import com.factpro.produtos.model.Produto;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ProdutoDAO extends BaseDAO<Produto> {

    private static final String TABLE = "produtos";
    private static final String SELECT_WITH_CATEGORY = "SELECT p.*, c.nome as categoria_nome FROM " + TABLE + " p LEFT JOIN categorias c ON p.categoria_id = c.id";

    private Produto mapResultSet(ResultSet rs) throws SQLException {
        Produto produto = new Produto();
        produto.setId(rs.getLong("id"));
        produto.setTenantId(rs.getObject("tenant_id") != null ? rs.getLong("tenant_id") : null);
        produto.setCategoriaId(rs.getObject("categoria_id") != null ? rs.getLong("categoria_id") : null);
        produto.setCodigoBarras(rs.getString("codigo_barras"));
        produto.setSku(rs.getString("sku"));
        produto.setNome(rs.getString("nome"));
        produto.setDescricao(rs.getString("descricao"));
        produto.setPrecoCompra(rs.getObject("preco_compra") != null ? rs.getDouble("preco_compra") : null);
        produto.setPrecoVenda(rs.getObject("preco_venda") != null ? rs.getDouble("preco_venda") : null);
        produto.setPrecoPromocao(rs.getObject("preco_promocao") != null ? rs.getDouble("preco_promocao") : null);
        produto.setStockAtual(rs.getObject("stock_atual") != null ? rs.getInt("stock_atual") : 0);
        produto.setStockMinimo(rs.getObject("stock_minimo") != null ? rs.getInt("stock_minimo") : 0);
        produto.setUnidadeMedida(rs.getString("unidade_medida"));
        produto.setValidade(rs.getString("validade"));
        produto.setImagemUrl(rs.getString("imagem_url"));
        produto.setComposto(rs.getObject("composto") != null && rs.getBoolean("composto"));
        produto.setAtivo(rs.getObject("ativo") != null ? rs.getBoolean("ativo") : true);
        produto.setCriadoEm(rs.getString("criado_em"));
        return produto;
    }

    @Override
    public Produto findById(Long id) {
        String sql = SELECT_WITH_CATEGORY + " WHERE p.id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar produto por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<Produto> findAll() {
        String sql = SELECT_WITH_CATEGORY + " ORDER BY p.nome";
        List<Produto> produtos = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                produtos.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar produtos", e);
        }
        return produtos;
    }

    public List<Produto> findAllWithCategory() {
        String sql = SELECT_WITH_CATEGORY + " WHERE c.id IS NOT NULL ORDER BY c.nome, p.nome";
        List<Produto> produtos = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                produtos.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar produtos com categoria", e);
        }
        return produtos;
    }

    public Produto findByCodigoBarras(String codigoBarras) {
        String sql = "SELECT * FROM " + TABLE + " WHERE codigo_barras = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, codigoBarras);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar produto por codigo_barras: {}", codigoBarras, e);
            return null;
        }
    }

    public List<Produto> findLowStock() {
        String sql = "SELECT * FROM " + TABLE + " WHERE stock_atual <= stock_minimo AND ativo = 1 ORDER BY nome";
        List<Produto> produtos = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                produtos.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar produtos com stock baixo", e);
        }
        return produtos;
    }

    public List<Produto> search(String query) {
        String sql = "SELECT * FROM " + TABLE + " WHERE nome LIKE ? OR codigo_barras LIKE ? ORDER BY nome";
        List<Produto> produtos = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            String pattern = "%" + query + "%";
            stmt.setString(1, pattern);
            stmt.setString(2, pattern);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    produtos.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao pesquisar produtos: {}", query, e);
        }
        return produtos;
    }

    @Override
    public Long save(Produto produto) {
        PermissionChecker.requireCreate("produtos");
        String sql = "INSERT INTO " + TABLE + " (tenant_id, categoria_id, codigo_barras, sku, nome, descricao, " +
                     "preco_compra, preco_venda, preco_promocao, stock_atual, stock_minimo, unidade_medida, " +
                     "validade, imagem_url, composto, ativo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            if (produto.getTenantId() != null) stmt.setLong(idx++, produto.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (produto.getCategoriaId() != null) stmt.setLong(idx++, produto.getCategoriaId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, produto.getCodigoBarras());
            stmt.setString(idx++, produto.getSku());
            stmt.setString(idx++, produto.getNome());
            stmt.setString(idx++, produto.getDescricao());
            if (produto.getPrecoCompra() != null) stmt.setDouble(idx++, produto.getPrecoCompra());
            else stmt.setNull(idx++, Types.DOUBLE);
            if (produto.getPrecoVenda() != null) stmt.setDouble(idx++, produto.getPrecoVenda());
            else stmt.setNull(idx++, Types.DOUBLE);
            if (produto.getPrecoPromocao() != null) stmt.setDouble(idx++, produto.getPrecoPromocao());
            else stmt.setNull(idx++, Types.DOUBLE);
            stmt.setInt(idx++, produto.getStockAtual() != null ? produto.getStockAtual() : 0);
            stmt.setInt(idx++, produto.getStockMinimo() != null ? produto.getStockMinimo() : 0);
            stmt.setString(idx++, produto.getUnidadeMedida());
            stmt.setString(idx++, produto.getValidade());
            stmt.setString(idx++, produto.getImagemUrl());
            stmt.setBoolean(idx++, produto.getComposto() != null ? produto.getComposto() : false);
            stmt.setBoolean(idx++, produto.getAtivo() != null ? produto.getAtivo() : true);
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar produto: {}", produto.getNome(), e);
            return null;
        }
    }

    @Override
    public boolean update(Produto produto) {
        PermissionChecker.requireUpdate("produtos");
        String sql = "UPDATE " + TABLE + " SET tenant_id = ?, categoria_id = ?, codigo_barras = ?, sku = ?, " +
                     "nome = ?, descricao = ?, preco_compra = ?, preco_venda = ?, preco_promocao = ?, " +
                     "stock_atual = ?, stock_minimo = ?, unidade_medida = ?, validade = ?, imagem_url = ?, " +
                     "composto = ?, ativo = ? WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int idx = 1;
            if (produto.getTenantId() != null) stmt.setLong(idx++, produto.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (produto.getCategoriaId() != null) stmt.setLong(idx++, produto.getCategoriaId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, produto.getCodigoBarras());
            stmt.setString(idx++, produto.getSku());
            stmt.setString(idx++, produto.getNome());
            stmt.setString(idx++, produto.getDescricao());
            if (produto.getPrecoCompra() != null) stmt.setDouble(idx++, produto.getPrecoCompra());
            else stmt.setNull(idx++, Types.DOUBLE);
            if (produto.getPrecoVenda() != null) stmt.setDouble(idx++, produto.getPrecoVenda());
            else stmt.setNull(idx++, Types.DOUBLE);
            if (produto.getPrecoPromocao() != null) stmt.setDouble(idx++, produto.getPrecoPromocao());
            else stmt.setNull(idx++, Types.DOUBLE);
            stmt.setInt(idx++, produto.getStockAtual() != null ? produto.getStockAtual() : 0);
            stmt.setInt(idx++, produto.getStockMinimo() != null ? produto.getStockMinimo() : 0);
            stmt.setString(idx++, produto.getUnidadeMedida());
            stmt.setString(idx++, produto.getValidade());
            stmt.setString(idx++, produto.getImagemUrl());
            stmt.setBoolean(idx++, produto.getComposto() != null ? produto.getComposto() : false);
            stmt.setBoolean(idx++, produto.getAtivo() != null ? produto.getAtivo() : true);
            stmt.setLong(idx++, produto.getId());
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar produto: {}", produto.getId(), e);
            return false;
        }
    }

    @Override
    public boolean delete(Long id) {
        PermissionChecker.requireDelete("produtos");
        String sql = "DELETE FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao eliminar produto: {}", id, e);
            return false;
        }
    }

    public boolean updateStock(Long produtoId, int quantidade) {
        return updateStock(produtoId, quantidade, null);
    }

    public boolean updateStock(Long produtoId, int quantidade, String motivo) {
        String sql = "UPDATE " + TABLE + " SET stock_atual = stock_atual + ? WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, quantidade);
            stmt.setLong(2, produtoId);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar stock do produto: {}", produtoId, e);
            return false;
        }
    }
}
