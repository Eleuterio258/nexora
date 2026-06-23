package com.factpro.compras.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Compra {
    private Long id;
    private Long tenantId;
    private Long fornecedorId;
    private Long userId;
    private Double total;
    private String status;
    private String dataCompra;
    private String observacoes;
    private String criadoEm;
}
