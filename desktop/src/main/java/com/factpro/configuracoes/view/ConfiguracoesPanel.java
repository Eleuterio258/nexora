package com.factpro.configuracoes.view;

import com.factpro.FactProApplication;
import com.factpro.auditoria.view.AuditDashboardPanel;
import com.factpro.auth.view.RoleListPanel;
import com.factpro.auth.view.UserListPanel;
import com.factpro.config.AppConfig;
import com.factpro.core.database.DatabaseManager;
import com.factpro.faturacao.printer.ThermalPrinterService;
import com.formdev.flatlaf.FlatClientProperties;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import javax.swing.*;
import java.awt.*;
import java.sql.Connection;

/**
 * System settings panel with tabs for Geral, Base de Dados, and Impressora.
 */
public class ConfiguracoesPanel extends JPanel {

    private final AppConfig config = AppConfig.getInstance();

    // Geral tab
    private JTextField terminalIdField;
    private JTextField terminalNameField;
    private JComboBox<String> themeCombo;
    private JComboBox<String> languageCombo;
    private JButton geralSaveButton;
    private JButton aplicarTemaButton;

    // Database tab
    private JLabel currentDbTypeLabel;
    private JComboBox<String> newDbTypeCombo;
    private JTextField dbHostField;
    private JSpinner dbPortSpinner;
    private JTextField dbNameField;
    private JTextField dbUserField;
    private JPasswordField dbPasswordField;
    private JLabel dbWarningLabel;
    private JButton testDbButton;
    private JButton dbSaveButton;

    // Printer tab
    private JTextField printerAddressField;
    private JTextField printerPortField;
    private JComboBox<String> paperSizeCombo;
    private JButton testPrinterButton;
    private JButton printerSaveButton;

    public ConfiguracoesPanel() {
        initComponents();
        setupLayout();
        loadConfig();
        setupListeners();
    }

    private void initComponents() {
        // --- Geral ---
        terminalIdField = new JTextField(15);
        terminalNameField = new JTextField(20);
        themeCombo = new JComboBox<>(new String[]{"Claro", "Escuro"});
        languageCombo = new JComboBox<>(new String[]{"Portugu\u00eas", "English"});
        geralSaveButton = new JButton("Guardar");
        aplicarTemaButton = new JButton("Aplicar Tema");

        // --- Database ---
        currentDbTypeLabel = new JLabel("Tipo atual: " + config.getDatabaseType());
        currentDbTypeLabel.putClientProperty(FlatClientProperties.STYLE_CLASS, "h4");
        newDbTypeCombo = new JComboBox<>(new String[]{"SQLITE", "MYSQL", "POSTGRESQL"});
        dbHostField = new JTextField(15);
        dbPortSpinner = new JSpinner(new SpinnerNumberModel(3306, 1, 65535, 1));
        dbNameField = new JTextField(15);
        dbUserField = new JTextField(15);
        dbPasswordField = new JPasswordField(15);
        dbWarningLabel = new JLabel("Aten\u00e7\u00e3o: Alterar a base de dados requer rein\u00edcio da aplica\u00e7\u00e3o.");
        dbWarningLabel.setForeground(Color.RED);
        testDbButton = new JButton("Testar Conex\u00e3o");
        dbSaveButton = new JButton("Guardar");

        // --- Printer ---
        printerAddressField = new JTextField(15);
        printerPortField = new JTextField(10);
        paperSizeCombo = new JComboBox<>(new String[]{"58mm", "80mm"});
        testPrinterButton = new JButton("Testar Impressora");
        printerSaveButton = new JButton("Guardar");
    }

    private void setupLayout() {
        setLayout(new BorderLayout());

        JTabbedPane tabbedPane = new JTabbedPane();
        tabbedPane.addTab("Geral", buildGeralTab());
        tabbedPane.addTab("Base de Dados", buildDatabaseTab());
        tabbedPane.addTab("Impressora", buildPrinterTab());
        tabbedPane.addTab("Utilizadores", buildUsuariosTab());
        tabbedPane.addTab("Roles e Permissoes", buildRolesTab());
        tabbedPane.addTab("Auditoria", buildAuditTab());

        add(tabbedPane, BorderLayout.CENTER);
    }

