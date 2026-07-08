package com.factpro.compras.view;

import com.factpro.auth.SessionManager;
import com.factpro.compras.dao.CompraItemDAO;
import com.factpro.compras.model.Compra;
import com.factpro.compras.model.CompraItem;
import com.factpro.compras.service.CompraService;
import com.factpro.core.util.CurrencyFormatter;
import com.factpro.fornecedores.model.Fornecedor;
import com.factpro.fornecedores.service.FornecedorService;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Produto;
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
import java.util.ArrayList;
import java.util.List;

/**
 * Purchase detail dialog showing purchase info, items, and receive action.
 */
public class CompraDetailDialog extends JDialog {

    private static final Logger logger = LoggerFactory.getLogger(CompraDetailDialog.class);

    private final Compra compra;
    private final CompraService compraService;
    private final FornecedorService fornecedorService;
    private final CompraItemDAO compraItemDAO;
    private final ProdutoDAO produtoDAO;
    private boolean updated = false;

    public CompraDetailDialog(Frame parent, Compra compra,
                              CompraService compraService, FornecedorService fornecedorService) {
        super(parent, "Detalhe da Compra", true);
        this.compra = compra;
        this.compraService = compraService;
        this.fornecedorService = fornecedorService;
        this.compraItemDAO = new CompraItemDAO();
        this.produtoDAO = new ProdutoDAO();

        setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
        setSize(700, 500);
        setLocationRelativeTo(parent);

        initComponents();
        setupLayout();
    }

    private void initComponents() {
        // No specific initialization needed
    }

    private void setupLayout() {
        setLayout(new MigLayout("fill, ins 15, gap 10", "[grow]", "[][][grow][][]"));

        // Header section
        JPanel headerPanel = new JPanel(new MigLayout("fillx, ins 5, gap 5 15", "[][][][]", "[][]"));
        headerPanel.setBackground(new Color(245, 245, 245));
        headerPanel.setBorder(new CompoundBorder(
                new LineBorder(new Color(200, 200, 200), 1, true),
                new EmptyBorder(8, 10, 8, 10)));

        // ID
        JLabel idLabel = new JLabel("Nº Compra:");
        idLabel.setFont(idLabel.getFont().deriveFont(Font.BOLD, 12f));
        idLabel.setForeground(Color.GRAY);
        JLabel idValue = new JLabel("#" + (compra.getId() != null ? compra.getId() : "N/A"));
        idValue.setFont(idValue.getFont().deriveFont(Font.BOLD, 16f));

        // Fornecedor
        String fornecedorNome = "-";
        if (compra.getFornecedorId() != null) {
            Fornecedor f = fornecedorService.findById(compra.getFornecedorId());
            if (f != null) fornecedorNome = f.getNome();
        }
        JLabel fornLabel = new JLabel("Fornecedor:");
        fornLabel.setFont(fornLabel.getFont().deriveFont(Font.BOLD, 12f));
        fornLabel.setForeground(Color.GRAY);
        JLabel fornValue = new JLabel(fornecedorNome);

        // Date
        JLabel dateLabel = new JLabel("Data:");
        dateLabel.setFont(dateLabel.getFont().deriveFont(Font.BOLD, 12f));
        dateLabel.setForeground(Color.GRAY);
        JLabel dateValue = new JLabel(compra.getDataCompra() != null ? compra.getDataCompra() : "N/A");

        // Status
        JLabel statusLabel = new JLabel("Status:");
        statusLabel.setFont(statusLabel.getFont().deriveFont(Font.BOLD, 12f));
        statusLabel.setForeground(Color.GRAY);
        JLabel statusValue = new JLabel(compra.getStatus() != null ? compra.getStatus() : "pendente");
        statusValue.setForeground(getStatusColor(compra.getStatus()));
        statusValue.setFont(statusValue.getFont().deriveFont(Font.BOLD, 13f));

        headerPanel.add(idLabel);
        headerPanel.add(fornLabel, "gapleft 20");
        headerPanel.add(dateLabel, "gapleft 20");
        headerPanel.add(statusLabel, "gapleft 20");
        headerPanel.add(idValue);
        headerPanel.add(fornValue);
        headerPanel.add(dateValue);
        headerPanel.add(statusValue);

        add(headerPanel, "growx");

        // Items section
        JLabel itemsTitle = new JLabel("Itens da Compra");
        itemsTitle.setFont(itemsTitle.getFont().deriveFont(Font.BOLD, 14f));
        add(itemsTitle);

        String[] itemCols = {"Produto", "Quantidade", "Preco", "Total"};
        List<CompraItem> compraItems = compraItemDAO.findByCompraId(compra.getId());
        CompraItemsTableModel itemModel = new CompraItemsTableModel(itemCols, compraItems, produtoDAO);
        JTable itemsTable = new JTable(itemModel);
        itemsTable.setRowHeight(26);
        itemsTable.getTableHeader().setReorderingAllowed(false);
        itemsTable.getColumnModel().getColumn(1).setCellRenderer(new CenterRenderer());
        itemsTable.getColumnModel().getColumn(2).setCellRenderer(new CurrencyRenderer());
        itemsTable.getColumnModel().getColumn(3).setCellRenderer(new CurrencyRenderer());

        add(new JScrollPane(itemsTable), "grow, h 200");

        // Summary
        JPanel summaryPanel = new JPanel(new MigLayout("fillx, ins 10, gap 5", "[grow][200]", "[]"));
        summaryPanel.setBackground(new Color(250, 250, 250));
        summaryPanel.setBorder(new CompoundBorder(
                new LineBorder(new Color(200, 200, 200), 1, true),
                new EmptyBorder(5, 5, 5, 5)));

        JLabel totalLabel = new JLabel("TOTAL: " + CurrencyFormatter.format(compra.getTotal() != null ? compra.getTotal() : 0.0));
        totalLabel.setFont(totalLabel.getFont().deriveFont(Font.BOLD, 18f));
        totalLabel.setForeground(new Color(57, 113, 227));
        summaryPanel.add(new JLabel("TOTAL:"), "right");
        summaryPanel.add(totalLabel, "right");

        add(summaryPanel, "growx");

        // Observacoes
        if (compra.getObservacoes() != null && !compra.getObservacoes().isBlank()) {
            add(new JLabel("<html><b>Observacoes:</b> " + compra.getObservacoes() + "</html>"));
        }

        // Buttons
        JPanel btnPanel = new JPanel(new MigLayout("ins 0, gap 10"));
        JButton btnReceber = new JButton("Marcar como Recebida");
        JButton closeBtn = new JButton("Fechar");

        if ("recebida".equals(compra.getStatus())) {
            btnReceber.setEnabled(false);
            btnReceber.setText("Ja Recebida");
        }

        styleBtn(btnReceber, new Color(34, 139, 34));
        btnPanel.add(btnReceber);
        btnPanel.add(closeBtn);
        add(btnPanel, "center");

        btnReceber.addActionListener(e -> receiveCompra());
        closeBtn.addActionListener(e -> dispose());

        getRootPane().setDefaultButton(closeBtn);
        KeyStroke escape = KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(escape, "cancel");
        getRootPane().getActionMap().put("cancel", new AbstractAction() {
            @Override public void actionPerformed(ActionEvent e) { dispose(); }
        });
    }

