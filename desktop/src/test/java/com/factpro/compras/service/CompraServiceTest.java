package com.factpro.compras.service;

import com.factpro.auth.PermissionChecker;
import com.factpro.compras.dao.CompraDAO;
import com.factpro.compras.dao.CompraItemDAO;
import com.factpro.compras.model.Compra;
import com.factpro.compras.model.CompraItem;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Produto;
import com.factpro.stock.dao.StockMovimentoDAO;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class CompraServiceTest {

    private CompraDAO compraDAO;
    private CompraItemDAO compraItemDAO;
    private ProdutoDAO produtoDAO;
    private StockMovimentoDAO stockMovimentoDAO;
    private CompraService compraService;

    @BeforeEach
    void setUp() {
        PermissionChecker.setTestBypass(true);
        compraDAO = mock(CompraDAO.class);
        compraItemDAO = mock(CompraItemDAO.class);
        produtoDAO = mock(ProdutoDAO.class);
        stockMovimentoDAO = mock(StockMovimentoDAO.class);
        compraService = new CompraService(compraDAO, compraItemDAO, produtoDAO, stockMovimentoDAO);
    }

    @AfterEach
    void tearDown() {
        PermissionChecker.setTestBypass(false);
    }

    @Test
    void shouldSaveCompraSuccessfully() {
        Compra compra = createCompra(null, 1000.0);
        when(compraDAO.save(any(Compra.class))).thenReturn(1L);

        Compra result = compraService.save(compra);

        assertEquals(1L, result.getId());
    }

    @Test
    void shouldThrowWhenSaveFails() {
        Compra compra = createCompra(null, 1000.0);
        when(compraDAO.save(any(Compra.class))).thenReturn(null);

        assertThrows(RuntimeException.class, () -> compraService.save(compra));
    }

    @Test
    void shouldSaveWithItems() {
        Compra compra = createCompra(null, 500.0);
        CompraItem item1 = createCompraItem(null, 1L, 10.0, 20.0);
        CompraItem item2 = createCompraItem(null, 2L, 5.0, 30.0);

        when(compraDAO.save(any(Compra.class))).thenReturn(5L);

        compraService.saveWithItems(compra, List.of(item1, item2));

        verify(compraItemDAO, times(2)).save(any(CompraItem.class));
        ArgumentCaptor<CompraItem> captor = ArgumentCaptor.forClass(CompraItem.class);
        verify(compraItemDAO, times(2)).save(captor.capture());
        for (CompraItem saved : captor.getAllValues()) {
            assertEquals(5L, saved.getCompraId());
        }
    }

    @Test
    void shouldUpdateCompraSuccessfully() {
        Compra compra = createCompra(1L, 1000.0);
        when(compraDAO.update(any(Compra.class))).thenReturn(true);

        Compra result = compraService.update(compra);

        assertEquals(1L, result.getId());
    }

    @Test
    void shouldThrowWhenUpdateFails() {
        Compra compra = createCompra(1L, 1000.0);
        when(compraDAO.update(any(Compra.class))).thenReturn(false);

        assertThrows(RuntimeException.class, () -> compraService.update(compra));
    }

    @Test
    void shouldReceiveCompraSuccessfully() {
        Compra compra = createCompra(1L, 500.0);
        compra.setStatus("pendente");

        CompraItem item = createCompraItem(1L, 1L, 10.0, 50.0);
        Produto produto = createProduto(1L, "Arroz", 5);

        when(compraDAO.findById(1L)).thenReturn(compra);
        when(compraDAO.receive(1L)).thenReturn(true);
        when(compraItemDAO.findByCompraId(1L)).thenReturn(List.of(item));
        when(produtoDAO.findById(1L)).thenReturn(produto);
        when(produtoDAO.updateStock(eq(1L), eq(10), eq("entrada"))).thenReturn(true);

        compraService.receiveCompra(1L, 2L);

        verify(compraDAO).receive(1L);
        verify(produtoDAO).updateStock(1L, 10, "entrada");
        verify(stockMovimentoDAO).save(argThat(m -> "entrada".equals(m.getTipo())));
    }

    @Test
    void shouldThrowWhenReceivingNotFoundCompra() {
        when(compraDAO.findById(99L)).thenReturn(null);

        assertThrows(RuntimeException.class, () -> compraService.receiveCompra(99L, 1L));
    }

    @Test
    void shouldSkipAlreadyReceivedCompra() {
        Compra compra = createCompra(1L, 500.0);
        compra.setStatus("recebida");
        when(compraDAO.findById(1L)).thenReturn(compra);

        compraService.receiveCompra(1L, 1L);

        verify(compraDAO, never()).receive(1L);
        verify(compraItemDAO, never()).findByCompraId(anyLong());
    }

    @Test
    void shouldThrowWhenReceiveUpdateFails() {
        Compra compra = createCompra(1L, 500.0);
        compra.setStatus("pendente");
        when(compraDAO.findById(1L)).thenReturn(compra);
        when(compraDAO.receive(1L)).thenReturn(false);

        assertThrows(RuntimeException.class, () -> compraService.receiveCompra(1L, 1L));
    }

    @Test
    void shouldHandleNullProdutoDuringReception() {
        Compra compra = createCompra(1L, 500.0);
        compra.setStatus("pendente");

        CompraItem item = createCompraItem(1L, 99L, 10.0, 50.0);
        when(compraDAO.findById(1L)).thenReturn(compra);
        when(compraDAO.receive(1L)).thenReturn(true);
        when(compraItemDAO.findByCompraId(1L)).thenReturn(List.of(item));
        when(produtoDAO.findById(99L)).thenReturn(null);

        assertDoesNotThrow(() -> compraService.receiveCompra(1L, 1L));

        verify(stockMovimentoDAO, never()).save(any());
    }

    @Test
    void shouldReturnAllCompras() {
        when(compraDAO.findAll()).thenReturn(List.of(createCompra(1L, 100.0), createCompra(2L, 200.0)));

        List<Compra> result = compraService.findAll();

        assertEquals(2, result.size());
    }

    @Test
    void shouldFindById() {
        Compra compra = createCompra(1L, 100.0);
        when(compraDAO.findById(1L)).thenReturn(compra);

        Compra result = compraService.findById(1L);

        assertNotNull(result);
    }

    @Test
    void shouldReturnItemsByCompraId() {
        CompraItem item = createCompraItem(1L, 1L, 10.0, 50.0);
        when(compraItemDAO.findByCompraId(1L)).thenReturn(List.of(item));

        List<CompraItem> result = compraService.getCompraItems(1L);

        assertEquals(1, result.size());
    }

    private Compra createCompra(Long id, Double total) {
        Compra c = new Compra();
        c.setId(id);
        c.setTotal(total);
        c.setStatus("pendente");
        return c;
    }

    private CompraItem createCompraItem(Long id, Long produtoId, Double qty, Double preco) {
        CompraItem item = new CompraItem();
        item.setId(id);
        item.setProdutoId(produtoId);
        item.setQuantidade(qty);
        item.setPrecoUnitario(preco);
        item.setTotal(qty * preco);
        return item;
    }

    private Produto createProduto(Long id, String nome, int stock) {
        Produto p = new Produto();
        p.setId(id);
        p.setNome(nome);
        p.setStockAtual(stock);
        return p;
    }
}
