package com.factpro.auditoria.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AuditLog {
    private Long id;
    private Long tenantId;
    private Long userId;
    private String usuarioNome;
    private String acao;
    private String recurso;
    private Long recursoId;
    private String descricao;
    private String ipAddress;
    private Boolean sucesso;
    private String criadoEm;
}
