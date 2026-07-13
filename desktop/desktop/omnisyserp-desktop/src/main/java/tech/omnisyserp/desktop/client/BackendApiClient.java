package tech.omnisyserp.desktop.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;
import tech.omnisyserp.desktop.auth.TokenStore;
import tech.omnisyserp.desktop.config.BackendProperties;
import tech.omnisyserp.desktop.dto.*;

import java.util.ArrayList;
import java.util.List;

/**
 * Cliente HTTP que envolve todas as chamadas ao backend FastAPI (controle).
 * Todos os endpoints requerem o Bearer token armazenado em TokenStore.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class BackendApiClient {

    private final RestTemplate restTemplate;
    private final TokenStore tokenStore;
    private final BackendProperties props;

    // ──────────────────────────────────────────────
    // Auth
    // ──────────────────────────────────────────────

    public LoginResponseDto login(String username, String password) {
        String url = props.getApi().getUrl() + "/api/v1/auth/login";
        LoginRequestDto body = new LoginRequestDto(username, password);
        ResponseEntity<LoginResponseDto> resp = restTemplate.postForEntity(url, body, LoginResponseDto.class);
        LoginResponseDto response = resp.getBody();
        if (response != null) {
            tokenStore.store(response.getAccess_token(), response.getRefresh_token(), response.getUser());
        }
        return response;
    }

    /**
     * Renova o access token usando o refresh token.
     * @return true se renovou com sucesso, false se falhou
     */
    public boolean refreshToken() {
        if (tokenStore.getRefreshToken() == null) {
            return false;
        }

        try {
            String url = props.getApi().getUrl() + "/api/v1/auth/refresh";
            RefreshTokenRequestDto body = new RefreshTokenRequestDto(tokenStore.getRefreshToken());

            log.info("A renovar token JWT...");
            ResponseEntity<LoginResponseDto> resp = restTemplate.postForEntity(url, body, LoginResponseDto.class);
            LoginResponseDto response = resp.getBody();

            if (response != null) {
                // Preferir user vindo da resposta; fallback para o que ja estava em memoria
                UserSummaryDto user = response.getUser() != null
                        ? response.getUser()
                        : tokenStore.getCurrentUser();
                tokenStore.store(response.getAccess_token(), response.getRefresh_token(), user);
                log.info("Token renovado com sucesso");
                return true;
            }
            return false;
        } catch (Exception e) {
            log.error("Falha ao renovar token: {}", e.getMessage());
            return false;
        }
    }

    /**
     * Intercepta erros 401 e tenta renovar token automaticamente.
     */
    public <T> T withTokenRetry(java.util.function.Supplier<T> apiCall) {
        try {
            return apiCall.get();
        } catch (HttpClientErrorException.Unauthorized e) {
            log.warn("Token expirado (401), a tentar renovar...");
            if (refreshToken()) {
                log.info("Token renovado, a repetir operacao...");
                return apiCall.get();
            } else {
                log.error("Falha ao renovar token, sessao expirou");
                throw new SessionExpiredException("Sessao expirou. Por favor faca login novamente.");
            }
        }
    }

    public static class SessionExpiredException extends RuntimeException {
        public SessionExpiredException(String message) { super(message); }
    }

    // ──────────────────────────────────────────────
    // Users (Funcionarios)
    // ──────────────────────────────────────────────

    public List<UserDto> listUsers(String statusFilter) {
        List<UserDto> all = new ArrayList<>();
        int page = 1;
        int pageSize = 100;

        while (true) {
            UriComponentsBuilder builder = UriComponentsBuilder
                    .fromHttpUrl(props.getApi().getUrl() + "/api/v1/admin/users")
                    .queryParam("page", page)
                    .queryParam("page_size", pageSize);
            if (statusFilter != null && !statusFilter.isBlank()) {
                builder.queryParam("status", statusFilter);
            }

            ResponseEntity<PaginatedUsersDto> resp = restTemplate.exchange(
                    builder.toUriString(),
                    HttpMethod.GET,
                    authHeaders(),
                    PaginatedUsersDto.class
            );

            PaginatedUsersDto body = resp.getBody();
            if (body == null || body.getItems() == null || body.getItems().isEmpty()) break;

            all.addAll(body.getItems());
            if (all.size() >= body.getTotal()) break;
            page++;
        }
        return all;
    }

    public UserDto getUser(String userId) {
        String url = props.getApi().getUrl() + "/api/v1/admin/users/" + userId;
        ResponseEntity<UserDto> resp = restTemplate.exchange(url, HttpMethod.GET, authHeaders(), UserDto.class);
        return resp.getBody();
    }

    public UserDto createUser(UserCreateDto dto) {
        String url = props.getApi().getUrl() + "/api/v1/admin/users";
        HttpEntity<UserCreateDto> req = new HttpEntity<>(dto, authHeadersMap());
        ResponseEntity<UserDto> resp = restTemplate.exchange(url, HttpMethod.POST, req, UserDto.class);
        return resp.getBody();
    }

    public UserDto updateUser(String userId, UserUpdateDto dto) {
        String url = props.getApi().getUrl() + "/api/v1/admin/users/" + userId;
        HttpEntity<UserUpdateDto> req = new HttpEntity<>(dto, authHeadersMap());
        ResponseEntity<UserDto> resp = restTemplate.exchange(url, HttpMethod.PATCH, req, UserDto.class);
        return resp.getBody();
    }

    public void deactivateUser(String userId) {
        String url = props.getApi().getUrl() + "/api/v1/admin/users/" + userId;
        restTemplate.exchange(url, HttpMethod.DELETE, authHeaders(), Void.class);
    }

    // ──────────────────────────────────────────────
    // Biometric
    // ──────────────────────────────────────────────

    public VerifyResponseDto verifyBiometric(VerifyRequestDto dto) {
        String url = props.getApi().getUrl() + "/api/v1/biometric/verify";
        HttpEntity<VerifyRequestDto> req = new HttpEntity<>(dto, authHeadersMap());
        ResponseEntity<VerifyResponseDto> resp = restTemplate.exchange(url, HttpMethod.POST, req, VerifyResponseDto.class);
        return resp.getBody();
    }

    public EnrollResponseDto enrollBiometric(EnrollRequestDto dto) {
        String url = props.getApi().getUrl() + "/api/v1/biometric/enroll";
        HttpEntity<EnrollRequestDto> req = new HttpEntity<>(dto, authHeadersMap());
        ResponseEntity<EnrollResponseDto> resp = restTemplate.exchange(url, HttpMethod.POST, req, EnrollResponseDto.class);
        return resp.getBody();
    }

    // ──────────────────────────────────────────────
    // Consents
    // ──────────────────────────────────────────────

    public ConsentResponseDto getActiveConsent(String userId) {
        String url = props.getApi().getUrl() + "/api/v1/consents/users/" + userId + "/active";
        try {
            ResponseEntity<ConsentResponseDto> resp = restTemplate.exchange(url, HttpMethod.GET, authHeaders(), ConsentResponseDto.class);
            return resp.getBody();
        } catch (org.springframework.web.client.HttpClientErrorException.NotFound e) {
            return null;
        }
    }

    public ConsentResponseDto createConsent(ConsentCreateDto dto) {
        String url = props.getApi().getUrl() + "/api/v1/consents";
        HttpEntity<ConsentCreateDto> req = new HttpEntity<>(dto, authHeadersMap());
        ResponseEntity<ConsentResponseDto> resp = restTemplate.exchange(url, HttpMethod.POST, req, ConsentResponseDto.class);
        return resp.getBody();
    }

    // ──────────────────────────────────────────────
    // Clock Records (Assiduidade)
    // ──────────────────────────────────────────────

    public List<ClockRecordDto> listClockRecords(String userId, String eventType,
                                                  String startDate, String endDate) {
        List<ClockRecordDto> all = new ArrayList<>();
        int page = 1;
        int pageSize = 200;

        while (true) {
            UriComponentsBuilder builder = UriComponentsBuilder
                    .fromHttpUrl(props.getApi().getUrl() + "/api/v1/admin/clock-records")
                    .queryParam("page", page)
                    .queryParam("page_size", pageSize);
            if (userId != null) builder.queryParam("user_id", userId);
            if (eventType != null) builder.queryParam("event_type", eventType);
            if (startDate != null) builder.queryParam("start_date", startDate);
            if (endDate != null) builder.queryParam("end_date", endDate);

            ResponseEntity<PaginatedClockRecordsDto> resp = restTemplate.exchange(
                    builder.toUriString(),
                    HttpMethod.GET,
                    authHeaders(),
                    PaginatedClockRecordsDto.class
            );

            PaginatedClockRecordsDto body = resp.getBody();
            if (body == null || body.getItems() == null || body.getItems().isEmpty()) break;

            all.addAll(body.getItems());
            if (all.size() >= body.getTotal()) break;
            page++;
        }
        return all;
    }

    public ClockRecordDto registerClock(ClockRegisterDto dto) {
        String url = props.getApi().getUrl() + "/api/v1/clock/register";
        HttpEntity<ClockRegisterDto> req = new HttpEntity<>(dto, authHeadersMap());
        try {
            ResponseEntity<ClockRecordDto> resp = restTemplate.exchange(url, HttpMethod.POST, req, ClockRecordDto.class);
            return resp.getBody();
        } catch (HttpClientErrorException.Conflict e) {
            // idempotency_key duplicado — registo ja existe
            log.warn("Registo de ponto ja existe (idempotency_key duplicado): {}", dto.getIdempotency_key());
            throw new IllegalStateException("Registo de ponto ja foi efectuado anteriormente.");
        }
    }

    /**
     * Regista o dispositivo desktop no backend se ainda nao existir.
     * Deve ser chamado apos login bem-sucedido.
     */
    public void registerDeviceIfNeeded() {
        String deviceCode = "DESKTOP-001";

        try {
            // Check if device already exists
            String listUrl = props.getApi().getUrl() + "/api/v1/admin/devices";
            ResponseEntity<PaginatedDevicesDto> resp = restTemplate.exchange(
                    listUrl,
                    HttpMethod.GET,
                    authHeaders(),
                    PaginatedDevicesDto.class
            );

            if (resp.getBody() != null && resp.getBody().getItems() != null) {
                for (DeviceDto d : resp.getBody().getItems()) {
                    if (deviceCode.equals(d.getDevice_code())) {
                        log.info("Device {} ja registado no backend com ID {}", deviceCode, d.getId());
                        props.getDevice().setId(d.getId().toString());
                        return;
                    }
                }
            }
        } catch (Exception e) {
            log.warn("Nao foi possivel verificar dispositivos existentes: {}", e.getMessage());
        }

        // Device not found, register it
        try {
            String createUrl = props.getApi().getUrl() + "/api/v1/admin/devices";
            String deviceJson = String.format(
                    "{\"device_code\":\"%s\",\"display_name\":\"%s\",\"type\":\"KIOSK\"}",
                    deviceCode, "OmnisysERP Desktop");

            HttpHeaders headers = authHeadersMap();
            HttpEntity<String> req = new HttpEntity<>(deviceJson, headers);

            ResponseEntity<DeviceDto> resp = restTemplate.exchange(createUrl, HttpMethod.POST, req, DeviceDto.class);
            if (resp.getBody() != null) {
                DeviceDto newDevice = resp.getBody();
                log.info("Dispositivo {} registado com sucesso com ID {}", deviceCode, newDevice.getId());
                props.getDevice().setId(newDevice.getId().toString());
            }
        } catch (Exception e) {
            log.error("Falha ao registar dispositivo: {}", e.getMessage());
        }
    }

    // ──────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────

    private HttpEntity<Void> authHeaders() {
        return new HttpEntity<>(authHeadersMap());
    }

    private HttpHeaders authHeadersMap() {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        if (tokenStore.isAuthenticated()) {
            headers.set(HttpHeaders.AUTHORIZATION, tokenStore.getBearerHeader());
        }
        return headers;
    }
}
