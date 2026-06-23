package com.factpro.auth;

import com.factpro.auth.dao.RoleDAO;
import com.factpro.auth.model.User;
import com.factpro.ui.NotificationManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * Singleton que gere a sessao do utilizador autenticado.
 */
public class SessionManager {

    private static final Logger logger = LoggerFactory.getLogger(SessionManager.class);
    private static SessionManager instance;

    private User currentUser;
    private boolean authenticated;
    private List<String> userPermissions;
    private long permissionsLoadedAt;

    private SessionManager() {
        this.authenticated = false;
    }

    public static synchronized SessionManager getInstance() {
        if (instance == null) {
            instance = new SessionManager();
        }
        return instance;
    }

    public void login(User user) {
        this.currentUser = user;
        this.authenticated = true;
        
        // Load user permissions based on role
        if (user.getRoleId() != null) {
            loadPermissions();
        }
        
        logger.info("Utilizador autenticado: {} (id={})", user.getNome(), user.getId());
    }

    public void logout() {
        logger.info("Logout do utilizador: {}", currentUser != null ? currentUser.getNome() : "unknown");
        this.currentUser = null;
        this.authenticated = false;
        this.userPermissions = null;
        this.permissionsLoadedAt = 0;
    }

    public boolean isAuthenticated() {
        return authenticated && currentUser != null;
    }

    public User getCurrentUser() {
        return currentUser;
    }

    public Long getCurrentUserId() {
        return currentUser != null ? currentUser.getId() : null;
    }

    public String getCurrentUserName() {
        return currentUser != null ? currentUser.getNome() : "Desconhecido";
    }

    public String getCurrentUserEmail() {
        return currentUser != null ? currentUser.getEmail() : "";
    }

    public Long getCurrentTenantId() {
        return currentUser != null ? currentUser.getTenantId() : null;
    }

    public Long getCurrentRoleId() {
        return currentUser != null ? currentUser.getRoleId() : null;
    }

    public List<String> getUserPermissions() {
        return userPermissions;
    }

    public boolean hasPermission(String permission) {
        return userPermissions != null && userPermissions.contains(permission);
    }

    public boolean hasAnyPermission(String... permissions) {
        if (userPermissions == null) return false;
        for (String perm : permissions) {
            if (userPermissions.contains(perm)) return true;
        }
        return false;
    }

    /**
     * Recarrega as permissoes do utilizador em tempo real.
     * Util quando permissoes sao alteradas por um administrador.
     */
    public synchronized void refreshPermissions() {
        if (!authenticated || currentUser == null || currentUser.getRoleId() == null) {
            logger.warn("Nao foi possivel recarregar permissoes: utilizador nao autenticado ou sem role");
            return;
        }
        
        loadPermissions();
        logger.info("Permissoes recarregadas para utilizador: {}", currentUser.getNome());
    }

    /**
     * Retorna timestamp quando as permissoes foram carregadas.
     */
    public long getPermissionsLoadedAt() {
        return permissionsLoadedAt;
    }

    private void loadPermissions() {
        RoleDAO roleDAO = new RoleDAO();
        this.userPermissions = roleDAO.findPermissionNamesByRoleId(currentUser.getRoleId());
        this.permissionsLoadedAt = System.currentTimeMillis();
        logger.info("Permissoes carregadas: {} (total: {})", userPermissions, userPermissions.size());
    }
}
