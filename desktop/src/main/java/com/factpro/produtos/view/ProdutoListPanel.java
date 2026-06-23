package com.factpro.produtos.view;

import com.factpro.core.util.CurrencyFormatter;
import com.factpro.produtos.dao.CategoriaDAO;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Produto;
import com.factpro.produtos.service.ProdutoService;
import com.factpro.stock.dao.StockMovimentoDAO;
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
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

/**
 * Product list panel with search, CRUD actions, and CSV import/export.
 */
public class ProdutoListPanel extends JPanel {

    private static final Logger logger = LoggerFactory.getLogger(ProdutoListPanel.class);

    private final ProdutoDAO produtoDAO;
    private final CategoriaDAO categoriaDAO;
    private final StockMovimentoDAO stockMovimentoDAO;
    private final ProdutoService produtoService;

    private JTextField searchField;
    private JTable productsTable;
    private ProdutoTableModel tableModel;
    private List<Produto> allProducts;

    // Button references
    private JButton btnNovo;

    private static final Color GREEN    = new Color(22, 163, 74);
    private static final Color RED      = new Color(220, 38,  38);
    private static final Color BLUE     = new Color(37,  99, 235);
    private static final Color ORANGE   = new Color(234, 88,  12);
    private static final Color INK      = new Color(15,  23,  42);
    private static final Color MUTED    = new Color(100, 116, 139);
    private static final Color BORDER_C = new Color(226, 232, 240);
    private static final Color SURFACE  = new Color(248, 250, 252);

    public ProdutoListPanel() {
        produtoDAO = new ProdutoDAO();
        categoriaDAO = new CategoriaDAO();
        stockMovimentoDAO = new StockMovimentoDAO();
        produtoService = new ProdutoService(produtoDAO, categoriaDAO, stockMovimentoDAO);
        allProducts = new ArrayList<>();

        setLayout(new BorderLayout());
        setBackground(SURFACE);
        setBorder(new EmptyBorder(10, 10, 10, 10));

        initComponents();
        setupLayout();
        setupListeners();
        loadProducts();
    }

    private void initComponents() {
        searchField = new JTextField();
        searchField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Pesquisar por nome, código ou SKU…");
        searchField.putClientProperty(FlatClientProperties.STYLE,
                "arc:8; innerFocusWidth:2; focusedBorderColor:#2563eb; margin:5,10,5,10");

        String[] cols = {"Código", "Nome", "Categoria", "Preço", "Stock", ""};
        tableModel = new ProdutoTableModel(cols);
        productsTable = new JTable(tableModel);
        productsTable.setRowHeight(32);
        productsTable.setShowGrid(false);
        productsTable.setIntercellSpacing(new Dimension(0, 0));
        productsTable.getTableHeader().setReorderingAllowed(false);
        productsTable.getColumnModel().getColumn(0).setPreferredWidth(110);
        productsTable.getColumnModel().getColumn(0).setMaxWidth(130);
        productsTable.getColumnModel().getColumn(2).setPreferredWidth(120);
        productsTable.getColumnModel().getColumn(2).setMaxWidth(160);
        productsTable.getColumnModel().getColumn(3).setPreferredWidth(100);
        productsTable.getColumnModel().getColumn(3).setMaxWidth(130);
        productsTable.getColumnModel().getColumn(4).setPreferredWidth(90);
        productsTable.getColumnModel().getColumn(4).setMaxWidth(120);
        productsTable.getColumnModel().getColumn(5).setPreferredWidth(100);
        productsTable.getColumnModel().getColumn(5).setMaxWidth(110);
        productsTable.getColumnModel().getColumn(3).setCellRenderer(new CurrencyRenderer());
        productsTable.getColumnModel().getColumn(4).setCellRenderer(new StockBadgeRenderer());
        productsTable.getColumnModel().getColumn(5).setCellRenderer(new ActionRenderer());
        productsTable.getColumnModel().getColumn(5).setCellEditor(new ActionEditor());
    }

