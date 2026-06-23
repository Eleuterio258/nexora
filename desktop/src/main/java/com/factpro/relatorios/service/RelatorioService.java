package com.factpro.relatorios.service;

import com.factpro.clientes.dao.ClienteDAO;
import com.factpro.clientes.model.Cliente;
import com.factpro.contas.dao.ContaReceberDAO;
import com.factpro.contas.model.ContaReceber;
import com.factpro.produtos.dao.CategoriaDAO;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Categoria;
import com.factpro.produtos.model.Produto;
import com.factpro.stock.dao.StockMovimentoDAO;
import com.factpro.vendas.dao.VendaDAO;
import com.factpro.vendas.dao.VendaItemDAO;
import com.factpro.vendas.model.Venda;
import com.factpro.vendas.model.VendaItem;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Service for generating business reports and summaries.
 */
public class RelatorioService {

    private static final Logger logger = LoggerFactory.getLogger(RelatorioService.class);

    private final VendaDAO vendaDAO;
    private final ProdutoDAO produtoDAO;
    private final ClienteDAO clienteDAO;
    private final StockMovimentoDAO stockMovimentoDAO;
    private final VendaItemDAO vendaItemDAO;
    private final CategoriaDAO categoriaDAO;
    private final ContaReceberDAO contaReceberDAO;

    public RelatorioService(VendaDAO vendaDAO, ProdutoDAO produtoDAO, ClienteDAO clienteDAO,
                            StockMovimentoDAO stockMovimentoDAO, VendaItemDAO vendaItemDAO,
                            CategoriaDAO categoriaDAO, ContaReceberDAO contaReceberDAO) {
        this.vendaDAO = vendaDAO;
        this.produtoDAO = produtoDAO;
        this.clienteDAO = clienteDAO;
        this.stockMovimentoDAO = stockMovimentoDAO;
        this.vendaItemDAO = vendaItemDAO;
        this.categoriaDAO = categoriaDAO;
        this.contaReceberDAO = contaReceberDAO;
    }

    /**
     * Returns a summary map with total vendas, count, and average ticket for a date range.
     */
    public Map<String, Object> getVendasResumo(String startDate, String endDate) {
        logger.debug("Generating vendas resumo from {} to {}", startDate, endDate);

        List<Venda> vendas = vendaDAO.findByDateRange(startDate, endDate);
        List<Venda> active = vendas.stream()
                .filter(v -> !"cancelada".equals(v.getStatus()))
                .toList();

        double totalVendas = active.stream()
                .mapToDouble(Venda::getTotal)
                .sum();

        long count = active.size();
        double averageTicket = count > 0 ? totalVendas / count : 0.0;

        Map<String, Object> resumo = new LinkedHashMap<>();
        resumo.put("totalVendas", totalVendas);
        resumo.put("count", count);
        resumo.put("averageTicket", averageTicket);
        resumo.put("startDate", startDate);
        resumo.put("endDate", endDate);

        return resumo;
    }

    /**
     * Returns the top 10 most sold products for a date range.
     */
    public List<Map<String, Object>> getTopProdutos(String startDate, String endDate) {
        logger.debug("Generating top produtos from {} to {}", startDate, endDate);

        List<Venda> vendas = vendaDAO.findByDateRange(startDate, endDate).stream()
                .filter(v -> !"cancelada".equals(v.getStatus()))
                .toList();

        // Aggregate quantity sold by product
        Map<Long, Double> productQtyMap = new HashMap<>();
        for (Venda venda : vendas) {
            List<VendaItem> items = vendaItemDAO.findByVendaId(venda.getId());
            for (VendaItem item : items) {
                productQtyMap.merge(item.getProdutoId(), item.getQuantidade(), Double::sum);
            }
        }

        // Sort by quantity descending and take top 10
        return productQtyMap.entrySet().stream()
                .sorted(Map.Entry.<Long, Double>comparingByValue().reversed())
                .limit(10)
                .map(entry -> {
                    Produto produto = produtoDAO.findById(entry.getKey());
                    Map<String, Object> map = new LinkedHashMap<>();
                    map.put("produtoId", entry.getKey());
                    map.put("produtoNome", produto != null ? produto.getNome() : "Desconhecido");
                    map.put("quantidadeVendida", entry.getValue());
                    map.put("receitaEstimada", produto != null
                            ? produto.getPrecoVenda() != null ? produto.getPrecoVenda() * entry.getValue() : 0.0
                            : 0.0);
                    return map;
                })
                .toList();
    }

