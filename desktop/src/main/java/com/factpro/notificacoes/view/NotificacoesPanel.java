package com.factpro.notificacoes.view;

import com.factpro.auth.SessionManager;
import com.factpro.notificacoes.dao.NotificacaoDAO;
import com.factpro.notificacoes.model.Notificacao;
import com.factpro.notificacoes.service.NotificacaoService;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.table.DefaultTableCellRenderer;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

/**
 * Notifications panel showing all notifications from the database.
 * Features: auto-refresh (30s), mark as read, filter by type, cleanup old.
 */
public class NotificacoesPanel extends JPanel {

    private static final Logger logger = LoggerFactory.getLogger(NotificacoesPanel.class);
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private static final Color BLUE = new Color(57, 113, 227);
    private static final Color RED = new Color(220, 53, 69);
    private static final Color GREEN = new Color(34, 139, 34);
    private static final Color ORANGE = new Color(255, 152, 0);
    private static final Color UNREAD_DOT = new Color(0, 102, 204);

    private final NotificacaoDAO notificacaoDAO;
    private final NotificacaoService notificacaoService;

    private JTable notificationTable;
    private NotificacaoTableModel tableModel;
    private JButton markAllReadButton;
    private JButton cleanupOldButton;
    private JComboBox<String> tipoFilterCombo;
    private JLabel unreadBadgeLabel;
    private Timer refreshTimer;

    private final List<Notificacao> allNotifications = new ArrayList<>();

    public NotificacoesPanel() {
        notificacaoDAO = new NotificacaoDAO();
        notificacaoService = new NotificacaoService(notificacaoDAO);

        setLayout(new BorderLayout());
        setBorder(new EmptyBorder(10, 10, 10, 10));

        initComponents();
        setupLayout();
        setupListeners();
        loadNotifications();
        startAutoRefresh();
    }

    private void initComponents() {
        String[] columns = {"Data", "Tipo", "Titulo", "Mensagem", "Estado"};
        tableModel = new NotificacaoTableModel(columns);
        notificationTable = new JTable(tableModel);
        notificationTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        notificationTable.setRowHeight(28);
        notificationTable.getTableHeader().setReorderingAllowed(false);
        notificationTable.setCursor(new Cursor(Cursor.HAND_CURSOR));

        // Renderer for Estado column (unread = blue dot, read = checkmark)
        notificationTable.getColumnModel().getColumn(4).setCellRenderer(new EstadoCellRenderer());

        // Bold font for unread rows
        notificationTable.setDefaultRenderer(Object.class, new DefaultTableCellRenderer() {
            @Override
            public Component getTableCellRendererComponent(JTable table, Object value,
                                                           boolean isSelected, boolean hasFocus,
                                                           int row, int column) {
                Component c = super.getTableCellRendererComponent(
                        table, value, isSelected, hasFocus, row, column);
                if (column == 4) return c; // handled by EstadoCellRenderer

                boolean lida = true;
                if (row >= 0 && row < tableModel.getRowCount()) {
                    Notificacao n = tableModel.getNotificationAt(row);
                    lida = n != null && Boolean.TRUE.equals(n.getLida());
                }
                c.setFont(c.getFont().deriveFont(lida ? Font.PLAIN : Font.BOLD));
                return c;
            }
        });

        // Unread badge
        unreadBadgeLabel = new JLabel("0 nao lidas");
        unreadBadgeLabel.setForeground(RED);
        unreadBadgeLabel.setFont(unreadBadgeLabel.getFont().deriveFont(Font.BOLD));

        // Filter combo
        tipoFilterCombo = new JComboBox<>(new String[]{
                "Todas",
                NotificacaoService.TIPO_STOCK_BAIXO,
                NotificacaoService.TIPO_VENDA_FINALIZADA,
                NotificacaoService.TIPO_VENDA_CANCELADA,
                NotificacaoService.TIPO_CONTA_VENCIDA,
                NotificacaoService.TIPO_INFO
        });

        // Buttons
        markAllReadButton = new JButton("Marcar todas como lidas");
        cleanupOldButton = new JButton("Limpar antigas");

        styleBtn(markAllReadButton, BLUE);
        styleBtn(cleanupOldButton, ORANGE);
    }

