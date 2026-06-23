package com.factpro.auditoria.service;

import com.factpro.auth.SessionManager;
import com.factpro.auditoria.dao.AuditoriaDAO;
import com.factpro.auditoria.model.AuditoriaLog;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * Servico de auditoria - fornece metodos de logging para todas as acoes do sistema.
 */
public class AuditoriaService {

    private static final Logger logger = LoggerFactory.getLogger(AuditoriaService.class);

    private final AuditoriaDAO auditoriaDAO;

    public AuditoriaService(AuditoriaDAO auditoriaDAO) {
        this.auditoriaDAO = auditoriaDAO;
    }

    // ==================== Generic log ====================

    /**
     * Regista um log de auditoria com todos os campos.
     */
    public void log(String acao, String recurso, Long recursoId, String descricao) {
        Long userId = SessionManager.getInstance().getCurrentUserId();
        AuditoriaLog logEntry = AuditoriaLog.create(userId, acao, recurso);
        logEntry.setRecursoId(recursoId);
        logEntry.setDescricao(descricao);
        auditoriaDAO.save(logEntry);
        logger.info("[AUDIT] user={} | acao={} | recurso={} | recursoId={} | desc={}",
                userId, acao, recurso, recursoId, descricao);
    }

    /**
     * Regista um log de auditoria simplificado (sem recursoId nem descricao).
     */
    public void log(String acao, String recurso) {
        log(acao, recurso, null, null);
    }

    // ==================== Venda ====================

    public void logVendaFinalizada(Long vendaId) {
        log("CRIAR", "venda", vendaId, "Venda finalizada com sucesso");
    }

    public void logVendaCancelada(Long vendaId, String motivo) {
        log("CANCELAR", "venda", vendaId, "Venda cancelada: " + (motivo != null ? motivo : "Sem motivo"));
    }

    // ==================== Produto ====================

    public void logProdutoAlterado(Long produtoId, String acao) {
        String acaoNorm = normalizeAcao(acao);
        log(acaoNorm, "produto", produtoId, "Produto " + acaoNorm.toLowerCase() + ": ID " + produtoId);
    }

    // ==================== Stock ====================

    public void logStockMovimento(Long produtoId, String tipo, int qty) {
        String descricao = String.format("Movimento de stock: %s de %d unidade(s)", tipo, qty);
        log("STOCK_MOVIMENTO", "produto", produtoId, descricao);
    }

    // ==================== Auth ====================

    public void logLoginSucesso(String email) {
        log("LOGIN_SUCESSO", "auth", null, "Login bem-sucedido: " + email);
    }

    public void logLoginFalhou(String email) {
        log("LOGIN_FALHOU", "auth", null, "Tentativa de login falhou: " + email);
    }

    // ==================== Cliente ====================

    public void logClienteAlterado(Long clienteId, String acao) {
        String acaoNorm = normalizeAcao(acao);
        log(acaoNorm, "cliente", clienteId, "Cliente " + acaoNorm.toLowerCase() + ": ID " + clienteId);
    }

    // ==================== Compra ====================

    public void logCompraAlterada(Long compraId, String acao) {
        String acaoNorm = normalizeAcao(acao);
        log(acaoNorm, "compra", compraId, "Compra " + acaoNorm.toLowerCase() + ": ID " + compraId);
    }

    // ==================== Queries ====================

    /**
     * Retorna os registos de auditoria mais recentes.
     */
    public List<AuditoriaLog> getRecentLogs(int limit) {
        return auditoriaDAO.findAll(limit);
    }

    /**
     * Retorna a atividade de um utilizador especifico.
     */
    public List<AuditoriaLog> getUserActivity(Long userId, int limit) {
        return auditoriaDAO.findByUserId(userId, limit);
    }

    /**
     * Filtra por recurso.
     */
    public List<AuditoriaLog> getByRecurso(String recurso) {
        return auditoriaDAO.findByRecurso(recurso);
    }

    /**
     * Filtra por intervalo de datas.
     */
    public List<AuditoriaLog> getByDateRange(String start, String end) {
        return auditoriaDAO.findByDateRange(start, end);
    }

    /**
     * Filtra por tipo de acao.
     */
    public List<AuditoriaLog> getByAcao(String acao) {
        return auditoriaDAO.findByAcao(acao);
    }

    /**
     * Elimina registos mais antigos que N dias.
     */
    public boolean cleanupOldLogs(int days) {
        return auditoriaDAO.deleteOlderThan(days);
    }

    // ==================== Helpers ====================

    private String normalizeAcao(String acao) {
        if (acao == null) return "ALTERAR";
        String lower = acao.toLowerCase();
        if (lower.contains("cri") || lower.contains("nov") || lower.contains("insert")) return "CRIAR";
        if (lower.contains("alt") || lower.contains("upd") || lower.contains("edit") || lower.contains("modif")) return "ALTERAR";
        if (lower.contains("elim") || lower.contains("del") || lower.contains("remov")) return "ELIMINAR";
        if (lower.contains("cancel")) return "CANCELAR";
        return acao.toUpperCase();
    }
}
