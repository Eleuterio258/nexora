package com.factpro.produtos.service;

import com.factpro.produtos.dao.CategoriaDAO;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Produto;
import com.factpro.stock.dao.StockMovimentoDAO;
import com.factpro.stock.model.StockMovimento;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * Service for managing products and stock operations.
 */
public class ProdutoService {

    private static final Logger logger = LoggerFactory.getLogger(ProdutoService.class);

    private final ProdutoDAO produtoDAO;
    private final CategoriaDAO categoriaDAO;
    private final StockMovimentoDAO stockMovimentoDAO;

    public ProdutoService(ProdutoDAO produtoDAO, CategoriaDAO categoriaDAO, StockMovimentoDAO stockMovimentoDAO) {
        this.produtoDAO = produtoDAO;
        this.categoriaDAO = categoriaDAO;
        this.stockMovimentoDAO = stockMovimentoDAO;
    }

    public Produto findById(Long id) {
        return produtoDAO.findById(id);
    }

    public List<Produto> findAll() {
        return produtoDAO.findAll();
    }

    /**
     * Searches products by name or barcode.
     */
    public List<Produto> search(String query) {
        if (query == null || query.isBlank()) {
            return List.of();
        }
        return produtoDAO.search(query.trim());
    }

    public Produto findByCodigoBarras(String codigo) {
        return produtoDAO.findByCodigoBarras(codigo);
    }

    /**
     * Returns products where current stock is at or below minimum stock.
     */
    public List<Produto> findLowStock() {
        return produtoDAO.findLowStock();
    }

    public Produto save(Produto produto) {
        Long id = produtoDAO.save(produto);
        if (id == null) {
            throw new RuntimeException("Falha ao guardar o produto.");
        }
        produto.setId(id);
        logger.info("Product saved: {} (ID: {})", produto.getNome(), id);
        return produto;
    }

    public Produto update(Produto produto) {
        boolean updated = produtoDAO.update(produto);
        if (!updated) {
            throw new RuntimeException("Falha ao atualizar o produto.");
        }
        logger.info("Product updated: {} (ID: {})", produto.getNome(), produto.getId());
        return produto;
    }

    public boolean delete(Long id) {
        boolean deleted = produtoDAO.delete(id);
        if (deleted) {
            logger.info("Product deleted: ID {}", id);
        } else {
            logger.warn("Failed to delete product: ID {}", id);
        }
        return deleted;
    }

    /**
     * Increases stock for a product and records a stock movement.
     */
    public void entradaStock(Long produtoId, double quantidade, String motivo) {
        logger.info("Stock entry for produto {}: qty={}, motivo={}", produtoId, quantidade, motivo);

        int qty = (int) Math.round(quantidade);
        boolean updated = produtoDAO.updateStock(produtoId, qty);
        if (!updated) {
            throw new RuntimeException("Falha ao atualizar stock do produto " + produtoId);
        }

        StockMovimento movimento = new StockMovimento();
        movimento.setProdutoId(produtoId);
        movimento.setTipo("entrada");
        movimento.setQuantidade(qty);
        movimento.setMotivo(motivo);
        movimento.setReferencia("ENTRADA-" + produtoId);
        stockMovimentoDAO.save(movimento);

        logger.info("Stock entry recorded for produto {}", produtoId);
    }

    /**
     * Decreases stock for a product and records a stock movement.
     */
    public void saidaStock(Long produtoId, double quantidade, String motivo) {
        logger.info("Stock exit for produto {}: qty={}, motivo={}", produtoId, quantidade, motivo);

        int qty = (int) Math.round(quantidade);
        boolean updated = produtoDAO.updateStock(produtoId, -qty);
        if (!updated) {
            throw new RuntimeException("Falha ao atualizar stock do produto " + produtoId);
        }

        StockMovimento movimento = new StockMovimento();
        movimento.setProdutoId(produtoId);
        movimento.setTipo("saida");
        movimento.setQuantidade(qty);
        movimento.setMotivo(motivo);
        movimento.setReferencia("SAIDA-" + produtoId);
        stockMovimentoDAO.save(movimento);

        logger.info("Stock exit recorded for produto {}", produtoId);
    }

    /**
     * Manual stock adjustment. Tipo should be "entrada" or "saida".
     */
    public void ajusteStock(Long produtoId, double quantidade, String tipo, String motivo) {
        logger.info("Stock adjustment for produto {}: qty={}, tipo={}, motivo={}", produtoId, quantidade, tipo, motivo);

        int qty = (int) Math.round(quantidade);
        int delta = "entrada".equalsIgnoreCase(tipo) ? qty : -qty;

        boolean updated = produtoDAO.updateStock(produtoId, delta);
        if (!updated) {
            throw new RuntimeException("Falha ao ajustar stock do produto " + produtoId);
        }

        StockMovimento movimento = new StockMovimento();
        movimento.setProdutoId(produtoId);
        movimento.setTipo(tipo.toLowerCase());
        movimento.setQuantidade(qty);
        movimento.setMotivo(motivo);
        movimento.setReferencia("AJUSTE-" + produtoId);
        stockMovimentoDAO.save(movimento);

        logger.info("Stock adjustment recorded for produto {} ({})", produtoId, tipo);
    }
}
