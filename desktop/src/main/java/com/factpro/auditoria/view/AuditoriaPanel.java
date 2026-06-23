package com.factpro.auditoria.view;

import com.factpro.auth.SessionManager;
import com.factpro.auth.dao.UserDAO;
import com.factpro.auth.model.User;
import com.factpro.auditoria.dao.AuditoriaDAO;
import com.factpro.auditoria.model.AuditoriaLog;
import com.factpro.auditoria.service.AuditoriaService;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.table.DefaultTableCellRenderer;
import java.awt.*;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/**
 * Painel de visualizacao de logs de auditoria.
 * Inclui filtros por data, utilizador, acao e recurso, pesquisa textual,
 * auto-refresh a cada 30s, exportacao para CSV e color coding por tipo de acao.
 */
public class AuditoriaPanel extends JPanel {

    private static final Logger logger = LoggerFactory.getLogger(AuditoriaPanel.class);

    private static final Color GREEN = new Color(34, 139, 34);
    private static final Color RED = new Color(220, 53, 69);
    private static final Color BLUE = new Color(57, 113, 227);

    private final AuditoriaDAO auditoriaDAO;
    private final AuditoriaService auditoriaService;
    private final UserDAO userDAO;

    private JTable logsTable;
    private AuditoriaLogTableModel tableModel;
    private List<AuditoriaLog> allLogs;

    private JTextField searchField;
    private JComboBox<String> comboUser;
    private JComboBox<String> comboAcao;
    private JComboBox<String> comboRecurso;
    private JSpinner dateFrom;
    private JSpinner dateTo;

    private Timer autoRefreshTimer;

    public AuditoriaPanel() {
        auditoriaDAO = new AuditoriaDAO();
        auditoriaService = new AuditoriaService(auditoriaDAO);
        userDAO = new UserDAO();
        allLogs = new ArrayList<>();

        setLayout(new BorderLayout());
        setBorder(new EmptyBorder(10, 10, 10, 10));

        initComponents();
        setupFilters();
        setupLayout();
        setupAutoRefresh();
        loadLogs();
    }

    private void initComponents() {
        searchField = new JTextField();
        searchField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Pesquisar na descricao...");

        String[] cols = {"Data/Hora", "Utilizador", "Acao", "Recurso", "Descricao"};
        tableModel = new AuditoriaLogTableModel(cols);
        logsTable = new JTable(tableModel);
        logsTable.setRowHeight(28);
        logsTable.getTableHeader().setReorderingAllowed(false);
        logsTable.getColumnModel().getColumn(0).setPreferredWidth(140);
        logsTable.getColumnModel().getColumn(1).setPreferredWidth(100);
        logsTable.getColumnModel().getColumn(2).setPreferredWidth(100);
        logsTable.getColumnModel().getColumn(3).setPreferredWidth(80);
        logsTable.getColumnModel().getColumn(4).setPreferredWidth(300);
        logsTable.setDefaultRenderer(Object.class, new AuditoriaLogCellRenderer());
    }

    private void setupFilters() {
        // User combo
        comboUser = new JComboBox<>();
        comboUser.addItem("Todos");
        List<User> users = userDAO.findAll();
        for (User u : users) {
            if (u.getAtivo() != null && u.getAtivo()) {
                comboUser.addItem(u.getNome() + " (ID:" + u.getId() + ")");
            }
        }

        // Acao combo
        comboAcao = new JComboBox<>(new String[]{
                "Todas", "CRIAR", "ALTERAR", "ELIMINAR", "CANCELAR",
                "LOGIN_SUCESSO", "LOGIN_FALHOU", "STOCK_MOVIMENTO"
        });

        // Recurso combo
        comboRecurso = new JComboBox<>(new String[]{
                "Todos", "venda", "produto", "cliente", "compra", "auth", "usuario", "stock"
        });

        // Date spinners (default: today to today)
        String today = java.time.LocalDate.now().toString() + " 00:00:00";
        String tomorrow = java.time.LocalDate.now().plusDays(1).toString() + " 23:59:59";
        SpinnerDateModel fromModel = new SpinnerDateModel();
        SpinnerDateModel toModel = new SpinnerDateModel();
        dateFrom = new JSpinner(fromModel);
        dateTo = new JSpinner(toModel);
        JSpinner.DateEditor fromEditor = new JSpinner.DateEditor(dateFrom, "yyyy-MM-dd HH:mm");
        JSpinner.DateEditor toEditor = new JSpinner.DateEditor(dateTo, "yyyy-MM-dd HH:mm");
        dateFrom.setEditor(fromEditor);
        dateTo.setEditor(toEditor);
    }

