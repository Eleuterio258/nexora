package com.terminar.assiduidade.integration;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Espelha {@code FuncionarioIntegracao} do ERP (GET /api/hardware/assiduidade/funcionarios) —
 * só identidade (nome/número/activo), sem credenciais de autenticação local.
 */
@Data
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class FuncionarioErp {

    private long id;

    @JsonProperty("employee_code")
    private String employeeCode;

    @JsonProperty("full_name")
    private String fullName;

    private String email;
    private String role;

    @JsonProperty("is_active")
    private boolean active;

    @JsonProperty("tenant_id")
    private long tenantId;
}