    private JPanel buildGeralTab() {
        JPanel panel = new JPanel(new GridBagLayout());
        panel.setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(5, 5, 5, 5);
        gbc.fill = GridBagConstraints.HORIZONTAL;

        gbc.gridx = 0; gbc.gridy = 0; gbc.weightx = 0;
        panel.add(new JLabel("ID do Terminal:"), gbc);
        gbc.gridx = 1; gbc.weightx = 1;
        panel.add(terminalIdField, gbc);

        gbc.gridx = 0; gbc.gridy = 1; gbc.weightx = 0;
        panel.add(new JLabel("Nome do Terminal:"), gbc);
        gbc.gridx = 1; gbc.weightx = 1;
        panel.add(terminalNameField, gbc);

        gbc.gridx = 0; gbc.gridy = 2; gbc.weightx = 0;
        panel.add(new JLabel("Tema:"), gbc);
        gbc.gridx = 1; gbc.weightx = 1;
        panel.add(themeCombo, gbc);

        gbc.gridx = 0; gbc.gridy = 3; gbc.weightx = 0;
        panel.add(new JLabel("Idioma:"), gbc);
        gbc.gridx = 1; gbc.weightx = 1;
        panel.add(languageCombo, gbc);

        gbc.gridx = 0; gbc.gridy = 4; gbc.weighty = 1;
        panel.add(new JLabel(""), gbc);

        gbc.gridx = 0; gbc.gridy = 5; gbc.gridwidth = 2; gbc.weighty = 0;
        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        buttonPanel.add(geralSaveButton);
        buttonPanel.add(aplicarTemaButton);
        panel.add(buttonPanel, gbc);

        return panel;
    }

    private JPanel buildDatabaseTab() {
        JPanel panel = new JPanel(new GridBagLayout());
        panel.setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(5, 5, 5, 5);
        gbc.fill = GridBagConstraints.HORIZONTAL;

        gbc.gridx = 0; gbc.gridy = 0; gbc.gridwidth = 2;
        panel.add(currentDbTypeLabel, gbc);
        gbc.gridwidth = 1;

        gbc.gridx = 0; gbc.gridy = 1; gbc.weightx = 0;
        panel.add(new JLabel("Novo Tipo:"), gbc);
        gbc.gridx = 1; gbc.weightx = 1;
        panel.add(newDbTypeCombo, gbc);

        gbc.gridx = 0; gbc.gridy = 2; gbc.weightx = 0;
        panel.add(new JLabel("Host:"), gbc);
        gbc.gridx = 1; gbc.weightx = 1;
        panel.add(dbHostField, gbc);

        gbc.gridx = 0; gbc.gridy = 3; gbc.weightx = 0;
        panel.add(new JLabel("Porta:"), gbc);
        gbc.gridx = 1; gbc.weightx = 1;
        panel.add(dbPortSpinner, gbc);

        gbc.gridx = 0; gbc.gridy = 4; gbc.weightx = 0;
        panel.add(new JLabel("Base de Dados:"), gbc);
        gbc.gridx = 1; gbc.weightx = 1;
        panel.add(dbNameField, gbc);

        gbc.gridx = 0; gbc.gridy = 5; gbc.weightx = 0;
        panel.add(new JLabel("Utilizador:"), gbc);
        gbc.gridx = 1; gbc.weightx = 1;
        panel.add(dbUserField, gbc);

        gbc.gridx = 0; gbc.gridy = 6; gbc.weightx = 0;
        panel.add(new JLabel("Password:"), gbc);
        gbc.gridx = 1; gbc.weightx = 1;
        panel.add(dbPasswordField, gbc);

        gbc.gridx = 0; gbc.gridy = 7; gbc.gridwidth = 2;
        panel.add(dbWarningLabel, gbc);
        gbc.gridwidth = 1;

        gbc.gridx = 0; gbc.gridy = 8; gbc.weighty = 1;
        panel.add(new JLabel(""), gbc);

        gbc.gridx = 0; gbc.gridy = 9; gbc.gridwidth = 2; gbc.weighty = 0;
        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        buttonPanel.add(testDbButton);
        buttonPanel.add(dbSaveButton);
        panel.add(buttonPanel, gbc);

        return panel;
    }

