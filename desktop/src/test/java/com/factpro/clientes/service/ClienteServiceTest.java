package com.factpro.clientes.service;

import com.factpro.clientes.dao.ClienteDAO;
import com.factpro.clientes.model.Cliente;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class ClienteServiceTest {

    private ClienteDAO clienteDAO;
    private ClienteService clienteService;

    @BeforeEach
    void setUp() {
        clienteDAO = mock(ClienteDAO.class);
        clienteService = new ClienteService(clienteDAO);
    }

    @Test
    void shouldFindById() {
        Cliente cliente = createCliente(1L, "Joao", 1000.0);
        when(clienteDAO.findById(1L)).thenReturn(cliente);

        Cliente result = clienteService.findById(1L);

        assertNotNull(result);
        assertEquals("Joao", result.getNome());
    }

    @Test
    void shouldFindAll() {
        when(clienteDAO.findAll()).thenReturn(Arrays.asList(
                createCliente(1L, "Joao", 1000.0),
                createCliente(2L, "Maria", 2000.0)
        ));

        List<Cliente> result = clienteService.findAll();

        assertEquals(2, result.size());
    }

    @Test
    void shouldReturnAllWhenSearchQueryIsEmpty() {
        when(clienteDAO.findAll()).thenReturn(List.of(createCliente(1L, "Joao", 1000.0)));

        List<Cliente> result = clienteService.search("");

        assertEquals(1, result.size());
        verify(clienteDAO, never()).findByCriteria(anyString());
    }

    @Test
    void shouldSearchByCriteriaWhenQueryProvided() {
        when(clienteDAO.findByCriteria("joao")).thenReturn(List.of(createCliente(1L, "Joao", 1000.0)));

        List<Cliente> result = clienteService.search("joao");

        assertEquals(1, result.size());
        verify(clienteDAO).findByCriteria("joao");
    }

    @Test
    void shouldSaveSuccessfully() {
        Cliente cliente = createCliente(null, "Joao", 1000.0);
        when(clienteDAO.save(any(Cliente.class))).thenReturn(1L);

        Cliente result = clienteService.save(cliente);

        assertEquals(1L, result.getId());
    }

    @Test
    void shouldThrowWhenSaveFails() {
        Cliente cliente = createCliente(null, "Joao", 1000.0);
        when(clienteDAO.save(any(Cliente.class))).thenReturn(null);

        assertThrows(RuntimeException.class, () -> clienteService.save(cliente));
    }

    @Test
    void shouldUpdateSuccessfully() {
        Cliente cliente = createCliente(1L, "Joao", 1000.0);
        when(clienteDAO.update(any(Cliente.class))).thenReturn(true);

        Cliente result = clienteService.update(cliente);

        assertEquals("Joao", result.getNome());
    }

    @Test
    void shouldThrowWhenUpdateFails() {
        Cliente cliente = createCliente(1L, "Joao", 1000.0);
        when(clienteDAO.update(any(Cliente.class))).thenReturn(false);

        assertThrows(RuntimeException.class, () -> clienteService.update(cliente));
    }

    @Test
    void shouldDeleteSuccessfully() {
        when(clienteDAO.delete(1L)).thenReturn(true);

        boolean result = clienteService.delete(1L);

        assertTrue(result);
    }

    @Test
    void shouldAllowCreditWhenWithinLimit() {
        Cliente cliente = createCliente(1L, "Joao", 1000.0);
        cliente.setCreditoUsado(200.0);
        when(clienteDAO.findById(1L)).thenReturn(cliente);

        boolean result = clienteService.podeVenderCredito(1L, 500.0);

        assertTrue(result); // 200 + 500 = 700 <= 1000
    }

    @Test
    void shouldDenyCreditWhenExceedingLimit() {
        Cliente cliente = createCliente(1L, "Joao", 1000.0);
        cliente.setCreditoUsado(800.0);
        when(clienteDAO.findById(1L)).thenReturn(cliente);

        boolean result = clienteService.podeVenderCredito(1L, 300.0);

        assertFalse(result); // 800 + 300 = 1100 > 1000
    }

    @Test
    void shouldDenyCreditWhenNoLimitSet() {
        Cliente cliente = createCliente(1L, "Joao", null);
        when(clienteDAO.findById(1L)).thenReturn(cliente);

        boolean result = clienteService.podeVenderCredito(1L, 100.0);

        assertFalse(result);
    }

    @Test
    void shouldDenyCreditWhenClientNotFound() {
        when(clienteDAO.findById(99L)).thenReturn(null);

        boolean result = clienteService.podeVenderCredito(99L, 100.0);

        assertFalse(result);
    }

    @Test
    void shouldUpdateCreditUsed() {
        Cliente cliente = createCliente(1L, "Joao", 1000.0);
        cliente.setCreditoUsado(200.0);
        when(clienteDAO.findById(1L)).thenReturn(cliente);
        when(clienteDAO.update(any(Cliente.class))).thenReturn(true);

        clienteService.actualizarCreditoUsado(1L, 300.0);

        verify(clienteDAO).update(argThat(c -> c.getCreditoUsado() == 500.0));
    }

    @Test
    void shouldThrowWhenUpdatingCreditForUnknownClient() {
        when(clienteDAO.findById(99L)).thenReturn(null);

        assertThrows(RuntimeException.class, () -> clienteService.actualizarCreditoUsado(99L, 100.0));
    }

    private Cliente createCliente(Long id, String nome, Double limiteCredito) {
        Cliente c = new Cliente();
        c.setId(id);
        c.setNome(nome);
        c.setLimiteCredito(limiteCredito);
        c.setCreditoUsado(0.0);
        c.setAtivo(true);
        return c;
    }
}
