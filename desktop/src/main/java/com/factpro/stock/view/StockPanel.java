package com.factpro.stock.view;

import com.factpro.auth.SessionManager;
import com.factpro.core.util.CurrencyFormatter;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Produto;
import com.factpro.stock.dao.StockMovimentoDAO;
import com.factpro.stock.model.StockMovimento;
import com.factpro.stock.service.StockService;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.CompoundBorder;
import javax.swing.border.EmptyBorder;
import javax.swing.border.LineBorder;
import javax.swing.table.DefaultTableCellRenderer;
import java.awt.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Stock management panel with movements tab and low stock alerts tab.
 */
public class StockPanel extends JPanel {

    private static final Logger logger = LoggerFactory.getLogger(StockPanel.class);

    private final StockService stockService;
    private final ProdutoDAO produtoDAO;

    private JTable movimentosTable;
    private MovimentosTableModel movimentosTableModel;
    private List<StockMovimento> allMovimentos;

    private JTable alertasTable;
    private AlertasTableModel alertasTableModel;
    private List<Produto> lowStockProdutos;

    private static final Color GREEN    = new Color(22, 163, 74);
    private static final Color RED      = new Color(220, 38,  38);
    private static final Color ORANGE   = new Color(234, 88,  12);
    private static final Color BLUE     = new Color(37,  99, 235);
    private static final Color INK      = new Color(15,  23,  42);
    private static final Color MUTED    = new Color(100, 116, 139);
    private static final Color BORDER_C = new Color(226, 232, 240);
    private static final Color SURFACE  = new Color(248, 250, 252);

    private JTextField movSearch;

    public StockPanel() {
        produtoDAO = new ProdutoDAO();
        StockMovimentoDAO stockMovimentoDAO = new StockMovimentoDAO();
        stockService = new StockService(stockMovimentoDAO, produtoDAO);
        allMovimentos = new ArrayList<>();
        lowStockProdutos = new ArrayList<>();

        setLayout(new BorderLayout());
        setBackground(SURFACE);
        setBorder(new EmptyBorder(10, 10, 10, 10));

        initComponents();
        setupLayout();
        loadData();
    }

    private void initComponents() {
        movSearch = new JTextField();
        movSearch.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Pesquisar por produto ou motivo…");
        movSearch.putClientProperty(FlatClientProperties.STYLE,
                "arc:8; innerFocusWidth:2; focusedBorderColor:#2563eb; margin:5,10,5,10");

        // Movimentos table
        String[] movCols = {"Data", "Produto", "Tipo", "Qtd", "Motivo", "Utilizador"};
        movimentosTableModel = new MovimentosTableModel(movCols);
        movimentosTable = new JTable(movimentosTableModel);
        movimentosTable.setRowHeight(32);
        movimentosTable.setShowGrid(false);
        movimentosTable.setIntercellSpacing(new Dimension(0, 0));
        movimentosTable.getTableHeader().setReorderingAllowed(false);
        movimentosTable.getColumnModel().getColumn(0).setPreferredWidth(130);
        movimentosTable.getColumnModel().getColumn(0).setMaxWidth(150);
        movimentosTable.getColumnModel().getColumn(2).setPreferredWidth(100);
        movimentosTable.getColumnModel().getColumn(2).setMaxWidth(120);
        movimentosTable.getColumnModel().getColumn(3).setPreferredWidth(60);
        movimentosTable.getColumnModel().getColumn(3).setMaxWidth(80);
        movimentosTable.getColumnModel().getColumn(5).setPreferredWidth(100);
        movimentosTable.getColumnModel().getColumn(5).setMaxWidth(130);
        movimentosTable.getColumnModel().getColumn(1).setCellRenderer(new ProdutoNameRenderer());
        movimentosTable.getColumnModel().getColumn(2).setCellRenderer(new TipoRenderer());
        movimentosTable.getColumnModel().getColumn(3).setCellRenderer(new CenterRenderer());

        // Alertas table
        String[] alertCols = {"Produto", "Stock Atual", "Mínimo", "Diferença"};
        alertasTableModel = new AlertasTableModel(alertCols);
        alertasTable = new JTable(alertasTableModel);
        alertasTable.setRowHeight(32);
        alertasTable.setShowGrid(false);
        alertasTable.setIntercellSpacing(new Dimension(0, 0));
        alertasTable.getTableHeader().setReorderingAllowed(false);
        alertasTable.getColumnModel().getColumn(1).setPreferredWidth(90);
        alertasTable.getColumnModel().getColumn(1).setMaxWidth(110);
        alertasTable.getColumnModel().getColumn(2).setPreferredWidth(80);
        alertasTable.getColumnModel().getColumn(2).setMaxWidth(100);
        alertasTable.getColumnModel().getColumn(3).setPreferredWidth(80);
        alertasTable.getColumnModel().getColumn(3).setMaxWidth(100);
        alertasTable.getColumnModel().getColumn(1).setCellRenderer(new StockBadgeRenderer());
        alertasTable.getColumnModel().getColumn(2).setCellRenderer(new CenterRenderer());
        alertasTable.getColumnModel().getColumn(3).setCellRenderer(new DiffRenderer());
    }

