package tech.omnisyserp.desktop.ui.components;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.ArrayList;
import java.util.List;

/**
 * Sistema de notificacoes toast para a aplicacao desktop.
 * Mostra notificacoes temporarias no canto inferior direito do ecra.
 */
public class ToastNotification {

    public enum Type {
        SUCCESS(new Color(80, 200, 120), "\u2714"),
        ERROR(new Color(220, 53, 69), "\u2718"),
        WARNING(new Color(255, 140, 0), "\u26A0"),
        INFO(new Color(52, 120, 246), "\u2139");

        final Color color;
        final String icon;

        Type(Color color, String icon) {
            this.color = color;
            this.icon = icon;
        }
    }

    private static final List<JDialog> activeToasts = new ArrayList<>();
    private static final int MAX_VISIBLE = 3;
    private static final int DISPLAY_DURATION = 4000; // 4 seconds
    private static final int TOAST_WIDTH = 350;
    private static final int TOAST_HEIGHT = 80;
    private static final int GAP = 10;

    /**
     * Mostra uma notificacao toast.
     */
    public static void show(String title, String message, Type type) {
        SwingUtilities.invokeLater(() -> {
            // Limitar numero de toasts visiveis
            if (activeToasts.size() >= MAX_VISIBLE) {
                JDialog oldest = activeToasts.remove(0);
                oldest.dispose();
            }

            JDialog toast = createToast(title, message, type);
            activeToasts.add(toast);
            toast.setVisible(true);

            // Auto-dismiss apos duration
            Timer dismissTimer = new Timer(DISPLAY_DURATION, e -> {
                dismissToast(toast);
            });
            dismissTimer.setRepeats(false);
            dismissTimer.start();
        });
    }

    private static JDialog createToast(String title, String message, Type type) {
        JDialog toast = new JDialog();
        toast.setUndecorated(true);
        toast.setSize(TOAST_WIDTH, TOAST_HEIGHT);
        toast.setAlwaysOnTop(true);
        toast.setFocusable(false);

        // Posicionar no canto inferior direito
        GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
        Rectangle screenBounds = ge.getMaximumWindowBounds();
        int x = screenBounds.width - TOAST_WIDTH - GAP - 20;
        int y = screenBounds.height - (activeToasts.size() + 1) * (TOAST_HEIGHT + GAP) - 20;
        toast.setLocation(x, y);

        // Painel principal
        JPanel panel = new JPanel(new BorderLayout(10, 0));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(type.color, 3),
                new EmptyBorder(10, 15, 10, 15)));

        // Icone
        JLabel lblIcon = new JLabel(type.icon);
        lblIcon.setFont(new Font("Segoe UI", Font.BOLD, 24));
        lblIcon.setForeground(type.color);
        lblIcon.setHorizontalAlignment(SwingConstants.CENTER);
        panel.add(lblIcon, BorderLayout.WEST);

        // Conteudo
        JPanel contentPanel = new JPanel(new BorderLayout(0, 5));
        contentPanel.setBackground(Color.WHITE);

        JLabel lblTitle = new JLabel(title);
        lblTitle.setFont(new Font("Segoe UI", Font.BOLD, 14));
        lblTitle.setForeground(new Color(30, 35, 50));
        contentPanel.add(lblTitle, BorderLayout.NORTH);

        JLabel lblMessage = new JLabel("<html><body style='width:250px'>" + message + "</body></html>");
        lblMessage.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        lblMessage.setForeground(new Color(100, 110, 130));
        contentPanel.add(lblMessage, BorderLayout.CENTER);

        panel.add(contentPanel, BorderLayout.CENTER);

        // Botao fechar
        JButton btnClose = new JButton("×");
        btnClose.setFont(new Font("Segoe UI", Font.BOLD, 16));
        btnClose.setForeground(new Color(150, 160, 180));
        btnClose.setBorderPainted(false);
        btnClose.setContentAreaFilled(false);
        btnClose.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        btnClose.addActionListener(e -> dismissToast(toast));
        panel.add(btnClose, BorderLayout.EAST);

        // Efeito hover
        panel.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseEntered(MouseEvent e) {
                panel.setBackground(new Color(250, 251, 252));
            }

            @Override
            public void mouseExited(MouseEvent e) {
                panel.setBackground(Color.WHITE);
            }
        });

        toast.add(panel);

        // Animacao de entrada
        toast.setOpacity(0f);
        Timer fadeIn = new Timer(20, null);
        final float[] opacity = {0f};
        fadeIn.addActionListener(e -> {
            opacity[0] += 0.1f;
            if (opacity[0] >= 1f) {
                opacity[0] = 1f;
                fadeIn.stop();
            }
            toast.setOpacity(opacity[0]);
        });
        fadeIn.start();

        return toast;
    }

    private static void dismissToast(JDialog toast) {
        // Animacao de saida
        Timer fadeOut = new Timer(20, null);
        final float[] opacity = {1f};
        fadeOut.addActionListener(e -> {
            opacity[0] -= 0.1f;
            if (opacity[0] <= 0f) {
                opacity[0] = 0f;
                fadeOut.stop();
                toast.dispose();
                activeToasts.remove(toast);
                reposicionarToasts();
            } else {
                toast.setOpacity(opacity[0]);
            }
        });
        fadeOut.start();
    }

    private static void reposicionarToasts() {
        GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
        Rectangle screenBounds = ge.getMaximumWindowBounds();
        
        for (int i = 0; i < activeToasts.size(); i++) {
            JDialog toast = activeToasts.get(i);
            int y = screenBounds.height - (i + 1) * (TOAST_HEIGHT + GAP) - 20;
            toast.setLocation(toast.getX(), y);
        }
    }

    // Metodos de conveniencia
    public static void success(String title, String message) {
        show(title, message, Type.SUCCESS);
    }

    public static void error(String title, String message) {
        show(title, message, Type.ERROR);
    }

    public static void warning(String title, String message) {
        show(title, message, Type.WARNING);
    }

    public static void info(String title, String message) {
        show(title, message, Type.INFO);
    }
}
