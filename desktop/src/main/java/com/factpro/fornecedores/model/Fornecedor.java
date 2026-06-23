package com.factpro.fornecedores.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Fornecedor {
    private Long id;
    private Long tenantId;
    private String nome;
    private String contato;
    private String telefone;
    private String email;
    private String endereco;
    private String nif;
    private Boolean ativo;
    private String criadoEm;
    private String atualizadoEm;
}
