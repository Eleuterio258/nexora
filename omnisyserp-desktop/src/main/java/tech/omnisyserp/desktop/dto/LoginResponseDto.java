package tech.omnisyserp.desktop.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class LoginResponseDto {
    private String access_token;
    private String refresh_token;
    private String token_type;
    private int expires_in;
    private UserSummaryDto user;
}
