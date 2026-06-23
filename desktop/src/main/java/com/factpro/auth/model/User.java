package com.factpro.auth.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {
    private Long id;
    private Long tenantId;
    private Long roleId;
    private String nome;
    private String email;
    private String senhaHash;
    private String telefone;
    private Boolean ativo;
    private String ultimoLogin;
    private Integer tentativasFalhas;
    private String bloqueadoAte;
    private String criadoEm;
}