    private void setupLayout() {
        // ── Header ──────────────────────────────────────────
        JButton btnEntrada = makeBtn("+ Entrada", GREEN);
        JButton btnSaida   = makeBtn("− Saída",   RED);
        JButton btnAjuste  = makeBtn("~ Ajuste",  ORANGE);
        JButton btnRefresh = makeBtn("Atualizar", BLUE);

        JPanel header = new JPanel(new MigLayout("fillx, ins 0 0 10 0", "[grow][]", "[]"));
        header.setOpaque(false);

        JLabel title = new JLabel("Gestão de Stock");
        title.setFont(title.getFont().deriveFont(Font.BOLD, 18f));
        title.setForeground(INK);

        JPanel btnRow = new JPanel(new MigLayout("ins 0, gap 8", "[][][][]", "[36!]"));
        btnRow.setOpaque(false);
        btnRow.add(btnEntrada, "grow");
        btnRow.add(btnSaida,   "grow");
        btnRow.add(btnAjuste,  "grow");
        btnRow.add(btnRefresh, "grow");

        header.add(title,  "left");
        header.add(btnRow, "right");
        add(header, BorderLayout.NORTH);

        // ── Tabs ─────────────────────────────────────────────
        JTabbedPane tabs = new JTabbedPane();
        tabs.putClientProperty(FlatClientProperties.STYLE,
                "tabHeight:36; selectedBackground:#ffffff");

        // Tab 1: Movimentações
        JPanel movTab = new JPanel(new MigLayout("fill, ins 12, gap 8, wrap 1", "[grow]", "[][1!][grow]"));
        movTab.setBackground(Color.WHITE);
        movTab.add(movSearch, "growx, h 40!");
        JSeparator sep1 = new JSeparator();
        sep1.setForeground(BORDER_C);
        movTab.add(sep1, "growx");
        JScrollPane movScroll = new JScrollPane(movimentosTable);
        movScroll.setBorder(BorderFactory.createEmptyBorder());
        movScroll.getViewport().setOpaque(false);
        movTab.add(movScroll, "grow");
        tabs.addTab("Movimentações", movTab);

        // Tab 2: Alertas
        JPanel alertTab = new JPanel(new MigLayout("fill, ins 12, gap 8, wrap 1", "[grow]", "[][1!][grow]"));
        alertTab.setBackground(Color.WHITE);
        alertTab.add(buildAlertSummaryBar(), "growx");
        JSeparator sep2 = new JSeparator();
        sep2.setForeground(BORDER_C);
        alertTab.add(sep2, "growx");
        JScrollPane alertScroll = new JScrollPane(alertasTable);
        alertScroll.setBorder(BorderFactory.createEmptyBorder());
        alertScroll.getViewport().setOpaque(false);
        alertTab.add(alertScroll, "grow");
        tabs.addTab("Alertas de Stock", alertTab);

        add(tabs, BorderLayout.CENTER);

        // Listeners
        btnEntrada.addActionListener(e -> openStockDialog("entrada"));
        btnSaida.addActionListener(e  -> openStockDialog("saida"));
        btnAjuste.addActionListener(e  -> openStockDialog("ajuste"));
        btnRefresh.addActionListener(e -> loadMovimentos());
        movSearch.addKeyListener(new java.awt.event.KeyAdapter() {
            @Override public void keyReleased(java.awt.event.KeyEvent e) {
                filterMovimentos(movSearch.getText());
            }
        });
    }

