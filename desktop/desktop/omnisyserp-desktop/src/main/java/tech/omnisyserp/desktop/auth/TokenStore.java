package tech.omnisyserp.desktop.auth;

import org.springframework.stereotype.Component;
import tech.omnisyserp.desktop.dto.UserSummaryDto;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.javakeyring.Keyring;
import com.github.javakeyring.PasswordAccessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import tech.omnisyserp.desktop.dto.UserSummaryDto;

/**
 * Armazena o token JWT da sessao atual e os dados do utilizador autenticado.
 * Utiliza o java-keyring para persistencia segura (SO Keychain/Credential Manager).
 */
@Component
@Slf4j
@RequiredArgsConstructor
public class TokenStore {

    private final ObjectMapper objectMapper;
    private static final String APP_NAME = "OmnisysERP_Desktop";
    private static final String REFRESH_TOKEN_KEY = "refresh_token";
    private static final String USER_DATA_KEY = "user_data";

    private String accessToken;
    private String refreshToken;
    private UserSummaryDto currentUser;

    /**
     * Armazena tokens em memoria e persiste o refresh token para sessoes futuras.
     */
    public void store(String accessToken, String refreshToken, UserSummaryDto user) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.currentUser = user;
        savePersistentToken(refreshToken, user);
    }

    /**
     * Carrega refresh token em memoria sem persistir (usado no arranque).
     */
    public void storeSilent(String refreshToken, UserSummaryDto user) {
        this.refreshToken = refreshToken;
        this.currentUser = user;
    }

    public void clear() {
        this.accessToken = null;
        this.refreshToken = null;
        this.currentUser = null;
        clearPersistentData();
    }

    // ──────────────────────────────────────────────
    // Persistencia Real (Keychain do SO)
    // ──────────────────────────────────────────────

    public String loadSavedRefreshToken() {
        try {
            Keyring keyring = Keyring.create();
            return keyring.getPassword(APP_NAME, REFRESH_TOKEN_KEY);
        } catch (Exception e) {
            log.debug("Nao foi possivel carregar refresh token persistente: {}", e.getMessage());
            return null;
        }
    }

    public UserSummaryDto loadSavedUser() {
        try {
            Keyring keyring = Keyring.create();
            String json = keyring.getPassword(APP_NAME, USER_DATA_KEY);
            if (json == null) return null;
            return objectMapper.readValue(json, UserSummaryDto.class);
        } catch (Exception e) {
            log.debug("Nao foi possivel carregar dados de utilizador persistentes: {}", e.getMessage());
            return null;
        }
    }

    private void savePersistentToken(String token, UserSummaryDto user) {
        try {
            Keyring keyring = Keyring.create();
            keyring.setPassword(APP_NAME, REFRESH_TOKEN_KEY, token);
            
            String json = objectMapper.writeValueAsString(user);
            keyring.setPassword(APP_NAME, USER_DATA_KEY, json);
            log.info("Sessao persistida com sucesso no keychain do SO");
        } catch (Exception e) {
            log.error("Falha ao persistir sessao no keychain: {}", e.getMessage());
        }
    }

    private void clearPersistentData() {
        try {
            Keyring keyring = Keyring.create();
            try { keyring.deletePassword(APP_NAME, REFRESH_TOKEN_KEY); } catch (Exception ignored) {}
            try { keyring.deletePassword(APP_NAME, USER_DATA_KEY); } catch (Exception ignored) {}
            log.info("Persistencia de sessao limpa.");
        } catch (Exception e) {
            log.error("Erro ao limpar dados persistentes: {}", e.getMessage());
        }
    }

    public boolean isAuthenticated() {
        return accessToken != null && !accessToken.isBlank();
    }

    public String getAccessToken() {
        return accessToken;
    }

    public String getRefreshToken() {
        return refreshToken;
    }

    public UserSummaryDto getCurrentUser() {
        return currentUser;
    }

    public String getBearerHeader() {
        return "Bearer " + accessToken;
    }
}