    private JPanel buildPrinterTab() {
        JPanel panel = new JPanel(new GridBagLayout());
        panel.setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(5, 5, 5, 5);
        gbc.fill = GridBagConstraints.HORIZONTAL;

        gbc.gridx = 0; gbc.gridy = 0; gbc.weightx = 0;
        panel.add(new JLabel("Endere\u00e7o:"), gbc);
        gbc.gridx = 1; gbc.weightx = 1;
        panel.add(printerAddressField, gbc);

        gbc.gridx = 0; gbc.gridy = 1; gbc.weightx = 0;
        panel.add(new JLabel("Porta:"), gbc);
        gbc.gridx = 1; gbc.weightx = 1;
        panel.add(printerPortField, gbc);

        gbc.gridx = 0; gbc.gridy = 2; gbc.weightx = 0;
        panel.add(new JLabel("Tamanho do Papel:"), gbc);
        gbc.gridx = 1; gbc.weightx = 1;
        panel.add(paperSizeCombo, gbc);

        gbc.gridx = 0; gbc.gridy = 3; gbc.weighty = 1;
        panel.add(new JLabel(""), gbc);

        gbc.gridx = 0; gbc.gridy = 4; gbc.gridwidth = 2; gbc.weighty = 0;
        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        buttonPanel.add(testPrinterButton);
        buttonPanel.add(printerSaveButton);
        panel.add(buttonPanel, gbc);

        return panel;
    }

    private void setupListeners() {
        // Geral save
        geralSaveButton.addActionListener(e -> saveGeralConfig());

        // Apply theme
        aplicarTemaButton.addActionListener(e -> {
            boolean isDark = "Escuro".equals(themeCombo.getSelectedItem());
            if (isDark != config.isDarkTheme()) {
                FactProApplication.toggleTheme();
                themeCombo.setSelectedIndex(isDark ? 1 : 0);
            }
        });

        // DB type combo
        newDbTypeCombo.addActionListener(e -> {
            toggleServerFields(!"SQLITE".equals(newDbTypeCombo.getSelectedItem()));
        });

        // Database test
        testDbButton.addActionListener(e -> testDatabaseConnection());

        // Database save
        dbSaveButton.addActionListener(e -> saveDatabaseConfig());

        // Printer test
        testPrinterButton.addActionListener(e -> testPrinter());

        // Printer save
        printerSaveButton.addActionListener(e -> savePrinterConfig());
    }

    private void loadConfig() {
        // Geral
        terminalIdField.setText(config.getTerminalId());
        terminalNameField.setText(config.getTerminalName());
        themeCombo.setSelectedIndex(config.isDarkTheme() ? 1 : 0);
        languageCombo.setSelectedIndex("pt".equals(config.getLanguage()) ? 0 : 1);

        // Database
        currentDbTypeLabel.setText("Tipo atual: " + config.getDatabaseType());
        newDbTypeCombo.setSelectedItem(config.getDatabaseType().name());
        dbHostField.setText(config.getDbHost());
        dbPortSpinner.setValue(config.getDbPort());
        dbNameField.setText(config.getDbName());
        dbUserField.setText(config.getDbUser());
        dbPasswordField.setText(config.getDbPassword());
        toggleServerFields(!"SQLITE".equals(config.getDatabaseType().name()));

        // Printer
        printerAddressField.setText(config.getPrinterAddress());
        printerPortField.setText(String.valueOf(config.getPrinterPort()));
        paperSizeCombo.setSelectedItem(config.getPaperSize());
    }

    private void toggleServerFields(boolean enabled) {
        dbHostField.setEnabled(enabled);
        dbPortSpinner.setEnabled(enabled);
        dbNameField.setEnabled(enabled);
        dbUserField.setEnabled(enabled);
        dbPasswordField.setEnabled(enabled);
    }

    private void saveGeralConfig() {
        config.setTerminalId(terminalIdField.getText().trim());
        config.setTerminalName(terminalNameField.getText().trim());
        config.setDarkTheme("Escuro".equals(themeCombo.getSelectedItem()));
        config.setLanguage(languageCombo.getSelectedIndex() == 0 ? "pt" : "en");
        config.save();
        JOptionPane.showMessageDialog(this, "Configura\u00e7\u00f5es gerais guardadas.", "Sucesso",
                JOptionPane.INFORMATION_MESSAGE);
    }

