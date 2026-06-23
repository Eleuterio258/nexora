package com.factpro.vendas.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Pagamento {
    private Long id;
    private Long vendaId;
    private String metodo;
    private Double valor;
    private String referencia;
    private String transacaoId;
    private String status;
    private String processadoEm;
    private String criadoEm;
}
