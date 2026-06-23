package com.factpro.stock.service;

import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Produto;
import com.factpro.stock.dao.StockMovimentoDAO;
import com.factpro.stock.model.StockMovimento;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * Service for managing stock movements and alerts.
 */
public class StockService {

    private static final Logger logger = LoggerFactory.getLogger(StockService.class);

    private final StockMovimentoDAO stockMovimentoDAO;
    private final ProdutoDAO produtoDAO;

    public StockService(StockMovimentoDAO stockMovimentoDAO, ProdutoDAO produtoDAO) {
        this.stockMovimentoDAO = stockMovimentoDAO;
        this.produtoDAO = produtoDAO;
    }

    public List<StockMovimento> findByProdutoId(Long produtoId) {
        return stockMovimentoDAO.findByProdutoId(produtoId);
    }

    public List<StockMovimento> findAll() {
        return stockMovimentoDAO.findAll();
    }

    /**
     * Records a stock entry for a product.
     */
    public void entrada(Long produtoId, double quantidade, String motivo, Long userId) {
        logger.info("Stock entry: produtoId={}, qty={}, motivo={}, userId={}", produtoId, quantidade, motivo, userId);

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
        movimento.setUserId(userId);
        stockMovimentoDAO.save(movimento);

        logger.info("Stock entry recorded for produto {}", produtoId);
    }

    /**
     * Records a stock exit for a product.
     */
    public void saida(Long produtoId, double quantidade, String motivo, Long userId) {
        logger.info("Stock exit: produtoId={}, qty={}, motivo={}, userId={}", produtoId, quantidade, motivo, userId);

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
        movimento.setUserId(userId);
        stockMovimentoDAO.save(movimento);

        logger.info("Stock exit recorded for produto {}", produtoId);
    }

    /**
     * Manual stock adjustment. Tipo should be "entrada" or "saida".
     */
    public void ajuste(Long produtoId, double quantidade, String tipo, String motivo, Long userId) {
        logger.info("Stock adjustment: produtoId={}, qty={}, tipo={}, motivo={}, userId={}",
                produtoId, quantidade, tipo, motivo, userId);

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
        movimento.setUserId(userId);
        stockMovimentoDAO.save(movimento);

        logger.info("Stock adjustment recorded for produto {} ({})", produtoId, tipo);
    }

    /**
     * Returns products where stock_atual <= stock_minimo.
     */
    public List<Produto> getLowStockAlerts() {
        return produtoDAO.findLowStock();
    }
}
