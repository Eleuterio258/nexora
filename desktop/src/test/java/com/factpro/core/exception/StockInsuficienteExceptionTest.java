package com.factpro.core.exception;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class StockInsuficienteExceptionTest {

    @Test
    void shouldCreateWithBasicInfo() {
        StockInsuficienteException ex = new StockInsuficienteException("Arroz", 2, 5);
        assertEquals("Arroz", ex.getProdutoNome());
        assertEquals(2, ex.getStockAtual());
        assertEquals(5.0, ex.getQuantidadePedida(), 0.01);
        assertNull(ex.getProdutoId());
        assertEquals("STOCK_INSUFICIENTE", ex.getErrorCode());
        assertTrue(ex.getMessage().contains("Arroz"));
        assertTrue(ex.getMessage().contains("2"));
        assertTrue(ex.getMessage().contains("5"));
    }

    @Test
    void shouldCreateWithProductId() {
        StockInsuficienteException ex = new StockInsuficienteException(42L, "Oleo", 1, 3);
        assertEquals(42L, ex.getProdutoId());
        assertEquals("Oleo", ex.getProdutoNome());
        assertEquals(1, ex.getStockAtual());
        assertEquals(3.0, ex.getQuantidadePedida(), 0.01);
        assertTrue(ex.getMessage().contains("ID:42"));
    }
}
