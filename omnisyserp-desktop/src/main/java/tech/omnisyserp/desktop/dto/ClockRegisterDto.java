package tech.omnisyserp.desktop.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClockRegisterDto {
    private String idempotency_key;
    private String user_id;
    private String device_id;
    private String event_type;   // ENTRY | EXIT | BREAK_START | BREAK_END
    private String recorded_at;  // ISO datetime string com timezone
    private String source;       // ONLINE | MANUAL
    private Double confidence_score;
    private Double liveness_score;
    private Double geo_lat;
    private Double geo_lng;
}