    private void setupLayout() {
        // Filters panel
        JPanel filterPanel = new JPanel(new MigLayout(
                "fillx, wrap 4, ins 5, gap 5",
                "[][][][]",
                "[][]"
        ));

        // Row 1: Date range
        filterPanel.add(new JLabel("De:"));
        filterPanel.add(dateFrom, "growx");
        filterPanel.add(new JLabel("Ate:"));
        filterPanel.add(dateTo, "growx");

        // Row 2: User, Acao, Recurso
        filterPanel.add(new JLabel("Utilizador:"));
        filterPanel.add(comboUser, "growx");
        filterPanel.add(new JLabel("Acao:"));
        filterPanel.add(comboAcao, "growx");

        filterPanel.add(new JLabel("Recurso:"));
        filterPanel.add(comboRecurso, "growx, span 3");

        // Action buttons row
        JPanel actionPanel = new JPanel(new MigLayout("fillx, ins 0, gap 10", "[][grow][][grow][][grow][][]"));

        JButton btnFiltrar = new JButton("Filtrar");
        JButton btnLimpar = new JButton("Limpar");
        JButton btnExportar = new JButton("Exportar CSV");
        JButton btnRefresh = new JButton("Atualizar");

        styleBtn(btnFiltrar, BLUE);
        styleBtn(btnLimpar, new Color(108, 117, 125));
        styleBtn(btnExportar, GREEN);
        styleBtn(btnRefresh, BLUE);

        actionPanel.add(searchField, "growx, h 35");
        actionPanel.add(btnFiltrar, "h 35");
        actionPanel.add(btnLimpar, "h 35");
        actionPanel.add(btnExportar, "h 35");
        actionPanel.add(btnRefresh, "h 35");

        // Main filter container
        JPanel topPanel = new JPanel(new MigLayout("fillx, wrap, ins 0", "[grow]", "[][]"));
        topPanel.add(filterPanel, "growx");
        topPanel.add(actionPanel, "growx");

        add(topPanel, BorderLayout.NORTH);
        add(new JScrollPane(logsTable), BorderLayout.CENTER);

        // Footer with stats
        JPanel footerPanel = new JPanel(new MigLayout("fillx, ins 5"));
        JLabel lblCount = new JLabel("0 registos");
        lblCount.setName("logCount");
        footerPanel.add(lblCount, "growx");

        JCheckBox chkAutoRefresh = new JCheckBox("Auto-refresh (30s)");
        chkAutoRefresh.setSelected(true);
        footerPanel.add(chkAutoRefresh, "align right");

        add(footerPanel, BorderLayout.SOUTH);

        // ==================== Listeners ====================
        btnFiltrar.addActionListener(e -> applyFilters());
        btnLimpar.addActionListener(e -> clearFilters());
        btnExportar.addActionListener(e -> exportToCSV());
        btnRefresh.addActionListener(e -> loadLogs());
        searchField.addActionListener(e -> applyFilters());

        chkAutoRefresh.addActionListener(e -> {
            if (chkAutoRefresh.isSelected()) {
                startAutoRefresh();
            } else {
                stopAutoRefresh();
            }
        });
    }

    private void setupAutoRefresh() {
        autoRefreshTimer = new Timer(30000, e -> {
            logger.debug("Auto-refresh auditoria logs");
            loadLogs();
            applyFilters();
        });
        autoRefreshTimer.start();
    }

    private void startAutoRefresh() {
        if (autoRefreshTimer != null && !autoRefreshTimer.isRunning()) {
            autoRefreshTimer.restart();
        }
    }

    private void stopAutoRefresh() {
        if (autoRefreshTimer != null && autoRefreshTimer.isRunning()) {
            autoRefreshTimer.stop();
        }
    }

    private void loadLogs() {
        allLogs = auditoriaService.getRecentLogs(1000);
    }

