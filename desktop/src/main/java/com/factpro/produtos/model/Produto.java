package com.factpro.produtos.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Produto {
    private Long id;
    private Long tenantId;
    private Long categoriaId;
    private String codigoBarras;
    private String sku;
    private String nome;
    private String descricao;
    private Double precoCompra;
    private Double precoVenda;
    private Double precoPromocao;
    private Integer stockAtual;
    private Integer stockMinimo;
    private String unidadeMedida;
    private String validade;
    private String imagemUrl;
    private Boolean composto;
    private Boolean ativo;
    private String criadoEm;
}
