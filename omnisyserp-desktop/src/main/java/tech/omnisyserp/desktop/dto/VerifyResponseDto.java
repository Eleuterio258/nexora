package tech.omnisyserp.desktop.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VerifyResponseDto {
    private boolean match;
    private UUID user_id;
    private double confidence_score;
    private double liveness_score;
    private String timestamp;
    private String reason;
}
