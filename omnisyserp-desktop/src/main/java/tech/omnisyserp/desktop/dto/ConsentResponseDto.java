package tech.omnisyserp.desktop.dto;

import lombok.Data;
import java.util.UUID;

@Data
public class ConsentResponseDto {
    private UUID id;
    private UUID user_id;
    private String term_version;
    private String consent_hash;
    private String legal_basis;
    private String accepted_at;
    private String revoked_at;
}
