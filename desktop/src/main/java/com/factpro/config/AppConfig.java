package com.factpro.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * Configuração global da aplicação (singleton).
 * Armazena e persiste configurações em ficheiro JSON.
 */
public class AppConfig {
    
    private static final Logger logger = LoggerFactory.getLogger(AppConfig.class);
    private static AppConfig instance;
    
    // Config file path
    private static final String CONFIG_DIR = System.getProperty("user.home") + "/.factpro";
    private static final String CONFIG_FILE = CONFIG_DIR + "/config.json";
    
    // Database settings
    private DatabaseType databaseType = DatabaseType.SQLITE;
    private String sqlitePath = "./data/factpro.db";
    private String dbHost = "localhost";
    private int dbPort = 3306;
    private String dbName = "factpro";
    private String dbUser = "";
    private String dbPassword = "";
    
    // App settings
    private boolean darkTheme = false;
    private String language = "pt";
    private String terminalId = "POS-001";
    private String terminalName = "Caixa 1";
    
    // Backup settings
    private String backupPath = "./backups";
    private int backupRetentionDays = 30;
    
    // Printer settings
    private String printerAddress = "192.168.1.100";
    private int printerPort = 9100;
    private String paperSize = "80mm";

    // Mobile payment API keys
    private String mpesaApiKey = "";
    private String mpesaPublicKey = "";
    private String emolaApiKey = "";
    
    private final ObjectMapper mapper = new ObjectMapper();
    
    public enum DatabaseType {
        SQLITE, MYSQL, POSTGRESQL
    }
    
    private AppConfig() {
        load();
    }
    
    public static synchronized AppConfig getInstance() {
        if (instance == null) {
            instance = new AppConfig();
        }
        return instance;
    }
    
    /**
     * Carrega configurações do ficheiro JSON.
     */
    private void load() {
        File file = new File(CONFIG_FILE);
        
        if (!file.exists()) {
            logger.info("Ficheiro de configuração não encontrado. Usando defaults.");
            createConfigDir();
            return;
        }
        
        try {
            ObjectNode config = (ObjectNode) mapper.readTree(file);
            
            if (config.has("databaseType")) {
                this.databaseType = DatabaseType.valueOf(config.get("databaseType").asText());
            }
            if (config.has("sqlitePath")) this.sqlitePath = config.get("sqlitePath").asText();
            if (config.has("dbHost")) this.dbHost = config.get("dbHost").asText();
            if (config.has("dbPort")) this.dbPort = config.get("dbPort").asInt();
            if (config.has("dbName")) this.dbName = config.get("dbName").asText();
            if (config.has("dbUser")) this.dbUser = config.get("dbUser").asText();
            if (config.has("dbPassword")) this.dbPassword = config.get("dbPassword").asText();
            if (config.has("darkTheme")) this.darkTheme = config.get("darkTheme").asBoolean();
            if (config.has("language")) this.language = config.get("language").asText();
            if (config.has("terminalId")) this.terminalId = config.get("terminalId").asText();
            if (config.has("terminalName")) this.terminalName = config.get("terminalName").asText();
            if (config.has("backupPath")) this.backupPath = config.get("backupPath").asText();
            if (config.has("printerAddress")) this.printerAddress = config.get("printerAddress").asText();
            if (config.has("printerPort")) this.printerPort = config.get("printerPort").asInt();
            if (config.has("paperSize")) this.paperSize = config.get("paperSize").asText();
            if (config.has("mpesaApiKey")) this.mpesaApiKey = config.get("mpesaApiKey").asText();
            if (config.has("mpesaPublicKey")) this.mpesaPublicKey = config.get("mpesaPublicKey").asText();
            if (config.has("emolaApiKey")) this.emolaApiKey = config.get("emolaApiKey").asText();
            
            logger.info("Configuração carregada com sucesso");
        } catch (IOException e) {
            logger.error("Erro ao carregar configuração", e);
        }
    }
    
