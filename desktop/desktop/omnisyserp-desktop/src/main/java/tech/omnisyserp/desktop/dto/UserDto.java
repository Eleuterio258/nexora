package tech.omnisyserp.desktop.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class UserDto {
    private String id;
    private String employee_code;
    private String full_name;
    private String email;
    private String phone;
    private String unit_id;
    private String role;
    private String status;
    private String hired_at;      // ISO date string: "2024-01-15"
    private String terminated_at;
    private String created_at;
    private String updated_at;
}