    private void testDatabaseConnection() {
        String dbType = (String) newDbTypeCombo.getSelectedItem();
        if ("SQLITE".equals(dbType)) {
            boolean ok = DatabaseManager.getInstance().testConnection();
            JOptionPane.showMessageDialog(this,
                    ok ? "Conex\u00e3o SQLite OK." : "Falha na conex\u00e3o SQLite.",
                    "Teste de Conex\u00e3o", ok ? JOptionPane.INFORMATION_MESSAGE : JOptionPane.ERROR_MESSAGE);
            return;
        }

        String host = dbHostField.getText().trim();
        int port = (Integer) dbPortSpinner.getValue();
        String dbName = dbNameField.getText().trim();
        String user = dbUserField.getText().trim();
        String password = new String(dbPasswordField.getPassword());

        String jdbcUrl;
        String driverClass;

        if ("MYSQL".equals(dbType)) {
            jdbcUrl = String.format(
                    "jdbc:mysql://%s:%d/%s?useSSL=false&serverTimezone=UTC&connectTimeout=5000",
                    host, port, dbName);
            driverClass = "com.mysql.cj.jdbc.Driver";
        } else {
            jdbcUrl = String.format(
                    "jdbc:postgresql://%s:%d/%s",
                    host, port, dbName);
            driverClass = "org.postgresql.Driver";
        }

        final String fJdbcUrl = jdbcUrl;
        final String fDriverClass = driverClass;

        SwingWorker<Boolean, Void> worker = new SwingWorker<>() {
            @Override
            protected Boolean doInBackground() {
                try {
                    Class.forName(fDriverClass);
                    HikariConfig hc = new HikariConfig();
                    hc.setJdbcUrl(fJdbcUrl);
                    hc.setUsername(user);
                    hc.setPassword(password);
                    hc.setDriverClassName(fDriverClass);
                    hc.setConnectionTimeout(5000);
                    try (HikariDataSource ds = new HikariDataSource(hc);
                         Connection conn = ds.getConnection()) {
                        return conn.isValid(5);
                    }
                } catch (Exception e) {
                    return false;
                }
            }

            @Override
            protected void done() {
                try {
                    boolean ok = get();
                    JOptionPane.showMessageDialog(ConfiguracoesPanel.this,
                            ok ? "Conex\u00e3o bem-sucedida!" : "Falha na conex\u00e3o. Verifique os dados.",
                            "Teste de Conex\u00e3o", ok ? JOptionPane.INFORMATION_MESSAGE : JOptionPane.ERROR_MESSAGE);
                } catch (Exception e) {
                    JOptionPane.showMessageDialog(ConfiguracoesPanel.this,
                            "Erro: " + e.getMessage(),
                            "Teste de Conex\u00e3o", JOptionPane.ERROR_MESSAGE);
                }
            }
        };
        worker.execute();
    }

    private void saveDatabaseConfig() {
        String dbTypeName = (String) newDbTypeCombo.getSelectedItem();
        config.setDatabaseType(AppConfig.DatabaseType.valueOf(dbTypeName));

        if (!"SQLITE".equals(dbTypeName)) {
            config.setDbHost(dbHostField.getText().trim());
            config.setDbPort((Integer) dbPortSpinner.getValue());
            config.setDbName(dbNameField.getText().trim());
            config.setDbUser(dbUserField.getText().trim());
            config.setDbPassword(new String(dbPasswordField.getPassword()));
        }

        config.save();
        currentDbTypeLabel.setText("Tipo atual: " + config.getDatabaseType());
        JOptionPane.showMessageDialog(this,
                "Configura\u00e7\u00e3o da base de dados guardada.\nReinicie a aplica\u00e7\u00e3o para aplicar.",
                "Sucesso", JOptionPane.INFORMATION_MESSAGE);
    }

    private void testPrinter() {
        String address = printerAddressField.getText().trim();
        String portStr = printerPortField.getText().trim();
        int port;
        try {
            port = Integer.parseInt(portStr);
        } catch (NumberFormatException e) {
            JOptionPane.showMessageDialog(this, "Porta inv\u00e1lida.", "Erro", JOptionPane.ERROR_MESSAGE);
            return;
        }

        ThermalPrinterService printer = new ThermalPrinterService(address, port);
        boolean ok = printer.testConnection();
        JOptionPane.showMessageDialog(this,
                ok ? "Impressora conectada com sucesso!" : "Falha ao conectar com a impressora.",
                "Teste de Impressora", ok ? JOptionPane.INFORMATION_MESSAGE : JOptionPane.ERROR_MESSAGE);
    }

    private void savePrinterConfig() {
        config.setPrinterAddress(printerAddressField.getText().trim());
        try {
            config.setPrinterPort(Integer.parseInt(printerPortField.getText().trim()));
        } catch (NumberFormatException ignored) {
        }
        config.setPaperSize((String) paperSizeCombo.getSelectedItem());
        config.save();
        JOptionPane.showMessageDialog(this, "Configura\u00e7\u00f5es da impressora guardadas.", "Sucesso",
                JOptionPane.INFORMATION_MESSAGE);
    }

    private JPanel buildUsuariosTab() {
        return new UserListPanel();
    }

    private JPanel buildRolesTab() {
        return new RoleListPanel();
    }

    private JPanel buildAuditTab() {
        return new AuditDashboardPanel();
    }
}
