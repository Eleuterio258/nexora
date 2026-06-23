package com.factpro.vendas.service;

import com.factpro.vendas.dao.PagamentoDAO;
import com.factpro.vendas.model.Pagamento;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Service for managing payment records.
 */
public class PagamentoService {

    private static final Logger logger = LoggerFactory.getLogger(PagamentoService.class);

    private final PagamentoDAO pagamentoDAO;

    public PagamentoService(PagamentoDAO pagamentoDAO) {
        this.pagamentoDAO = pagamentoDAO;
    }

    /**
     * Creates a payment record for a sale.
     */
    public void registarPagamento(Long vendaId, String metodo, double valor, String transacaoId) {
        logger.info("Registering payment for venda {} - method: {}, amount: {}", vendaId, metodo, valor);

        Pagamento pagamento = new Pagamento();
        pagamento.setVendaId(vendaId);
        pagamento.setMetodo(metodo);
        pagamento.setValor(valor);
        pagamento.setTransacaoId(transacaoId);
        pagamento.setStatus("processado");
        pagamento.setProcessadoEm(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));

        Long id = pagamentoDAO.save(pagamento);
        if (id == null) {
            logger.error("Failed to save payment for venda {}", vendaId);
            throw new RuntimeException("Falha ao registar o pagamento.");
        }

        logger.info("Payment registered successfully with ID {}", id);
    }

    /**
     * Returns all payments for a given sale.
     */
    public List<Pagamento> getPagamentosByVenda(Long vendaId) {
        return pagamentoDAO.findByVendaId(vendaId);
    }
}
