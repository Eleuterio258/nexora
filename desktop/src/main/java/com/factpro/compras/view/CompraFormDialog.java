package com.factpro.compras.view;

import com.factpro.auth.SessionManager;
import com.factpro.compras.model.Compra;
import com.factpro.compras.service.CompraService;
import com.factpro.core.util.CurrencyFormatter;
import com.factpro.fornecedores.model.Fornecedor;
import com.factpro.fornecedores.service.FornecedorService;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Produto;
import com.factpro.produtos.service.ProdutoService;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.table.DefaultTableCellRenderer;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * Purchase form dialog for creating and editing purchases.
 */
public class CompraFormDialog extends JDialog {

    private static final Logger logger = LoggerFactory.getLogger(CompraFormDialog.class);

    private final CompraService compraService;
    private final FornecedorService fornecedorService;
    private final Compra editingCompra;
    private boolean saved = false;

    private JComboBox<FornecedorItem> fornecedorCombo;
    private JTextField dataCompraField;
    private JTextField produtoSearchField;
    private JList<ProdutoItem> produtoList;
    private DefaultListModel<ProdutoItem> produtoListModel;
    private JScrollPane produtoScroll;
    private JSpinner quantidadeSpinner;
    private JTextField precoUnitarioField;

    private JTable itemsTable;
    private CompraItemsTableModel itemsTableModel;
    private final List<CompraItemRow> items = new ArrayList<>();

    private JLabel totalLabel;

    public CompraFormDialog(Frame parent, Compra compra,
                            CompraService compraService, FornecedorService fornecedorService) {
        super(parent, compra == null ? "Nova Compra" : "Editar Compra", true);
        this.editingCompra = compra;
        this.compraService = compraService;
        this.fornecedorService = fornecedorService;

        setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
        setSize(750, 600);
        setLocationRelativeTo(parent);

        initComponents();
        setupLayout();
        setupListeners();

        if (editingCompra != null) populateForm();
    }

