package com.terminar.assiduidade.integration;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.exception.AssiduidadeException;
import com.terminar.assiduidade.model.MetodoAutenticacao;
import com.terminar.assiduidade.model.RegistoPonto;
import com.terminar.assiduidade.model.TipoMarcacao;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Cliente do Nexora ERP (backend/), autenticado como "device" via X-API-Key
 * (RequireDeviceAuth, ver internal/middleware/device_auth.go no ERP).
 */
public class ErpApiClient {

    private static final HttpClient CLIENT = HttpClient.newBuilder()
        .connectTimeout(Duration.ofSeconds(5))
        .build();
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final String baseUrl;
    private final String deviceKey;

    /** Usa a configuração activa (AppConfig) — caso normal, usado por ErpSyncService. */
    public ErpApiClient() {
        this(AppConfig.getApiBaseUrl(), AppConfig.getApiDeviceKey());
    }

    /** URL/chave explícitos, sem tocar na configuração global — usado para "Testar ligação". */
    public ErpApiClient(String baseUrl, String deviceKey) {
        this.baseUrl = baseUrl;
        this.deviceKey = deviceKey;
    }

    /** GET /api/hardware/assiduidade/funcionarios */
    public List<FuncionarioErp> listarFuncionarios() {
        HttpRequest request = requestBuilder("/api/hardware/assiduidade/funcionarios")
            .GET()
            .build();
        HttpResponse<String> response = enviar(request);
        try {
            return MAPPER.readValue(response.body(),
                MAPPER.getTypeFactory().constructCollectionType(List.class, FuncionarioErp.class));
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao interpretar resposta do ERP", e);
        }
    }

    /** POST /api/hardware/events/generic — contrato adapters.GenericPayload do ERP. */
    public void enviarEvento(RegistoPonto registo) {
        HttpResponse<String> response;
        try {
            String corpo = MAPPER.writeValueAsString(new EventoGenerico(registo));
            HttpRequest request = requestBuilder("/api/hardware/events/generic")
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(corpo))
                .build();
            response = enviar(request);
        } catch (AssiduidadeException e) {
            throw e;
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao construir evento para o ERP", e);
        }
        garantirProcessado(response);
    }

    /**
     * O ERP aceita o evento (guarda-o em hardware.device_events) mas pode
     * recusar-se a transformá-lo numa marcação — funcionário não mapeado em
     * hardware.device_users, funcionário inactivo, método de assiduidade
     * desligado para o tenant. Nesse caso responde 200 com
     * {"processed": false, "error": "..."}, e só responde 201 quando a
     * marcação foi mesmo criada (ver handlers/events.go no ERP).
     *
     * Olhar apenas para a família 2xx dava as duas respostas por boas, e o
     * ErpSyncService marcava como sincronizado um evento que o ERP tinha
     * recusado — a marcação desaparecia sem rasto. Tratar "processed: false"
     * como falha devolve o erro do ERP a quem chamou, que o regista e deixa o
     * registo por sincronizar.
     */
    private void garantirProcessado(HttpResponse<String> response) {
        boolean processado;
        String erro;
        try {
            JsonNode corpo = MAPPER.readTree(response.body());
            processado = corpo.path("processed").asBoolean(false);
            erro = corpo.path("error").asText("");
        } catch (Exception e) {
            throw new AssiduidadeException("Resposta ilegível do ERP ao registar evento", e);
        }
        if (!processado) {
            throw new AssiduidadeException(
                "ERP não processou o evento" + (erro.isBlank() ? "" : ": " + erro));
        }
    }

    private static final int MAX_TENTATIVAS = 3;
    private static final long BACKOFF_INICIAL_MS = 1000;

    private HttpRequest.Builder requestBuilder(String caminho) {
        return HttpRequest.newBuilder()
            .uri(URI.create(baseUrl + caminho))
            .timeout(Duration.ofSeconds(10))
            .header("X-API-Key", deviceKey);
    }

    /**
     * Repete até {@value #MAX_TENTATIVAS} vezes com backoff a duplicar (1s, 2s), para cobrir
     * falhas de rede transitórias (timeout, ligação recusada) sem depender só do reenvio
     * periódico do ErpSyncService, que só corre minutos depois. Repetir é seguro mesmo para
     * POST /events porque o ERP é idempotente por event_hash (ver processor.go no backend).
     * Erros 4xx (chave inválida, payload rejeitado) não são repetidos — tentar de novo não
     * muda o resultado.
     */
    private HttpResponse<String> enviar(HttpRequest request) {
        AssiduidadeException falhaFinal = null;
        long esperaMs = BACKOFF_INICIAL_MS;
        for (int tentativa = 1; tentativa <= MAX_TENTATIVAS; tentativa++) {
            if (tentativa > 1) {
                aguardar(esperaMs);
                esperaMs *= 2;
            }
            try {
                HttpResponse<String> response = CLIENT.send(request, HttpResponse.BodyHandlers.ofString());
                if (response.statusCode() / 100 == 2) {
                    return response;
                }
                falhaFinal = new AssiduidadeException("ERP devolveu " + response.statusCode() + ": " + response.body());
                if (response.statusCode() / 100 == 4) {
                    break;
                }
            } catch (Exception e) {
                falhaFinal = new AssiduidadeException("Erro de comunicação com o ERP", e);
            }
        }
        throw falhaFinal;
    }

    private void aguardar(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new AssiduidadeException("Interrompido a aguardar novo envio ao ERP", e);
        }
    }

    private static final class EventoGenerico {
        public final String employee_no;
        public final String event_time;
        public final String event_type = "access_granted";
        public final String direction;
        public final String credential_type;

        EventoGenerico(RegistoPonto registo) {
            this.employee_no = registo.getEmployeeNumero();
            this.event_time = registo.getDataHora().atOffset(ZoneOffset.UTC)
                .format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
            this.direction = direcao(registo.getTipo());
            this.credential_type = credencial(registo.getMetodo());
        }

        /**
         * O vocabulário do ERP é "entry"/"exit"/"unknown" (NormalizedEvent em
         * models/event.go); "in"/"out" não casava com nenhum caso do
         * inferirTipoEventoCodigo e o ERP acabava sempre a inferir a direcção
         * pela paridade dos eventos do dia, ignorando a decisão do terminal.
         *
         * As pausas continuam achatadas em entrada/saída porque o contrato
         * genérico do ERP não tem forma de as distinguir — quem precisar disso
         * tem de passar por rh.eventos_assiduidade com os códigos
         * intervalo_inicio/intervalo_fim.
         */
        private static String direcao(TipoMarcacao tipo) {
            return switch (tipo) {
                case ENTRADA, FIM_PAUSA -> "entry";
                case SAIDA, INICIO_PAUSA -> "exit";
            };
        }

        /**
         * Chaves reconhecidas pelo credentialTypeToMetodo do ERP
         * (service/processor.go). "qrcode" não era uma delas: o evento ficava
         * gravado como método "biometria" e escapava à verificação de método
         * activo do tenant, que falha aberta em credential_type desconhecido.
         */
        private static String credencial(MetodoAutenticacao metodo) {
            return switch (metodo) {
                case PIN -> "pin";
                case QR_CODE -> "qr";
                case FINGERPRINT -> "fingerprint";
                case NFC -> "nfc";
            };
        }
    }
}