    private void setupLayout() {
        JPanel north = new JPanel(new MigLayout("fillx, ins 0, gap 0, wrap 1", "[grow]"));
        north.setOpaque(false);

        // Header: title + action buttons
        JPanel header = new JPanel(new MigLayout("fillx, ins 0 0 8 0", "[grow][]", "[]"));
        header.setOpaque(false);
        JLabel title = new JLabel("Catálogo de Produtos");
        title.setFont(title.getFont().deriveFont(Font.BOLD, 18f));
        title.setForeground(INK);
        btnNovo = makeBtn("+ Novo Produto", GREEN);
        JButton btnImportar = makeBtn("Importar CSV", new Color(71, 85, 105));
        JButton btnExportar = makeBtn("Exportar CSV", new Color(71, 85, 105));
        JPanel btnRow = new JPanel(new MigLayout("ins 0, gap 8", "[][][]", "[36!]"));
        btnRow.setOpaque(false);
        btnRow.add(btnNovo,     "grow");
        btnRow.add(btnImportar, "grow");
        btnRow.add(btnExportar, "grow");
        header.add(title,  "left");
        header.add(btnRow, "right");
        north.add(header, "growx");

        // Search bar
        JButton btnSearch = makeBtn("Pesquisar", BLUE);
        JPanel searchRow = new JPanel(new MigLayout("fillx, ins 0 0 8 0, gap 8", "[grow][]", "[40!]"));
        searchRow.setOpaque(false);
        searchRow.add(searchField, "grow");
        searchRow.add(btnSearch,   "h 40!");
        north.add(searchRow, "growx");

        add(north, BorderLayout.NORTH);

        JScrollPane scroll = new JScrollPane(productsTable);
        scroll.setBorder(BorderFactory.createLineBorder(BORDER_C));
        add(scroll, BorderLayout.CENTER);

        btnSearch.addActionListener(e -> searchProducts());
        btnNovo.addActionListener(e -> openNewDialog());
        btnImportar.addActionListener(e -> importCSV());
        btnExportar.addActionListener(e -> exportCSV());
    }

    private JButton makeBtn(String label, Color bg) {
        String hex = String.format("#%02x%02x%02x", bg.getRed(), bg.getGreen(), bg.getBlue());
        String hov = String.format("#%02x%02x%02x",
                Math.max(0, bg.getRed()   - 25),
                Math.max(0, bg.getGreen() - 25),
                Math.max(0, bg.getBlue()  - 25));
        JButton btn = new JButton(label);
        btn.putClientProperty(FlatClientProperties.STYLE,
                "arc:8; background:" + hex + "; foreground:#ffffff; font:bold; " +
                "hoverBackground:" + hov + "; borderColor:null");
        btn.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        return btn;
    }

