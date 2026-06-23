package com.factpro.vendas.view;

import com.factpro.clientes.dao.ClienteDAO;
import com.factpro.contas.dao.ContaReceberDAO;
import com.factpro.core.util.CurrencyFormatter;
import com.factpro.produtos.dao.CategoriaDAO;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.service.ProdutoService;
import com.factpro.relatorios.service.RelatorioService;
import com.factpro.stock.dao.StockMovimentoDAO;
import com.factpro.vendas.dao.VendaDAO;
import com.factpro.vendas.dao.VendaItemDAO;
import com.factpro.vendas.model.Venda;
import net.miginfocom.swing.MigLayout;
import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.CategoryPlot;
import org.jfree.chart.renderer.category.BarRenderer;
import org.jfree.data.category.DefaultCategoryDataset;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.table.DefaultTableCellRenderer;
import java.awt.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

/**
 * Dashboard panel with sales statistics, charts, and quick actions.
 */
public class DashboardPanel extends JPanel {

    private static final Logger logger = LoggerFactory.getLogger(DashboardPanel.class);

    private final VendaDAO vendaDAO;
    private final ProdutoDAO produtoDAO;
    private final StockMovimentoDAO stockMovimentoDAO;
    private final VendaItemDAO vendaItemDAO;
    private final RelatorioService relatorioService;
    private final ProdutoService produtoService;

    private JLabel vendasHojeCountLabel;
    private JLabel vendasHojeTotalLabel;
    private JLabel lowStockCountLabel;
    private JLabel clientesPendentesLabel;
    private JLabel lucroLabel;
    private JTable topProdutosTable;
    private Timer refreshTimer;

    private static final Color GREEN    = new Color(22, 163, 74);
    private static final Color ORANGE   = new Color(234, 88,  12);
    private static final Color BLUE     = new Color(37,  99, 235);
    private static final Color PURPLE   = new Color(124, 58, 237);
    private static final Color INK      = new Color(15,  23,  42);
    private static final Color MUTED    = new Color(100, 116, 139);
    private static final Color BORDER_C = new Color(226, 232, 240);
    private static final Color SURFACE  = new Color(248, 250, 252);

    private DefaultCategoryDataset chartDataset;

    public DashboardPanel() {
        vendaDAO = new VendaDAO();
        produtoDAO = new ProdutoDAO();
        stockMovimentoDAO = new StockMovimentoDAO();
        vendaItemDAO = new VendaItemDAO();
        relatorioService = new RelatorioService(vendaDAO, produtoDAO, new ClienteDAO(),
                stockMovimentoDAO, vendaItemDAO, new CategoriaDAO(), new ContaReceberDAO());
        produtoService = new ProdutoService(produtoDAO, null, stockMovimentoDAO);

        setLayout(new BorderLayout());
        setBackground(SURFACE);
        setBorder(new EmptyBorder(12, 12, 12, 12));

        initComponents();
        setupLayout();
        refreshData();
        startAutoRefresh();
    }

    private void initComponents() {
        vendasHojeCountLabel = new JLabel("0");
        vendasHojeCountLabel.setFont(vendasHojeCountLabel.getFont().deriveFont(Font.BOLD, 32f));
        vendasHojeCountLabel.setForeground(INK);

        vendasHojeTotalLabel = new JLabel("0,00 MT");
        vendasHojeTotalLabel.setFont(vendasHojeTotalLabel.getFont().deriveFont(Font.PLAIN, 12f));
        vendasHojeTotalLabel.setForeground(GREEN);

        lowStockCountLabel = new JLabel("0");
        lowStockCountLabel.setFont(lowStockCountLabel.getFont().deriveFont(Font.BOLD, 32f));
        lowStockCountLabel.setForeground(INK);

        clientesPendentesLabel = new JLabel("0");
        clientesPendentesLabel.setFont(clientesPendentesLabel.getFont().deriveFont(Font.BOLD, 32f));
        clientesPendentesLabel.setForeground(INK);

        lucroLabel = new JLabel("0,00 MT");
        lucroLabel.setFont(lucroLabel.getFont().deriveFont(Font.BOLD, 18f));
        lucroLabel.setForeground(INK);

        // Top products table
        String[] cols = {"#", "Produto", "Qtd", "Receita"};
        topProdutosTable = new JTable(new TopProdutosTableModel(cols));
        topProdutosTable.setRowHeight(30);
        topProdutosTable.setShowGrid(false);
        topProdutosTable.setIntercellSpacing(new Dimension(0, 0));
        topProdutosTable.getTableHeader().setReorderingAllowed(false);
        topProdutosTable.getColumnModel().getColumn(0).setMaxWidth(28);
        topProdutosTable.getColumnModel().getColumn(2).setMaxWidth(50);
        topProdutosTable.getColumnModel().getColumn(2).setCellRenderer(new CenterRenderer());
        topProdutosTable.getColumnModel().getColumn(3).setCellRenderer(new CurrencyRenderer());
    }

