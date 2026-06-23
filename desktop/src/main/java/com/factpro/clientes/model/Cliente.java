package com.factpro.clientes.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Cliente {
    private Long id;
    private Long tenantId;
    private String codigo;
    private String nome;
    private String email;
    private String telefone;
    private String nif;
    private String endereco;
    private Double limiteCredito;
    private Double creditoUsado;
    private Integer pontosFidelidade;
    private String tipoPreco;
    private Boolean ativo;
    private String criadoEm;
}
