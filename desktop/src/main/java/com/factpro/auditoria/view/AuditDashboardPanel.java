package com.factpro.auditoria.view;

import com.factpro.auditoria.AuditDAO;
import com.factpro.auditoria.model.AuditLog;
import com.factpro.auth.SessionManager;
import com.factpro.ui.charts.ChartUtils;
import net.miginfocom.swing.MigLayout;

import org.jfree.chart.ChartPanel;

import javax.swing.*;
import javax.swing.border.TitledBorder;
import javax.swing.filechooser.FileNameExtensionFilter;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Dashboard para visualizar logs de auditoria.
 * Inclui filtros, graficos e exportacao CSV.
 */
public class AuditDashboardPanel extends JPanel {

    private final AuditDAO auditDAO;
    
    // Filtros
    private JComboBox<String> actionFilter;
    private JComboBox<String> resourceFilter;
    private JSpinner dateFromSpinner;
    private JSpinner dateToSpinner;
    private JButton filterButton;
    private JButton exportCsvButton;
    
    // Tabela
    private JTable auditTable;
    private DefaultTableModel tableModel;
    
    // Graficos
    private ChartPanel pieChartPanel;
    private ChartPanel barChartPanel;
    
    // Stats
    private JLabel totalLabel;
    private JLabel successLabel;
    private JLabel deniedLabel;

    private static final Color GREEN = new Color(40, 167, 69);
    private static final Color RED = new Color(220, 53, 69);
    private static final Color BLUE = new Color(57, 113, 227);

    public AuditDashboardPanel() {
        auditDAO = new AuditDAO();
        
        setLayout(new BorderLayout());
        setBorder(javax.swing.BorderFactory.createEmptyBorder(10, 10, 10, 10));
        
        initComponents();
        setupFilters();
        setupTable();
        setupStats();
        setupLayout();
        
        loadAuditLogs();
    }

    private void initComponents() {
        // Filtros
        actionFilter = new JComboBox<>(new String[]{
            "Todas Ações", "CREATE", "UPDATE", "DELETE", "ACCESS_DENIED", 
            "PERMISSION_CHANGE", "ROLE_CHANGE", "LOGIN", "LOGOUT"
        });
        
        resourceFilter = new JComboBox<>(new String[]{
            "Todos Recursos", "vendas", "produtos", "clientes", "stock", 
            "compras", "fornecedores", "usuarios", "roles", "permissions"
        });
        
        Date now = new Date();
        Date weekAgo = new Date(now.getTime() - 7L * 24 * 60 * 60 * 1000);
        
        dateFromSpinner = new JSpinner(new SpinnerDateModel(weekAgo, null, now, java.util.Calendar.DAY_OF_MONTH));
        dateToSpinner = new JSpinner(new SpinnerDateModel(now, null, null, java.util.Calendar.DAY_OF_MONTH));
        
        ((JSpinner.DateEditor) dateFromSpinner.getEditor()).getTextField().setFont(
            ((JSpinner.DateEditor) dateFromSpinner.getEditor()).getTextField().getFont().deriveFont(11f)
        );
        ((JSpinner.DateEditor) dateToSpinner.getEditor()).getTextField().setFont(
            ((JSpinner.DateEditor) dateToSpinner.getEditor()).getTextField().getFont().deriveFont(11f)
        );
        
        filterButton = new JButton("Filtrar");
        filterButton.setBackground(BLUE);
        filterButton.setForeground(Color.WHITE);
        filterButton.setFocusPainted(false);
        
        exportCsvButton = new JButton("Exportar CSV");
        exportCsvButton.setBackground(GREEN);
        exportCsvButton.setForeground(Color.WHITE);
        exportCsvButton.setFocusPainted(false);
        
        // Stats labels
        totalLabel = new JLabel("Total: 0");
        totalLabel.setFont(totalLabel.getFont().deriveFont(Font.BOLD, 14f));
        
        successLabel = new JLabel("Sucesso: 0");
        successLabel.setFont(successLabel.getFont().deriveFont(Font.BOLD, 14f));
        successLabel.setForeground(GREEN);
        
        deniedLabel = new JLabel("Negados: 0");
        deniedLabel.setFont(deniedLabel.getFont().deriveFont(Font.BOLD, 14f));
        deniedLabel.setForeground(RED);
    }

    private void setupFilters() {
        filterButton.addActionListener(e -> loadAuditLogs());
        exportCsvButton.addActionListener(e -> exportToCsv());
    }