    private void applyFilters() {
        List<AuditoriaLog> filtered = new ArrayList<>(allLogs);

        // Filter by user
        String selectedUser = (String) comboUser.getSelectedItem();
        if (selectedUser != null && !selectedUser.equals("Todos")) {
            int idx = selectedUser.lastIndexOf("(ID:");
            if (idx > 0) {
                try {
                    String uidStr = selectedUser.substring(idx + 4, selectedUser.length() - 1);
                    Long uid = Long.parseLong(uidStr);
                    filtered.removeIf(log -> log.getUserId() == null || !log.getUserId().equals(uid));
                } catch (NumberFormatException ex) {
                    logger.warn("Invalid user ID in filter: {}", selectedUser);
                }
            }
        }

        // Filter by acao
        String selectedAcao = (String) comboAcao.getSelectedItem();
        if (selectedAcao != null && !selectedAcao.equals("Todas")) {
            final String acaoFilter = selectedAcao;
            filtered.removeIf(log -> log.getAcao() == null || !log.getAcao().equals(acaoFilter));
        }

        // Filter by recurso
        String selectedRecurso = (String) comboRecurso.getSelectedItem();
        if (selectedRecurso != null && !selectedRecurso.equals("Todos")) {
            final String recursoFilter = selectedRecurso;
            filtered.removeIf(log -> log.getRecurso() == null || !log.getRecurso().equals(recursoFilter));
        }

        // Filter by search (descricao)
        String searchQuery = searchField.getText().trim();
        if (!searchQuery.isEmpty()) {
            final String query = searchQuery.toLowerCase();
            filtered.removeIf(log -> {
                if (log.getDescricao() != null && log.getDescricao().toLowerCase().contains(query)) return false;
                if (log.getRecurso() != null && log.getRecurso().toLowerCase().contains(query)) return false;
                if (log.getAcao() != null && log.getAcao().toLowerCase().contains(query)) return false;
                return true;
            });
        }

        tableModel.setLogs(filtered);
        updateCount(filtered.size());
    }

    private void clearFilters() {
        comboUser.setSelectedIndex(0);
        comboAcao.setSelectedIndex(0);
        comboRecurso.setSelectedIndex(0);
        searchField.setText("");
        tableModel.setLogs(allLogs);
        updateCount(allLogs.size());
    }

    private void updateCount(int count) {
        Component[] components = getComponents();
        for (Component c : components) {
            if (c instanceof JPanel) {
                for (Component child : ((JPanel) c).getComponents()) {
                    if (child instanceof JPanel) {
                        for (Component grandchild : ((JPanel) child).getComponents()) {
                            if (grandchild instanceof JLabel && "logCount".equals(grandchild.getName())) {
                                ((JLabel) grandchild).setText(count + " registos");
                            }
                        }
                    }
                }
            }
        }
    }

