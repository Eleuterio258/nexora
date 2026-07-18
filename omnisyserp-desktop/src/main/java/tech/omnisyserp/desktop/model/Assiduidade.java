package tech.omnisyserp.desktop.model;

import lombok.*;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Modelo de dominio que representa uma sessao de assiduidade (par ENTRY + EXIT).
 * Construido a partir de dois ClockRecordDto vindos do backend controle.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Assiduidade {

    /** UUID do ClockRecord ENTRY (registo de entrada). */
    private String id;

    /** UUID do ClockRecord EXIT (registo de saida). Null se sessao em aberto. */
    private String exitId;

    private Funcionario funcionario;

    /** recorded_at do ClockRecord ENTRY. */
    private LocalDateTime dataHoraEntrada;

    /** recorded_at do ClockRecord EXIT. Null se sessao em aberto. */
    private LocalDateTime dataHoraSaida;

    @Builder.Default
    private TipoRegisto tipo = TipoRegisto.PRESENCIAL;

    private String observacao;

    // Fotos nao sao suportadas no backend controle (usa face templates separados)

    public boolean estaAberto() {
        return dataHoraSaida == null;
    }

    public String getDuracaoFormatada() {
        if (dataHoraSaida == null) return "Em curso";
        Duration d = Duration.between(dataHoraEntrada, dataHoraSaida);
        long horas = d.toHours();
        long minutos = d.toMinutesPart();
        return String.format("%dh %02dmin", horas, minutos);
    }

    // ── Conversao de/para DTO ─────────────────────────────────────────────

    private static final DateTimeFormatter ISO_FORMATTER =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss[.SSSSSS][.SSS][XXX][X]");

    public static LocalDateTime parseDateTime(String iso) {
        if (iso == null || iso.isBlank()) return null;
        try {
            // Normalizar: remover timezone suffix se presente
            String s = iso;
            if (s.endsWith("Z")) s = s.substring(0, s.length() - 1);
            if (s.length() > 19 && s.charAt(19) == '+') s = s.substring(0, 19);
            if (s.length() > 19 && s.charAt(19) == '.') {
                int plusIdx = s.indexOf('+', 19);
                if (plusIdx > 0) s = s.substring(0, plusIdx);
            }
            return LocalDateTime.parse(s.length() > 19 ? s : s);
        } catch (Exception e) {
            try {
                return LocalDateTime.parse(iso.substring(0, 19));
            } catch (Exception ex) {
                return null;
            }
        }
    }

    /**
     * Mapeia source do backend para TipoRegisto da UI.
     */
    public static TipoRegisto sourceParaTipoRegisto(String source) {
        if (source == null) return TipoRegisto.PRESENCIAL;
        return switch (source.toUpperCase()) {
            case "MANUAL" -> TipoRegisto.FORMACAO;
            case "OFFLINE_SYNC" -> TipoRegisto.REMOTO;
            default -> TipoRegisto.PRESENCIAL;
        };
    }

    /**
     * Mapeia TipoRegisto da UI para source do backend.
     */
    public static String tipoRegistoParaSource(TipoRegisto tipo) {
        if (tipo == null) return "ONLINE";
        return switch (tipo) {
            case FORMACAO -> "MANUAL";
            case REMOTO -> "OFFLINE_SYNC";
            default -> "ONLINE";
        };
    }
}