    private void setupTable() {
        String[] columns = {"Data/Hora", "Utilizador", "Ação", "Recurso", "Descrição", "Status"};
        tableModel = new DefaultTableModel(columns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        
        auditTable = new JTable(tableModel);
        auditTable.setRowHeight(28);
        auditTable.getTableHeader().setReorderingAllowed(false);
        auditTable.getTableHeader().setFont(auditTable.getTableHeader().getFont().deriveFont(Font.BOLD, 12f));
        auditTable.setFont(auditTable.getFont().deriveFont(11f));
        auditTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        
        // Renderizador customizado para coluna de status
        auditTable.getColumnModel().getColumn(5).setCellRenderer(new DefaultTableCellRenderer() {
            @Override
            public Component getTableCellRendererComponent(JTable table, Object value, 
                    boolean isSelected, boolean hasFocus, int row, int column) {
                JLabel label = (JLabel) super.getTableCellRendererComponent(
                    table, value, isSelected, hasFocus, row, column);
                
                if ("SUCESSO".equals(value)) {
                    label.setForeground(GREEN);
                    label.setText("✅ Sucesso");
                } else if ("NEGADO".equals(value)) {
                    label.setForeground(RED);
                    label.setText("❌ Negado");
                }
                
                return label;
            }
        });
    }

    private void setupStats() {
        // Stats panel will be added in setupLayout
    }

    private void setupLayout() {
        // Painel de filtros
        JPanel filterPanel = new JPanel(new MigLayout("fillx, wrap 5, gap 10, ins 10", 
            "[][][][][grow]"));
        filterPanel.setBorder(BorderFactory.createTitledBorder(
            BorderFactory.createLineBorder(new Color(200, 200, 200)),
            "Filtros",
            TitledBorder.LEFT,
            TitledBorder.TOP,
            new Font("Segoe UI", Font.BOLD, 13),
            new Color(50, 50, 50)
        ));
        
        JPanel actionPanel = new JPanel(new MigLayout("ins 0, wrap 1, gap 2"));
        actionPanel.add(new JLabel("Ação:"), "font 11");
        actionPanel.add(actionFilter, "w 150!");
        filterPanel.add(actionPanel);
        
        JPanel resourcePanel = new JPanel(new MigLayout("ins 0, wrap 1, gap 2"));
        resourcePanel.add(new JLabel("Recurso:"), "font 11");
        resourcePanel.add(resourceFilter, "w 150!");
        filterPanel.add(resourcePanel);
        
        JPanel fromPanel = new JPanel(new MigLayout("ins 0, wrap 1, gap 2"));
        fromPanel.add(new JLabel("De:"), "font 11");
        fromPanel.add(dateFromSpinner, "w 130!");
        filterPanel.add(fromPanel);
        
        JPanel toPanel = new JPanel(new MigLayout("ins 0, wrap 1, gap 2"));
        toPanel.add(new JLabel("Até:"), "font 11");
        toPanel.add(dateToSpinner, "w 130!");
        filterPanel.add(toPanel);
        
        JPanel btnPanel = new JPanel(new MigLayout("ins 0, gap 5"));
        btnPanel.add(filterButton, "h 30!");
        btnPanel.add(exportCsvButton, "h 30!");
        filterPanel.add(btnPanel, "span 1, align right");
        
        add(filterPanel, BorderLayout.NORTH);
        
        // Stats panel
        JPanel statsPanel = new JPanel(new MigLayout("ins 10, gap 20", "[][][]"));
        statsPanel.setBackground(new Color(245, 245, 245));
        statsPanel.add(totalLabel);
        statsPanel.add(successLabel);
        statsPanel.add(deniedLabel);
        
        // Main content with charts
        JPanel centerPanel = new JPanel(new BorderLayout());
        centerPanel.add(statsPanel, BorderLayout.NORTH);
        
        // Charts panel
        JPanel chartsPanel = new JPanel(new MigLayout("fill, wrap 2, gap 10, ins 10"));
        chartsPanel.setBorder(BorderFactory.createTitledBorder("Estatisticas Visuais"));
        centerPanel.add(chartsPanel, BorderLayout.CENTER);
        
        centerPanel.add(new JScrollPane(auditTable), BorderLayout.SOUTH);
        
        add(centerPanel, BorderLayout.CENTER);
    }

    private void loadAuditLogs() {
        // Limpar tabela
        tableModel.setRowCount(0);
        
        // Obter filtros
        String action = actionFilter.getSelectedIndex() == 0 ? null : (String) actionFilter.getSelectedItem();
        String resource = resourceFilter.getSelectedIndex() == 0 ? null : (String) resourceFilter.getSelectedItem();
        
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
        String dateFrom = sdf.format(dateFromSpinner.getValue());
        String dateTo = sdf.format(dateToSpinner.getValue());
        
        // Carregar logs
        List<AuditLog> logs = auditDAO.findByFilters(action, resource, dateFrom, dateTo, 100);
        
        for (AuditLog log : logs) {
            tableModel.addRow(new Object[]{
                log.getCriadoEm(),
                log.getUsuarioNome() != null ? log.getUsuarioNome() : "Sistema",
                log.getAcao(),
                log.getRecurso(),
                log.getDescricao() != null && log.getDescricao().length() > 50 
                    ? log.getDescricao().substring(0, 50) + "..." 
                    : log.getDescricao(),
                log.getSucesso() ? "SUCESSO" : "NEGADO"
            });
        }
        
        // Atualizar stats
        updateStats(logs);
        
        // Atualizar graficos
        updateCharts(logs);
    }

    private void updateStats(List<AuditLog> logs) {
        int total = logs.size();
        long success = logs.stream().filter(AuditLog::getSucesso).count();
        long denied = total - success;
        
        totalLabel.setText("Total: " + total);
        successLabel.setText("Sucesso: " + success);
        deniedLabel.setText("Negados: " + denied);
    }

    private void updateCharts(List<AuditLog> logs) {
        // Pie chart data - Status
        Map<String, Integer> pieData = new HashMap<>();
        long success = logs.stream().filter(AuditLog::getSucesso).count();
        long denied = logs.size() - success;
        pieData.put("SUCESSO", (int) success);
        pieData.put("NEGADO", (int) denied);
        
        // Bar chart data - Actions by resource
        Map<String, Long> barData = logs.stream()
            .collect(Collectors.groupingBy(AuditLog::getRecurso, Collectors.counting()));
        Map<String, Integer> barDataInt = new HashMap<>();
        barData.forEach((k, v) -> barDataInt.put(k, v.intValue()));
        
        // Create charts
        if (pieChartPanel != null) {
            pieChartPanel.getParent().remove();
        }
        if (barChartPanel != null) {
            barChartPanel.getParent().remove();
        }
        
        pieChartPanel = ChartUtils.createPieChart("Distribuicao por Status", pieData);
        barChartPanel = ChartUtils.createBarChart("Logs por Recurso", "Recurso", "Quantidade", barDataInt);
        
        // Add to charts panel
        Container parent = ((JPanel) getParent()).getComponent(1);
        if (parent instanceof JPanel chartsPanel) {
            chartsPanel.removeAll();
            chartsPanel.add(pieChartPanel, "grow");
            chartsPanel.add(barChartPanel, "grow");
            chartsPanel.revalidate();
            chartsPanel.repaint();
        }
    }

    private void exportToCsv() {
        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setDialogTitle("Exportar Logs de Auditoria");
        fileChooser.setSelectedFile(new java.io.File("auditoria_logs_" + 
            new SimpleDateFormat("yyyy-MM-dd").format(new Date()) + ".csv"));
        fileChooser.setFileFilter(new FileNameExtensionFilter("Arquivo CSV", "csv"));
        
        if (fileChooser.showSaveDialog(this) == JFileChooser.APPROVE_OPTION) {
            try (PrintWriter writer = new PrintWriter(new FileWriter(fileChooser.getSelectedFile()))) {
                // Header
                writer.println("Data/Hora,Utilizador,Ação,Recurso,Descrição,Status");
                
                // Data
                for (int i = 0; i < tableModel.getRowCount(); i++) {
                    writer.printf("\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"%n",
                        tableModel.getValueAt(i, 0),
                        tableModel.getValueAt(i, 1),
                        tableModel.getValueAt(i, 2),
                        tableModel.getValueAt(i, 3),
                        tableModel.getValueAt(i, 4),
                        tableModel.getValueAt(i, 5)
                    );
                }
                
                writer.flush();
                
                JOptionPane.showMessageDialog(this,
                    "Logs exportados com sucesso!\nArquivo: " + fileChooser.getSelectedFile().getName(),
                    "Exportação Concluída",
                    JOptionPane.INFORMATION_MESSAGE);
                
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(this,
                    "Erro ao exportar logs: " + ex.getMessage(),
                    "Erro de Exportação",
                    JOptionPane.ERROR_MESSAGE);
            }
        }
    }
}
