package com.terminar.assiduidade.config;

import lombok.Getter;
import lombok.extern.slf4j.Slf4j;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

@Slf4j
@Getter
public class AppConfig {

    private static final Properties props = new Properties();

    private static String databaseUrl;
    private static String appTitle;
    private static boolean fingerprintSimulation;
    private static int sessionTimeoutSeconds;
    private static String companyName;
    private static String adminPin;
    private static int webcamDefaultIndex;
    private static int qrCodeSize;
    private static int screenWidth;
    private static int screenHeight;
    private static String apiBaseUrl;
    private static String apiDeviceKey;

    public static void load() throws IOException {
        try (InputStream is = AppConfig.class.getResourceAsStream("/application.properties")) {
            if (is != null) {
                props.load(is);
            }
        }
        databaseUrl = get("db.url", "jdbc:sqlite:data/assiduidade.db");
        appTitle = get("app.title", "Terminar Assiduidade");
        fingerprintSimulation = Boolean.parseBoolean(get("fingerprint.simulation", "true"));
        sessionTimeoutSeconds = Integer.parseInt(get("session.timeout.seconds", "30"));
        companyName = get("app.company", "Nexora");
        adminPin = get("admin.pin", "0000");
        webcamDefaultIndex = Integer.parseInt(get("webcam.default.index", "0"));
        qrCodeSize = Integer.parseInt(get("qrcode.size", "300"));
        screenWidth = Integer.parseInt(get("screen.width", "400"));
        screenHeight = Integer.parseInt(get("screen.height", "200"));
        apiBaseUrl = get("api.base.url", "");
        apiDeviceKey = get("api.device.key", "");
        log.info("Configuração carregada: db={}, simulação={}, timeout={}, ecrã={}x{}",
            databaseUrl, fingerprintSimulation, sessionTimeoutSeconds, screenWidth, screenHeight);
    }

    /** A sincronização/envio de eventos para o ERP só fica activa com base e chave configuradas. */
    public static boolean isApiSyncAtivo() {
        return !apiBaseUrl.isBlank() && !apiDeviceKey.isBlank();
    }

    private static String get(String key, String defaultValue) {
        String value = System.getProperty(key);
        if (value != null && !value.isBlank()) return value;
        value = props.getProperty(key);
        return value != null && !value.isBlank() ? value : defaultValue;
    }

    public static String getDatabaseUrl() { return databaseUrl; }
    public static String getAppTitle() { return appTitle; }
    public static boolean isFingerprintSimulation() { return fingerprintSimulation; }
    public static int getSessionTimeoutSeconds() { return sessionTimeoutSeconds; }
    public static String getCompanyName() { return companyName; }
    public static String getAdminPin() { return adminPin; }
    public static int getWebcamDefaultIndex() { return webcamDefaultIndex; }
    public static int getQrCodeSize() { return qrCodeSize; }
    public static int getScreenWidth() { return screenWidth; }
    public static int getScreenHeight() { return screenHeight; }
    public static String getApiBaseUrl() { return apiBaseUrl; }
    public static String getApiDeviceKey() { return apiDeviceKey; }

    /** Usado pelo ecrã "Configurações" do admin — tem efeito imediato, sem reiniciar a app. */
    public static void setApiBaseUrl(String value) { apiBaseUrl = value == null ? "" : value.trim(); }

    public static void setApiDeviceKey(String value) { apiDeviceKey = value == null ? "" : value.trim(); }
}
