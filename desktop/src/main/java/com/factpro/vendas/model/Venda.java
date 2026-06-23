package com.factpro.vendas.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Venda {
    private Long id;
    private Long tenantId;
    private Long userId;
    private Long clienteId;
    private String terminal;
    private Double subtotal;
    private Double desconto;
    private Double imposto;
    private Double total;
    private String metodoPagamento;
    private String status;
    private String tipoDocumento;
    private String serieDocumento;
    private Integer numeroDocumento;
    private String referencia;
    private String observacoes;
    private Long canceladaPor;
    private String canceladaMotivo;
    private String canceladaEm;
    private String criadaEm;
}
