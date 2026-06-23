package com.factpro.notificacoes.service;

import com.factpro.auth.SessionManager;
import com.factpro.notificacoes.dao.NotificacaoDAO;
import com.factpro.notificacoes.model.Notificacao;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * Service for managing notifications.
 * Auto-detects userId from SessionManager when not provided.
 */
public class NotificacaoService {

    private static final Logger logger = LoggerFactory.getLogger(NotificacaoService.class);

    public static final String TIPO_STOCK_BAIXO = "STOCK_BAIXO";
    public static final String TIPO_VENDA_FINALIZADA = "VENDA_FINALIZADA";
    public static final String TIPO_VENDA_CANCELADA = "VENDA_CANCELADA";
    public static final String TIPO_CONTA_VENCIDA = "CONTA_VENCIDA";
    public static final String TIPO_INFO = "INFO";

    private final NotificacaoDAO notificacaoDAO;

    public NotificacaoService(NotificacaoDAO notificacaoDAO) {
        this.notificacaoDAO = notificacaoDAO;
    }

    /**
     * Gets the current user ID from SessionManager, or returns the provided one.
     */
    private Long resolveUserId(Long userId) {
        if (userId != null) {
            return userId;
        }
        return SessionManager.getInstance().getCurrentUserId();
    }

    /**
     * Creates a notification for the given user.
     */
    public Notificacao createNotificacao(Long userId, String tipo, String titulo, String mensagem) {
        Long resolvedUserId = resolveUserId(userId);
        if (resolvedUserId == null) {
            logger.warn("Nenhum userId disponivel para criar notificacao: {}", titulo);
            return null;
        }

        Notificacao n = new Notificacao();
        n.setUserId(resolvedUserId);
        n.setTipo(tipo);
        n.setTitulo(titulo);
        n.setMensagem(mensagem);
        n.setLida(false);

        Long id = notificacaoDAO.save(n);
        if (id != null) {
            n.setId(id);
            logger.info("Notificacao criada: {} (userId={}, tipo={})", titulo, resolvedUserId, tipo);
        } else {
            logger.error("Falha ao criar notificacao: {}", titulo);
        }
        return n;
    }

    /**
     * Creates a stock low notification.
     */
    public void notifyStockBaixo(String produtoNome, int stockAtual) {
        String titulo = "Stock Baixo: " + produtoNome;
        String mensagem = String.format("O produto '%s' tem stock abaixo do minimo (stock atual: %d unidades).", produtoNome, stockAtual);
        createNotificacao(null, TIPO_STOCK_BAIXO, titulo, mensagem);
    }

    /**
     * Creates a sale finalized notification.
     */
    public void notifyVendaFinalizada(Long vendaId, double total) {
        String titulo = "Venda Finalizada #" + vendaId;
        String mensagem = String.format("Venda #%d finalizada com sucesso. Total: %,.2f MT.", vendaId, total);
        createNotificacao(null, TIPO_VENDA_FINALIZADA, titulo, mensagem);
    }

    /**
     * Creates a sale cancelled notification.
     */
    public void notifyVendaCancelada(Long vendaId, String motivo) {
        String titulo = "Venda Cancelada #" + vendaId;
        String mensagem = String.format("Venda #%d cancelada. Motivo: %s", vendaId, motivo);
        createNotificacao(null, TIPO_VENDA_CANCELADA, titulo, mensagem);
    }

    /**
     * Creates an overdue account notification.
     */
    public void notifyContaVencida(String clienteNome, double valor) {
        String titulo = "Conta Vencida: " + clienteNome;
        String mensagem = String.format("O cliente '%s' tem uma conta vencida no valor de %,.2f MT.", clienteNome, valor);
        createNotificacao(null, TIPO_CONTA_VENCIDA, titulo, mensagem);
    }

    /**
     * Gets notifications for the given user (auto-detects if null).
     */
    public List<Notificacao> getNotificacoes(Long userId, int limit) {
        Long resolvedUserId = resolveUserId(userId);
        if (resolvedUserId == null) {
            logger.warn("Nenhum userId disponivel para listar notificacoes");
            return List.of();
        }
        return notificacaoDAO.findByUserId(resolvedUserId, limit);
    }

    /**
     * Gets the unread notification count for the given user (auto-detects if null).
     */
    public int getUnreadCount(Long userId) {
        Long resolvedUserId = resolveUserId(userId);
        if (resolvedUserId == null) {
            return 0;
        }
        return notificacaoDAO.getUnreadCount(resolvedUserId);
    }

    /**
     * Marks a notification as read.
     */
    public boolean markAsRead(Long notificacaoId) {
        boolean result = notificacaoDAO.markAsRead(notificacaoId);
        if (result) {
            logger.info("Notificacao marcada como lida: {}", notificacaoId);
        }
        return result;
    }

    /**
     * Marks all notifications as read for the given user (auto-detects if null).
     */
    public boolean markAllAsRead(Long userId) {
        Long resolvedUserId = resolveUserId(userId);
        if (resolvedUserId == null) {
            logger.warn("Nenhum userId disponivel para marcar todas como lidas");
            return false;
        }
        boolean result = notificacaoDAO.markAllAsRead(resolvedUserId);
        if (result) {
            logger.info("Todas notificacoes marcadas como lidas para userId: {}", resolvedUserId);
        }
        return result;
    }

    /**
     * Deletes notifications older than the given number of days.
     */
    public boolean cleanupOld(int days) {
        boolean result = notificacaoDAO.deleteOlderThan(days);
        if (result) {
            logger.info("Limpeza de notificacoes antigas ({} dias) concluida", days);
        }
        return result;
    }
}