    private void setupListeners() {
        // Double-click opens edit dialog
        productsTable.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                if (e.getClickCount() == 2) {
                    int row = productsTable.rowAtPoint(e.getPoint());
                    if (row >= 0 && row < tableModel.getRowCount()) {
                        Produto produto = tableModel.getProdutoAt(row);
                        if (produto != null) openEditDialog(produto);
                    }
                }
            }
        });
    }

    private void loadProducts() {
        allProducts = produtoService.findAll();
        tableModel.setProducts(allProducts);
    }

    private void searchProducts() {
        String query = searchField.getText().trim();
        if (query.isEmpty()) {
            tableModel.setProducts(allProducts);
            return;
        }
        List<Produto> results = produtoService.search(query);
        tableModel.setProducts(results);
    }

    private void openNewDialog() {
        ProdutoFormDialog dialog = new ProdutoFormDialog(
                (Frame) SwingUtilities.getWindowAncestor(this), null);
        dialog.setVisible(true);
        if (dialog.isSaved()) loadProducts();
    }

    private void openEditDialog(Produto produto) {
        ProdutoFormDialog dialog = new ProdutoFormDialog(
                (Frame) SwingUtilities.getWindowAncestor(this), produto);
        dialog.setVisible(true);
        if (dialog.isSaved()) loadProducts();
    }

    private void deleteProduto(Produto produto) {
        int confirm = JOptionPane.showConfirmDialog(this,
                "Deseja realmente eliminar o produto \"" + produto.getNome() + "\"?",
                "Confirmar Eliminacao",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.WARNING_MESSAGE);

        if (confirm == JOptionPane.YES_OPTION) {
            boolean deleted = produtoService.delete(produto.getId());
            if (deleted) {
                JOptionPane.showMessageDialog(this, "Produto eliminado com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                loadProducts();
            } else {
                JOptionPane.showMessageDialog(this, "Erro ao eliminar o produto.",
                        "Erro", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    private void importCSV() {
        JFileChooser chooser = new JFileChooser();
        chooser.setFileFilter(new javax.swing.filechooser.FileNameExtensionFilter("CSV Files", "csv"));
        if (chooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
            File file = chooser.getSelectedFile();
            try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
                String line;
                boolean header = true;
                int count = 0;
                while ((line = reader.readLine()) != null) {
                    if (header) { header = false; continue; }
                    String[] parts = line.split(",", -1);
                    if (parts.length >= 5) {
                        Produto p = new Produto();
                        p.setNome(parts[0].trim());
                        p.setCodigoBarras(parts.length > 1 ? parts[1].trim() : null);
                        p.setSku(parts.length > 2 ? parts[2].trim() : null);
                        try { p.setPrecoVenda(Double.parseDouble(parts[3].trim())); } catch (Exception ignored) {}
                        try { p.setStockAtual(Integer.parseInt(parts[4].trim())); } catch (Exception ignored) {}
                        p.setAtivo(true);
                        p.setStockMinimo(5);
                        p.setUnidadeMedida("un");
                        produtoService.save(p);
                        count++;
                    }
                }
                JOptionPane.showMessageDialog(this, count + " produtos importados com sucesso.",
                        "Importacao CSV", JOptionPane.INFORMATION_MESSAGE);
                loadProducts();
            } catch (IOException e) {
                logger.error("Erro ao importar CSV", e);
                JOptionPane.showMessageDialog(this, "Erro ao importar CSV: " + e.getMessage(),
                        "Erro", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    private void exportCSV() {
        JFileChooser chooser = new JFileChooser();
        chooser.setSelectedFile(new File("produtos_export.csv"));
        chooser.setFileFilter(new javax.swing.filechooser.FileNameExtensionFilter("CSV Files", "csv"));
        if (chooser.showSaveDialog(this) == JFileChooser.APPROVE_OPTION) {
            File file = chooser.getSelectedFile();
            try (PrintWriter writer = new PrintWriter(new FileWriter(file))) {
                writer.println("Nome,Codigo Barras,SKU,Preco Venda,Stock");
                for (Produto p : allProducts) {
                    writer.printf("%s,%s,%s,%.2f,%d%n",
                            escapeCSV(p.getNome()),
                            escapeCSV(p.getCodigoBarras()),
                            escapeCSV(p.getSku()),
                            p.getPrecoVenda() != null ? p.getPrecoVenda() : 0.0,
                            p.getStockAtual() != null ? p.getStockAtual() : 0);
                }
                JOptionPane.showMessageDialog(this, "Dados exportados com sucesso.",
                        "Exportacao CSV", JOptionPane.INFORMATION_MESSAGE);
            } catch (IOException e) {
                logger.error("Erro ao exportar CSV", e);
                JOptionPane.showMessageDialog(this, "Erro ao exportar CSV: " + e.getMessage(),
                        "Erro", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    private String escapeCSV(String value) {
        if (value == null) return "";
        if (value.contains(",") || value.contains("\"") || value.contains("\n")) {
            return "\"" + value.replace("\"", "\"\"") + "\"";
        }
        return value;
    }

    // ==================== Table Model ====================

    private static class ProdutoTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private List<Produto> products = new ArrayList<>();

        ProdutoTableModel(String[] columns) { this.columns = columns; }

        void setProducts(List<Produto> products) {
            this.products = products;
            fireTableDataChanged();
        }

        Produto getProdutoAt(int row) {
            return (row >= 0 && row < products.size()) ? products.get(row) : null;
        }

        @Override public int getRowCount() { return products.size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= products.size()) return null;
            Produto p = products.get(row);
            return switch (col) {
                case 0 -> p.getCodigoBarras() != null ? p.getCodigoBarras() : p.getSku();
                case 1 -> p.getNome();
                case 2 -> p.getCategoriaId() != null ? "Cat#" + p.getCategoriaId() : "-";
                case 3 -> p.getPrecoVenda() != null ? p.getPrecoVenda() : 0.0;
                case 4 -> p.getStockAtual() != null ? p.getStockAtual() : 0;
                case 5 -> "Editar | Eliminar";
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

    private static class StockBadgeRenderer extends DefaultTableCellRenderer {
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            if (value instanceof Number) {
                int stock = ((Number) value).intValue();
                if (stock <= 0) {
                    setForeground(RED);
                    setText("Esgotado");
                } else if (stock <= 5) {
                    setForeground(ORANGE);
                    setText("Baixo (" + stock + ")");
                } else {
                    setForeground(GREEN);
                    setText(String.valueOf(stock));
                }
            }
            setHorizontalAlignment(SwingConstants.CENTER);
            return this;
        }
    }

    private static class ActionRenderer extends JPanel implements javax.swing.table.TableCellRenderer {
        private static final Color EDIT_BLUE = new Color(57, 113, 227);
        private static final Color DELETE_RED = new Color(220, 53, 69);
        private final JButton editBtn = new JButton("Editar");
        private final JButton deleteBtn = new JButton("X");

        ActionRenderer() {
            setLayout(new FlowLayout(FlowLayout.CENTER, 3, 0));
            editBtn.setFont(editBtn.getFont().deriveFont(Font.PLAIN, 10f));
            editBtn.setBackground(EDIT_BLUE);
            editBtn.setForeground(Color.WHITE);
            editBtn.setFocusPainted(false);
            editBtn.setPreferredSize(new Dimension(50, 20));
            deleteBtn.setFont(deleteBtn.getFont().deriveFont(Font.BOLD, 10f));
            deleteBtn.setBackground(DELETE_RED);
            deleteBtn.setForeground(Color.WHITE);
            deleteBtn.setFocusPainted(false);
            deleteBtn.setPreferredSize(new Dimension(24, 20));
            add(editBtn);
            add(deleteBtn);
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
        private final JButton editBtn = new JButton("Editar");
        private final JButton deleteBtn = new JButton("X");
        private Produto currentProduto;

        ActionEditor() {
            editBtn.setFont(editBtn.getFont().deriveFont(Font.PLAIN, 10f));
            editBtn.setBackground(new Color(57, 113, 227));
            editBtn.setForeground(Color.WHITE);
            editBtn.setFocusPainted(false);
            editBtn.setPreferredSize(new Dimension(50, 20));
            deleteBtn.setFont(deleteBtn.getFont().deriveFont(Font.BOLD, 10f));
            deleteBtn.setBackground(new Color(220, 53, 69));
            deleteBtn.setForeground(Color.WHITE);
            deleteBtn.setFocusPainted(false);
            deleteBtn.setPreferredSize(new Dimension(24, 20));

            editBtn.addActionListener(e -> {
                fireEditingStopped();
                if (currentProduto != null) openEditDialog(currentProduto);
            });
            deleteBtn.addActionListener(e -> {
                fireEditingStopped();
                if (currentProduto != null) deleteProduto(currentProduto);
            });

            panel.add(editBtn);
            panel.add(deleteBtn);
        }

        @Override
        public Component getTableCellEditorComponent(JTable table, Object value,
                                                     boolean isSelected, int row, int col) {
            currentProduto = tableModel.getProdutoAt(row);
            panel.setBackground(isSelected ? table.getSelectionBackground() : table.getBackground());
            return panel;
        }

        @Override public Object getCellEditorValue() { return ""; }
    }
}
