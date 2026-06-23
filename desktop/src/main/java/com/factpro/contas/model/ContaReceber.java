package com.factpro.contas.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ContaReceber {
    private Long id;
    private Long clienteId;
    private Long vendaId;
    private Double valorTotal;
    private Double valorPago;
    private Double valorPendente;
    private String status;
    private String dataVencimento;
    private String criadoEm;
}