    private void setupLayout() {
        JPanel main = new JPanel(new MigLayout(
                "fill, ins 0, gap 12, wrap 4",
                "[grow][grow][grow][grow]",
                "[106!][grow][54!]"));
        main.setOpaque(false);

        // Row 1 — stat cards
        main.add(createStatCard("VENDAS HOJE",       vendasHojeCountLabel,    vendasHojeTotalLabel,         GREEN),  "grow");
        main.add(createStatCard("STOCK BAIXO",       lowStockCountLabel,      newMuted("produtos em alerta"), ORANGE), "grow");
        main.add(createStatCard("CLIENTES PENDENTES",clientesPendentesLabel,  newMuted("aguardando pag."),    BLUE),   "grow");
        main.add(createStatCard("LUCRO ESTIMADO",    lucroLabel,              newMuted("mês corrente"),       PURPLE), "grow");

        // Row 2 — chart (3 cols) + top products (1 col)
        main.add(createChartPanel(),       "span 3, grow");
        main.add(createTopProductsPanel(), "grow");

        // Row 3 — quick actions
        main.add(buildActionsPanel(), "span 4, growx");

        add(main, BorderLayout.CENTER);
    }

    private JLabel newMuted(String text) {
        JLabel l = new JLabel(text);
        l.setFont(l.getFont().deriveFont(Font.PLAIN, 11f));
        l.setForeground(MUTED);
        return l;
    }

    private JPanel createStatCard(String title, JLabel valueLabel, JLabel subLabel, Color accent) {
        JPanel card = new JPanel(new MigLayout("fill, ins 14 16 12 16, wrap 1", "[grow]", "[]6[]4[]")) {
            @Override
            protected void paintComponent(Graphics g) {
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
                g2.setColor(Color.WHITE);
                g2.fillRect(0, 0, getWidth(), getHeight());
                g2.setColor(accent);
                g2.fillRect(0, 0, getWidth(), 4);
                g2.setColor(BORDER_C);
                g2.drawRect(0, 0, getWidth() - 1, getHeight() - 1);
                g2.dispose();
            }
        };
        card.setOpaque(false);

        JLabel titleLabel = new JLabel(title);
        titleLabel.setFont(titleLabel.getFont().deriveFont(Font.BOLD, 10f));
        titleLabel.setForeground(MUTED);

        card.add(titleLabel);
        card.add(valueLabel);
        card.add(subLabel);

        return card;
    }

