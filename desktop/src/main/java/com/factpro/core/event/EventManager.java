package com.factpro.core.event;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Consumer;

/**
 * Gestor de eventos (padrão Observer).
 * Permite registo e disparo de eventos entre módulos.
 */
public class EventManager {
    
    private static final Logger logger = LoggerFactory.getLogger(EventManager.class);
    private static EventManager instance;
    
    private final Map<String, List<Consumer<Object>>> listeners = new ConcurrentHashMap<>();
    
    private EventManager() {}
    
    public static synchronized EventManager getInstance() {
        if (instance == null) {
            instance = new EventManager();
        }
        return instance;
    }
    
    /**
     * Regista um listener para um tipo de evento.
     */
    public <T> void on(String eventType, Consumer<T> listener) {
        listeners.computeIfAbsent(eventType, k -> new ArrayList<>())
                .add((Consumer<Object>) listener);
        logger.debug("Listener registado para evento: {}", eventType);
    }
    
    /**
     * Dispara um evento para todos os listeners registados.
     */
    public void emit(String eventType, Object data) {
        List<Consumer<Object>> eventListeners = listeners.get(eventType);
        
        if (eventListeners != null) {
            logger.debug("Emitindo evento: {} ({} listeners)", eventType, eventListeners.size());
            eventListeners.forEach(listener -> {
                try {
                    listener.accept(data);
                } catch (Exception e) {
                    logger.error("Erro ao processar evento: {}", eventType, e);
                }
            });
        }
    }
    
    /**
     * Dispara um evento sem dados.
     */
    public void emit(String eventType) {
        emit(eventType, null);
    }
    
    /**
     * Remove todos os listeners de um evento.
     */
    public void off(String eventType) {
        listeners.remove(eventType);
    }
    
    /**
     * Remove um listener específico.
     */
    public <T> void off(String eventType, Consumer<T> listener) {
        List<Consumer<Object>> eventListeners = listeners.get(eventType);
        if (eventListeners != null) {
            eventListeners.remove((Consumer<Object>) listener);
        }
    }
    
    /**
     * Limpa todos os listeners.
     */
    public void clear() {
        listeners.clear();
        logger.info("Todos os listeners removidos");
    }
}
