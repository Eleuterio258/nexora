package tech.omnisyserp.desktop.dto;

import lombok.Data;
import java.util.UUID;
import java.time.LocalDateTime;

@Data
public class DeviceDto {
    private UUID id;
    private String device_code;
    private String display_name;
    private UUID unit_id;
    private String type;
    private String status;
    private LocalDateTime last_seen_at;
    private LocalDateTime created_at;
    private LocalDateTime updated_at;
}
