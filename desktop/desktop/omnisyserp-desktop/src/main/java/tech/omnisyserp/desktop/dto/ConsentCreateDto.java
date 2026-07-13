package tech.omnisyserp.desktop.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConsentCreateDto {
    private UUID user_id;
    private String term_version;
    private String consent_hash;
    private String accepted_at; // ISO string
    private String legal_basis; // "CONSENT"
}
