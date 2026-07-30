package com.terminar.assiduidade.integration;

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
        try {
            String corpo = MAPPER.writeValueAsString(new EventoGenerico(registo));
            HttpRequest request = requestBuilder("/api/hardware/events/generic")
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(corpo))
                .build();
            enviar(request);
        } catch (AssiduidadeException e) {
            throw e;
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao construir evento para o ERP", e);
        }
    }

    private HttpRequest.Builder requestBuilder(String caminho) {
        return HttpRequest.newBuilder()
            .uri(URI.create(baseUrl + caminho))
            .timeout(Duration.ofSeconds(10))
            .header("X-API-Key", deviceKey);
    }

    private HttpResponse<String> enviar(HttpRequest request) {
        try {
            HttpResponse<String> response = CLIENT.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() / 100 != 2) {
                throw new AssiduidadeException("ERP devolveu " + response.statusCode() + ": " + response.body());
            }
            return response;
        } catch (AssiduidadeException e) {
            throw e;
        } catch (Exception e) {
            throw new AssiduidadeException("Erro de comunicação com o ERP", e);
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

        private static String direcao(TipoMarcacao tipo) {
            return switch (tipo) {
                case ENTRADA, FIM_PAUSA -> "in";
                case SAIDA, INICIO_PAUSA -> "out";
            };
        }

        private static String credencial(MetodoAutenticacao metodo) {
            return switch (metodo) {
                case PIN -> "pin";
                case QR_CODE -> "qrcode";
                case FINGERPRINT -> "fingerprint";
                case NFC -> "nfc";
            };
        }
    }
}
