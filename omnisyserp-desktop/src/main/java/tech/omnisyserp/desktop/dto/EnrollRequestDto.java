package tech.omnisyserp.desktop.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EnrollRequestDto {
    private UUID user_id;
    private List<CaptureInput> captures;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CaptureInput {
        private String image_base64;
        private String angle; // Opcional: "FRONT", "LEFT", "RIGHT"
    }
}
