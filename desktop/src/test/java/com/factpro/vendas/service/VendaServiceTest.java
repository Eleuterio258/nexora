package com.factpro.vendas.service;

import com.factpro.core.exception.BusinessException;
import com.factpro.core.exception.StockInsuficienteException;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Produto;
import com.factpro.stock.dao.StockMovimentoDAO;
import com.factpro.vendas.dao.PagamentoDAO;
import com.factpro.vendas.dao.VendaDAO;
import com.factpro.vendas.dao.VendaItemDAO;
import com.factpro.vendas.model.Pagamento;
import com.factpro.vendas.model.Venda;
import com.factpro.vendas.model.VendaItem;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class VendaServiceTest {

    private VendaDAO vendaDAO;
    private VendaItemDAO vendaItemDAO;
    private ProdutoDAO produtoDAO;
    private StockMovimentoDAO stockMovimentoDAO;
    private PagamentoDAO pagamentoDAO;
    private VendaService vendaService;

    @BeforeEach
    void setUp() {
        vendaDAO = mock(VendaDAO.class);
        vendaItemDAO = mock(VendaItemDAO.class);
        produtoDAO = mock(ProdutoDAO.class);
        stockMovimentoDAO = mock(StockMovimentoDAO.class);
        pagamentoDAO = mock(PagamentoDAO.class);
        vendaService = new VendaService(vendaDAO, vendaItemDAO, produtoDAO, stockMovimentoDAO, pagamentoDAO);

        // Clear cart before each test
        CarrinhoService.getInstance().clear();
    }

    @AfterEach
    void tearDown() {
        CarrinhoService.getInstance().clear();
    }

    @Test
    void shouldFinalizeSaleSuccessfully() {
        // Arrange: add items to cart
        CarrinhoService cart = CarrinhoService.getInstance();
        VendaItem item = createVendaItem(1L, 100.0, 2.0);
        cart.addItem(item);

        // Mock DAOs
        Produto produto = createProduto(1L, "Arroz", 50, 10);
        when(produtoDAO.findById(1L)).thenReturn(produto);
        when(vendaDAO.getNextNumeroDocumento("FT")).thenReturn(42);
        when(vendaDAO.save(any(Venda.class))).thenReturn(10L);

        Venda venda = createVenda(1L, "FT");

        // Act
        Venda result = vendaService.finalizarVenda(venda, List.of());

        // Assert
        assertNotNull(result);
        assertEquals(10L, result.getId());
        assertEquals("FT", result.getSerieDocumento());
        assertEquals(42, result.getNumeroDocumento());

        // Verify stock was updated
        verify(produtoDAO).updateStock(eq(1L), eq(-2));
        verify(stockMovimentoDAO).save(argThat(mov -> "saida".equals(mov.getTipo())));
        verify(vendaDAO).save(any(Venda.class));
    }

    @Test
    void shouldThrowWhenCartIsEmpty() {
        Venda venda = createVenda(1L, "FT");

        assertThrows(BusinessException.class, () -> vendaService.finalizarVenda(venda, List.of()));
    }

    @Test
    void shouldThrowWhenProductNotFound() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.addItem(createVendaItem(99L, 100.0, 1.0));

        when(produtoDAO.findById(99L)).thenReturn(null);

        Venda venda = createVenda(1L, "FT");

        assertThrows(BusinessException.class, () -> vendaService.finalizarVenda(venda, List.of()));
    }

    @Test
    void shouldThrowWhenStockIsInsufficient() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.clear(); // Extra safety
        cart.addItem(createVendaItem(1L, 100.0, 10.0));

        Produto produto = createProduto(1L, "Oleo", 3, 5);
        when(produtoDAO.findById(1L)).thenReturn(produto);

        Venda venda = createVenda(1L, "FT");

        assertThrows(StockInsuficienteException.class, () -> {
            try {
                vendaService.finalizarVenda(venda, List.of());
            } finally {
                cart.clear();
            }
        });
    }

    @Test
    void shouldSavePaymentsWhenProvided() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.addItem(createVendaItem(1L, 100.0, 1.0));

        Produto produto = createProduto(1L, "Sumo", 50, 10);
        when(produtoDAO.findById(1L)).thenReturn(produto);
        when(vendaDAO.getNextNumeroDocumento("FT")).thenReturn(1);
        when(vendaDAO.save(any(Venda.class))).thenReturn(5L);

        Venda venda = createVenda(1L, "FT");
        Pagamento pagamento = new Pagamento();
        pagamento.setMetodo("dinheiro");
        pagamento.setValor(100.0);

        vendaService.finalizarVenda(venda, List.of(pagamento));

        ArgumentCaptor<Pagamento> captor = ArgumentCaptor.forClass(Pagamento.class);
        verify(pagamentoDAO).save(captor.capture());
        assertEquals(5L, captor.getValue().getVendaId());
    }

    @Test
    void shouldClearCartAfterFinalizing() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.addItem(createVendaItem(1L, 100.0, 1.0));

        Produto produto = createProduto(1L, "Pao", 20, 5);
        when(produtoDAO.findById(1L)).thenReturn(produto);
        when(vendaDAO.getNextNumeroDocumento("FT")).thenReturn(1);
        when(vendaDAO.save(any(Venda.class))).thenReturn(1L);

        Venda venda = createVenda(1L, "FT");

        vendaService.finalizarVenda(venda, List.of());

        assertEquals(0, cart.getItemCount());
    }

    @Test
    void shouldCancelVendaSuccessfully() {
        Venda venda = createVenda(1L, "FT");
        venda.setStatus("finalizada");

        VendaItem item = createVendaItem(1L, 100.0, 2.0);
        when(vendaDAO.findById(1L)).thenReturn(venda);
        when(vendaDAO.cancel(1L, 2L, "Erro de digitacao")).thenReturn(true);
        when(vendaItemDAO.findByVendaId(1L)).thenReturn(List.of(item));

        boolean result = vendaService.cancelarVenda(1L, 2L, "Erro de digitacao");

        assertTrue(result);
        verify(produtoDAO).updateStock(eq(1L), eq(2));
        verify(stockMovimentoDAO).save(argThat(mov -> "entrada".equals(mov.getTipo())));
    }

    @Test
    void shouldNotCancelNotFoundVenda() {
        when(vendaDAO.findById(1L)).thenReturn(null);

        boolean result = vendaService.cancelarVenda(1L, 2L, "Motivo");

        assertFalse(result);
    }

    @Test
    void shouldNotCancelAlreadyCancelledVenda() {
        Venda venda = createVenda(1L, "FT");
        venda.setStatus("cancelada");
        when(vendaDAO.findById(1L)).thenReturn(venda);

        boolean result = vendaService.cancelarVenda(1L, 2L, "Motivo");

        assertFalse(result);
    }

    @Test
    void shouldFindVendasHoje() {
        Venda v1 = createVenda(1L, "FT");
        v1.setStatus("finalizada");
        Venda v2 = createVenda(2L, "FT");
        v2.setStatus("cancelada");

        when(vendaDAO.findByDateRange(anyString(), anyString())).thenReturn(List.of(v1, v2));

        List<Venda> result = vendaService.findVendasHoje();

        assertEquals(1, result.size());
        assertEquals(1L, result.get(0).getId());
    }

    @Test
    void shouldSumVendasHoje() {
        when(vendaDAO.sumTodayTotal()).thenReturn(1500.0);

        double result = vendaService.sumVendasHoje();

        assertEquals(1500.0, result, 0.01);
    }

    @Test
    void shouldFindVendaById() {
        Venda venda = createVenda(1L, "FT");
        when(vendaDAO.findById(1L)).thenReturn(venda);

        Venda result = vendaService.findById(1L);

        assertNotNull(result);
        assertEquals(1L, result.getId());
    }

    private Venda createVenda(Long id, String serie) {
        Venda venda = new Venda();
        venda.setId(id);
        venda.setTenantId(1L);
        venda.setUserId(1L);
        venda.setSerieDocumento(serie);
        venda.setTipoDocumento("fatura");
        venda.setStatus("aberta");
        return venda;
    }

    private VendaItem createVendaItem(Long produtoId, double preco, double qty) {
        VendaItem item = new VendaItem();
        item.setProdutoId(produtoId);
        item.setPrecoUnitario(preco);
        item.setQuantidade(qty);
        item.setTotal(preco * qty);
        item.setDesconto(0.0);
        return item;
    }

    private Produto createProduto(Long id, String nome, int stock, int minimo) {
        Produto p = new Produto();
        p.setId(id);
        p.setNome(nome);
        p.setStockAtual(stock);
        p.setStockMinimo(minimo);
        p.setAtivo(true);
        return p;
    }
}
