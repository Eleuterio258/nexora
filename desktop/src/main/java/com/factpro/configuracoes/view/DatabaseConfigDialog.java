package com.factpro.configuracoes.view;

import com.factpro.config.AppConfig;
import com.factpro.core.database.DatabaseManager;
import com.formdev.flatlaf.FlatClientProperties;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import javax.swing.*;
import java.awt.*;
import java.sql.Connection;
import java.sql.DriverManager;

/**
 * Database configuration dialog shown on first run.
 */
public class DatabaseConfigDialog extends JDialog {

    private boolean configSaved = false;

    private JRadioButton sqliteRadio;
    private JRadioButton mysqlRadio;
    private JRadioButton pgRadio;

    private JTextField hostField;
    private JSpinner portSpinner;
    private JTextField dbNameField;
    private JTextField dbUserField;
    private JPasswordField dbPasswordField;

    private JPanel serverConfigPanel;
    private JButton testButton;
    private JButton avancarButton;
    private JButton cancelarButton;
    private JLabel statusLabel;

    public DatabaseConfigDialog(Frame parent) {
        super(parent, "Configura\u00e7\u00e3o Inicial - Base de Dados", true);
        initComponents();
        setupLayout();
        setupListeners();
        setSize(480, 420);
        setLocationRelativeTo(parent);
        setResizable(false);
    }

    private void initComponents() {
        ButtonGroup group = new ButtonGroup();

        sqliteRadio = new JRadioButton("SQLite (Local - Recomendado)");
        sqliteRadio.setSelected(true);
        mysqlRadio = new JRadioButton("MySQL (Servidor)");
        pgRadio = new JRadioButton("PostgreSQL (Servidor)");

        group.add(sqliteRadio);
        group.add(mysqlRadio);
        group.add(pgRadio);

        serverConfigPanel = new JPanel(new GridBagLayout());
        serverConfigPanel.setBorder(BorderFactory.createTitledBorder("Configura\u00e7\u00e3o do Servidor"));
        serverConfigPanel.setEnabled(false);

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(4, 4, 4, 4);
        gbc.fill = GridBagConstraints.HORIZONTAL;

        // Host
        gbc.gridx = 0;
        gbc.gridy = 0;
        gbc.weightx = 0;
        serverConfigPanel.add(new JLabel("Host:"), gbc);
        gbc.gridx = 1;
        gbc.weightx = 1;
        hostField = new JTextField("localhost");
        serverConfigPanel.add(hostField, gbc);

        // Port
        gbc.gridx = 0;
        gbc.gridy = 1;
        gbc.weightx = 0;
        serverConfigPanel.add(new JLabel("Porta:"), gbc);
        gbc.gridx = 1;
        gbc.weightx = 1;
        portSpinner = new JSpinner(new SpinnerNumberModel(3306, 1, 65535, 1));
        serverConfigPanel.add(portSpinner, gbc);

        // Database name
        gbc.gridx = 0;
        gbc.gridy = 2;
        gbc.weightx = 0;
        serverConfigPanel.add(new JLabel("Base de Dados:"), gbc);
        gbc.gridx = 1;
        gbc.weightx = 1;
        dbNameField = new JTextField("factpro");
        serverConfigPanel.add(dbNameField, gbc);

        // User
        gbc.gridx = 0;
        gbc.gridy = 3;
        gbc.weightx = 0;
        serverConfigPanel.add(new JLabel("Utilizador:"), gbc);
        gbc.gridx = 1;
        gbc.weightx = 1;
        dbUserField = new JTextField();
        serverConfigPanel.add(dbUserField, gbc);

        // Password
        gbc.gridx = 0;
        gbc.gridy = 4;
        gbc.weightx = 0;
        serverConfigPanel.add(new JLabel("Password:"), gbc);
        gbc.gridx = 1;
        gbc.weightx = 1;
        dbPasswordField = new JPasswordField();
        serverConfigPanel.add(dbPasswordField, gbc);

        testButton = new JButton("Testar Conex\u00e3o");
        avancarButton = new JButton("Avan\u00e7ar");
        cancelarButton = new JButton("Cancelar");
        statusLabel = new JLabel(" ");
        statusLabel.putClientProperty(FlatClientProperties.STYLE_CLASS, "info");

        toggleServerConfig(false);
    }

