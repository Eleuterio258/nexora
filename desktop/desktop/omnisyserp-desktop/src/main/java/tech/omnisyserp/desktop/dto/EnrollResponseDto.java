package tech.omnisyserp.desktop.dto;

import lombok.Data;
import java.util.UUID;

@Data
public class EnrollResponseDto {
    private String template_id;
    private UUID user_id;
    private String model_version;
    private String status;
}
