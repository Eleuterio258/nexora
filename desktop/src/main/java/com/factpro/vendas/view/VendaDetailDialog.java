package com.factpro.vendas.view;

import com.factpro.clientes.dao.ClienteDAO;
import com.factpro.clientes.model.Cliente;
import com.factpro.core.util.CurrencyFormatter;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Produto;
import com.factpro.vendas.dao.PagamentoDAO;
import com.factpro.vendas.dao.VendaDAO;
import com.factpro.vendas.dao.VendaItemDAO;
import com.factpro.vendas.model.Pagamento;
import com.factpro.vendas.model.Venda;
import com.factpro.vendas.model.VendaItem;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.CompoundBorder;
import javax.swing.border.EmptyBorder;
import javax.swing.border.LineBorder;
import javax.swing.table.DefaultTableCellRenderer;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;
import java.util.List;

/**
 * Sale detail dialog showing items, payments, and status.
 */
public class VendaDetailDialog extends JDialog {

    private static final Logger logger = LoggerFactory.getLogger(VendaDetailDialog.class);

    private final Venda venda;
    private final VendaItemDAO vendaItemDAO;
    private final ProdutoDAO produtoDAO;
    private final PagamentoDAO pagamentoDAO;
    private final ClienteDAO clienteDAO;

    public VendaDetailDialog(Frame parent, Venda venda) {
        super(parent, "Detalhe da Venda", true);
        this.venda = venda;

        vendaItemDAO = new VendaItemDAO();
        produtoDAO = new ProdutoDAO();
        pagamentoDAO = new PagamentoDAO();
        clienteDAO = new ClienteDAO();

        setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
        setSize(700, 550);
        setLocationRelativeTo(parent);

        initComponents();
        setupLayout();
        setupListeners();
    }

    private void initComponents() {
        // No specific initialization needed - all done in setupLayout
    }

