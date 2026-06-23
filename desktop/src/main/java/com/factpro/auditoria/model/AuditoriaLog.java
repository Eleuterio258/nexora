package com.factpro.auditoria.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Modelo de registo de auditoria (auditoria_logs).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AuditoriaLog {
    private Long id;
    private Long userId;
    private String acao;
    private String recurso;
    private Long recursoId;
    private String descricao;
    private String ipAddress;
    private String criadoEm;

    /**
     * Factory method que retorna um registo pre-preenchido com os campos obrigatorios.
     */
    public static AuditoriaLog create(Long userId, String acao, String recurso) {
        AuditoriaLog log = new AuditoriaLog();
        log.setUserId(userId);
        log.setAcao(acao);
        log.setRecurso(recurso);
        return log;
    }
}
