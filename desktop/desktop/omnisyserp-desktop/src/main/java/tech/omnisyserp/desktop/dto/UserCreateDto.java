package tech.omnisyserp.desktop.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserCreateDto {
    private String employee_code;
    private String full_name;
    private String email;
    private String phone;
    private String password;
    private String unit_id;
    @Builder.Default
    private String role = "COLABORADOR";
    @Builder.Default
    private String status = "ACTIVE";
    private String hired_at;  // ISO date string: "2024-01-15"
    private String pin;
}