    private void setupLayout() {
        JPanel toolbar = new JPanel(new MigLayout("fillx, ins 5, gap 10", "[][][grow][]"));

        JLabel titleLabel = new JLabel("Notificacoes");
        titleLabel.putClientProperty(FlatClientProperties.STYLE_CLASS, "h2");
        toolbar.add(titleLabel);
        toolbar.add(unreadBadgeLabel);

        toolbar.add(new JLabel("Filtrar:"), "gapleft 20");
        toolbar.add(tipoFilterCombo, "w 180");

        JPanel buttonPanel = new JPanel(new MigLayout("ins 0, gap 5"));
        buttonPanel.add(markAllReadButton);
        buttonPanel.add(cleanupOldButton);
        toolbar.add(buttonPanel, "gapleft 20");

        add(toolbar, BorderLayout.NORTH);
        add(new JScrollPane(notificationTable), BorderLayout.CENTER);
    }

    private void setupListeners() {
        // Double-click to mark as read
        notificationTable.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                if (e.getClickCount() == 2) {
                    int row = notificationTable.rowAtPoint(e.getPoint());
                    if (row >= 0 && row < tableModel.getRowCount()) {
                        Notificacao n = tableModel.getNotificationAt(row);
                        if (n != null && !Boolean.TRUE.equals(n.getLida())) {
                            notificacaoService.markAsRead(n.getId());
                            loadNotifications();
                        }
                    }
                }
            }
        });

        // Mark all as read
        markAllReadButton.addActionListener(e -> {
            if (!SessionManager.getInstance().isAuthenticated()) {
                JOptionPane.showMessageDialog(this, "Nenhum utilizador autenticado.",
                        "Erro", JOptionPane.WARNING_MESSAGE);
                return;
            }
            int confirm = JOptionPane.showConfirmDialog(this,
                    "Marcar todas as notificacoes como lidas?",
                    "Confirmar",
                    JOptionPane.YES_NO_OPTION,
                    JOptionPane.QUESTION_MESSAGE);
            if (confirm == JOptionPane.YES_OPTION) {
                notificacaoService.markAllAsRead(null);
                loadNotifications();
            }
        });

        // Cleanup old
        cleanupOldButton.addActionListener(e -> {
            String input = JOptionPane.showInputDialog(this,
                    "Eliminar notificacoes mais antigas que quantos dias?",
                    "Limpar notificacoes antigas",
                    JOptionPane.QUESTION_MESSAGE);
            if (input != null && !input.isBlank()) {
                try {
                    int days = Integer.parseInt(input.trim());
                    if (days <= 0) {
                        JOptionPane.showMessageDialog(this,
                                "O numero de dias deve ser positivo.",
                                "Erro", JOptionPane.ERROR_MESSAGE);
                        return;
                    }
                    int confirm = JOptionPane.showConfirmDialog(this,
                            "Eliminar notificacoes com mais de " + days + " dias?",
                            "Confirmar",
                            JOptionPane.YES_NO_OPTION,
                            JOptionPane.WARNING_MESSAGE);
                    if (confirm == JOptionPane.YES_OPTION) {
                        notificacaoService.cleanupOld(days);
                        loadNotifications();
                        JOptionPane.showMessageDialog(this,
                                "Notificacoes antigas eliminadas.",
                                "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                    }
                } catch (NumberFormatException ex) {
                    JOptionPane.showMessageDialog(this,
                            "Valor invalido: " + input,
                            "Erro", JOptionPane.ERROR_MESSAGE);
                }
            }
        });

        // Filter change
        tipoFilterCombo.addActionListener(e -> applyFilter());
    }

    private void loadNotifications() {
        if (!SessionManager.getInstance().isAuthenticated()) {
            logger.debug("Nenhum utilizador autenticado, a ignorar carregamento de notificacoes");
            allNotifications.clear();
            refreshTable();
            return;
        }

        allNotifications.clear();
        allNotifications.addAll(notificacaoService.getNotificacoes(null, 200));
        applyFilter();
    }

    private void applyFilter() {
        String selected = (String) tipoFilterCombo.getSelectedItem();
        List<Notificacao> filtered;
        if ("Todas".equals(selected)) {
            filtered = allNotifications;
        } else {
            filtered = allNotifications.stream()
                    .filter(n -> selected.equals(n.getTipo()))
                    .toList();
        }
        tableModel.setNotifications(filtered);
        updateUnreadBadge();
    }

    private void updateUnreadBadge() {
        int count = 0;
        for (Notificacao n : allNotifications) {
            if (!Boolean.TRUE.equals(n.getLida())) {
                count++;
            }
        }
        unreadBadgeLabel.setText(count + " nao lida" + (count != 1 ? "s" : ""));
    }

    private void refreshTable() {
        applyFilter();
    }

    private void startAutoRefresh() {
        refreshTimer = new Timer(true);
        refreshTimer.scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                SwingUtilities.invokeLater(NotificacoesPanel.this::loadNotifications);
            }
        }, 30000, 30000); // Every 30 seconds
    }

    public void stopRefresh() {
        if (refreshTimer != null) {
            refreshTimer.cancel();
        }
    }

    private void styleBtn(JButton btn, Color bgColor) {
        btn.setFont(btn.getFont().deriveFont(Font.PLAIN, 12f));
        btn.setBackground(bgColor);
        btn.setForeground(Color.WHITE);
        btn.setFocusPainted(false);
    }

    // ==================== Table Model ====================

    private static class NotificacaoTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private final List<Notificacao> notifications = new ArrayList<>();

        NotificacaoTableModel(String[] columns) {
            this.columns = columns;
        }

        void setNotifications(List<Notificacao> notifications) {
            this.notifications.clear();
            this.notifications.addAll(notifications);
            fireTableDataChanged();
        }

        Notificacao getNotificationAt(int row) {
            return (row >= 0 && row < notifications.size()) ? notifications.get(row) : null;
        }

        @Override
        public int getRowCount() {
            return notifications.size();
        }

        @Override
        public int getColumnCount() {
            return columns.length;
        }

        @Override
        public String getColumnName(int col) {
            return columns[col];
        }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= notifications.size()) return null;
            Notificacao n = notifications.get(row);
            return switch (col) {
                case 0 -> formatCriadoEm(n.getCriadoEm());
                case 1 -> formatTipo(n.getTipo());
                case 2 -> n.getTitulo() != null ? n.getTitulo() : "";
                case 3 -> n.getMensagem() != null ? n.getMensagem() : "";
                case 4 -> Boolean.TRUE.equals(n.getLida());
                default -> null;
            };
        }

        private String formatCriadoEm(String criadoEm) {
            if (criadoEm == null || criadoEm.isBlank()) return "-";
            try {
                // Handle SQLite datetime format
                String cleaned = criadoEm.replace(" ", "T");
                if (!cleaned.contains("T")) {
                    return criadoEm;
                }
                return java.time.LocalDateTime.parse(cleaned).format(FMT);
            } catch (Exception e) {
                return criadoEm.length() > 16 ? criadoEm.substring(0, 16) : criadoEm;
            }
        }

        private String formatTipo(String tipo) {
            if (tipo == null) return "";
            return switch (tipo) {
                case NotificacaoService.TIPO_STOCK_BAIXO -> "Stock Baixo";
                case NotificacaoService.TIPO_VENDA_FINALIZADA -> "Venda Finalizada";
                case NotificacaoService.TIPO_VENDA_CANCELADA -> "Venda Cancelada";
                case NotificacaoService.TIPO_CONTA_VENCIDA -> "Conta Vencida";
                case NotificacaoService.TIPO_INFO -> "Informacao";
                default -> tipo;
            };
        }
    }

    // ==================== Renderer ====================

    private static class EstadoCellRenderer extends DefaultTableCellRenderer {
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus,
                                                       int row, int column) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);
            setHorizontalAlignment(SwingConstants.CENTER);
            if (Boolean.FALSE.equals(value)) {
                setText("\u25cf"); // filled circle
                setForeground(UNREAD_DOT);
                setFont(getFont().deriveFont(Font.BOLD, 14f));
            } else {
                setText("\u2713"); // checkmark
                setForeground(new Color(100, 100, 100));
                setFont(getFont().deriveFont(Font.PLAIN, 14f));
            }
            return this;
        }
    }
}