    private JPanel buildAlertSummaryBar() {
        JPanel bar = new JPanel(new MigLayout("fillx, ins 0, gap 12", "[][grow][]", "[]"));
        bar.setOpaque(false);

        JLabel icon = new JLabel("⚠");
        icon.setFont(icon.getFont().deriveFont(Font.BOLD, 15f));
        icon.setForeground(ORANGE);

        JLabel label = new JLabel("Produtos com stock abaixo do mínimo ou esgotado");
        label.setFont(label.getFont().deriveFont(Font.PLAIN, 13f));
        label.setForeground(MUTED);

        JButton btnRefreshAlertas = makeBtn("Atualizar", BLUE);
        btnRefreshAlertas.addActionListener(e -> loadAlertas());

        bar.add(icon);
        bar.add(label, "left");
        bar.add(btnRefreshAlertas, "right, h 32!");
        return bar;
    }

    private JButton makeBtn(String label, Color bg) {
        String hex = String.format("#%02x%02x%02x", bg.getRed(), bg.getGreen(), bg.getBlue());
        String hov = String.format("#%02x%02x%02x",
                Math.max(0, bg.getRed() - 25),
                Math.max(0, bg.getGreen() - 25),
                Math.max(0, bg.getBlue() - 25));
        JButton btn = new JButton(label);
        btn.putClientProperty(FlatClientProperties.STYLE,
                "arc:8; background:" + hex + "; foreground:#ffffff; font:bold; " +
                "hoverBackground:" + hov + "; borderColor:null");
        btn.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        return btn;
    }

    private void filterMovimentos(String query) {
        if (query == null || query.isBlank()) {
            movimentosTableModel.setMovimentos(allMovimentos);
            return;
        }
        String q = query.toLowerCase();
        List<StockMovimento> filtered = allMovimentos.stream()
                .filter(m -> (m.getTipo()   != null && m.getTipo().toLowerCase().contains(q))
                          || (m.getMotivo() != null && m.getMotivo().toLowerCase().contains(q)))
                .toList();
        movimentosTableModel.setMovimentos(filtered);
    }

    private void openStockDialog(String tipo) {
        StockMovimentoDialog dialog = new StockMovimentoDialog(
                (Frame) SwingUtilities.getWindowAncestor(this), tipo, stockService, produtoDAO);
        dialog.setVisible(true);
        if (dialog.isSaved()) {
            loadMovimentos();
            loadAlertas();
        }
    }

    private void loadData() {
        loadMovimentos();
        loadAlertas();
    }

    private void loadMovimentos() {
        allMovimentos = stockService.findAll();
        movimentosTableModel.setMovimentos(allMovimentos);
    }

    private void loadAlertas() {
        lowStockProdutos = stockService.getLowStockAlerts();
        alertasTableModel.setProdutos(lowStockProdutos);
    }


    // ==================== Table Models ====================

    private static class MovimentosTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private List<StockMovimento> movimentos = new ArrayList<>();
        private final ProdutoDAO produtoDAO = new ProdutoDAO();

        MovimentosTableModel(String[] columns) { this.columns = columns; }

        void setMovimentos(List<StockMovimento> movimentos) {
            this.movimentos = movimentos;
            fireTableDataChanged();
        }