    /**
     * Returns a daily sales breakdown for a date range.
     */
    public Map<String, Object> getVendasPorDia(String startDate, String endDate) {
        logger.debug("Generating vendas por dia from {} to {}", startDate, endDate);

        List<Venda> vendas = vendaDAO.findByDateRange(startDate, endDate).stream()
                .filter(v -> !"cancelada".equals(v.getStatus()))
                .toList();

        Map<String, Double> dailyTotals = new LinkedHashMap<>();
        for (Venda venda : vendas) {
            String dateKey = venda.getCriadaEm() != null && venda.getCriadaEm().length() >= 10
                    ? venda.getCriadaEm().substring(0, 10)
                    : "unknown";
            dailyTotals.merge(dateKey, venda.getTotal(), Double::sum);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("dailySales", dailyTotals);
        result.put("startDate", startDate);
        result.put("endDate", endDate);

        return result;
    }

    /**
     * Returns the estimated profit for a date range: sum of (preco_venda - preco_compra) * quantity.
     */
    public double getLucroEstimado(String startDate, String endDate) {
        logger.debug("Calculating lucro estimado from {} to {}", startDate, endDate);

        List<Venda> vendas = vendaDAO.findByDateRange(startDate, endDate).stream()
                .filter(v -> !"cancelada".equals(v.getStatus()))
                .toList();

        double lucroTotal = 0.0;
        for (Venda venda : vendas) {
            List<VendaItem> items = vendaItemDAO.findByVendaId(venda.getId());
            for (VendaItem item : items) {
                Produto produto = produtoDAO.findById(item.getProdutoId());
                if (produto != null && produto.getPrecoVenda() != null && produto.getPrecoCompra() != null) {
                    double margem = produto.getPrecoVenda() - produto.getPrecoCompra();
                    lucroTotal += margem * item.getQuantidade();
                }
            }
        }

        logger.info("Estimated profit from {} to {}: {}", startDate, endDate, lucroTotal);
        return lucroTotal;
    }

    /**
     * Returns a list of String[] with stock report columns: nome, stock_atual, stock_minimo, categoria.
     */
    public List<String[]> getStockReport() {
        logger.debug("Generating stock report");
        List<Produto> produtos = produtoDAO.findAll();
        List<String[]> report = new ArrayList<>();
        for (Produto p : produtos) {
            String categoriaNome = "N/A";
            if (p.getCategoriaId() != null) {
                Categoria cat = categoriaDAO.findById(p.getCategoriaId());
                if (cat != null) {
                    categoriaNome = cat.getNome();
                }
            }
            report.add(new String[]{
                    p.getNome(),
                    String.valueOf(p.getStockAtual() != null ? p.getStockAtual() : 0),
                    String.valueOf(p.getStockMinimo() != null ? p.getStockMinimo() : 0),
                    categoriaNome
            });
        }
        return report;
    }

    /**
     * Returns a list of String[] with clientes report columns: nome, telefone, email, limite_credito, credito_usado.
     */
    public List<String[]> getClientesReport() {
        logger.debug("Generating clientes report");
        List<Cliente> clientes = clienteDAO.findAll();
        List<String[]> report = new ArrayList<>();
        for (Cliente c : clientes) {
            report.add(new String[]{
                    c.getNome(),
                    c.getTelefone() != null ? c.getTelefone() : "",
                    c.getEmail() != null ? c.getEmail() : "",
                    c.getLimiteCredito() != null ? String.valueOf(c.getLimiteCredito()) : "N/A",
                    String.valueOf(c.getCreditoUsado() != null ? c.getCreditoUsado() : 0.0)
            });
        }
        return report;
    }

    /**
     * Returns a list of String[] with contas a receber report columns:
     * cliente_nome, valor_total, valor_pago, valor_pendente, status, data_vencimento.
     */
    public List<String[]> getContasReceberReport() {
        logger.debug("Generating contas receber report");
        List<ContaReceber> contas = contaReceberDAO.findAll();
        List<String[]> report = new ArrayList<>();
        for (ContaReceber cr : contas) {
            String clienteNome = "N/A";
            if (cr.getClienteId() != null) {
                Cliente cliente = clienteDAO.findById(cr.getClienteId());
                if (cliente != null) {
                    clienteNome = cliente.getNome();
                }
            }
            report.add(new String[]{
                    clienteNome,
                    String.valueOf(cr.getValorTotal()),
                    String.valueOf(cr.getValorPago() != null ? cr.getValorPago() : 0.0),
                    String.valueOf(cr.getValorPendente()),
                    cr.getStatus() != null ? cr.getStatus() : "pendente",
                    cr.getDataVencimento() != null ? cr.getDataVencimento() : "N/A"
            });
        }
        return report;
    }
}
