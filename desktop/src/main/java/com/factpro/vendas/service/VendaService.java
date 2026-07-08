package com.factpro.vendas.service;

import com.factpro.auth.PermissionChecker;
import com.factpro.core.event.EventManager;
import com.factpro.core.exception.BusinessException;
import com.factpro.core.exception.StockInsuficienteException;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Produto;
import com.factpro.stock.dao.StockMovimentoDAO;
import com.factpro.stock.model.StockMovimento;
import com.factpro.vendas.dao.PagamentoDAO;
import com.factpro.vendas.dao.VendaDAO;
import com.factpro.vendas.dao.VendaItemDAO;
import com.factpro.vendas.model.Pagamento;
import com.factpro.vendas.model.Venda;
import com.factpro.vendas.model.VendaItem;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Service orchestrating sale finalization, cancellation, and queries.
 */
public class VendaService {

    private static final Logger logger = LoggerFactory.getLogger(VendaService.class);

    private final VendaDAO vendaDAO;
    private final VendaItemDAO vendaItemDAO;
    private final ProdutoDAO produtoDAO;
    private final StockMovimentoDAO stockMovimentoDAO;
    private final PagamentoDAO pagamentoDAO;

    public VendaService(VendaDAO vendaDAO, VendaItemDAO vendaItemDAO, ProdutoDAO produtoDAO,
                        StockMovimentoDAO stockMovimentoDAO, PagamentoDAO pagamentoDAO) {
        this.vendaDAO = vendaDAO;
        this.vendaItemDAO = vendaItemDAO;
        this.produtoDAO = produtoDAO;
        this.stockMovimentoDAO = stockMovimentoDAO;
        this.pagamentoDAO = pagamentoDAO;
    }

    /**
     * Finalizes a sale: validates stock, generates document number, saves venda + items + pagamentos,
     * updates stock, creates stock movements, and returns the saved venda.
     */
    public Venda finalizarVenda(Venda venda, List<Pagamento> pagamentos) {
        PermissionChecker.requireCreate("vendas");
        logger.info("Finalizing sale for clienteId {}", venda.getClienteId());

        // 1. Validate stock availability
        List<VendaItem> items = CarrinhoService.getInstance().getItems();
        if (items.isEmpty()) {
            throw new BusinessException("Carrinho vazio. Nao ha itens para finalizar a venda.");
        }

        for (VendaItem item : items) {
            Produto produto = produtoDAO.findById(item.getProdutoId());
            if (produto == null) {
                throw new BusinessException("Produto nao encontrado: ID " + item.getProdutoId());
            }
            if (produto.getStockAtual() < item.getQuantidade()) {
                throw new StockInsuficienteException(
                        produto.getNome(),
                        produto.getStockAtual(),
                        item.getQuantidade()
                );
            }
        }

        // 2. Generate document number
        String serie = venda.getSerieDocumento() != null ? venda.getSerieDocumento() : "FT";
        venda.setSerieDocumento(serie);
        int numeroDoc = vendaDAO.getNextNumeroDocumento(serie);
        venda.setNumeroDocumento(numeroDoc);

        // 3. Calculate totals from cart
        double subtotal = CarrinhoService.getInstance().getSubtotal();
        double desconto = CarrinhoService.getInstance().getDesconto();
        double total = CarrinhoService.getInstance().getTotal();
        venda.setSubtotal(subtotal);
        venda.setDesconto(desconto);
        venda.setTotal(total);

        // 4. Save venda
        Long vendaId = vendaDAO.save(venda);
        if (vendaId == null) {
            throw new RuntimeException("Falha ao guardar a venda.");
        }
        venda.setId(vendaId);
        logger.info("Venda saved with ID {}", vendaId);

        // 5. Save venda items and update stock
        for (VendaItem item : items) {
            item.setVendaId(vendaId);
            vendaItemDAO.save(item);

            // Update product stock
            int qty = (int) Math.round(item.getQuantidade());
            produtoDAO.updateStock(item.getProdutoId(), -qty);

            // Check low stock after update
            Produto updatedProduct = produtoDAO.findById(item.getProdutoId());
            if (updatedProduct != null && updatedProduct.getStockMinimo() != null
                    && updatedProduct.getStockAtual() <= updatedProduct.getStockMinimo()) {
                EventManager.getInstance().emit("stock_baixo",
                        new Object[]{updatedProduct.getNome(), updatedProduct.getStockAtual()});
            }

            // Create stock movement
            StockMovimento movimento = new StockMovimento();
            movimento.setTenantId(venda.getTenantId());
            movimento.setProdutoId(item.getProdutoId());
            movimento.setTipo("saida");
            movimento.setQuantidade(qty);
            movimento.setMotivo("Venda #" + vendaId);
            movimento.setReferencia("VENDA-" + vendaId);
            movimento.setUserId(venda.getUserId());
            stockMovimentoDAO.save(movimento);
        }

        // 6. Save pagamentos
        if (pagamentos != null) {
            for (Pagamento pagamento : pagamentos) {
                pagamento.setVendaId(vendaId);
                pagamentoDAO.save(pagamento);
            }
        }

        // 7. Clear the cart
        CarrinhoService.getInstance().clear();

        logger.info("Sale {} finalized successfully with {} items", vendaId, items.size());
        return venda;
    }

