package com.factpro.vendas.service;

import com.factpro.vendas.dao.PagamentoDAO;
import com.factpro.vendas.model.Pagamento;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class PagamentoServiceTest {

    private PagamentoDAO pagamentoDAO;
    private PagamentoService pagamentoService;

    @BeforeEach
    void setUp() {
        pagamentoDAO = mock(PagamentoDAO.class);
        pagamentoService = new PagamentoService(pagamentoDAO);
    }

    @Test
    void shouldRegisterPaymentSuccessfully() {
        when(pagamentoDAO.save(any(Pagamento.class))).thenReturn(1L);

        pagamentoService.registarPagamento(1L, "dinheiro", 500.0, null);

        ArgumentCaptor<Pagamento> captor = ArgumentCaptor.forClass(Pagamento.class);
        verify(pagamentoDAO).save(captor.capture());

        Pagamento saved = captor.getValue();
        assertEquals(1L, saved.getVendaId());
        assertEquals("dinheiro", saved.getMetodo());
        assertEquals(500.0, saved.getValor(), 0.01);
        assertEquals("processado", saved.getStatus());
        assertNotNull(saved.getProcessadoEm());
    }

    @Test
    void shouldThrowWhenSaveFails() {
        when(pagamentoDAO.save(any(Pagamento.class))).thenReturn(null);

        assertThrows(RuntimeException.class, () ->
                pagamentoService.registarPagamento(1L, "cartao", 200.0, "TX123"));
    }

    @Test
    void shouldReturnPaymentsByVenda() {
        Pagamento p1 = new Pagamento();
        p1.setId(1L);
        p1.setVendaId(1L);
        p1.setMetodo("dinheiro");
        p1.setValor(300.0);

        Pagamento p2 = new Pagamento();
        p2.setId(2L);
        p2.setVendaId(1L);
        p2.setMetodo("mpesa");
        p2.setValor(200.0);

        when(pagamentoDAO.findByVendaId(1L)).thenReturn(Arrays.asList(p1, p2));

        List<Pagamento> result = pagamentoService.getPagamentosByVenda(1L);

        assertEquals(2, result.size());
        assertEquals(500.0, result.stream().mapToDouble(Pagamento::getValor).sum(), 0.01);
    }

    @Test
    void shouldReturnEmptyListWhenNoPayments() {
        when(pagamentoDAO.findByVendaId(99L)).thenReturn(List.of());

        List<Pagamento> result = pagamentoService.getPagamentosByVenda(99L);

        assertTrue(result.isEmpty());
    }
}
