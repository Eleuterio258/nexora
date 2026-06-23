package com.factpro.produtos.service;

import com.factpro.produtos.dao.CategoriaDAO;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Produto;
import com.factpro.stock.dao.StockMovimentoDAO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class ProdutoServiceTest {

    private ProdutoDAO produtoDAO;
    private CategoriaDAO categoriaDAO;
    private StockMovimentoDAO stockMovimentoDAO;
    private ProdutoService produtoService;

    @BeforeEach
    void setUp() {
        produtoDAO = mock(ProdutoDAO.class);
        categoriaDAO = mock(CategoriaDAO.class);
        stockMovimentoDAO = mock(StockMovimentoDAO.class);
        produtoService = new ProdutoService(produtoDAO, categoriaDAO, stockMovimentoDAO);
    }

    @Test
    void shouldFindById() {
        Produto p = createProduto(1L, "Arroz", 50);
        when(produtoDAO.findById(1L)).thenReturn(p);

        Produto result = produtoService.findById(1L);

        assertNotNull(result);
        assertEquals("Arroz", result.getNome());
    }

    @Test
    void shouldFindAll() {
        when(produtoDAO.findAll()).thenReturn(Arrays.asList(
                createProduto(1L, "Arroz", 50),
                createProduto(2L, "Oleo", 30)
        ));

        List<Produto> result = produtoService.findAll();

        assertEquals(2, result.size());
    }

    @Test
    void shouldReturnEmptyWhenSearchQueryIsEmpty() {
        List<Produto> result = produtoService.search("");

        assertTrue(result.isEmpty());
        verify(produtoDAO, never()).search(anyString());
    }

    @Test
    void shouldSearchByQuery() {
        when(produtoDAO.search("arroz")).thenReturn(List.of(createProduto(1L, "Arroz", 50)));

        List<Produto> result = produtoService.search("arroz");

        assertEquals(1, result.size());
        verify(produtoDAO).search("arroz");
    }

    @Test
    void shouldFindByCodigoBarras() {
        Produto p = createProduto(1L, "Arroz", 50);
        when(produtoDAO.findByCodigoBarras("7890123456789")).thenReturn(p);

        Produto result = produtoService.findByCodigoBarras("7890123456789");

        assertNotNull(result);
    }

    @Test
    void shouldFindLowStock() {
        when(produtoDAO.findLowStock()).thenReturn(List.of(createProduto(1L, "Oleo", 2)));

        List<Produto> result = produtoService.findLowStock();

        assertEquals(1, result.size());
    }

    @Test
    void shouldSaveSuccessfully() {
        Produto p = createProduto(null, "Arroz", 50);
        when(produtoDAO.save(any(Produto.class))).thenReturn(1L);

        Produto result = produtoService.save(p);

        assertEquals(1L, result.getId());
    }

    @Test
    void shouldThrowWhenSaveFails() {
        Produto p = createProduto(null, "Arroz", 50);
        when(produtoDAO.save(any(Produto.class))).thenReturn(null);

        assertThrows(RuntimeException.class, () -> produtoService.save(p));
    }

    @Test
    void shouldUpdateSuccessfully() {
        Produto p = createProduto(1L, "Arroz", 50);
        when(produtoDAO.update(any(Produto.class))).thenReturn(true);

        Produto result = produtoService.update(p);

        assertEquals("Arroz", result.getNome());
    }

    @Test
    void shouldThrowWhenUpdateFails() {
        Produto p = createProduto(1L, "Arroz", 50);
        when(produtoDAO.update(any(Produto.class))).thenReturn(false);

        assertThrows(RuntimeException.class, () -> produtoService.update(p));
    }

    @Test
    void shouldDeleteSuccessfully() {
        when(produtoDAO.delete(1L)).thenReturn(true);

        boolean result = produtoService.delete(1L);

        assertTrue(result);
    }

    @Test
    void shouldRecordStockEntrada() {
        when(produtoDAO.updateStock(1L, 10)).thenReturn(true);

        produtoService.entradaStock(1L, 10.0, "Compra fornecedor");

        verify(produtoDAO).updateStock(1L, 10);
        verify(stockMovimentoDAO).save(argThat(m -> "entrada".equals(m.getTipo())));
    }

    @Test
    void shouldThrowWhenStockEntradaFails() {
        when(produtoDAO.updateStock(1L, 10)).thenReturn(false);

        assertThrows(RuntimeException.class, () -> produtoService.entradaStock(1L, 10.0, "Compra"));
    }

    @Test
    void shouldRecordStockSaida() {
        when(produtoDAO.updateStock(1L, -5)).thenReturn(true);

        produtoService.saidaStock(1L, 5.0, "Venda");

        verify(produtoDAO).updateStock(1L, -5);
        verify(stockMovimentoDAO).save(argThat(m -> "saida".equals(m.getTipo())));
    }

    @Test
    void shouldRecordStockAjusteEntrada() {
        when(produtoDAO.updateStock(1L, 3)).thenReturn(true);

        produtoService.ajusteStock(1L, 3.0, "entrada", "Correcao inventario");

        verify(produtoDAO).updateStock(1L, 3);
        verify(stockMovimentoDAO).save(argThat(m -> "entrada".equals(m.getTipo())));
    }

    @Test
    void shouldRecordStockAjustaSaida() {
        when(produtoDAO.updateStock(1L, -2)).thenReturn(true);

        produtoService.ajusteStock(1L, 2.0, "saida", "Avaria");

        verify(produtoDAO).updateStock(1L, -2);
        verify(stockMovimentoDAO).save(argThat(m -> "saida".equals(m.getTipo())));
    }

    @Test
    void shouldThrowWhenStockAdjustmentFails() {
        when(produtoDAO.updateStock(1L, 5)).thenReturn(false);

        assertThrows(RuntimeException.class, () -> produtoService.ajusteStock(1L, 5.0, "entrada", "Correcao"));
    }

    private Produto createProduto(Long id, String nome, int stock) {
        Produto p = new Produto();
        p.setId(id);
        p.setNome(nome);
        p.setStockAtual(stock);
        p.setStockMinimo(5);
        p.setAtivo(true);
        return p;
    }
}
