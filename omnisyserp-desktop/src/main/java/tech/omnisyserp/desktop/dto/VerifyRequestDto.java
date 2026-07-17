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
public class VerifyRequestDto {
    private UUID user_id;
    private UUID device_id;
    private String image_base64;
    private Double geo_lat;
    private Double geo_lng;
}