    private void receiveCompra() {
        int confirm = JOptionPane.showConfirmDialog(this,
                "Deseja marcar esta compra como recebida?\nO stock sera atualizado.",
                "Confirmar Recebimento",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.QUESTION_MESSAGE);

        if (confirm == JOptionPane.YES_OPTION) {
            try {
                Long userId = SessionManager.getInstance().getCurrentUserId();
                compraService.receiveCompra(compra.getId(), userId != null ? userId : 1L);
                JOptionPane.showMessageDialog(this, "Compra recebida com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                updated = true;
                dispose();
            } catch (Exception ex) {
                logger.error("Erro ao receber compra", ex);
                JOptionPane.showMessageDialog(this, "Erro ao receber compra: " + ex.getMessage(),
                        "Erro", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    public boolean isUpdated() { return updated; }

    private Color getStatusColor(String status) {
        if (status == null) return Color.ORANGE;
        return switch (status.toLowerCase()) {
            case "pendente" -> new Color(255, 152, 0);
            case "recebida" -> new Color(34, 139, 34);
            case "cancelada" -> new Color(220, 53, 69);
            default -> Color.GRAY;
        };
    }

    private void styleBtn(JButton btn, Color bgColor) {
        btn.setFont(btn.getFont().deriveFont(Font.PLAIN, 12f));
        btn.setBackground(bgColor);
        btn.setForeground(Color.WHITE);
        btn.setFocusPainted(false);
    }

    // ==================== Table Model ====================

    private static class CompraItemsTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private final List<Object[]> items = new ArrayList<>();

        CompraItemsTableModel(String[] columns, List<CompraItem> compraItems, ProdutoDAO produtoDAO) {
            this.columns = columns;
            if (compraItems == null || compraItems.isEmpty()) {
                items.add(new Object[]{"Nenhum item registado para esta compra.", 0.0, 0.0, 0.0});
            } else {
                for (CompraItem item : compraItems) {
                    String nomeProduto = "Produto #" + item.getProdutoId();
                    if (produtoDAO != null) {
                        Produto p = produtoDAO.findById(item.getProdutoId());
                        if (p != null && p.getNome() != null) {
                            nomeProduto = p.getNome();
                        }
                    }
                    items.add(new Object[]{
                            nomeProduto,
                            item.getQuantidade(),
                            item.getPrecoUnitario(),
                            item.getTotal()
                    });
                }
            }
        }

        @Override public int getRowCount() { return items.size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= items.size()) return null;
            return items.get(row)[col];
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
