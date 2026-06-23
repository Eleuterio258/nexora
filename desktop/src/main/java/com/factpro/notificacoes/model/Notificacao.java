package com.factpro.notificacoes.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Notificacao {
    private Long id;
    private Long userId;
    private String tipo;
    private String titulo;
    private String mensagem;
    private Boolean lida;
    private String lidaEm;
    private String criadoEm;
}
