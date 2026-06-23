package com.factpro.auditoria;

import com.factpro.auth.SessionManager;
import com.factpro.core.database.DatabaseManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Timestamp;

/**
 * Utilitario para registrar logs de auditoria.
 * Usado para registrar alteracoes criticas no sistema.
 */
public class AuditLogger {

    private static final Logger logger = LoggerFactory.getLogger(AuditLogger.class);
    private static final String TABLE = "auditoria_logs";

    /**
     * Tipos de acoes auditaveis.
     */
    public enum ActionType {
        CREATE, UPDATE, DELETE, LOGIN, LOGOUT, PERMISSION_CHANGE, ROLE_CHANGE, 
        ACCESS_DENIED, CONFIG_CHANGE, BACKUP, RESTORE
    }

    /**
     * Registra um log de auditoria.
     * 
     * @param acao Tipo da acao realizada
     * @param recurso Nome do recurso afetado (ex: "vendas", "roles", "usuarios")
     * @param recursoId ID do recurso afetado (pode ser null)
     * @param descricao Descricao detalhada da acao
     * @param sucesso Se a acao foi bem-sucedida
     */
    public static void log(ActionType acao, String recurso, Long recursoId, 
                          String descricao, boolean sucesso) {
        // Log assincrono para nao bloquear operacao principal
        new Thread(() -> {
            try {
                logAsync(acao, recurso, recursoId, descricao, sucesso);
            } catch (Exception e) {
                logger.error("Erro ao registrar log de auditoria", e);
            }
        }).start();
    }

    /**
     * Registra log de tentativa de acesso negado.
     */
    public static void logAccessDenied(String recurso, String permissaoNecessaria) {
        SessionManager session = SessionManager.getInstance();
        String descricao = String.format("Tentativa de acesso negado a '%s'. Permissao necessaria: %s",
            recurso, permissaoNecessaria);
        
        log(ActionType.ACCESS_DENIED, recurso, null, descricao, false);
    }

    /**
     * Registra log de alteracao em role.
     */
    public static void logRoleChange(Long roleId, String roleName, String acao, String detalhes) {
        String descricao = String.format("Role '%s' (ID: %d) - %s. %s", 
            roleName, roleId, acao, detalhes != null ? detalhes : "");
        
        log(ActionType.ROLE_CHANGE, "roles", roleId, descricao.trim(), true);
    }

    /**
     * Registra log de alteracao em permissoes.
     */
    public static void logPermissionChange(Long roleId, String roleName, int qtdPermissoes) {
        String descricao = String.format("Permissoes do role '%s' (ID: %d) atualizadas. Total: %d permissoes",
            roleName, roleId, qtdPermissoes);
        
        log(ActionType.PERMISSION_CHANGE, "permissions", roleId, descricao, true);
    }

    private static void logAsync(ActionType acao, String recurso, Long recursoId,
                                 String descricao, boolean sucesso) {
        String sql = "INSERT INTO " + TABLE + 
                     " (tenant_id, user_id, acao, recurso, recurso_id, descricao, " +
                     "endereco_ip, sucesso, criado_em) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

        SessionManager session = SessionManager.getInstance();
        
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            int idx = 1;
            stmt.setObject(idx++, session.getCurrentTenantId());
            stmt.setObject(idx++, session.getCurrentUserId());
            stmt.setString(idx++, acao.name());
            stmt.setString(idx++, recurso);
            stmt.setObject(idx++, recursoId);
            stmt.setString(idx++, descricao);
            stmt.setString(idx++, "local"); // Desktop app - no IP
            stmt.setBoolean(idx++, sucesso);
            stmt.setTimestamp(idx++, new Timestamp(System.currentTimeMillis()));
            
            stmt.executeUpdate();
            
        } catch (Exception e) {
            logger.error("Erro ao registrar log de auditoria: {} - {}", acao, recurso, e);
        }
    }
}
