package com.factpro.auditoria.util;

import com.factpro.auditoria.dao.AuditoriaDAO;
import com.factpro.auditoria.model.AuditoriaLog;
import com.factpro.auditoria.service.AuditoriaService;

import java.util.List;

/**
 * Classe utilitaria com metodos estaticos para logging de auditoria.
 * Permite que qualquer servico registe acoes de auditoria sem necessidade
 * de injetar o AuditoriaService.
 */
public class AuditoriaHelper {

    private static volatile AuditoriaService instance;

    /**
     * Retorna a instancia singleton do AuditoriaService (lazy initialization).
     */
    private static AuditoriaService getInstance() {
        if (instance == null) {
            synchronized (AuditoriaHelper.class) {
                if (instance == null) {
                    AuditoriaDAO dao = new AuditoriaDAO();
                    instance = new AuditoriaService(dao);
                }
            }
        }
        return instance;
    }

    // ==================== Generic log ====================

    /**
     * Regista um log de auditoria completo.
     */
    public static void log(String acao, String recurso, Long recursoId, String descricao) {
        getInstance().log(acao, recurso, recursoId, descricao);
    }

    /**
     * Regista um log de auditoria simplificado.
     */
    public static void log(String acao, String recurso) {
        getInstance().log(acao, recurso);
    }

    // ==================== Venda ====================

    public static void logVendaFinalizada(Long vendaId) {
        getInstance().logVendaFinalizada(vendaId);
    }

    public static void logVendaCancelada(Long vendaId, String motivo) {
        getInstance().logVendaCancelada(vendaId, motivo);
    }

    // ==================== Produto ====================

    public static void logProdutoAlterado(Long produtoId, String acao) {
        getInstance().logProdutoAlterado(produtoId, acao);
    }

    // ==================== Stock ====================

    public static void logStockMovimento(Long produtoId, String tipo, int qty) {
        getInstance().logStockMovimento(produtoId, tipo, qty);
    }

    // ==================== Auth ====================

    public static void logLoginSucesso(String email) {
        getInstance().logLoginSucesso(email);
    }

    public static void logLoginFalhou(String email) {
        getInstance().logLoginFalhou(email);
    }

    // ==================== Cliente ====================

    public static void logClienteAlterado(Long clienteId, String acao) {
        getInstance().logClienteAlterado(clienteId, acao);
    }

    // ==================== Compra ====================

    public static void logCompraAlterada(Long compraId, String acao) {
        getInstance().logCompraAlterada(compraId, acao);
    }

    // ==================== Queries ====================

    public static List<AuditoriaLog> getRecentLogs(int limit) {
        return getInstance().getRecentLogs(limit);
    }

    public static List<AuditoriaLog> getUserActivity(Long userId, int limit) {
        return getInstance().getUserActivity(userId, limit);
    }

    public static List<AuditoriaLog> getByRecurso(String recurso) {
        return getInstance().getByRecurso(recurso);
    }

    public static List<AuditoriaLog> getByDateRange(String start, String end) {
        return getInstance().getByDateRange(start, end);
    }

    public static List<AuditoriaLog> getByAcao(String acao) {
        return getInstance().getByAcao(acao);
    }
}
