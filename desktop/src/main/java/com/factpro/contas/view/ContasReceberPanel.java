package com.factpro.contas.view;

import com.factpro.clientes.dao.ClienteDAO;
import com.factpro.clientes.model.Cliente;
import com.factpro.contas.dao.ContaReceberDAO;
import com.factpro.contas.model.ContaReceber;
import com.factpro.contas.service.ContaReceberService;
import com.factpro.core.util.CurrencyFormatter;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.CompoundBorder;
import javax.swing.border.EmptyBorder;
import javax.swing.border.LineBorder;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.SpinnerDateModel;
import java.awt.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Panel for managing accounts receivable (contas a receber / fiado).
 */
public class ContasReceberPanel extends JPanel {

    private static final Logger logger = LoggerFactory.getLogger(ContasReceberPanel.class);

    private final ContaReceberDAO contaReceberDAO;
    private final ContaReceberService contaReceberService;
    private final ClienteDAO clienteDAO;

    private JTable contasTable;
    private ContasTableModel tableModel;
    private List<ContaReceber> allContas;
    private Map<Long, String> clienteNames;

    private JTextField searchField;
    private JComboBox<String> statusFilter;
    private JSpinner startDateSpinner;
    private JSpinner endDateSpinner;

    private static final Color GREEN = new Color(34, 139, 34);
    private static final Color RED = new Color(220, 53, 69);
    private static final Color ORANGE = new Color(255, 152, 0);
    private static final Color BLUE = new Color(57, 113, 227);
    private static final Color GRAY = new Color(128, 128, 128);

    public ContasReceberPanel() {
        contaReceberDAO = new ContaReceberDAO();
        contaReceberService = new ContaReceberService(contaReceberDAO);
        clienteDAO = new ClienteDAO();
        allContas = new ArrayList<>();
        clienteNames = new HashMap<>();

        setLayout(new BorderLayout());
        setBorder(new EmptyBorder(10, 10, 10, 10));

        initComponents();
        setupLayout();
        setupListeners();
        loadContas();
        loadClientNames();
    }

    private void initComponents() {
        searchField = new JTextField();
        searchField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Pesquisar...");

        statusFilter = new JComboBox<>(new String[]{"Todos", "Pendente", "Pago", "Parcial", "Vencido"});

        String today = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE);
        String thirtyDaysAgo = LocalDate.now().minusDays(30).format(DateTimeFormatter.ISO_LOCAL_DATE);
        startDateSpinner = new JSpinner(new SpinnerDateModel());
        endDateSpinner = new JSpinner(new SpinnerDateModel());

