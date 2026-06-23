package com.factpro.compras.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CompraItem {
    private Long id;
    private Long compraId;
    private Long produtoId;
    private Double quantidade;
    private Double precoUnitario;
    private Double total;
    private String criadoEm;
}