    private void setupLayout() {
        setLayout(new BorderLayout(10, 10));

        JPanel topPanel = new JPanel();
        topPanel.setLayout(new BoxLayout(topPanel, BoxLayout.Y_AXIS));
        topPanel.setBorder(BorderFactory.createEmptyBorder(15, 15, 10, 15));

        JLabel titleLabel = new JLabel("Seleccione o tipo de base de dados:");
        titleLabel.putClientProperty(FlatClientProperties.STYLE_CLASS, "h3");

        topPanel.add(titleLabel);
        topPanel.add(Box.createVerticalStrut(10));
        topPanel.add(sqliteRadio);
        topPanel.add(mysqlRadio);
        topPanel.add(pgRadio);

        JPanel centerPanel = new JPanel(new BorderLayout());
        centerPanel.add(serverConfigPanel, BorderLayout.CENTER);

        JPanel statusPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        statusPanel.setBorder(BorderFactory.createEmptyBorder(5, 15, 0, 15));
        statusPanel.add(statusLabel);

        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        buttonPanel.setBorder(BorderFactory.createEmptyBorder(0, 10, 15, 10));
        buttonPanel.add(testButton);
        buttonPanel.add(avancarButton);
        buttonPanel.add(cancelarButton);

        add(topPanel, BorderLayout.NORTH);
        add(centerPanel, BorderLayout.CENTER);
        add(statusPanel, BorderLayout.PAGE_END);
        add(buttonPanel, BorderLayout.SOUTH);

        getRootPane().setDefaultButton(avancarButton);
    }

    private void setupListeners() {
        sqliteRadio.addActionListener(e -> {
            if (sqliteRadio.isSelected()) {
                toggleServerConfig(false);
            }
        });

        mysqlRadio.addActionListener(e -> {
            if (mysqlRadio.isSelected()) {
                toggleServerConfig(true);
                portSpinner.setValue(3306);
            }
        });

        pgRadio.addActionListener(e -> {
            if (pgRadio.isSelected()) {
                toggleServerConfig(true);
                portSpinner.setValue(5432);
            }
        });

        testButton.addActionListener(e -> testConnection());

        avancarButton.addActionListener(e -> {
            saveConfig();
            configSaved = true;
            dispose();
        });

        cancelarButton.addActionListener(e -> dispose());
    }

    private void toggleServerConfig(boolean enabled) {
        serverConfigPanel.setEnabled(enabled);
        for (Component c : serverConfigPanel.getComponents()) {
            c.setEnabled(enabled);
        }
    }

    private void testConnection() {
        statusLabel.setText("A testar conex\u00e3o...");
        statusLabel.setForeground(Color.BLUE);

        SwingWorker<Boolean, Void> worker = new SwingWorker<>() {
            @Override
            protected Boolean doInBackground() {
                String host = hostField.getText().trim();
                int port = (Integer) portSpinner.getValue();
                String dbName = dbNameField.getText().trim();
                String user = dbUserField.getText().trim();
                String password = new String(dbPasswordField.getPassword());

                String jdbcUrl;
                String driverClass;

                if (mysqlRadio.isSelected()) {
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

                try {
                    Class.forName(driverClass);
                    HikariConfig config = new HikariConfig();
                    config.setJdbcUrl(jdbcUrl);
                    config.setUsername(user);
                    config.setPassword(password);
                    config.setDriverClassName(driverClass);
                    config.setConnectionTimeout(5000);

                    try (HikariDataSource ds = new HikariDataSource(config);
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
                    boolean success = get();
                    if (success) {
                        statusLabel.setText("Conex\u00e3o bem-sucedida!");
                        statusLabel.setForeground(new Color(0, 128, 0));
                    } else {
                        statusLabel.setText("Falha na conex\u00e3o. Verifique os dados.");
                        statusLabel.setForeground(Color.RED);
                    }
                } catch (Exception e) {
                    statusLabel.setText("Erro: " + e.getMessage());
                    statusLabel.setForeground(Color.RED);
                }
            }
        };
        worker.execute();
    }

    private void saveConfig() {
        AppConfig config = AppConfig.getInstance();

        if (sqliteRadio.isSelected()) {
            config.setDatabaseType(AppConfig.DatabaseType.SQLITE);
        } else if (mysqlRadio.isSelected()) {
            config.setDatabaseType(AppConfig.DatabaseType.MYSQL);
            config.setDbHost(hostField.getText().trim());
            config.setDbPort((Integer) portSpinner.getValue());
            config.setDbName(dbNameField.getText().trim());
            config.setDbUser(dbUserField.getText().trim());
            config.setDbPassword(new String(dbPasswordField.getPassword()));
        } else {
            config.setDatabaseType(AppConfig.DatabaseType.POSTGRESQL);
            config.setDbHost(hostField.getText().trim());
            config.setDbPort((Integer) portSpinner.getValue());
            config.setDbName(dbNameField.getText().trim());
            config.setDbUser(dbUserField.getText().trim());
            config.setDbPassword(new String(dbPasswordField.getPassword()));
        }

        config.save();
    }

    public boolean isConfigSaved() {
        return configSaved;
    }
}