        @Override public int getRowCount() { return movimentos.size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= movimentos.size()) return null;
            StockMovimento m = movimentos.get(row);
            return switch (col) {
                case 0 -> m.getCriadoEm() != null ? m.getCriadoEm().substring(0, 16) : "-";
                case 1 -> m.getProdutoId(); // ProdutoNameRenderer resolves the name
                case 2 -> formatTipo(m.getTipo());
                case 3 -> m.getQuantidade() != null ? m.getQuantidade() : 0;
                case 4 -> m.getMotivo() != null ? m.getMotivo() : "-";
                case 5 -> m.getUserId() != null ? "User #" + m.getUserId() : "-";
                default -> null;
            };
        }
    }

    private static class AlertasTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private List<Produto> produtos = new ArrayList<>();

        AlertasTableModel(String[] columns) { this.columns = columns; }

        void setProdutos(List<Produto> produtos) {
            this.produtos = produtos;
            fireTableDataChanged();
        }

        @Override public int getRowCount() { return produtos.size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= produtos.size()) return null;
            Produto p = produtos.get(row);
            int stock = p.getStockAtual() != null ? p.getStockAtual() : 0;
            int minimo = p.getStockMinimo() != null ? p.getStockMinimo() : 0;
            int diff = stock - minimo;
            return switch (col) {
                case 0 -> p.getNome();
                case 1 -> stock;
                case 2 -> minimo;
                case 3 -> diff;
                default -> null;
            };
        }
    }

    // ==================== Renderers ====================

    private static class ProdutoNameRenderer extends DefaultTableCellRenderer {
        private final ProdutoDAO produtoDAO = new ProdutoDAO();

        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            if (value instanceof Long produtoId) {
                Produto p = produtoDAO.findById(produtoId);
                setText(p != null ? p.getNome() : "Produto #" + produtoId);
            } else {
                setText(value != null ? value.toString() : "-");
            }
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

    private static class StockBadgeRenderer extends DefaultTableCellRenderer {
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            if (value instanceof Number) {
                int stock = ((Number) value).intValue();
                if (stock <= 0) {
                    setBackground(RED);
                    setForeground(Color.WHITE);
                    setText("ESGOTADO");
                } else {
                    setBackground(ORANGE);
                    setForeground(Color.WHITE);
                    setText(String.valueOf(stock));
                }
            }
            setHorizontalAlignment(SwingConstants.CENTER);
            return this;
        }
    }

    private static class DiffRenderer extends DefaultTableCellRenderer {
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            if (value instanceof Number) {
                int diff = ((Number) value).intValue();
                if (diff <= 0) {
                    setForeground(RED);
                } else {
                    setForeground(GREEN);
                }
                setText(String.valueOf(diff));
            }
            setHorizontalAlignment(SwingConstants.CENTER);
            return this;
        }
    }

    private static class TipoRenderer extends DefaultTableCellRenderer {
        private static final Color ENTRADA_BG = new Color(220, 252, 231);
        private static final Color ENTRADA_FG = new Color(22, 101, 52);
        private static final Color SAIDA_BG   = new Color(254, 226, 226);
        private static final Color SAIDA_FG   = new Color(153, 27,  27);
        private static final Color AJUSTE_BG  = new Color(254, 243, 199);
        private static final Color AJUSTE_FG  = new Color(146, 64,  14);

        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            String v = value != null ? value.toString() : "";
            if (!isSelected) {
                if (v.startsWith("Entrada")) {
                    setBackground(ENTRADA_BG); setForeground(ENTRADA_FG);
                } else if (v.startsWith("Saída") || v.startsWith("Saida")) {
                    setBackground(SAIDA_BG); setForeground(SAIDA_FG);
                } else {
                    setBackground(AJUSTE_BG); setForeground(AJUSTE_FG);
                }
            }
            setHorizontalAlignment(SwingConstants.CENTER);
            return this;
        }
    }

    private static String formatTipo(String tipo) {
        if (tipo == null) return "-";
        return switch (tipo.toLowerCase()) {
            case "entrada" -> "Entrada";
            case "saida" -> "Saida";
            case "ajuste_positivo" -> "Ajuste (+)";
            case "ajuste_negativo" -> "Ajuste (-)";
            default -> tipo;
        };
    }
}
