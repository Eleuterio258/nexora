package com.factpro.ui;

import com.factpro.config.AppConfig;

import javax.swing.*;
import java.awt.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Painel de status na parte inferior da janela principal.
 * Mostra nome do utilizador, data/hora atual e nome do terminal.
 */
public class StatusBarPanel extends JPanel {

    private final JLabel userLabel;
    private final JLabel dateLabel;
    private final JLabel terminalLabel;
    private final Timer clockTimer;

    private static final DateTimeFormatter DATE_FORMATTER =
            DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");

    public StatusBarPanel() {
        setLayout(new FlowLayout(FlowLayout.LEFT, 20, 4));
        setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createMatteBorder(1, 0, 0, 0, Color.GRAY),
                BorderFactory.createEmptyBorder(4, 10, 4, 10)));
        setBackground(new Color(240, 240, 240));

        userLabel = new JLabel();
        userLabel.setFont(userLabel.getFont().deriveFont(Font.PLAIN, 12f));

        dateLabel = new JLabel();
        dateLabel.setFont(dateLabel.getFont().deriveFont(Font.PLAIN, 12f));

        terminalLabel = new JLabel();
        terminalLabel.setFont(terminalLabel.getFont().deriveFont(Font.PLAIN, 12f));

        // Add separator lines between items
        add(userLabel);
        add(new JSeparator(SwingConstants.VERTICAL));
        add(dateLabel);
        add(new JSeparator(SwingConstants.VERTICAL));
        add(terminalLabel);

        // Initialize values
        updateUserInfo();
        updateDateTime();
        updateTerminalInfo();

        // Update clock every second
        clockTimer = new Timer(1000, e -> updateDateTime());
        clockTimer.start();
    }

    private void updateUserInfo() {
        String userName = getCurrentUserName();
        userLabel.setText("Utilizador: " + userName);
    }

    private void updateDateTime() {
        String now = LocalDateTime.now().format(DATE_FORMATTER);
        dateLabel.setText(now);
    }

    private void updateTerminalInfo() {
        AppConfig config = AppConfig.getInstance();
        terminalLabel.setText("Terminal: " + config.getTerminalName() + " (" + config.getTerminalId() + ")");
    }

    private String getCurrentUserName() {
        try {
            com.factpro.auth.SessionManager session = com.factpro.auth.SessionManager.getInstance();
            if (session.isAuthenticated()) {
                return session.getCurrentUserName();
            }
        } catch (Exception e) {
            // ignore
        }
        return "N/A";
    }

    public void refresh() {
        updateUserInfo();
        updateTerminalInfo();
    }

    public void stopClock() {
        if (clockTimer != null && clockTimer.isRunning()) {
            clockTimer.stop();
        }
    }
}
