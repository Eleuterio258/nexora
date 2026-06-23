package com.factpro.auth;

import com.factpro.auditoria.AuditLogger;
import com.factpro.ui.NotificationManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;

/**
 * Validador de permissoes no backend.
 * Deve ser usado em DAOs e Services para validar acoes criticas.
 */
public class PermissionChecker {

    private static final Logger logger = LoggerFactory.getLogger(PermissionChecker.class);

    /**
     * Verifica se o utilizador tem a permissao especificada.
     * @throws SecurityException se nao tiver permissao
     */
    public static void require(String permission) {
        SessionManager session = SessionManager.getInstance();
        
        if (!session.isAuthenticated()) {
            logger.warn("Tentativa de acesso sem autenticacao: {}", permission);
            throw new SecurityException("Utilizador nao autenticado.");
        }

        if (!session.hasPermission(permission)) {
            logger.warn("Acesso negado para utilizador {} (role: {}) - Permissao necessaria: {}",
                session.getCurrentUserName(),
                session.getCurrentRoleId(),
                permission);
            
            // Registrar log de auditoria
            AuditLogger.logAccessDenied(permission, permission);
            
            // Mostrar notificao visual
            SwingUtilities.invokeLater(() -> 
                NotificationManager.showAccessDenied(permission, permission)
            );
            
            throw new SecurityException("Acesso negado: permissao '" + permission + "' necessaria.");
        }

        logger.debug("Permissao verificada: {} -> {}", session.getCurrentUserName(), permission);
    }

    /**
     * Verifica se o utilizador tem pelo menos uma das permissoes.
     */
    public static void requireAny(String... permissions) {
        SessionManager session = SessionManager.getInstance();
        
        if (!session.isAuthenticated()) {
            logger.warn("Tentativa de acesso sem autenticacao");
            throw new SecurityException("Utilizador nao autenticado.");
        }

        if (!session.hasAnyPermission(permissions)) {
            logger.warn("Acesso negado para utilizador {} - Permissoes necessarias: {}",
                session.getCurrentUserName(),
                String.join(", ", permissions));
            throw new SecurityException("Acesso negado: necessaria pelo menos uma das permissoes: " 
                + String.join(", ", permissions));
        }
    }

    /**
     * Verifica apenas se esta autenticado.
     */
    public static void requireAuthenticated() {
        if (!SessionManager.getInstance().isAuthenticated()) {
            throw new SecurityException("Autenticacao necessaria.");
        }
    }

    /**
     * Verifica se o utilizador pode acessar o modulo especificado.
     */
    public static void requireMenu(String menuName) {
        require("menu:" + menuName.toLowerCase());
    }

    /**
     * Verifica se o utilizador pode criar recursos do tipo especificado.
     */
    public static void requireCreate(String resource) {
        require(resource.toLowerCase() + ":create");
    }

    /**
     * Verifica se o utilizador pode atualizar recursos do tipo especificado.
     */
    public static void requireUpdate(String resource) {
        require(resource.toLowerCase() + ":update");
    }

    /**
     * Verifica se o utilizador pode eliminar recursos do tipo especificado.
     */
    public static void requireDelete(String resource) {
        require(resource.toLowerCase() + ":delete");
    }
}
