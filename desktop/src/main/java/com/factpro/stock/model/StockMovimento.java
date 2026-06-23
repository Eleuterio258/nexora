package com.factpro.stock.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StockMovimento {
    private Long id;
    private Long tenantId;
    private Long produtoId;
    private String tipo;
    private Integer quantidade;
    private String motivo;
    private String referencia;
    private Long userId;
    private String criadoEm;
}
