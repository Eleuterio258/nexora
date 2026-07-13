package tech.omnisyserp.desktop.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class ClockRecordDto {
    private String id;
    private String user_id;
    private String device_id;
    private String event_type;   // ENTRY | EXIT | BREAK_START | BREAK_END
    private String recorded_at;  // ISO datetime string
    private String source;       // ONLINE | OFFLINE_SYNC | MANUAL | INTEGRATION
    private String sync_status;  // SYNCED | PENDING | FAILED
    private Double confidence_score;
    private Double liveness_score;
    private String created_at;
}
