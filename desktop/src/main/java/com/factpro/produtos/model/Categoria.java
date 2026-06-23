package com.factpro.produtos.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Categoria {
    private Long id;
    private Long tenantId;
    private String nome;
    private String descricao;
    private String cor;
    private Boolean ativo;
    private String criadoEm;
}