    /**
     * Salva configurações no ficheiro JSON.
     */
    public void save() {
        try {
            createConfigDir();
            
            ObjectNode config = mapper.createObjectNode();
            config.put("databaseType", databaseType.name());
            config.put("sqlitePath", sqlitePath);
            config.put("dbHost", dbHost);
            config.put("dbPort", dbPort);
            config.put("dbName", dbName);
            config.put("dbUser", dbUser);
            config.put("dbPassword", dbPassword);
            config.put("darkTheme", darkTheme);
            config.put("language", language);
            config.put("terminalId", terminalId);
            config.put("terminalName", terminalName);
            config.put("backupPath", backupPath);
            config.put("printerAddress", printerAddress);
            config.put("printerPort", printerPort);
            config.put("paperSize", paperSize);
            config.put("mpesaApiKey", mpesaApiKey);
            config.put("mpesaPublicKey", mpesaPublicKey);
            config.put("emolaApiKey", emolaApiKey);
            
            mapper.writerWithDefaultPrettyPrinter().writeValue(new File(CONFIG_FILE), config);
            logger.info("Configuração salva com sucesso");
        } catch (IOException e) {
            logger.error("Erro ao salvar configuração", e);
        }
    }
    
    private void createConfigDir() {
        try {
            Files.createDirectories(Path.of(CONFIG_DIR));
        } catch (IOException e) {
            logger.error("Erro ao criar diretório de configuração", e);
        }
    }
    
    // Getters and Setters
    
    public DatabaseType getDatabaseType() { return databaseType; }
    public void setDatabaseType(DatabaseType databaseType) { this.databaseType = databaseType; }
    
    public String getSqlitePath() { return sqlitePath; }
    public void setSqlitePath(String sqlitePath) { this.sqlitePath = sqlitePath; }
    
    public String getDbHost() { return dbHost; }
    public void setDbHost(String dbHost) { this.dbHost = dbHost; }
    
    public int getDbPort() { return dbPort; }
    public void setDbPort(int dbPort) { this.dbPort = dbPort; }
    
    public String getDbName() { return dbName; }
    public void setDbName(String dbName) { this.dbName = dbName; }
    
    public String getDbUser() { return dbUser; }
    public void setDbUser(String dbUser) { this.dbUser = dbUser; }
    
    public String getDbPassword() { return dbPassword; }
    public void setDbPassword(String dbPassword) { this.dbPassword = dbPassword; }
    
    public boolean isDarkTheme() { return darkTheme; }
    public void setDarkTheme(boolean darkTheme) { this.darkTheme = darkTheme; }
    
    public String getLanguage() { return language; }
    public void setLanguage(String language) { this.language = language; }
    
    public String getTerminalId() { return terminalId; }
    public void setTerminalId(String terminalId) { this.terminalId = terminalId; }
    
    public String getTerminalName() { return terminalName; }
    public void setTerminalName(String terminalName) { this.terminalName = terminalName; }
    
    public String getBackupPath() { return backupPath; }
    public void setBackupPath(String backupPath) { this.backupPath = backupPath; }
    
    public int getBackupRetentionDays() { return backupRetentionDays; }
    public void setBackupRetentionDays(int backupRetentionDays) { this.backupRetentionDays = backupRetentionDays; }
    
    public String getPrinterAddress() { return printerAddress; }
    public void setPrinterAddress(String printerAddress) { this.printerAddress = printerAddress; }
    
    public int getPrinterPort() { return printerPort; }
    public void setPrinterPort(int printerPort) { this.printerPort = printerPort; }
    
    public String getPaperSize() { return paperSize; }
    public void setPaperSize(String paperSize) { this.paperSize = paperSize; }
    
    public boolean isServerMode() {
        return databaseType == DatabaseType.MYSQL || databaseType == DatabaseType.POSTGRESQL;
    }

    public String getMpesaApiKey() { return mpesaApiKey; }
    public void setMpesaApiKey(String mpesaApiKey) { this.mpesaApiKey = mpesaApiKey; }

    public String getMpesaPublicKey() { return mpesaPublicKey; }
    public void setMpesaPublicKey(String mpesaPublicKey) { this.mpesaPublicKey = mpesaPublicKey; }

    public String getEmolaApiKey() { return emolaApiKey; }
    public void setEmolaApiKey(String emolaApiKey) { this.emolaApiKey = emolaApiKey; }
}
