package com.factpro.notificacoes.service;

import com.factpro.core.event.EventManager;
import com.factpro.notificacoes.dao.NotificacaoDAO;
import com.factpro.vendas.model.Venda;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Regista listeners de eventos do sistema para criar notificacoes automaticamente.
 */
public class NotificationEventListener {

    private static final Logger logger = LoggerFactory.getLogger(NotificationEventListener.class);

    private final NotificacaoService notificacaoService;

    public NotificationEventListener() {
        this.notificacaoService = new NotificacaoService(new NotificacaoDAO());
    }

    public NotificationEventListener(NotificacaoService notificacaoService) {
        this.notificacaoService = notificacaoService;
    }

    /**
     * Regista todos os listeners de eventos.
     */
    public void registerListeners() {
        EventManager eventManager = EventManager.getInstance();

        eventManager.on("venda_finalizada", (Venda venda) -> {
            if (venda != null && venda.getId() != null) {
                notificacaoService.notifyVendaFinalizada(venda.getId(), venda.getTotal());
            }
        });

        eventManager.on("venda_cancelada", (Venda venda) -> {
            if (venda != null && venda.getId() != null) {
                notificacaoService.notifyVendaCancelada(venda.getId(), venda.getObservacoes());
            }
        });

        eventManager.on("stock_baixo", (Object[] data) -> {
            if (data != null && data.length >= 2) {
                String produtoNome = String.valueOf(data[0]);
                int stockAtual = ((Number) data[1]).intValue();
                notificacaoService.notifyStockBaixo(produtoNome, stockAtual);
            }
        });

        logger.info("Listeners de notificacoes registados");
    }
}