    private void setupLayout() {
        setLayout(new MigLayout("fill, ins 15, gap 10", "[grow]", "[][][grow][][]"));

        // Header section
        JPanel headerPanel = new JPanel(new MigLayout("fillx, ins 5, gap 5 15", "[][][][]", "[][]"));
        headerPanel.setBackground(new Color(245, 245, 245));
        headerPanel.setBorder(new CompoundBorder(
                new LineBorder(new Color(200, 200, 200), 1, true),
                new EmptyBorder(8, 10, 8, 10)));

        // Document number
        JLabel docLabel = new JLabel("Nº Documento:");
        docLabel.setFont(docLabel.getFont().deriveFont(Font.BOLD, 12f));
        docLabel.setForeground(Color.GRAY);
        String docNumber = (venda.getSerieDocumento() != null ? venda.getSerieDocumento() : "FT")
                + " " + (venda.getNumeroDocumento() != null ? venda.getNumeroDocumento() : "N/A");
        JLabel docValue = new JLabel(docNumber);
        docValue.setFont(docValue.getFont().deriveFont(Font.BOLD, 16f));

        // Date
        JLabel dateLabel = new JLabel("Data:");
        dateLabel.setFont(dateLabel.getFont().deriveFont(Font.BOLD, 12f));
        dateLabel.setForeground(Color.GRAY);
        JLabel dateValue = new JLabel(venda.getCriadaEm() != null ? venda.getCriadaEm() : "N/A");

        // Client
        JLabel clientLabel = new JLabel("Cliente:");
        clientLabel.setFont(clientLabel.getFont().deriveFont(Font.BOLD, 12f));
        clientLabel.setForeground(Color.GRAY);
        String clientName = "Balcao";
        if (venda.getClienteId() != null) {
            Cliente cliente = clienteDAO.findById(venda.getClienteId());
            if (cliente != null) clientName = cliente.getNome();
        }
        JLabel clientValue = new JLabel(clientName);

        // Terminal
        JLabel termLabel = new JLabel("Terminal:");
        termLabel.setFont(termLabel.getFont().deriveFont(Font.BOLD, 12f));
        termLabel.setForeground(Color.GRAY);
        JLabel termValue = new JLabel(venda.getTerminal() != null ? venda.getTerminal() : "N/A");

        headerPanel.add(docLabel);
        headerPanel.add(dateLabel, "gapleft 20");
        headerPanel.add(clientLabel, "gapleft 20");
        headerPanel.add(termLabel, "gapleft 20");
        headerPanel.add(docValue);
        headerPanel.add(dateValue);
        headerPanel.add(clientValue);
        headerPanel.add(termValue);

        add(headerPanel, "growx");

        // Status badge
        JPanel statusPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        JLabel statusBadge = new JLabel(formatStatus(venda.getStatus()));
        statusBadge.setFont(statusBadge.getFont().deriveFont(Font.BOLD, 13f));
        statusBadge.setBorder(new CompoundBorder(
                new LineBorder(getStatusColor(venda.getStatus()), 2, true),
                new EmptyBorder(4, 10, 4, 10)));
        statusBadge.setForeground(getStatusColor(venda.getStatus()));
        statusPanel.add(statusBadge);
        add(statusPanel, "growx");

        // Items table
        JLabel itemsTitle = new JLabel("Itens da Venda");
        itemsTitle.setFont(itemsTitle.getFont().deriveFont(Font.BOLD, 14f));
        add(itemsTitle);

        String[] itemCols = {"Produto", "Qtd", "Preco Unit.", "Desconto", "Total"};
        VendaItemsTableModel itemModel = new VendaItemsTableModel(itemCols);
        JTable itemsTable = new JTable(itemModel);
        itemsTable.setRowHeight(26);
        itemsTable.getTableHeader().setReorderingAllowed(false);
        itemsTable.getColumnModel().getColumn(1).setCellRenderer(new CenterRenderer());
        itemsTable.getColumnModel().getColumn(2).setCellRenderer(new CurrencyRenderer());
        itemsTable.getColumnModel().getColumn(3).setCellRenderer(new CurrencyRenderer());
        itemsTable.getColumnModel().getColumn(4).setCellRenderer(new CurrencyRenderer());

        List<VendaItem> items = vendaItemDAO.findByVendaId(venda.getId());
        itemModel.setItems(items);

        add(new JScrollPane(itemsTable), "grow, h 180");

        // Summary panel
        JPanel summaryPanel = new JPanel(new MigLayout("fillx, ins 10, gap 5", "[grow][200]", "[][][]"));
        summaryPanel.setBackground(new Color(250, 250, 250));
        summaryPanel.setBorder(new CompoundBorder(
                new LineBorder(new Color(200, 200, 200), 1, true),
                new EmptyBorder(5, 5, 5, 5)));

        summaryPanel.add(new JLabel("Subtotal:"), "right");
        summaryPanel.add(new JLabel(CurrencyFormatter.format(venda.getSubtotal() != null ? venda.getSubtotal() : 0.0)), "right");
        summaryPanel.add(new JLabel("Desconto:"), "right");
        summaryPanel.add(new JLabel(CurrencyFormatter.format(venda.getDesconto() != null ? venda.getDesconto() : 0.0)), "right");

        JLabel totalLabel = new JLabel("TOTAL: " + CurrencyFormatter.format(venda.getTotal() != null ? venda.getTotal() : 0.0));
        totalLabel.setFont(totalLabel.getFont().deriveFont(Font.BOLD, 18f));
        totalLabel.setForeground(new Color(57, 113, 227));
        summaryPanel.add(new JLabel("TOTAL:"), "right");
        summaryPanel.add(totalLabel, "right");

        add(summaryPanel, "growx");

        // Payments section
        JLabel payTitle = new JLabel("Pagamentos");
        payTitle.setFont(payTitle.getFont().deriveFont(Font.BOLD, 14f));
        add(payTitle);

        JPanel payPanel = new JPanel(new MigLayout("fillx, ins 5", "[][][]", "[]"));
        payPanel.setBackground(new Color(250, 250, 250));
        payPanel.setBorder(new CompoundBorder(
                new LineBorder(new Color(200, 200, 200), 1, true),
                new EmptyBorder(5, 5, 5, 5)));

        List<Pagamento> pagamentos = pagamentoDAO.findByVendaId(venda.getId());
        int payRow = 0;
        if (pagamentos.isEmpty()) {
            // Show payment info from the venda itself
            payPanel.add(new JLabel(venda.getMetodoPagamento() != null ? venda.getMetodoPagamento() : "-"), "cell 0 0");
            payPanel.add(new JLabel(CurrencyFormatter.format(venda.getTotal() != null ? venda.getTotal() : 0.0)), "cell 2 0, right");
        } else {
            for (Pagamento pg : pagamentos) {
                payPanel.add(new JLabel(pg.getMetodo()), "cell 0 " + payRow);
                if (pg.getTransacaoId() != null && !pg.getTransacaoId().isEmpty()) {
                    payPanel.add(new JLabel("Ref: " + pg.getTransacaoId()), "cell 1 " + payRow);
                }
                payPanel.add(new JLabel(CurrencyFormatter.format(pg.getValor())), "cell 2 " + payRow + ", right");
                payRow++;
            }
        }
        add(payPanel, "growx");

        // Buttons
        JPanel btnPanel = new JPanel(new MigLayout("ins 0, gap 10"));
        JButton printBtn = new JButton("Imprimir Recibo");
        JButton closeBtn = new JButton("Fechar");
        btnPanel.add(printBtn);
        btnPanel.add(closeBtn);
        add(btnPanel, "center");

        printBtn.addActionListener(e -> {
            JOptionPane.showMessageDialog(this,
                    "Funcionalidade de impressao em desenvolvimento.",
                    "Imprimir",
                    JOptionPane.INFORMATION_MESSAGE);
        });

        closeBtn.addActionListener(e -> dispose());

        // Escape key closes
        getRootPane().setDefaultButton(closeBtn);
        KeyStroke escape = KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(escape, "cancel");
        getRootPane().getActionMap().put("cancel", new AbstractAction() {
            @Override public void actionPerformed(ActionEvent e) { dispose(); }
        });
    }

