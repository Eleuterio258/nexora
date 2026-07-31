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
public class RegistoPonto {

    private Long id;
    private Long employeeId;
    private String employeeNumero;
    private String employeeNome;
    private MetodoAutenticacao metodo;
    private LocalDateTime dataHora;
    private boolean sincronizado;
    private String observacao;
}
