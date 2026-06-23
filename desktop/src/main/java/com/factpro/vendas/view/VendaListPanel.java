package com.factpro.vendas.view;

import com.factpro.auth.SessionManager;
import com.factpro.clientes.dao.ClienteDAO;
import com.factpro.clientes.model.Cliente;
import com.factpro.core.util.CurrencyFormatter;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.vendas.dao.PagamentoDAO;
import com.factpro.vendas.dao.VendaDAO;
import com.factpro.vendas.dao.VendaItemDAO;
import com.factpro.vendas.model.Venda;
import com.factpro.vendas.service.VendaService;
import com.factpro.stock.dao.StockMovimentoDAO;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.CompoundBorder;
import javax.swing.border.EmptyBorder;
import javax.swing.border.LineBorder;
import javax.swing.table.DefaultTableCellRenderer;
import java.awt.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * Sales list panel with date filtering, status badges, and cancel action.
 */
public class VendaListPanel extends JPanel {

    private static final Logger logger = LoggerFactory.getLogger(VendaListPanel.class);

    private final VendaDAO vendaDAO;
    private final VendaItemDAO vendaItemDAO;
    private final StockMovimentoDAO stockMovimentoDAO;
    private final PagamentoDAO pagamentoDAO;
    private final VendaService vendaService;
    private final ClienteDAO clienteDAO;

    private JTable salesTable;
    private VendaTableModel tableModel;
    private List<Venda> allVendas;
    private JTextField startDateField;
    private JTextField endDateField;

    private static final Color GREEN    = new Color(22, 163, 74);
    private static final Color RED      = new Color(220, 38,  38);
    private static final Color ORANGE   = new Color(234, 88,  12);
    private static final Color BLUE     = new Color(37,  99, 235);
    private static final Color INK      = new Color(15,  23,  42);
    private static final Color MUTED    = new Color(100, 116, 139);
    private static final Color BORDER_C = new Color(226, 232, 240);
    private static final Color SURFACE  = new Color(248, 250, 252);

    public VendaListPanel() {
        vendaDAO = new VendaDAO();
        vendaItemDAO = new VendaItemDAO();
        stockMovimentoDAO = new StockMovimentoDAO();
        pagamentoDAO = new PagamentoDAO();
        clienteDAO = new ClienteDAO();
        ProdutoDAO produtoDAO = new ProdutoDAO();
        vendaService = new VendaService(vendaDAO, vendaItemDAO, produtoDAO, stockMovimentoDAO, pagamentoDAO);
        allVendas = new ArrayList<>();

        setLayout(new BorderLayout());
        setBackground(SURFACE);
        setBorder(new EmptyBorder(10, 10, 10, 10));

        initComponents();
        setupLayout();
        setupListeners();
        loadVendas();
    }

    private void initComponents() {
        String today = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE);
        String firstOfMonth = today.substring(0, 8) + "01";

        String fieldStyle = "arc:8; innerFocusWidth:2; focusedBorderColor:#2563eb; margin:5,10,5,10";
        startDateField = new JTextField(firstOfMonth, 12);
        startDateField.putClientProperty(com.formdev.flatlaf.FlatClientProperties.PLACEHOLDER_TEXT, "AAAA-MM-DD");
        startDateField.putClientProperty(com.formdev.flatlaf.FlatClientProperties.STYLE, fieldStyle);
        endDateField = new JTextField(today, 12);
        endDateField.putClientProperty(com.formdev.flatlaf.FlatClientProperties.PLACEHOLDER_TEXT, "AAAA-MM-DD");
        endDateField.putClientProperty(com.formdev.flatlaf.FlatClientProperties.STYLE, fieldStyle);

