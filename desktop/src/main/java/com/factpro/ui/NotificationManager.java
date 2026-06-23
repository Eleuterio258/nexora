package com.factpro.ui;

import com.factpro.auth.PermissionChecker;
import com.factpro.auth.SessionManager;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.ArrayList;
import java.util.List;

/**
 * Sistema de notificacao visual para erros de permissao.
 * Exibe notificacoes temporarias no canto inferior direito.
 */
public class NotificationManager {

    private static final List<NotificationPopup> activeNotifications = new ArrayList<>();
    private static final int MAX_VISIBLE = 3;

    /**
     * Exibe notificao de acesso negado.
     */
    public static void showAccessDenied(String recurso, String permissao) {
        String message = String.format(
            "<html><b>Acesso Negado</b><br/>" +
            "Recurso: %s<br/>" +
            "Permissão necessária: <font color='red'>%s</font></html>",
            recurso, permissao
        );
        
        show(message, NotificationType.ERROR);
    }

    /**
     * Exibe notificao genérica.
     */
    public static void show(String message, NotificationType type) {
        // Remove notificacoes antigas se exceder limite
        while (activeNotifications.size() >= MAX_VISIBLE) {
            NotificationPopup old = activeNotifications.remove(0);
            old.hide();
        }

        NotificationPopup popup = new NotificationPopup(message, type);
        activeNotifications.add(popup);
        popup.show();

        // Auto-remove apos 5 segundos
        Timer timer = new Timer(5000, e -> {
            popup.hide();
            activeNotifications.remove(popup);
        });
        timer.setRepeats(false);
        timer.start();
    }

    /**
     * Tipos de notificao.
     */
    public enum NotificationType {
        ERROR(new Color(220, 53, 69), "Erro"),
        WARNING(new Color(255, 193, 7), "Aviso"),
        SUCCESS(new Color(40, 167, 69), "Sucesso"),
        INFO(new Color(23, 162, 184), "Informação");

        private final Color backgroundColor;
        private final String label;

        NotificationType(Color backgroundColor, String label) {
            this.backgroundColor = backgroundColor;
            this.label = label;
        }
    }

    /**
     * Popup individual de notificao.
     */
    private static class NotificationPopup extends JDialog {
        private final String message;
        private final NotificationType type;

        NotificationPopup(String message, NotificationType type) {
            super((Frame) null, "", true);
            this.message = message;
            this.type = type;
            
            setUndecorated(true);
            setAlwaysOnTop(true);
            setSize(350, 80);
            setLocationRelativeTo(null);
            setLayout(new BorderLayout());
        }

        public void show() {
            // Conteudo
            JPanel content = new JPanel(new BorderLayout());
            content.setBackground(type.backgroundColor);
            content.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(type.backgroundColor.darker()),
                BorderFactory.createEmptyBorder(10, 15, 10, 15)
            ));

            // Icon
            JLabel iconLabel = new JLabel(getIconForType(type));
            iconLabel.setHorizontalAlignment(SwingConstants.CENTER);
            content.add(iconLabel, BorderLayout.WEST);

            // Texto
            JLabel textLabel = new JLabel(message);
            textLabel.setForeground(Color.WHITE);
            textLabel.setFont(textLabel.getFont().deriveFont(Font.PLAIN, 13f));
            content.add(textLabel, BorderLayout.CENTER);

            // Botao fechar
            JButton btnClose = new JButton("×");
            btnClose.setFont(new Font("Arial", Font.BOLD, 18));
            btnClose.setForeground(Color.WHITE);
            btnClose.setBorderPainted(false);
            btnClose.setContentAreaFilled(false);
            btnClose.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
            btnClose.addActionListener(e -> hide());
            content.add(btnClose, BorderLayout.EAST);

            add(content, BorderLayout.CENTER);

            // Posicionar no canto inferior direito
            GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
            Rectangle screenBounds = ge.getMaximumWindowBounds();
            int x = screenBounds.width - getWidth() - 20;
            int y = screenBounds.height - getHeight() - 20 - (activeNotifications.size() * 90);
            
            setLocation(x, y);
            setVisible(true);
        }

        public void hide() {
            setVisible(false);
            dispose();
        }

        private String getIconForType(NotificationType type) {
            return switch (type) {
                case ERROR -> "⛔";
                case WARNING -> "⚠️";
                case SUCCESS -> "✅";
                case INFO -> "ℹ️";
            };
        }
    }
}