    private void exportToCSV() {
        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setDialogTitle("Exportar Logs de Auditoria");
        fileChooser.setSelectedFile(new File("auditoria_logs.csv"));

        if (fileChooser.showSaveDialog(this) == JFileChooser.APPROVE_OPTION) {
            File file = fileChooser.getSelectedFile();
            if (!file.getName().endsWith(".csv")) {
                file = new File(file.getAbsolutePath() + ".csv");
            }

            try (BufferedWriter writer = new BufferedWriter(new FileWriter(file))) {
                writer.write("Data/Hora;Utilizador;Acao;Recurso;Recurso ID;Descricao\n");

                List<AuditoriaLog> logsToExport = tableModel.getCurrentLogs();
                for (AuditoriaLog log : logsToExport) {
                    String userName = resolveUserName(log.getUserId());
                    writer.write(String.format("%s;%s;%s;%s;%s;%s\n",
                            log.getCriadoEm() != null ? log.getCriadoEm() : "",
                            userName,
                            log.getAcao() != null ? log.getAcao() : "",
                            log.getRecurso() != null ? log.getRecurso() : "",
                            log.getRecursoId() != null ? log.getRecursoId() : "",
                            log.getDescricao() != null ? log.getDescricao().replace(";", ",") : ""
                    ));
                }

                JOptionPane.showMessageDialog(this,
                        "Exportados " + logsToExport.size() + " registos para:\n" + file.getAbsolutePath(),
                        "Exportacao Concluida",
                        JOptionPane.INFORMATION_MESSAGE);
                logger.info("Auditoria logs exported to: {}", file.getAbsolutePath());
            } catch (IOException ex) {
                logger.error("Erro ao exportar logs de auditoria", ex);
                JOptionPane.showMessageDialog(this,
                        "Erro ao exportar ficheiro: " + ex.getMessage(),
                        "Erro de Exportacao",
                        JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    private String resolveUserName(Long userId) {
        if (userId == null) return "Sistema";
        if (SessionManager.getInstance().getCurrentUserId() != null &&
                SessionManager.getInstance().getCurrentUserId().equals(userId)) {
            return SessionManager.getInstance().getCurrentUserName();
        }
        User user = userDAO.findById(userId);
        return user != null ? user.getNome() : "User #" + userId;
    }

    private void styleBtn(JButton btn, Color bgColor) {
        btn.setFont(btn.getFont().deriveFont(Font.PLAIN, 12f));
        btn.setBackground(bgColor);
        btn.setForeground(Color.WHITE);
        btn.setFocusPainted(false);
    }

    // ==================== Table Model ====================

    private static class AuditoriaLogTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private List<AuditoriaLog> logs = new ArrayList<>();
        private final UserDAO userDAO = new UserDAO();

        AuditoriaLogTableModel(String[] columns) {
            this.columns = columns;
        }

        void setLogs(List<AuditoriaLog> logs) {
            this.logs = logs;
            fireTableDataChanged();
        }

        List<AuditoriaLog> getCurrentLogs() {
            return logs;
        }

        @Override
        public int getRowCount() {
            return logs.size();
        }

        @Override
        public int getColumnCount() {
            return columns.length;
        }

        @Override
        public String getColumnName(int c) {
            return columns[c];
        }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= logs.size()) return null;
            AuditoriaLog log = logs.get(row);
            return switch (col) {
                case 0 -> formatCriadoEm(log.getCriadoEm());
                case 1 -> resolveUserName(log.getUserId());
                case 2 -> log.getAcao() != null ? log.getAcao() : "-";
                case 3 -> log.getRecurso() != null ? log.getRecurso() : "-";
                case 4 -> log.getDescricao() != null ? log.getDescricao() : "-";
                default -> null;
            };
        }

        private String resolveUserName(Long userId) {
            if (userId == null) return "Sistema";
            if (SessionManager.getInstance().getCurrentUserId() != null &&
                    SessionManager.getInstance().getCurrentUserId().equals(userId)) {
                return SessionManager.getInstance().getCurrentUserName();
            }
            User user = userDAO.findById(userId);
            return user != null ? user.getNome() : "User #" + userId;
        }

        private String formatCriadoEm(String criadoEm) {
            if (criadoEm == null || criadoEm.length() < 16) return "-";
            // SQLite stores as "YYYY-MM-DD HH:MM:SS"
            return criadoEm.replace(" ", " ").substring(0, 16).replace("-", "/");
        }
    }

    // ==================== Cell Renderer (color coding) ====================

    private static class AuditoriaLogCellRenderer extends DefaultTableCellRenderer {
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);

            // Reset colors first
            setBackground(isSelected ? table.getSelectionBackground() : Color.WHITE);
            setForeground(isSelected ? table.getSelectionForeground() : Color.BLACK);

            if (!isSelected && col == 2 && value instanceof String acao) {
                String acaoLower = acao.toLowerCase();
                // Red for deletions/cancellations
                if (acaoLower.contains("elim") || acaoLower.contains("cancel") || acaoLower.contains("del")) {
                    setForeground(RED);
                    setFont(getFont().deriveFont(Font.BOLD));
                }
                // Green for creations
                else if (acaoLower.contains("cri") || acaoLower.contains("insert") || acaoLower.contains("nov") || acaoLower.contains("login_sucesso")) {
                    setForeground(GREEN);
                }
                // Blue for updates
                else if (acaoLower.contains("alt") || acaoLower.contains("upd") || acaoLower.contains("edit") || acaoLower.contains("stock")) {
                    setForeground(BLUE);
                }
            } else if (!isSelected) {
                setFont(getFont().deriveFont(Font.PLAIN));
            }

            return this;
        }
    }
}