        String[] cols = {"Nº Doc", "Data", "Cliente", "Total", "Pagamento", "Estado", ""};
        tableModel = new VendaTableModel(cols);
        salesTable = new JTable(tableModel);
        salesTable.setRowHeight(32);
        salesTable.setShowGrid(false);
        salesTable.setIntercellSpacing(new Dimension(0, 0));
        salesTable.getTableHeader().setReorderingAllowed(false);
        salesTable.getColumnModel().getColumn(0).setPreferredWidth(100);
        salesTable.getColumnModel().getColumn(0).setMaxWidth(130);
        salesTable.getColumnModel().getColumn(1).setPreferredWidth(130);
        salesTable.getColumnModel().getColumn(1).setMaxWidth(160);
        salesTable.getColumnModel().getColumn(3).setPreferredWidth(110);
        salesTable.getColumnModel().getColumn(3).setMaxWidth(140);
        salesTable.getColumnModel().getColumn(4).setPreferredWidth(100);
        salesTable.getColumnModel().getColumn(4).setMaxWidth(130);
        salesTable.getColumnModel().getColumn(5).setPreferredWidth(110);
        salesTable.getColumnModel().getColumn(5).setMaxWidth(130);
        salesTable.getColumnModel().getColumn(6).setPreferredWidth(60);
        salesTable.getColumnModel().getColumn(6).setMaxWidth(70);
        salesTable.getColumnModel().getColumn(3).setCellRenderer(new CurrencyRenderer());
        salesTable.getColumnModel().getColumn(5).setCellRenderer(new StatusBadgeRenderer());
        salesTable.getColumnModel().getColumn(6).setCellRenderer(new ActionRenderer());
        salesTable.getColumnModel().getColumn(6).setCellEditor(new ActionEditor());
    }

    private void setupLayout() {
        JPanel north = new JPanel(new MigLayout("fillx, ins 0, gap 0, wrap 1", "[grow]"));
        north.setOpaque(false);

        // Header: title + action buttons
        JPanel header = new JPanel(new MigLayout("fillx, ins 0 0 8 0", "[grow][]", "[]"));
        header.setOpaque(false);
        JLabel title = new JLabel("Historial de Vendas");
        title.setFont(title.getFont().deriveFont(Font.BOLD, 18f));
        title.setForeground(INK);
        JButton btnCancelar = makeBtn("Cancelar Venda", RED);
        JButton btnExportar = makeBtn("Exportar CSV",   new Color(71, 85, 105));
        JPanel btnRow = new JPanel(new MigLayout("ins 0, gap 8", "[][]", "[36!]"));
        btnRow.setOpaque(false);
        btnRow.add(btnCancelar, "grow");
        btnRow.add(btnExportar, "grow");
        header.add(title,  "left");
        header.add(btnRow, "right");
        north.add(header, "growx");

        // Filter bar
        JButton btnFiltrar = makeBtn("Filtrar",      BLUE);
        JButton btnDetalhe  = makeBtn("Ver Detalhe", GREEN);
        JPanel filterRow = new JPanel(new MigLayout("fillx, ins 0 0 8 0, gap 8",
                "[grow 0][120!][grow 0][120!][grow][][]", "[40!]"));
        filterRow.setOpaque(false);
        JLabel lblDe  = new JLabel("De:");  lblDe.setForeground(MUTED);
        JLabel lblAte = new JLabel("Até:"); lblAte.setForeground(MUTED);
        filterRow.add(lblDe);
        filterRow.add(startDateField, "h 40!");
        filterRow.add(lblAte);
        filterRow.add(endDateField,   "h 40!");
        filterRow.add(new JPanel(){{setOpaque(false);}}, "grow");
        filterRow.add(btnFiltrar, "h 40!");
        filterRow.add(btnDetalhe, "h 40!");
        north.add(filterRow, "growx");

        add(north, BorderLayout.NORTH);

        JScrollPane scroll = new JScrollPane(salesTable);
        scroll.setBorder(BorderFactory.createLineBorder(BORDER_C));
        add(scroll, BorderLayout.CENTER);

        btnFiltrar.addActionListener(e -> loadVendas());
        btnCancelar.addActionListener(e -> cancelSelectedVenda());
        btnExportar.addActionListener(e -> exportVendas());
        btnDetalhe.addActionListener(e -> showSelectedDetail());
    }

    private JButton makeBtn(String label, Color bg) {
        String hex = String.format("#%02x%02x%02x", bg.getRed(), bg.getGreen(), bg.getBlue());
        String hov = String.format("#%02x%02x%02x",
                Math.max(0, bg.getRed()   - 25),
                Math.max(0, bg.getGreen() - 25),
                Math.max(0, bg.getBlue()  - 25));
        JButton btn = new JButton(label);
        btn.putClientProperty(com.formdev.flatlaf.FlatClientProperties.STYLE,
                "arc:8; background:" + hex + "; foreground:#ffffff; font:bold; " +
                "hoverBackground:" + hov + "; borderColor:null");
        btn.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        return btn;
    }

    private void setupListeners() {
        salesTable.addMouseListener(new java.awt.event.MouseAdapter() {
            @Override
            public void mouseClicked(java.awt.event.MouseEvent e) {
                if (e.getClickCount() == 2) {
                    showSelectedDetail();
                }
            }
        });
    }

    private void loadVendas() {
        String startDate = startDateField.getText().trim();
        String endDate = endDateField.getText().trim();

        if (startDate.isEmpty() || endDate.isEmpty()) {
            allVendas = vendaDAO.findAll();
        } else {
            allVendas = vendaService.findVendasByDateRange(
                    startDate + " 00:00:00", endDate + " 23:59:59");
        }

        tableModel.setVendas(allVendas);
    }

    private void cancelSelectedVenda() {
        int row = salesTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(this, "Selecione uma venda para cancelar.",
                    "Nenhuma Selecionada", JOptionPane.WARNING_MESSAGE);
            return;
        }

        Venda venda = tableModel.getVendaAt(row);
        if (venda == null) return;

        if (!"finalizada".equals(venda.getStatus())) {
            JOptionPane.showMessageDialog(this,
                    "Apenas vendas finalizadas podem ser canceladas.\nStatus atual: " + venda.getStatus(),
                    "Nao e Possivel Cancelar",
                    JOptionPane.WARNING_MESSAGE);
            return;
        }

        // Show cancel dialog
        CancelVendaDialog dialog = new CancelVendaDialog(
                (Frame) SwingUtilities.getWindowAncestor(this), venda);
        dialog.setVisible(true);

        if (dialog.isCancelled()) {
            loadVendas();
        }
    }

    private void showSelectedDetail() {
        int row = salesTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(this, "Selecione uma venda para ver os detalhes.",
                    "Nenhuma Selecionada", JOptionPane.WARNING_MESSAGE);
            return;
        }

        Venda venda = tableModel.getVendaAt(row);
        if (venda != null) {
            VendaDetailDialog dialog = new VendaDetailDialog(
                    (Frame) SwingUtilities.getWindowAncestor(this), venda);
            dialog.setVisible(true);
        }
    }

    private void exportVendas() {
        JFileChooser chooser = new JFileChooser();
        chooser.setSelectedFile(new java.io.File("vendas_export.csv"));
        chooser.setFileFilter(new javax.swing.filechooser.FileNameExtensionFilter("CSV Files", "csv"));
        if (chooser.showSaveDialog(this) == JFileChooser.APPROVE_OPTION) {
            java.io.File file = chooser.getSelectedFile();
            try (java.io.PrintWriter writer = new java.io.PrintWriter(new java.io.FileWriter(file))) {
                writer.println("Nº Doc,Data,Cliente,Total,Metodo Pagamento,Status");
                for (Venda v : allVendas) {
                    String clienteNome = "N/A";
                    if (v.getClienteId() != null) {
                        Cliente c = clienteDAO.findById(v.getClienteId());
                        if (c != null) clienteNome = c.getNome();
                    }
                    writer.printf("%s %d,%s,%s,%.2f,%s,%s%n",
                            v.getSerieDocumento(), v.getNumeroDocumento(),
                            v.getCriadaEm() != null ? v.getCriadaEm().substring(0, 10) : "",
                            escapeCSV(clienteNome),
                            v.getTotal(),
                            v.getMetodoPagamento(),
                            v.getStatus());
                }
                JOptionPane.showMessageDialog(this, "Dados exportados com sucesso.",
                        "Exportacao CSV", JOptionPane.INFORMATION_MESSAGE);
            } catch (Exception e) {
                logger.error("Erro ao exportar vendas", e);
                JOptionPane.showMessageDialog(this, "Erro ao exportar: " + e.getMessage(),
                        "Erro", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    private String escapeCSV(String value) {
        if (value == null) return "";
        if (value.contains(",") || value.contains("\"")) return "\"" + value.replace("\"", "\"\"") + "\"";
        return value;
    }

    // ==================== Table Model ====================

    private static class VendaTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private List<Venda> vendas = new ArrayList<>();

        VendaTableModel(String[] columns) { this.columns = columns; }

        void setVendas(List<Venda> vendas) {
            this.vendas = vendas;
            fireTableDataChanged();
        }

        Venda getVendaAt(int row) {
            return (row >= 0 && row < vendas.size()) ? vendas.get(row) : null;
        }

        @Override public int getRowCount() { return vendas.size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= vendas.size()) return null;
            Venda v = vendas.get(row);
            return switch (col) {
                case 0 -> (v.getSerieDocumento() != null ? v.getSerieDocumento() : "FT") + " "
                        + (v.getNumeroDocumento() != null ? v.getNumeroDocumento() : "-");
                case 1 -> v.getCriadaEm() != null ? v.getCriadaEm().substring(0, 16) : "-";
                case 2 -> v.getClienteId() != null ? "Cliente #" + v.getClienteId() : "Balcão";
                case 3 -> v.getTotal() != null ? v.getTotal() : 0.0;
                case 4 -> v.getMetodoPagamento() != null ? v.getMetodoPagamento() : "-";
                case 5 -> v.getStatus() != null ? v.getStatus() : "aberta";
                case 6 -> "Detalhe";
                default -> null;
            };
        }
    }

    // ==================== Renderers ====================

    private static class CurrencyRenderer extends DefaultTableCellRenderer {
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            if (value instanceof Number) setText(CurrencyFormatter.format(((Number) value).doubleValue()));
            setHorizontalAlignment(SwingConstants.RIGHT);
            return this;
        }
    }

    private static class StatusBadgeRenderer extends DefaultTableCellRenderer {
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            if (value instanceof String status) {
                switch (status.toLowerCase()) {
                    case "finalizada" -> { setForeground(GREEN); setText("\u2714 Finalizada"); }
                    case "cancelada" -> { setForeground(RED); setText("\u2716 Cancelada"); }
                    case "aberta" -> { setForeground(ORANGE); setText("\u25CF Aberta"); }
                    default -> setText(status);
                }
            }
            setHorizontalAlignment(SwingConstants.CENTER);
            return this;
        }
    }

    private static class ActionRenderer extends JPanel implements javax.swing.table.TableCellRenderer {
        private final JButton detailBtn = new JButton("Ver");

        ActionRenderer() {
            setLayout(new FlowLayout(FlowLayout.CENTER, 0, 0));
            detailBtn.setFont(detailBtn.getFont().deriveFont(Font.PLAIN, 10f));
            detailBtn.setBackground(BLUE);
            detailBtn.setForeground(Color.WHITE);
            detailBtn.setFocusPainted(false);
            detailBtn.setPreferredSize(new Dimension(45, 20));
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
        private final JPanel panel = new JPanel(new FlowLayout(FlowLayout.CENTER, 0, 0));
        private final JButton detailBtn = new JButton("Ver");
        private Venda currentVenda;

        ActionEditor() {
            detailBtn.setFont(detailBtn.getFont().deriveFont(Font.PLAIN, 10f));
            detailBtn.setBackground(BLUE);
            detailBtn.setForeground(Color.WHITE);
            detailBtn.setFocusPainted(false);
            detailBtn.setPreferredSize(new Dimension(45, 20));
            detailBtn.addActionListener(e -> {
                fireEditingStopped();
                if (currentVenda != null) {
                    VendaDetailDialog dialog = new VendaDetailDialog(
                            (Frame) SwingUtilities.getWindowAncestor(VendaListPanel.this), currentVenda);
                    dialog.setVisible(true);
                }
            });
            panel.add(detailBtn);
        }

        @Override
        public Component getTableCellEditorComponent(JTable table, Object value,
                                                     boolean isSelected, int row, int col) {
            currentVenda = tableModel.getVendaAt(row);
            panel.setBackground(isSelected ? table.getSelectionBackground() : table.getBackground());
            return panel;
        }

        @Override public Object getCellEditorValue() { return ""; }
    }

    // ==================== Cancel Dialog ====================

    private static class CancelVendaDialog extends JDialog {
        private final Venda venda;
        private boolean cancelled = false;

        CancelVendaDialog(Frame parent, Venda venda) {
            super(parent, "Cancelar Venda", true);
            this.venda = venda;

            setSize(400, 250);
            setLocationRelativeTo(parent);
            setLayout(new MigLayout("fill, ins 20", "[grow]", "[][][][]"));

            add(new JLabel("Cancelar Venda: " + venda.getSerieDocumento() + " " + venda.getNumeroDocumento()), "gapy 0 10");
            add(new JLabel("Total: " + CurrencyFormatter.format(venda.getTotal())), "gapy 5");
            add(new JSeparator(), "growx");

            JTextArea motivoArea = new JTextArea(3, 30);
            motivoArea.setLineWrap(true);
            add(new JLabel("Motivo do cancelamento:"), "gapy 10 0");
            add(new JScrollPane(motivoArea), "growx");

            JPanel btnPanel = new JPanel(new MigLayout("ins 0, gap 10", "[]"));
            JButton confirmBtn = new JButton("Confirmar Cancelamento");
            JButton cancelBtn = new JButton("Voltar");
            confirmBtn.setBackground(RED);
            confirmBtn.setForeground(Color.WHITE);
            btnPanel.add(confirmBtn);
            btnPanel.add(cancelBtn);
            add(btnPanel, "center, gapy 10");

            confirmBtn.addActionListener(e -> {
                String motivo = motivoArea.getText().trim();
                if (motivo.isEmpty()) {
                    JOptionPane.showMessageDialog(this, "Informe o motivo do cancelamento.",
                            "Motivo Obrigatorio", JOptionPane.WARNING_MESSAGE);
                    return;
                }

                VendaDAO vDAO = new VendaDAO();
                StockMovimentoDAO smDAO = new StockMovimentoDAO();
                VendaItemDAO viDAO = new VendaItemDAO();
                ProdutoDAO pDAO = new ProdutoDAO();
                VendaService vService = new VendaService(vDAO, viDAO, pDAO, smDAO, new PagamentoDAO());

                boolean result = vService.cancelarVenda(venda.getId(),
                        SessionManager.getInstance().getCurrentUserId(), motivo);

                if (result) {
                    JOptionPane.showMessageDialog(this, "Venda cancelada com sucesso.",
                            "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                    cancelled = true;
                    dispose();
                } else {
                    JOptionPane.showMessageDialog(this, "Erro ao cancelar a venda.",
                            "Erro", JOptionPane.ERROR_MESSAGE);
                }
            });

            cancelBtn.addActionListener(e -> dispose());
        }

        boolean isCancelled() { return cancelled; }
    }
}
