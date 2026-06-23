package com.factpro.contas.service;

import com.factpro.contas.dao.ContaReceberDAO;
import com.factpro.contas.model.ContaReceber;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Service for managing accounts receivable (contas a receber / fiado).
 */
public class ContaReceberService {

    private static final Logger logger = LoggerFactory.getLogger(ContaReceberService.class);

    private final ContaReceberDAO contaReceberDAO;

    public ContaReceberService(ContaReceberDAO contaReceberDAO) {
        this.contaReceberDAO = contaReceberDAO;
    }

    public ContaReceber findById(Long id) {
        return contaReceberDAO.findById(id);
    }

    public List<ContaReceber> findAll() {
        return contaReceberDAO.findAll();
    }

    public List<ContaReceber> findByStatus(String status) {
        return contaReceberDAO.findByStatus(status);
    }

    public List<ContaReceber> findByDateRange(String startDate, String endDate) {
        return contaReceberDAO.findByDateRange(startDate, endDate);
    }

    public List<ContaReceber> findOverdueAccounts() {
        return contaReceberDAO.findOverdue();
    }

    /**
     * Registers a new accounts receivable entry from a credit sale.
     */
    public ContaReceber registerContaReceber(Long clienteId, Long vendaId,
                                              double valorTotal, String dataVencimento) {
        ContaReceber conta = new ContaReceber();
        conta.setClienteId(clienteId);
        conta.setVendaId(vendaId);
        conta.setValorTotal(valorTotal);
        conta.setValorPago(0.0);
        conta.setValorPendente(valorTotal);
        conta.setStatus("pendente");
        conta.setDataVencimento(dataVencimento);

        Long id = contaReceberDAO.save(conta);
        if (id == null) {
            throw new RuntimeException("Falha ao registar conta a receber.");
        }
        conta.setId(id);
        logger.info("Conta a receber registada: ID {}, cliente {}, valor {}", id, clienteId, valorTotal);
        return conta;
    }

    /**
     * Registers a payment towards an accounts receivable entry.
     * Updates valorPago, recalculates valorPendente, and adjusts status.
     */
    public void registarPagamento(Long contaId, double valorPago) {
        ContaReceber conta = contaReceberDAO.findById(contaId);
        if (conta == null) {
            throw new RuntimeException("Conta a receber nao encontrada: ID " + contaId);
        }

        double currentPago = conta.getValorPago() != null ? conta.getValorPago() : 0.0;
        double newPago = currentPago + valorPago;
        double newPendente = Math.max(0.0, conta.getValorTotal() - newPago);

        // Update status
        String newStatus;
        if (newPendente <= 0.001) {
            newStatus = "pago";
        } else if (newPago > 0) {
            newStatus = "parcial";
        } else {
            newStatus = "pendente";
        }

        // Check if overdue
        if ("pendente".equals(newStatus) || "parcial".equals(newStatus)) {
            String today = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE);
            if (conta.getDataVencimento() != null && conta.getDataVencimento().compareTo(today) < 0) {
                newStatus = "vencido";
            }
        }

        conta.setValorPago(newPago);
        conta.setValorPendente(newPendente);
        conta.setStatus(newStatus);

        boolean updated = contaReceberDAO.update(conta);
        if (!updated) {
            throw new RuntimeException("Falha ao atualizar conta a receber: ID " + contaId);
        }

        logger.info("Pagamento registado: conta {}, valor={}, novo status={}", contaId, valorPago, newStatus);
    }

    /**
     * Marks an account as overdue.
     */
    public void marcarComoVencido(Long contaId) {
        ContaReceber conta = contaReceberDAO.findById(contaId);
        if (conta == null) {
            throw new RuntimeException("Conta a receber nao encontrada: ID " + contaId);
        }
        conta.setStatus("vencido");
        boolean updated = contaReceberDAO.update(conta);
        if (!updated) {
            throw new RuntimeException("Falha ao marcar conta como vencida: ID " + contaId);
        }
        logger.info("Conta {} marcada como vencida", contaId);
    }

    /**
     * Returns total amount still pending across all accounts.
     */
    public double getTotalReceber() {
        return contaReceberDAO.findAll().stream()
                .filter(c -> !"pago".equals(c.getStatus()))
                .mapToDouble(c -> c.getValorPendente() != null ? c.getValorPendente() : 0.0)
                .sum();
    }

    /**
     * Returns total amount already paid.
     */
    public double getTotalRecebido() {
        return contaReceberDAO.findAll().stream()
                .mapToDouble(c -> c.getValorPago() != null ? c.getValorPago() : 0.0)
                .sum();
    }

    public ContaReceber save(ContaReceber conta) {
        Long id = contaReceberDAO.save(conta);
        if (id == null) {
            throw new RuntimeException("Falha ao guardar conta a receber.");
        }
        conta.setId(id);
        return conta;
    }

    public ContaReceber update(ContaReceber conta) {
        boolean updated = contaReceberDAO.update(conta);
        if (!updated) {
            throw new RuntimeException("Falha ao atualizar conta a receber.");
        }
        return conta;
    }

    public boolean delete(Long id) {
        return contaReceberDAO.delete(id);
    }
}
