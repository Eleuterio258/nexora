package tech.omnisyserp.desktop.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import tech.omnisyserp.desktop.client.BackendApiClient;
import tech.omnisyserp.desktop.config.BackendProperties;
import tech.omnisyserp.desktop.dto.ClockRecordDto;
import tech.omnisyserp.desktop.dto.ClockRegisterDto;
import tech.omnisyserp.desktop.model.Assiduidade;
import tech.omnisyserp.desktop.model.Funcionario;
import tech.omnisyserp.desktop.model.TipoRegisto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Servico de Assiduidade — delega ao backend controle via HTTP.
 * Os registos do backend sao ClockRecord individuais (ENTRY/EXIT).
 * Este servico faz o emparelhamento ENTRY+EXIT para construir sessoes Assiduidade.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AssiduidadeService {

    private final BackendApiClient apiClient;
    private final BackendProperties props;
    private final FuncionarioService funcionarioService;

    private static final DateTimeFormatter ISO_TZ =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ssXXX");

    // ── Listagem ──────────────────────────────────────────────────────────

    public List<Assiduidade> listarTodos() {
        List<ClockRecordDto> records = apiClient.withTokenRetry(() ->
                apiClient.listClockRecords(null, null, null, null));
        return agruparEmSessoes(records, null);
    }

    public List<Assiduidade> listarPorFuncionario(Funcionario funcionario) {
        if (funcionario == null || funcionario.getId() == null) return Collections.emptyList();
        List<ClockRecordDto> records = apiClient.withTokenRetry(() ->
                apiClient.listClockRecords(funcionario.getId(), null, null, null));
        return agruparEmSessoes(records, funcionario);
    }

    public List<Assiduidade> listarPorPeriodo(LocalDate inicio, LocalDate fim) {
        List<ClockRecordDto> records = apiClient.withTokenRetry(() ->
                apiClient.listClockRecords(null, null, inicio.toString(), fim.toString()));
        return agruparEmSessoes(records, null);
    }

    public List<Assiduidade> listarPorFuncionarioEPeriodo(Funcionario f, LocalDate inicio, LocalDate fim) {
        if (f == null || f.getId() == null) return Collections.emptyList();
        List<ClockRecordDto> records = apiClient.withTokenRetry(() ->
                apiClient.listClockRecords(f.getId(), null, inicio.toString(), fim.toString()));
        return agruparEmSessoes(records, f);
    }

    public List<Assiduidade> listarAbertos() {
        List<Assiduidade> todos = listarTodos();
        return todos.stream().filter(Assiduidade::estaAberto).collect(Collectors.toList());
    }

    public Optional<Assiduidade> buscarPorId(String id) {
        // id == UUID do registo ENTRY — procurar na lista completa
        List<ClockRecordDto> records = apiClient.listClockRecords(null, null, null, null);
        return agruparEmSessoes(records, null).stream()
                .filter(a -> id.equals(a.getId()))
                .findFirst();
    }

    // ── Registo de presenca ───────────────────────────────────────────────

    public Assiduidade registarEntrada(Funcionario funcionario, TipoRegisto tipo, byte[] foto) {
        // Verificar sessao em aberto
        if (buscarRegistoAberto(funcionario).isPresent()) {
            throw new IllegalStateException(
                    funcionario.getNomeCompleto() + " ja tem entrada registada sem saida.");
        }

        String source = Assiduidade.tipoRegistoParaSource(tipo);
        ClockRegisterDto req = ClockRegisterDto.builder()
                .idempotency_key(UUID.randomUUID().toString())
                .user_id(funcionario.getId())
                .device_id(props.getDevice().getId())
                .event_type("ENTRY")
                .recorded_at(LocalDateTime.now().atZone(ZoneId.systemDefault()).format(ISO_TZ))
                .source(source)
                .build();

        ClockRecordDto resultado = apiClient.withTokenRetry(() -> apiClient.registerClock(req));
        log.info("Entrada registada: {} em {}", funcionario.getNomeCompleto(), resultado.getRecorded_at());

        return Assiduidade.builder()
                .id(resultado.getId())
                .funcionario(funcionario)
                .dataHoraEntrada(Assiduidade.parseDateTime(resultado.getRecorded_at()))
                .tipo(tipo)
                .build();
    }

    public Assiduidade registarSaida(Funcionario funcionario, byte[] foto) {
        Assiduidade aberto = buscarRegistoAberto(funcionario)
                .orElseThrow(() -> new IllegalStateException(
                        funcionario.getNomeCompleto() + " nao tem entrada registada em aberto."));

        ClockRegisterDto req = ClockRegisterDto.builder()
                .idempotency_key(UUID.randomUUID().toString())
                .user_id(funcionario.getId())
                .device_id(props.getDevice().getId())
                .event_type("EXIT")
                .recorded_at(LocalDateTime.now().atZone(ZoneId.systemDefault()).format(ISO_TZ))
                .source("ONLINE")
                .build();

        ClockRecordDto resultado = apiClient.withTokenRetry(() -> apiClient.registerClock(req));
        LocalDateTime horaSaida = Assiduidade.parseDateTime(resultado.getRecorded_at());
        log.info("Saida registada: {} em {}", funcionario.getNomeCompleto(), horaSaida);

        aberto.setExitId(resultado.getId());
        aberto.setDataHoraSaida(horaSaida);
        return aberto;
    }

    public Assiduidade registarManual(Funcionario funcionario, LocalDateTime entrada,
                                      LocalDateTime saida, TipoRegisto tipo, String observacao) {
        if (entrada == null) throw new IllegalArgumentException("Data/hora de entrada e obrigatoria.");
        if (saida != null && saida.isBefore(entrada))
            throw new IllegalArgumentException("Data/hora de saida nao pode ser anterior a entrada.");

        String source = "MANUAL";

        // Registar ENTRY
        ClockRegisterDto entryReq = ClockRegisterDto.builder()
                .idempotency_key(UUID.randomUUID().toString())
                .user_id(funcionario.getId())
                .device_id(props.getDevice().getId())
                .event_type("ENTRY")
                .recorded_at(entrada.atZone(ZoneId.systemDefault()).format(ISO_TZ))
                .source(source)
                .build();
        ClockRecordDto entryResult = apiClient.withTokenRetry(() -> apiClient.registerClock(entryReq));

        Assiduidade sessao = Assiduidade.builder()
                .id(entryResult.getId())
                .funcionario(funcionario)
                .dataHoraEntrada(entrada)
                .tipo(tipo)
                .observacao(observacao)
                .build();

        // Registar EXIT se fornecido
        if (saida != null) {
            ClockRegisterDto exitReq = ClockRegisterDto.builder()
                    .idempotency_key(UUID.randomUUID().toString())
                    .user_id(funcionario.getId())
                    .device_id(props.getDevice().getId())
                    .event_type("EXIT")
                    .recorded_at(saida.atZone(ZoneId.systemDefault()).format(ISO_TZ))
                    .source(source)
                    .build();
            ClockRecordDto exitResult = apiClient.withTokenRetry(() -> apiClient.registerClock(exitReq));
            sessao.setExitId(exitResult.getId());
            sessao.setDataHoraSaida(saida);
        }

        return sessao;
    }

    public Assiduidade guardar(Assiduidade assiduidade) {
        // O backend nao suporta edicao de registos — usar registarManual
        return registarManual(
                assiduidade.getFuncionario(),
                assiduidade.getDataHoraEntrada(),
                assiduidade.getDataHoraSaida(),
                assiduidade.getTipo(),
                assiduidade.getObservacao());
    }

    public void eliminar(String id) {
        throw new UnsupportedOperationException(
                "O backend nao suporta eliminacao de registos de ponto. Utilize um ajuste (adjustment request).");
    }

    // ── Sessao em aberto ──────────────────────────────────────────────────

    public Optional<Assiduidade> buscarRegistoAberto(Funcionario funcionario) {
        if (funcionario == null || funcionario.getId() == null) return Optional.empty();

        // Obter os ultimos registos ENTRY e EXIT para o utilizador
        List<ClockRecordDto> entries = apiClient.withTokenRetry(() -> 
                apiClient.listClockRecords(funcionario.getId(), "ENTRY", null, null));
        List<ClockRecordDto> exits = apiClient.withTokenRetry(() -> 
                apiClient.listClockRecords(funcionario.getId(), "EXIT", null, null));

        if (entries.isEmpty()) return Optional.empty();

        // Ordenar por recorded_at descendente
        Comparator<ClockRecordDto> byTime = Comparator.comparing(
                r -> Assiduidade.parseDateTime(r.getRecorded_at()),
                Comparator.nullsLast(Comparator.reverseOrder()));
        entries.sort(byTime);
        exits.sort(byTime);

        ClockRecordDto lastEntry = entries.get(0);
        LocalDateTime entryTime = Assiduidade.parseDateTime(lastEntry.getRecorded_at());

        // Verifica se existe saida posterior a ultima entrada
        if (!exits.isEmpty()) {
            LocalDateTime lastExitTime = Assiduidade.parseDateTime(exits.get(0).getRecorded_at());
            if (lastExitTime != null && entryTime != null && !lastExitTime.isBefore(entryTime)) {
                return Optional.empty(); // sessao fechada
            }
        }

        // Sessao em aberto
        Assiduidade aberta = Assiduidade.builder()
                .id(lastEntry.getId())
                .funcionario(funcionario)
                .dataHoraEntrada(entryTime)
                .tipo(Assiduidade.sourceParaTipoRegisto(lastEntry.getSource()))
                .build();
        return Optional.of(aberta);
    }

    // ── Emparelhamento ENTRY+EXIT ─────────────────────────────────────────

    /**
     * Agrupa uma lista plana de ClockRecordDto em sessoes Assiduidade (ENTRY+EXIT pares).
     * Registos ordenados por recorded_at ASC. Cada ENTRY inicia uma sessao;
     * o EXIT mais proximo subsequente fecha-a.
     */
    private List<Assiduidade> agruparEmSessoes(List<ClockRecordDto> records, Funcionario funcFixo) {
        // Ordenar por user_id + recorded_at ASC
        records.sort(Comparator
                .comparing(ClockRecordDto::getUser_id)
                .thenComparing(r -> Assiduidade.parseDateTime(r.getRecorded_at()),
                        Comparator.nullsLast(Comparator.naturalOrder())));

        List<Assiduidade> sessoes = new ArrayList<>();
        Map<String, Assiduidade> abertas = new HashMap<>(); // user_id -> sessao em aberto

        for (ClockRecordDto r : records) {
            String userId = r.getUser_id();
            LocalDateTime ts = Assiduidade.parseDateTime(r.getRecorded_at());

            Funcionario func = funcFixo != null ? funcFixo : resolverFuncionario(userId);

            if ("ENTRY".equals(r.getEvent_type()) || "BREAK_END".equals(r.getEvent_type())) {
                Assiduidade sessao = Assiduidade.builder()
                        .id(r.getId())
                        .funcionario(func)
                        .dataHoraEntrada(ts)
                        .tipo(Assiduidade.sourceParaTipoRegisto(r.getSource()))
                        .build();
                // Se havia sessao aberta anterior, fechar sem saida
                Assiduidade anterior = abertas.put(userId, sessao);
                if (anterior != null) sessoes.add(anterior);

            } else if ("EXIT".equals(r.getEvent_type()) || "BREAK_START".equals(r.getEvent_type())) {
                Assiduidade sessao = abertas.remove(userId);
                if (sessao != null) {
                    sessao.setExitId(r.getId());
                    sessao.setDataHoraSaida(ts);
                    sessoes.add(sessao);
                }
            }
        }

        // Adicionar sessoes ainda em aberto
        sessoes.addAll(abertas.values());

        // Ordenar por hora de entrada DESC
        sessoes.sort(Comparator.comparing(
                Assiduidade::getDataHoraEntrada,
                Comparator.nullsLast(Comparator.reverseOrder())));

        return sessoes;
    }

    private final Map<String, Funcionario> cacheFunc = new HashMap<>();

    private Funcionario resolverFuncionario(String userId) {
        return cacheFunc.computeIfAbsent(userId, id ->
                funcionarioService.buscarPorId(id).orElseGet(() -> {
                    Funcionario f = new Funcionario();
                    f.setId(id);
                    f.setNome("Utilizador");
                    f.setApelido(id.substring(0, 8));
                    return f;
                }));
    }
}
