package tech.omnisyserp.desktop.model;

import lombok.*;

import java.time.LocalDate;

/**
 * Modelo de dominio do lado do desktop que representa um utilizador/colaborador.
 * Mapeado a partir de UserDto (backend controle): User.employee_code → nif,
 * User.full_name → nome + apelido, User.role → cargo, User.status → ativo.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Funcionario {

    /** UUID do utilizador no backend (String). */
    private String id;

    /** Primeiro nome. Derivado de full_name.split(" ")[0]. */
    private String nome;

    /** Apelido(s). Derivado de full_name apos o primeiro espaco. */
    private String apelido;

    private String email;

    /** phone no backend. */
    private String telefone;

    /** employee_code no backend. */
    private String nif;

    /** role.name() do backend (COLABORADOR, GESTOR_RH, ADMIN_SISTEMA, AUDITOR). */
    private String cargo;

    /** unit_id do backend (UUID). Apresentado como departamento na UI. */
    private String departamento;

    /** hired_at do backend. */
    private LocalDate dataAdmissao;

    /** true quando status == ACTIVE no backend. */
    @Builder.Default
    private Boolean ativo = true;

    // Palavra-passe apenas usada ao criar/atualizar — nao e armazenada localmente.
    private transient String password;

    public String getNomeCompleto() {
        String n = nome != null ? nome : "";
        String a = apelido != null ? apelido : "";
        return (n + " " + a).trim();
    }

    @Override
    public String toString() {
        return getNomeCompleto();
    }

    // ── Conversao de/para DTO ─────────────────────────────────────────────

    /**
     * Constroi um Funcionario a partir dos campos de UserDto vindos do backend.
     */
    public static Funcionario fromUserDto(tech.omnisyserp.desktop.dto.UserDto dto) {
        if (dto == null) return null;

        String[] partes = splitNome(dto.getFull_name());
        LocalDate dataAdmissao = parseDate(dto.getHired_at());
        boolean ativo = "ACTIVE".equalsIgnoreCase(dto.getStatus());

        return Funcionario.builder()
                .id(dto.getId())
                .nome(partes[0])
                .apelido(partes[1])
                .email(dto.getEmail())
                .telefone(dto.getPhone())
                .nif(dto.getEmployee_code())
                .cargo(dto.getRole())
                .departamento(dto.getUnit_id())
                .dataAdmissao(dataAdmissao)
                .ativo(ativo)
                .build();
    }

    private static String[] splitNome(String fullName) {
        if (fullName == null || fullName.isBlank()) return new String[]{"", ""};
        int idx = fullName.indexOf(' ');
        if (idx < 0) return new String[]{fullName, ""};
        return new String[]{fullName.substring(0, idx), fullName.substring(idx + 1)};
    }

    private static LocalDate parseDate(String iso) {
        if (iso == null || iso.isBlank()) return null;
        try {
            // ISO format: "2024-01-15" ou "2024-01-15T00:00:00..."
            String datePart = iso.length() > 10 ? iso.substring(0, 10) : iso;
            return LocalDate.parse(datePart);
        } catch (Exception e) {
            return null;
        }
    }
}