    private void setupListeners() {
        // No additional listeners needed
    }

    private String formatStatus(String status) {
        if (status == null) return "Aberta";
        return switch (status.toLowerCase()) {
            case "finalizada" -> "\u2714 Finalizada";
            case "cancelada" -> "\u2716 Cancelada";
            case "aberta" -> "\u25CF Aberta";
            default -> status;
        };
    }

    private Color getStatusColor(String status) {
        if (status == null) return Color.ORANGE;
        return switch (status.toLowerCase()) {
            case "finalizada" -> new Color(34, 139, 34);
            case "cancelada" -> new Color(220, 53, 69);
            case "aberta" -> Color.ORANGE;
            default -> Color.GRAY;
        };
    }

    // ==================== Table Model ====================

    private static class VendaItemsTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private List<VendaItem> items = new java.util.ArrayList<>();

        VendaItemsTableModel(String[] columns) { this.columns = columns; }

        void setItems(List<VendaItem> items) {
            this.items = items;
            fireTableDataChanged();
        }

        @Override public int getRowCount() { return items.size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= items.size()) return null;
            VendaItem item = items.get(row);
            ProdutoDAO produtoDAO = new ProdutoDAO();
            Produto produto = produtoDAO.findById(item.getProdutoId());
            String nome = produto != null ? produto.getNome() : "Produto #" + item.getProdutoId();

            return switch (col) {
                case 0 -> nome;
                case 1 -> item.getQuantidade();
                case 2 -> item.getPrecoUnitario();
                case 3 -> item.getDesconto() != null ? item.getDesconto() : 0.0;
                case 4 -> item.getTotal() != null ? item.getTotal() : 0.0;
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

    private static class CenterRenderer extends DefaultTableCellRenderer {
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            setHorizontalAlignment(SwingConstants.CENTER);
            return this;
        }
    }
}