    private void initComponents() {
        // Fornecedor combo
        fornecedorCombo = new JComboBox<>();
        fornecedorCombo.addItem(new FornecedorItem(null, "-- Selecione Fornecedor --"));
        List<Fornecedor> fornecedores = fornecedorService.findAll();
        for (Fornecedor f : fornecedores) {
            fornecedorCombo.addItem(new FornecedorItem(f.getId(), f.getNome()));
        }

        // Data compra
        dataCompraField = new JTextField(15);
        dataCompraField.setText(LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE));
        dataCompraField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "AAAA-MM-DD");

        // Product search
        ProdutoDAO produtoDAO = new ProdutoDAO();
        ProdutoService produtoService = new ProdutoService(produtoDAO, null, null);

        produtoSearchField = new JTextField(20);
        produtoSearchField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Pesquisar produto...");

        produtoListModel = new DefaultListModel<>();
        produtoList = new JList<>(produtoListModel);
        produtoList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        produtoList.setCellRenderer(new ProdutoListCellRenderer());
        produtoScroll = new JScrollPane(produtoList);
        produtoScroll.setPreferredSize(new Dimension(0, 100));
        produtoScroll.setVisible(false);

        quantidadeSpinner = new JSpinner(new SpinnerNumberModel(1.0, 0.01, 99999.0, 1.0));
        precoUnitarioField = new JTextField(10);
        precoUnitarioField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "0.00");

        // Items table
        String[] cols = {"Produto", "Quantidade", "Preco Unit.", "Total", "Acoes"};
        itemsTableModel = new CompraItemsTableModel(cols, items);
        itemsTable = new JTable(itemsTableModel);
        itemsTable.setRowHeight(28);
        itemsTable.getTableHeader().setReorderingAllowed(false);
        itemsTable.getColumnModel().getColumn(1).setCellRenderer(new CenterRenderer());
        itemsTable.getColumnModel().getColumn(2).setCellRenderer(new CurrencyRenderer());
        itemsTable.getColumnModel().getColumn(3).setCellRenderer(new CurrencyRenderer());

        totalLabel = new JLabel("Total: " + CurrencyFormatter.format(0.0));
        totalLabel.setFont(totalLabel.getFont().deriveFont(Font.BOLD, 18f));
        totalLabel.setForeground(new Color(57, 113, 227));
        totalLabel.setHorizontalAlignment(SwingConstants.RIGHT);
    }

    private void setupLayout() {
        setLayout(new MigLayout("fill, wrap 1, ins 15, gap 8", "[grow]"));

        add(new JLabel("<html><b>Dados da Compra</b></html>"), "gapy 0 5");

        JPanel formPanel = new JPanel(new MigLayout("fillx, ins 0, gap 10", "[][][][][][][]"));
        formPanel.add(new JLabel("Fornecedor:"));
        formPanel.add(fornecedorCombo, "w 200");
        formPanel.add(new JLabel("Data:"));
        formPanel.add(dataCompraField, "w 120");
        add(formPanel, "growx");

        // Add product section
        add(new JLabel("<html><b>Adicionar Produtos</b></html>"), "gapy 10 5");
        JPanel addPanel = new JPanel(new MigLayout("fillx, ins 0, gap 8", "[grow][][][][]"));
        addPanel.add(produtoSearchField, "growx");
        addPanel.add(produtoScroll, "span 5, growx, h 100, wrap");
        addPanel.add(new JLabel("Qtd:"));
        addPanel.add(quantidadeSpinner, "w 80");
        addPanel.add(new JLabel("Preco:"));
        addPanel.add(precoUnitarioField, "w 100");
        JButton btnAdd = new JButton("Adicionar");
        styleBtn(btnAdd, new Color(57, 113, 227));
        addPanel.add(btnAdd);
        add(addPanel, "growx");

        // Items table
        add(new JScrollPane(itemsTable), "grow, h 200");

        // Total
        JPanel totalPanel = new JPanel(new MigLayout("fillx, ins 5", "[grow][]"));
        totalPanel.add(new JLabel(""), "grow");
        totalPanel.add(totalLabel);
        add(totalPanel, "growx");

        // Buttons
        JPanel btnPanel = new JPanel(new MigLayout("ins 0, gap 10"));
        JButton saveBtn = new JButton("Guardar");
        JButton cancelBtn = new JButton("Cancelar");
        saveBtn.setFont(saveBtn.getFont().deriveFont(Font.BOLD, 13f));
        cancelBtn.setFont(cancelBtn.getFont().deriveFont(Font.PLAIN, 13f));
        btnPanel.add(saveBtn);
        btnPanel.add(cancelBtn);
        add(btnPanel, "center");

        saveBtn.addActionListener(e -> saveCompra());
        cancelBtn.addActionListener(e -> dispose());
        btnAdd.addActionListener(e -> addItemToCompra());

        getRootPane().setDefaultButton(saveBtn);
        KeyStroke escape = KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(escape, "cancel");
        getRootPane().getActionMap().put("cancel", new AbstractAction() {
            @Override public void actionPerformed(ActionEvent e) { dispose(); }
        });
    }

    private void setupListeners() {
        produtoSearchField.addKeyListener(new java.awt.event.KeyAdapter() {
            @Override
            public void keyReleased(java.awt.event.KeyEvent e) {
                String query = produtoSearchField.getText().trim();
                if (query.length() >= 2) {
                    searchProduto(query);
                } else {
                    produtoScroll.setVisible(false);
                    revalidate();
                    repaint();
                }
            }
        });

        produtoList.addMouseListener(new java.awt.event.MouseAdapter() {
            @Override
            public void mouseClicked(java.awt.event.MouseEvent e) {
                if (e.getClickCount() == 2) {
                    ProdutoItem item = produtoList.getSelectedValue();
                    if (item != null) {
                        Produto p = item.produto;
                        produtoSearchField.setText(p.getNome());
                        precoUnitarioField.setText(String.valueOf(p.getPrecoCompra() != null ? p.getPrecoCompra() : 0.0));
                        produtoScroll.setVisible(false);
                        revalidate();
                        repaint();
                    }
                }
            }
        });
    }

    private void searchProduto(String query) {
        ProdutoDAO dao = new ProdutoDAO();
        ProdutoService ps = new ProdutoService(dao, null, null);
        List<Produto> results = ps.search(query);
        produtoListModel.clear();
        for (Produto p : results) {
            produtoListModel.addElement(new ProdutoItem(p));
        }
        produtoScroll.setVisible(!results.isEmpty());
        revalidate();
        repaint();
    }

    private void addItemToCompra() {
        String nome = produtoSearchField.getText().trim();
        if (nome.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Pesquise e selecione um produto.",
                    "Produto Nao Selecionado", JOptionPane.WARNING_MESSAGE);
            return;
        }

        double qty = ((Number) quantidadeSpinner.getValue()).doubleValue();
        double preco = parseDouble(precoUnitarioField.getText());

        if (qty <= 0) {
            JOptionPane.showMessageDialog(this, "Quantidade deve ser maior que zero.",
                    "Validacao", JOptionPane.WARNING_MESSAGE);
            return;
        }
        if (preco <= 0) {
            JOptionPane.showMessageDialog(this, "Preco deve ser maior que zero.",
                    "Validacao", JOptionPane.WARNING_MESSAGE);
            return;
        }

        // Find the product to get its ID
        ProdutoDAO dao = new ProdutoDAO();
        List<Produto> results = dao.search(nome);
        Produto produto = results.isEmpty() ? null : results.get(0);

        CompraItemRow row = new CompraItemRow(
                produto != null ? produto.getId() : null,
                nome, qty, preco);
        items.add(row);
        itemsTableModel.fireTableDataChanged();
        updateTotal();

        produtoSearchField.setText("");
        quantidadeSpinner.setValue(1.0);
        precoUnitarioField.setText("");
    }

    private void updateTotal() {
        double total = items.stream().mapToDouble(i -> i.quantidade * i.precoUnitario).sum();
        totalLabel.setText("Total: " + CurrencyFormatter.format(total));
    }

    private void populateForm() {
        if (editingCompra == null) return;
        if (editingCompra.getFornecedorId() != null) {
            for (int i = 0; i < fornecedorCombo.getItemCount(); i++) {
                FornecedorItem item = fornecedorCombo.getItemAt(i);
                if (item.id != null && item.id.equals(editingCompra.getFornecedorId())) {
                    fornecedorCombo.setSelectedIndex(i);
                    break;
                }
            }
        }
        if (editingCompra.getDataCompra() != null) {
            dataCompraField.setText(editingCompra.getDataCompra());
        }
    }

    private void saveCompra() {
        // Validation
        FornecedorItem selectedFornecedor = (FornecedorItem) fornecedorCombo.getSelectedItem();
        if (selectedFornecedor == null || selectedFornecedor.id == null) {
            JOptionPane.showMessageDialog(this, "Selecione um fornecedor.",
                    "Validacao", JOptionPane.WARNING_MESSAGE);
            return;
        }

        if (items.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Adicione pelo menos um produto.",
                    "Validacao", JOptionPane.WARNING_MESSAGE);
            return;
        }

        String dataCompra = dataCompraField.getText().trim();
        double total = items.stream().mapToDouble(i -> i.quantidade * i.precoUnitario).sum();

        try {
            Compra compra = editingCompra != null ? editingCompra : new Compra();
            compra.setFornecedorId(selectedFornecedor.id);
            compra.setDataCompra(dataCompra);
            compra.setTotal(total);
            compra.setStatus("pendente");
            compra.setUserId(SessionManager.getInstance().getCurrentUserId());
            compra.setTenantId(SessionManager.getInstance().getCurrentTenantId());

            if (editingCompra == null) {
                compraService.save(compra);
                JOptionPane.showMessageDialog(this, "Compra criada com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            } else {
                compraService.update(compra);
                JOptionPane.showMessageDialog(this, "Compra atualizada com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            }
            saved = true;
            dispose();
        } catch (Exception ex) {
            logger.error("Erro ao guardar compra", ex);
            JOptionPane.showMessageDialog(this, "Erro ao guardar compra: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
        }
    }

    private Double parseDouble(String text) {
        if (text == null || text.trim().isEmpty()) return null;
        try {
            return Double.parseDouble(text.trim().replace(",", "."));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private void styleBtn(JButton btn, Color bgColor) {
        btn.setFont(btn.getFont().deriveFont(Font.PLAIN, 12f));
        btn.setBackground(bgColor);
        btn.setForeground(Color.WHITE);
        btn.setFocusPainted(false);
    }

    public boolean isSaved() { return saved; }

    // ==================== Helper Classes ====================

    private record FornecedorItem(Long id, String nome) {
        @Override public String toString() { return nome; }
    }

    private record ProdutoItem(Produto produto) {
        @Override public String toString() { return produto.getNome(); }
    }

    static class CompraItemRow {
        Long produtoId;
        String nome;
        double quantidade;
        double precoUnitario;

        CompraItemRow(Long produtoId, String nome, double quantidade, double precoUnitario) {
            this.produtoId = produtoId;
            this.nome = nome;
            this.quantidade = quantidade;
            this.precoUnitario = precoUnitario;
        }
    }

    // ==================== Table Model ====================

    private static class CompraItemsTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private final List<CompraItemRow> items;

        CompraItemsTableModel(String[] columns, List<CompraItemRow> items) {
            this.columns = columns;
            this.items = items;
        }

        @Override public int getRowCount() { return items.size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= items.size()) return null;
            CompraItemRow item = items.get(row);
            return switch (col) {
                case 0 -> item.nome;
                case 1 -> item.quantidade;
                case 2 -> item.precoUnitario;
                case 3 -> item.quantidade * item.precoUnitario;
                case 4 -> "Remover";
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

    private static class ProdutoListCellRenderer extends DefaultListCellRenderer {
        @Override
        public Component getListCellRendererComponent(JList<?> list, Object value, int index,
                                                      boolean isSelected, boolean cellHasFocus) {
            super.getListCellRendererComponent(list, value, index, isSelected, cellHasFocus);
            if (value instanceof ProdutoItem item) {
                Produto p = item.produto;
                setText(p.getNome() + " - Preco Compra: " + (p.getPrecoCompra() != null ? p.getPrecoCompra() : "N/A"));
            }
            return this;
        }
    }
}