    private JPanel createChartPanel() {
        JPanel panel = new JPanel(new MigLayout("fill, ins 14 16 12 16, wrap 1", "[grow]", "[][grow]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createLineBorder(BORDER_C));

        JLabel title = new JLabel("Vendas — Últimos 7 Dias");
        title.setFont(title.getFont().deriveFont(Font.BOLD, 13f));
        title.setForeground(INK);
        panel.add(title, "gapbottom 4");

        chartDataset = new DefaultCategoryDataset();
        LocalDate today = LocalDate.now();
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM");
        for (int i = 6; i >= 0; i--) {
            chartDataset.addValue(0.0, "Vendas", today.minusDays(i).format(fmt));
        }

        JFreeChart chart = ChartFactory.createBarChart(
                null, null, "MT", chartDataset,
                org.jfree.chart.plot.PlotOrientation.VERTICAL, false, true, false);

        chart.setBackgroundPaint(Color.WHITE);
        chart.getPlot().setBackgroundPaint(Color.WHITE);
        chart.getPlot().setOutlineVisible(false);

        CategoryPlot plot = chart.getCategoryPlot();
        plot.setRangeGridlinePaint(BORDER_C);
        plot.setDomainGridlinesVisible(false);

        BarRenderer renderer = new BarRenderer();
        renderer.setSeriesPaint(0, BLUE);
        renderer.setShadowVisible(false);
        renderer.setBarPainter(new org.jfree.chart.renderer.category.StandardBarPainter());
        renderer.setMaximumBarWidth(0.06);
        plot.setRenderer(renderer);

        ChartPanel cp = new ChartPanel(chart);
        cp.setDomainZoomable(false);
        cp.setRangeZoomable(false);
        cp.setMouseWheelEnabled(false);
        cp.setBackground(Color.WHITE);
        panel.add(cp, "grow");

        return panel;
    }

    private JPanel createTopProductsPanel() {
        JPanel panel = new JPanel(new MigLayout("fill, ins 14 16 12 16, wrap 1", "[grow]", "[][grow]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createLineBorder(BORDER_C));

        JLabel title = new JLabel("Top 5 Produtos");
        title.setFont(title.getFont().deriveFont(Font.BOLD, 13f));
        title.setForeground(INK);
        panel.add(title, "gapbottom 4");

        JScrollPane scroll = new JScrollPane(topProdutosTable);
        scroll.setBorder(BorderFactory.createEmptyBorder());
        scroll.getViewport().setOpaque(false);
        panel.add(scroll, "grow");

        return panel;
    }

    private JPanel buildActionsPanel() {
        JPanel p = new JPanel(new MigLayout("fill, ins 0, gap 12", "[grow][grow][grow]", "[grow]"));
        p.setOpaque(false);

        JButton btnNovaVenda   = makeActionButton("Nova Venda",   GREEN);
        JButton btnNovoProduto = makeActionButton("Novo Produto", BLUE);
        JButton btnNovoCliente = makeActionButton("Novo Cliente", PURPLE);

        p.add(btnNovaVenda,   "grow");
        p.add(btnNovoProduto, "grow");
        p.add(btnNovoCliente, "grow");
        return p;
    }

    private JButton makeActionButton(String label, Color bg) {
        String hex = String.format("#%02x%02x%02x", bg.getRed(), bg.getGreen(), bg.getBlue());
        int r = Math.max(0, bg.getRed()   - 30);
        int gr = Math.max(0, bg.getGreen() - 30);
        int b = Math.max(0, bg.getBlue()  - 30);
        String hoverHex = String.format("#%02x%02x%02x", r, gr, b);
        JButton btn = new JButton(label);
        btn.putClientProperty(com.formdev.flatlaf.FlatClientProperties.STYLE,
                "arc:10; background:" + hex + "; foreground:#ffffff; font:bold +1; " +
                "hoverBackground:" + hoverHex + "; borderColor:null");
        btn.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        return btn;
    }


    /** Holds all data fetched in the background. */
    private static class DashboardData {
        int vendasHojeCount;
        double vendasHojeTotal;
        int lowStockCount;
        double lucroEstimado;
        List<Venda> vendas;
        List<Map<String, Object>> topProdutos;
    }

    private void refreshData() {
        // Show loading state
        vendasHojeCountLabel.setText("…");
        vendasHojeTotalLabel.setText("…");
        lowStockCountLabel.setText("…");
        lucroLabel.setText("…");

        new SwingWorker<DashboardData, Void>() {
            @Override
            protected DashboardData doInBackground() {
                DashboardData d = new DashboardData();
                try {
                    d.vendasHojeCount = vendaDAO.countToday();
                    d.vendasHojeTotal = vendaDAO.sumTodayTotal();
                    d.lowStockCount   = produtoService.findLowStock().size();

                    String today     = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE);
                    String startDate = today.substring(0, 8) + "01";
                    d.lucroEstimado  = relatorioService.getLucroEstimado(startDate, today);
                    d.vendas         = vendaDAO.findAll();
                    d.topProdutos    = relatorioService.getTopProdutos(startDate, today);
                } catch (Exception e) {
                    logger.error("Erro ao carregar dados do dashboard", e);
                }
                return d;
            }

            @Override
            protected void done() {
                try {
                    DashboardData d = get();
                    if (d == null) return;

                    vendasHojeCountLabel.setText(String.valueOf(d.vendasHojeCount));
                    vendasHojeTotalLabel.setText(CurrencyFormatter.format(d.vendasHojeTotal));
                    lowStockCountLabel.setText(String.valueOf(d.lowStockCount));
                    clientesPendentesLabel.setText("0");
                    lucroLabel.setText(CurrencyFormatter.format(d.lucroEstimado));

                    // Chart
                    if (chartDataset != null && d.vendas != null) {
                        chartDataset.clear();
                        LocalDate today = LocalDate.now();
                        DateTimeFormatter fmt   = DateTimeFormatter.ofPattern("dd/MM");
                        DateTimeFormatter dbFmt = DateTimeFormatter.ISO_LOCAL_DATE;
                        for (int i = 6; i >= 0; i--) {
                            LocalDate day = today.minusDays(i);
                            double dayTotal = d.vendas.stream()
                                    .filter(v -> v.getCriadaEm() != null
                                            && v.getCriadaEm().startsWith(day.format(dbFmt))
                                            && !"cancelada".equals(v.getStatus()))
                                    .mapToDouble(Venda::getTotal)
                                    .sum();
                            chartDataset.addValue(dayTotal, "Vendas", day.format(fmt));
                        }
                    }

                    // Top products
                    if (d.topProdutos != null) {
                        TopProdutosTableModel model = (TopProdutosTableModel) topProdutosTable.getModel();
                        model.setData(d.topProdutos);
                    }

                    logger.debug("Dashboard carregado com sucesso");
                } catch (Exception e) {
                    logger.error("Erro ao atualizar UI do dashboard", e);
                }
            }
        }.execute();
    }

    private void startAutoRefresh() {
        refreshTimer = new Timer(5 * 60 * 1000, e -> refreshData()); // 5 minutes
        refreshTimer.start();
    }

    public void dispose() {
        if (refreshTimer != null) refreshTimer.stop();
    }

    // ==================== Table Model ====================

    private static class TopProdutosTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private List<Map<String, Object>> data = new java.util.ArrayList<>();

        TopProdutosTableModel(String[] columns) { this.columns = columns; }

        void setData(List<Map<String, Object>> data) {
            this.data = data;
            fireTableDataChanged();
        }

        @Override public int getRowCount() { return Math.min(data.size(), 5); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row >= data.size()) return null;
            Map<String, Object> map = data.get(row);
            return switch (col) {
                case 0 -> row + 1;
                case 1 -> map.get("produtoNome");
                case 2 -> map.get("quantidadeVendida");
                case 3 -> map.get("receitaEstimada");
                default -> null;
            };
        }
    }

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
