package tech.omnisyserp.desktop.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import tech.omnisyserp.desktop.client.BackendApiClient;
import tech.omnisyserp.desktop.dto.UserCreateDto;
import tech.omnisyserp.desktop.dto.UserDto;
import tech.omnisyserp.desktop.dto.UserUpdateDto;
import tech.omnisyserp.desktop.model.Funcionario;

import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Servico de Funcionarios — delega ao backend controle via HTTP.
 * Mapeia UserDto (backend) <-> Funcionario (modelo de dominio do desktop).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FuncionarioService {

    private final BackendApiClient apiClient;

    public List<Funcionario> listarTodos() {
        return apiClient.withTokenRetry(() ->
            apiClient.listUsers(null)
                .stream()
                .map(Funcionario::fromUserDto)
                .sorted((a, b) -> a.getNomeCompleto().compareToIgnoreCase(b.getNomeCompleto()))
                .collect(Collectors.toList())
        );
    }

    public List<Funcionario> listarAtivos() {
        return apiClient.withTokenRetry(() -> 
            apiClient.listUsers("ACTIVE")
                .stream()
                .map(Funcionario::fromUserDto)
                .sorted((a, b) -> a.getNomeCompleto().compareToIgnoreCase(b.getNomeCompleto()))
                .collect(Collectors.toList())
        );
    }

    public List<Funcionario> pesquisar(String termo) {
        if (termo == null || termo.isBlank()) return listarTodos();
        String t = termo.toLowerCase();
        return listarTodos().stream()
                .filter(f -> contem(f.getNomeCompleto(), t)
                        || contem(f.getEmail(), t)
                        || contem(f.getNif(), t)
                        || contem(f.getCargo(), t))
                .collect(Collectors.toList());
    }

    public Optional<Funcionario> buscarPorId(String id) {
        try {
            UserDto dto = apiClient.withTokenRetry(() -> apiClient.getUser(id));
            return Optional.ofNullable(Funcionario.fromUserDto(dto));
        } catch (Exception e) {
            log.warn("Funcionario nao encontrado: {}", id);
            return Optional.empty();
        }
    }

    public Funcionario guardar(Funcionario f) {
        validar(f);
        UserDto resultado;

        if (f.getId() == null || f.getId().isBlank()) {
            // Criar novo utilizador
            if (f.getPassword() == null || f.getPassword().isBlank()) {
                throw new IllegalArgumentException("Palavra-passe e obrigatoria para criar um novo funcionario.");
            }
            UserCreateDto dto = UserCreateDto.builder()
                    .employee_code(f.getNif())
                    .full_name(f.getNomeCompleto())
                    .email(emptyToNull(f.getEmail()))
                    .phone(emptyToNull(f.getTelefone()))
                    .password(f.getPassword())
                    .role(f.getCargo() != null ? f.getCargo() : "COLABORADOR")
                    .status(Boolean.TRUE.equals(f.getAtivo()) ? "ACTIVE" : "INACTIVE")
                    .hired_at(formatDate(f))
                    .build();
            resultado = apiClient.withTokenRetry(() -> apiClient.createUser(dto));
            log.info("Funcionario criado: {} ({})", f.getNomeCompleto(), resultado.getId());
        } else {
            // Atualizar utilizador existente
            UserUpdateDto dto = UserUpdateDto.builder()
                    .full_name(f.getNomeCompleto())
                    .email(emptyToNull(f.getEmail()))
                    .phone(emptyToNull(f.getTelefone()))
                    .role(f.getCargo() != null ? f.getCargo() : "COLABORADOR")
                    .status(Boolean.TRUE.equals(f.getAtivo()) ? "ACTIVE" : "INACTIVE")
                    .hired_at(formatDate(f))
                    .password(emptyToNull(f.getPassword()))
                    .build();
            resultado = apiClient.withTokenRetry(() -> apiClient.updateUser(f.getId(), dto));
            log.info("Funcionario actualizado: {} ({})", f.getNomeCompleto(), f.getId());
        }

        return Funcionario.fromUserDto(resultado);
    }

    public void eliminar(String id) {
        // O backend nao elimina fisicamente — apenas desactiva (status=INACTIVE)
        apiClient.withTokenRetry(() -> {
            apiClient.deactivateUser(id);
            return null;
        });
        log.info("Funcionario desactivado no backend: {}", id);
    }

    public Funcionario desativar(String id) {
        UserUpdateDto dto = UserUpdateDto.builder().status("INACTIVE").build();
        UserDto resultado = apiClient.withTokenRetry(() -> apiClient.updateUser(id, dto));
        return Funcionario.fromUserDto(resultado);
    }

    public Funcionario ativar(String id) {
        UserUpdateDto dto = UserUpdateDto.builder().status("ACTIVE").build();
        UserDto resultado = apiClient.withTokenRetry(() -> apiClient.updateUser(id, dto));
        return Funcionario.fromUserDto(resultado);
    }

    public long contarAtivos() {
        return listarAtivos().size();
    }

    // ── helpers ──────────────────────────────────────────────────────────

    private void validar(Funcionario f) {
        if (f.getNome() == null || f.getNome().isBlank())
            throw new IllegalArgumentException("Nome e obrigatorio.");
        if (f.getApelido() == null || f.getApelido().isBlank())
            throw new IllegalArgumentException("Apelido e obrigatorio.");
        if (f.getNif() == null || f.getNif().isBlank())
            throw new IllegalArgumentException("Codigo de funcionario (NIF/employee_code) e obrigatorio.");
    }

    private boolean contem(String campo, String termo) {
        return campo != null && campo.toLowerCase().contains(termo);
    }

    private String emptyToNull(String s) {
        return (s == null || s.isBlank()) ? null : s.trim();
    }

    private String formatDate(Funcionario f) {
        if (f.getDataAdmissao() == null) return null;
        return f.getDataAdmissao().format(DateTimeFormatter.ISO_LOCAL_DATE);
    }
}
