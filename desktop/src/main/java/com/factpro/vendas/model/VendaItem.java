package com.factpro.vendas.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class VendaItem {
    private Long id;
    private Long vendaId;
    private Long produtoId;
    private Double quantidade;
    private Double precoUnitario;
    private Double desconto;
    private Double total;
    private String criadoEm;
}
