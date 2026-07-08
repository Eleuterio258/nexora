package com.factpro.clientes.service;

import com.factpro.auth.PermissionChecker;
import com.factpro.clientes.dao.ClienteDAO;
import com.factpro.clientes.model.Cliente;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * Service for managing clients and credit operations.
 */
public class ClienteService {

    private static final Logger logger = LoggerFactory.getLogger(ClienteService.class);

    private final ClienteDAO clienteDAO;

    public ClienteService(ClienteDAO clienteDAO) {
        this.clienteDAO = clienteDAO;
    }

    public Cliente findById(Long id) {
        return clienteDAO.findById(id);
    }

    public List<Cliente> findAll() {
        return clienteDAO.findAll();
    }

    /**
     * Searches clients by name, email, NIF, or phone.
     */
    public List<Cliente> search(String query) {
        if (query == null || query.isBlank()) {
            return clienteDAO.findAll();
        }
        return clienteDAO.findByCriteria(query.trim());
    }

    public Cliente save(Cliente cliente) {
        PermissionChecker.requireCreate("clientes");
        Long id = clienteDAO.save(cliente);
        if (id == null) {
            throw new RuntimeException("Falha ao guardar o cliente.");
        }
        cliente.setId(id);
        logger.info("Client saved: {} (ID: {})", cliente.getNome(), id);
        return cliente;
    }

    public Cliente update(Cliente cliente) {
        PermissionChecker.requireUpdate("clientes");
        boolean updated = clienteDAO.update(cliente);
        if (!updated) {
            throw new RuntimeException("Falha ao atualizar o cliente.");
        }
        logger.info("Client updated: {} (ID: {})", cliente.getNome(), cliente.getId());
        return cliente;
    }

    public boolean delete(Long id) {
        PermissionChecker.requireDelete("clientes");
        boolean deleted = clienteDAO.delete(id);
        if (deleted) {
            logger.info("Client deleted: ID {}", id);
        } else {
            logger.warn("Failed to delete client: ID {}", id);
        }
        return deleted;
    }

    /**
     * Checks if the client can make a credit purchase of the given amount.
     * Returns true if credito_usado + valor <= limite_credito.
     */
    public boolean podeVenderCredito(Long clienteId, double valor) {
        Cliente cliente = clienteDAO.findById(clienteId);
        if (cliente == null) {
            logger.warn("Client not found: ID {}", clienteId);
            return false;
        }

        if (cliente.getLimiteCredito() == null) {
            logger.debug("Client {} has no credit limit set", cliente.getNome());
            return false;
        }

        double creditoUsado = cliente.getCreditoUsado() != null ? cliente.getCreditoUsado() : 0.0;
        boolean pode = (creditoUsado + valor) <= cliente.getLimiteCredito();

        logger.debug("Credit check for client {}: usado={}, limite={}, valor={}, pode={}",
                cliente.getNome(), creditoUsado, cliente.getLimiteCredito(), valor, pode);
        return pode;
    }

    /**
     * Updates the client's used credit by adding the given value.
     */
    public void actualizarCreditoUsado(Long clienteId, double valor) {
        Cliente cliente = clienteDAO.findById(clienteId);
        if (cliente == null) {
            throw new RuntimeException("Cliente nao encontrado: ID " + clienteId);
        }

        double currentCredito = cliente.getCreditoUsado() != null ? cliente.getCreditoUsado() : 0.0;
        cliente.setCreditoUsado(currentCredito + valor);

        boolean updated = clienteDAO.update(cliente);
        if (!updated) {
            throw new RuntimeException("Falha ao atualizar credito usado do cliente " + clienteId);
        }

        logger.info("Credit updated for client {}: new usado={}", cliente.getNome(), cliente.getCreditoUsado());
    }
}
