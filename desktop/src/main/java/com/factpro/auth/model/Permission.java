package com.factpro.auth.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Permission {
    private Long id;
    private String nome;
    private String recurso;
    private String acao;
    private String descricao;
}
