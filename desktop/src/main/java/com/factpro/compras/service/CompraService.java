package com.factpro.compras.service;

import com.factpro.compras.dao.CompraDAO;
import com.factpro.compras.dao.CompraItemDAO;
import com.factpro.compras.model.Compra;
import com.factpro.compras.model.CompraItem;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Produto;
import com.factpro.stock.dao.StockMovimentoDAO;
import com.factpro.stock.model.StockMovimento;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * Service for managing purchases and stock reception.
 */
public class CompraService {

    private static final Logger logger = LoggerFactory.getLogger(CompraService.class);

    private final CompraDAO compraDAO;
    private final CompraItemDAO compraItemDAO;
    private final ProdutoDAO produtoDAO;
    private final StockMovimentoDAO stockMovimentoDAO;

    public CompraService(CompraDAO compraDAO, CompraItemDAO compraItemDAO, ProdutoDAO produtoDAO, StockMovimentoDAO stockMovimentoDAO) {
        this.compraDAO = compraDAO;
        this.compraItemDAO = compraItemDAO;
        this.produtoDAO = produtoDAO;
        this.stockMovimentoDAO = stockMovimentoDAO;
    }

    public Compra save(Compra compra) {
        Long id = compraDAO.save(compra);
        if (id == null) {
            throw new RuntimeException("Falha ao guardar a compra.");
        }
        compra.setId(id);
        logger.info("Compra saved with ID {}", id);
        return compra;
    }

    /**
     * Guarda a compra e os seus itens.
     */
    public Compra saveWithItems(Compra compra, List<CompraItem> items) {
        Compra savedCompra = save(compra);
        for (CompraItem item : items) {
            item.setCompraId(savedCompra.getId());
            compraItemDAO.save(item);
        }
        logger.info("Compra guardada com {} itens", items.size());
        return savedCompra;
    }

    public Compra update(Compra compra) {
        boolean updated = compraDAO.update(compra);
        if (!updated) {
            throw new RuntimeException("Falha ao atualizar a compra.");
        }
        logger.info("Compra updated: ID {}", compra.getId());
        return compra;
    }

    /**
     * Receives a purchase: updates status, adds stock for each product,
     * and creates stock movements.
     */
    public void receiveCompra(Long compraId, Long userId) {
        logger.info("Recebendo compra ID {}", compraId);

        Compra compra = compraDAO.findById(compraId);
        if (compra == null) {
            throw new RuntimeException("Compra nao encontrada: ID " + compraId);
        }

        if ("recebida".equals(compra.getStatus())) {
            logger.warn("Compra {} já foi recebida", compraId);
            return;
        }

        boolean updated = compraDAO.receive(compraId);
        if (!updated) {
            throw new RuntimeException("Falha ao atualizar status da compra " + compraId);
        }

        // Iterate over items and update stock
        List<CompraItem> items = compraItemDAO.findByCompraId(compraId);
        for (CompraItem item : items) {
            Produto produto = produtoDAO.findById(item.getProdutoId());
            if (produto != null) {
                produtoDAO.updateStock(item.getProdutoId(), (int) Math.round(item.getQuantidade()), "entrada");

                StockMovimento movimento = new StockMovimento();
                movimento.setProdutoId(item.getProdutoId());
                movimento.setTipo("entrada");
                movimento.setQuantidade(item.getQuantidade().intValue());
                movimento.setMotivo("Recebimento compra #" + compraId);
                movimento.setReferencia("COMPRA-" + compraId);
                movimento.setUserId(userId);
                stockMovimentoDAO.save(movimento);

                logger.info("Stock atualizado: produto {} +{}", produto.getNome(), item.getQuantidade());
            }
        }

        logger.info("Compra {} recebida com sucesso. {} itens processados.", compraId, items.size());
    }

    public List<Compra> findAll() {
        return compraDAO.findAll();
    }

    public Compra findById(Long id) {
        return compraDAO.findById(id);
    }

    public List<CompraItem> getCompraItems(Long compraId) {
        return compraItemDAO.findByCompraId(compraId);
    }
}
