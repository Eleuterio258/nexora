package com.terminar.assiduidade.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Employee {

    private Long id;
    private String numero;
    private String nome;
    private String departamento;
    private String pinHash;
    private String qrCodeToken;
    private String fingerprintTemplate;
    private String nfcUid;
    private boolean ativo;
    private LocalDateTime criadoEm;
    private LocalDateTime atualizadoEm;
}
