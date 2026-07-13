package tech.omnisyserp.desktop.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserUpdateDto {
    private String full_name;
    private String email;
    private String phone;
    private String unit_id;
    private String role;
    private String status;
    private String hired_at;  // ISO date string: "2024-01-15"
    private String password;
    private String pin;
}
