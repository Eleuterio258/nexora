package com.factpro.auth.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Role {
    private Long id;
    private Long tenantId;
    private String nome;
    private String descricao;
    private String responsabilidades;
    private String criadoEm;
}