        String[] cols = {"Cliente", "Venda Ref", "Valor Total", "Valor Pago", "Pendente", "Vencimento", "Status", "Acoes"};
        tableModel = new ContasTableModel(cols);
        contasTable = new JTable(tableModel);
        contasTable.setRowHeight(28);
        contasTable.getTableHeader().setReorderingAllowed(false);
        contasTable.getColumnModel().getColumn(2).setCellRenderer(new CurrencyRenderer());
        contasTable.getColumnModel().getColumn(3).setCellRenderer(new CurrencyRenderer());
        contasTable.getColumnModel().getColumn(4).setCellRenderer(new CurrencyRenderer());
        contasTable.getColumnModel().getColumn(6).setCellRenderer(new StatusRenderer());
        contasTable.getColumnModel().getColumn(7).setCellRenderer(new ActionRenderer());
        contasTable.getColumnModel().getColumn(7).setCellEditor(new ActionEditor());
    }

    private JButton btnFilter;
    private JButton btnPagamento;
    private JButton btnRefresh;

    private void setupLayout() {
        // Top panel: filters
        JPanel filterPanel = new JPanel(new MigLayout("fillx, ins 0, gap 10", "[grow][][][][][][]"));

        filterPanel.add(searchField, "growx, h 35");
        filterPanel.add(statusFilter, "h 35, w 120");

        btnFilter = new JButton("Filtrar");
        btnPagamento = new JButton("Registar Pagamento");
        btnRefresh = new JButton("Atualizar");

        styleBtn(btnFilter, BLUE);
        styleBtn(btnPagamento, GREEN);
        styleBtn(btnRefresh, GRAY);

        filterPanel.add(btnFilter, "h 35");
        filterPanel.add(btnPagamento, "h 35");
        filterPanel.add(btnRefresh, "h 35");

        add(filterPanel, BorderLayout.NORTH);
        add(new JScrollPane(contasTable), BorderLayout.CENTER);

        // Summary bar at bottom
        JPanel summaryPanel = new JPanel(new MigLayout("fillx, ins 5", "[][][][]"));
        JLabel lblTotal = new JLabel("Total Pendente: 0.00 MT");
        lblTotal.setFont(lblTotal.getFont().deriveFont(Font.BOLD, 13f));
        lblTotal.setForeground(RED);
        summaryPanel.add(lblTotal, "align left");

        add(summaryPanel, BorderLayout.SOUTH);

        // Store reference for update
        final JLabel totalLabel = lblTotal;
        summaryPanel.putClientProperty("totalLabel", totalLabel);
    }

    private void setupListeners() {
        // Filter button
        btnFilter.addActionListener(e -> applyFilters());

        // Payment button
        btnPagamento.addActionListener(e -> openPagamentoDialog());

        // Refresh button
        btnRefresh.addActionListener(e -> {
            loadContas();
            loadClientNames();
        });

        // Double-click to open pagamento
        contasTable.addMouseListener(new java.awt.event.MouseAdapter() {
            @Override
            public void mouseClicked(java.awt.event.MouseEvent e) {
                if (e.getClickCount() == 2) {
                    int row = contasTable.rowAtPoint(e.getPoint());
                    if (row >= 0 && row < tableModel.getRowCount()) {
                        ContaReceber conta = tableModel.getContaAt(row);
                        if (conta != null && !"pago".equals(conta.getStatus())) {
                            openPagamentoDialog(conta);
                        }
                    }
                }
            }
        });
    }

    private void loadContas() {
        allContas = contaReceberService.findAll();
        applyFilters();
    }

    private void loadClientNames() {
        clienteNames.clear();
        List<Cliente> clientes = clienteDAO.findAll();
        for (Cliente c : clientes) {
            clienteNames.put(c.getId(), c.getNome());
        }
    }

    private void applyFilters() {
        String status = (String) statusFilter.getSelectedItem();
        String search = searchField.getText().trim();

        List<ContaReceber> filtered = new ArrayList<>(allContas);

        // Filter by status
        if (!"Todos".equals(status)) {
            String s = status.toLowerCase();
            filtered.removeIf(c -> !s.equals(c.getStatus()));
        }

        // Filter by search (cliente name)
        if (!search.isEmpty()) {
            String pattern = search.toLowerCase();
            filtered.removeIf(c -> {
                String nome = clienteNames.getOrDefault(c.getClienteId(), "");
                return !nome.toLowerCase().contains(pattern);
            });
        }

        tableModel.setContas(filtered);
        updateSummary(filtered);
    }

    private void updateSummary(List<ContaReceber> contas) {
        double totalPendente = contas.stream()
                .filter(c -> !"pago".equals(c.getStatus()))
                .mapToDouble(c -> c.getValorPendente() != null ? c.getValorPendente() : 0.0)
                .sum();

        JPanel summaryPanel = (JPanel) getComponent(getComponentCount() - 1);
        JLabel totalLabel = (JLabel) summaryPanel.getClientProperty("totalLabel");
        if (totalLabel != null) {
            totalLabel.setText(String.format("Total Pendente: %s", CurrencyFormatter.format(totalPendente)));
        }
    }

    private void openPagamentoDialog() {
        openPagamentoDialog(null);
    }

    private void openPagamentoDialog(ContaReceber conta) {
        PagamentoContaDialog dialog = new PagamentoContaDialog(
                (Frame) SwingUtilities.getWindowAncestor(this),
                contaReceberService,
                clienteNames,
                conta
        );
        dialog.setVisible(true);
        if (dialog.isSaved()) {
            loadContas();
        }
    }

    private void styleBtn(JButton btn, Color bgColor) {
        btn.setFont(btn.getFont().deriveFont(Font.PLAIN, 12f));
        btn.setBackground(bgColor);
        btn.setForeground(Color.WHITE);
        btn.setFocusPainted(false);
    }

    // ==================== Table Model ====================

    private class ContasTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private List<ContaReceber> contas = new ArrayList<>();

        ContasTableModel(String[] columns) { this.columns = columns; }

        void setContas(List<ContaReceber> contas) {
            this.contas = contas;
            fireTableDataChanged();
        }

        ContaReceber getContaAt(int row) {
            return (row >= 0 && row < contas.size()) ? contas.get(row) : null;
        }

        @Override public int getRowCount() { return contas.size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= contas.size()) return null;
            ContaReceber c = contas.get(row);
            return switch (col) {
                case 0 -> clienteNames.getOrDefault(c.getClienteId(), "CLI-" + c.getClienteId());
                case 1 -> c.getVendaId() != null ? "VENDA-" + c.getVendaId() : "-";
                case 2 -> c.getValorTotal();
                case 3 -> c.getValorPago() != null ? c.getValorPago() : 0.0;
                case 4 -> c.getValorPendente() != null ? c.getValorPendente() : 0.0;
                case 5 -> c.getDataVencimento() != null ? c.getDataVencimento() : "-";
                case 6 -> capitalize(c.getStatus());
                case 7 -> "Pagar | Detalhes";
                default -> null;
            };
        }

        private String capitalize(String s) {
            if (s == null) return "";
            return s.substring(0, 1).toUpperCase() + s.substring(1).toLowerCase();
        }
    }

    // ==================== Renderers ====================

    private static class CurrencyRenderer extends DefaultTableCellRenderer {
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            if (value instanceof Number) {
                setText(String.format("%,.2f MT", ((Number) value).doubleValue()));
            }
            setHorizontalAlignment(SwingConstants.RIGHT);
            return this;
        }
    }

    private static class StatusRenderer extends DefaultTableCellRenderer {
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            String status = value != null ? value.toString().toLowerCase() : "";
            setForeground(switch (status) {
                case "pago" -> GREEN;
                case "vencido" -> RED;
                case "parcial" -> ORANGE;
                case "pendente" -> BLUE;
                default -> table.getForeground();
            });
            setHorizontalAlignment(SwingConstants.CENTER);
            return this;
        }
    }

    private static class ActionRenderer extends JPanel implements javax.swing.table.TableCellRenderer {
        private static final Color EDIT_BLUE = new Color(57, 113, 227);
        private static final Color DELETE_RED = new Color(220, 53, 69);
        private final JButton payBtn = new JButton("Pagar");
        private final JButton detailBtn = new JButton("Detalhes");

        ActionRenderer() {
            setLayout(new FlowLayout(FlowLayout.CENTER, 3, 0));
            payBtn.setFont(payBtn.getFont().deriveFont(Font.PLAIN, 10f));
            payBtn.setBackground(EDIT_BLUE);
            payBtn.setForeground(Color.WHITE);
            payBtn.setFocusPainted(false);
            payBtn.setPreferredSize(new Dimension(50, 20));
            detailBtn.setFont(detailBtn.getFont().deriveFont(Font.PLAIN, 10f));
            detailBtn.setBackground(GRAY);
            detailBtn.setForeground(Color.WHITE);
            detailBtn.setFocusPainted(false);
            detailBtn.setPreferredSize(new Dimension(60, 20));
            add(payBtn);
            add(detailBtn);
        }

        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            setBackground(isSelected ? table.getSelectionBackground() : table.getBackground());
            return this;
        }
    }

    private class ActionEditor extends AbstractCellEditor implements javax.swing.table.TableCellEditor {
        private final JPanel panel = new JPanel(new FlowLayout(FlowLayout.CENTER, 3, 0));
        private final JButton payBtn = new JButton("Pagar");
        private final JButton detailBtn = new JButton("Detalhes");
        private ContaReceber currentConta;

        ActionEditor() {
            payBtn.setFont(payBtn.getFont().deriveFont(Font.PLAIN, 10f));
            payBtn.setBackground(new Color(57, 113, 227));
            payBtn.setForeground(Color.WHITE);
            payBtn.setFocusPainted(false);
            payBtn.setPreferredSize(new Dimension(50, 20));
            detailBtn.setFont(detailBtn.getFont().deriveFont(Font.PLAIN, 10f));
            detailBtn.setBackground(new Color(128, 128, 128));
            detailBtn.setForeground(Color.WHITE);
            detailBtn.setFocusPainted(false);
            detailBtn.setPreferredSize(new Dimension(60, 20));

            payBtn.addActionListener(e -> {
                fireEditingStopped();
                if (currentConta != null && !"pago".equals(currentConta.getStatus())) {
                    openPagamentoDialog(currentConta);
                }
            });
            detailBtn.addActionListener(e -> {
                fireEditingStopped();
                if (currentConta != null) {
                    ContaDetailDialog dialog = new ContaDetailDialog(
                            (Frame) SwingUtilities.getWindowAncestor(ContasReceberPanel.this),
                            currentConta,
                            clienteNames
                    );
                    dialog.setVisible(true);
                }
            });

            panel.add(payBtn);
            panel.add(detailBtn);
        }

        @Override
        public Component getTableCellEditorComponent(JTable table, Object value,
                                                     boolean isSelected, int row, int col) {
            currentConta = tableModel.getContaAt(row);
            panel.setBackground(isSelected ? table.getSelectionBackground() : table.getBackground());
            return panel;
        }

        @Override public Object getCellEditorValue() { return ""; }
    }
}