    /**
     * Cancels a sale: updates status to 'cancelada' and restores stock.
     */
    public boolean cancelarVenda(Long vendaId, Long userId, String motivo) {
        PermissionChecker.require("vendas:cancel");
        logger.info("Cancelling sale ID {} by user {} - reason: {}", vendaId, userId, motivo);

        Venda venda = vendaDAO.findById(vendaId);
        if (venda == null) {
            logger.error("Venda not found: ID {}", vendaId);
            return false;
        }

        if ("cancelada".equals(venda.getStatus())) {
            logger.warn("Venda {} is already cancelled", vendaId);
            return false;
        }

        // Cancel the sale in DB
        boolean cancelled = vendaDAO.cancel(vendaId, userId, motivo);
        if (!cancelled) {
            logger.error("Failed to cancel venda {}", vendaId);
            return false;
        }

        // Restore stock for each item
        List<VendaItem> items = vendaItemDAO.findByVendaId(vendaId);
        for (VendaItem item : items) {
            int qty = (int) Math.round(item.getQuantidade());
            produtoDAO.updateStock(item.getProdutoId(), qty);

            StockMovimento movimento = new StockMovimento();
            movimento.setTenantId(venda.getTenantId());
            movimento.setProdutoId(item.getProdutoId());
            movimento.setTipo("entrada");
            movimento.setQuantidade(qty);
            movimento.setMotivo("Cancelamento venda #" + vendaId + ": " + motivo);
            movimento.setReferencia("CANCEL-" + vendaId);
            movimento.setUserId(userId);
            stockMovimentoDAO.save(movimento);
        }

        logger.info("Sale {} cancelled successfully", vendaId);

        // Emit cancellation event for notifications
        EventManager.getInstance().emit("venda_cancelada", venda);

        return true;
    }

    /**
     * Returns today's sales (non-cancelled).
     */
    public List<Venda> findVendasHoje() {
        String today = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE);
        String start = today + " 00:00:00";
        String end = today + " 23:59:59";
        List<Venda> all = vendaDAO.findByDateRange(start, end);
        return all.stream()
                .filter(v -> !"cancelada".equals(v.getStatus()))
                .toList();
    }

    /**
     * Returns the total revenue of today's sales.
     */
    public double sumVendasHoje() {
        return vendaDAO.sumTodayTotal();
    }

    /**
     * Returns sales within a date range.
     */
    public List<Venda> findVendasByDateRange(String startDate, String endDate) {
        logger.debug("Finding vendas from {} to {}", startDate, endDate);
        return vendaDAO.findByDateRange(startDate, endDate);
    }

    /**
     * Finds a venda by ID.
     */
    public Venda findById(Long id) {
        return vendaDAO.findById(id);
    }
}
