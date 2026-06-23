package com.factpro.relatorios.view;

import com.factpro.contas.dao.ContaReceberDAO;
import com.factpro.produtos.dao.CategoriaDAO;
import com.factpro.relatorios.service.RelatorioService;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.data.category.DefaultCategoryDataset;
import org.jfree.data.general.DefaultPieDataset;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.NumberFormat;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Reports panel with sidebar navigation, date range selector, charts, and export.
 */
public class RelatoriosPanel extends JPanel {

    private final RelatorioService relatorioService;
    private final CategoriaDAO categoriaDAO;
    private final ContaReceberDAO contaReceberDAO;

    // Sidebar
    private JList<String> reportList;

    // Date range
    private JTextField startDateField;
    private JTextField endDateField;

    // Content area
    private JPanel contentPanel;
    private ChartPanel chartPanel;
    private JTable resultsTable;

    private JButton gerarButton;
    private JButton exportPdfButton;
    private JButton exportExcelButton;

    private enum ReportType {
        VENDAS("Vendas (por per\u00edodo)"),
        PRODUTOS("Produtos Mais Vendidos"),
        STOCK("Stock"),
        CLIENTES("Clientes"),
        CONTAS("Contas a Receber"),
        FECHO("Fecho de Caixa");

        private final String label;

        ReportType(String label) {
            this.label = label;
        }

        @Override
        public String toString() {
            return label;
        }
    }

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    public RelatoriosPanel(RelatorioService relatorioService, CategoriaDAO categoriaDAO,
                           ContaReceberDAO contaReceberDAO) {
        this.relatorioService = relatorioService;
        this.categoriaDAO = categoriaDAO;
        this.contaReceberDAO = contaReceberDAO;
        initComponents();
        setupLayout();
        setupListeners();
        setDefaultDates();
    }

    private void initComponents() {
        String[] reportNames = new String[ReportType.values().length];
        for (int i = 0; i < ReportType.values().length; i++) {
            reportNames[i] = ReportType.values()[i].toString();
        }
        reportList = new JList<>(reportNames);
        reportList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        reportList.setSelectedIndex(0);
        reportList.setVisibleRowCount(8);

        startDateField = new JTextField(12);
        endDateField = new JTextField(12);

        gerarButton = new JButton("Gerar Relat\u00f3rio");
        exportPdfButton = new JButton("Exportar PDF");
        exportExcelButton = new JButton("Exportar Excel");

        contentPanel = new JPanel(new BorderLayout());
        contentPanel.setBorder(BorderFactory.createTitledBorder("Resultados"));

        // Placeholder label
        JLabel placeholder = new JLabel("Seleccione um relat\u00f3rio e clique em \"Gerar Relat\u00f3rio\"", SwingConstants.CENTER);
        placeholder.setForeground(Color.GRAY);
        contentPanel.add(placeholder, BorderLayout.CENTER);
    }

    private void setupLayout() {
        setLayout(new BorderLayout(5, 5));

        // Left sidebar
        JPanel sidebar = new JPanel(new BorderLayout());
        sidebar.setBorder(BorderFactory.createTitledBorder("Tipos de Relat\u00f3rio"));
        sidebar.setPreferredSize(new Dimension(200, 0));
        sidebar.add(new JScrollPane(reportList), BorderLayout.CENTER);

        // Date range panel
        JPanel datePanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        datePanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        datePanel.add(new JLabel("De:"));
        datePanel.add(startDateField);
        datePanel.add(new JLabel("At\u00e9:"));
        datePanel.add(endDateField);
        datePanel.add(gerarButton);

        // Export buttons
        JPanel exportPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        exportPanel.add(exportPdfButton);
        exportPanel.add(exportExcelButton);

        // Top panel combining dates and exports
        JPanel topPanel = new JPanel(new BorderLayout());
        topPanel.add(datePanel, BorderLayout.WEST);
        topPanel.add(exportPanel, BorderLayout.EAST);

        // Content
        JScrollPane contentScroll = new JScrollPane(contentPanel);

        JSplitPane splitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, sidebar, contentScroll);
        splitPane.setDividerLocation(200);
        splitPane.setResizeWeight(0.0);

        add(topPanel, BorderLayout.NORTH);
        add(splitPane, BorderLayout.CENTER);
    }

    private void setupListeners() {
        gerarButton.addActionListener(e -> generateReport());
        exportPdfButton.addActionListener(e -> exportPdf());
        exportExcelButton.addActionListener(e -> exportExcel());
    }

    private void setDefaultDates() {
        LocalDate now = LocalDate.now();
        LocalDate monthStart = now.withDayOfMonth(1);
        startDateField.setText(monthStart.format(DATE_FMT));
        endDateField.setText(now.format(DATE_FMT));
    }

    private LocalDate parseDateField(JTextField field, String fieldName) {
        try {
            return LocalDate.parse(field.getText().trim(), DATE_FMT);
        } catch (DateTimeParseException ex) {
            JOptionPane.showMessageDialog(this,
                    "Data inv\u00e1lida em " + fieldName + ". Use o formato dd/MM/yyyy.",
                    "Erro", JOptionPane.ERROR_MESSAGE);
            return null;
        }
    }

    private void generateReport() {
        ReportType selected = ReportType.values()[reportList.getSelectedIndex()];
        LocalDate start = parseDateField(startDateField, "data inicial");
        if (start == null) return;
        LocalDate end = parseDateField(endDateField, "data final");
        if (end == null) return;

        String startDate = start.format(DATE_FMT);
        String endDate = end.format(DATE_FMT);

        gerarButton.setEnabled(false);
        gerarButton.setText("A gerar...");

        SwingWorker<Void, Void> worker = new SwingWorker<>() {
            @Override
            protected Void doInBackground() {
                switch (selected) {
                    case VENDAS:
                        generateVendasReport(startDate, endDate);
                        break;
                    case PRODUTOS:
                        generateProdutosReport(startDate, endDate);
                        break;
                    case STOCK:
                        generateStockReport();
                        break;
                    case CLIENTES:
                        generateClientesReport();
                        break;
                    case CONTAS:
                        generateContasReport();
                        break;
                    case FECHO:
                        generateFechoReport(startDate, endDate);
                        break;
                }
                return null;
            }

            @Override
            protected void done() {
                gerarButton.setEnabled(true);
                gerarButton.setText("Gerar Relat\u00f3rio");
                try {
                    get();
                } catch (Exception ex) {
                    JOptionPane.showMessageDialog(RelatoriosPanel.this,
                            "Erro ao gerar relat\u00f3rio: " + ex.getMessage(),
                            "Erro", JOptionPane.ERROR_MESSAGE);
                }
            }
        };
        worker.execute();
    }

    private void generateVendasReport(String startDate, String endDate) {
        Map<String, Object> resumo = relatorioService.getVendasResumo(startDate, endDate);
        Map<String, Object> dailySales = relatorioService.getVendasPorDia(startDate, endDate);

        // Build chart
        DefaultCategoryDataset dataset = new DefaultCategoryDataset();
        @SuppressWarnings("unchecked")
        Map<String, Double> dailyTotals = (Map<String, Double>) dailySales.get("dailySales");
        if (dailyTotals != null) {
            for (Map.Entry<String, Double> entry : dailyTotals.entrySet()) {
                dataset.addValue(entry.getValue(), "Vendas", entry.getKey());
            }
        }

        JFreeChart chart = ChartFactory.createBarChart(
                "Vendas por Dia (" + startDate + " - " + endDate + ")",
                "Data", "Valor (Kz)", dataset);

        // Build summary table
        String[] columns = {"M\u00e9trica", "Valor"};
        DefaultTableModel model = new DefaultTableModel(columns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) { return false; }
        };

        NumberFormat currencyFmt = NumberFormat.getCurrencyInstance();
        model.addRow(new Object[]{"Total de Vendas", currencyFmt.format(resumo.get("totalVendas"))});
        model.addRow(new Object[]{"N\u00famero de Vendas", resumo.get("count")});
        model.addRow(new Object[]{"Ticket M\u00e9dio", currencyFmt.format(resumo.get("averageTicket"))});
        model.addRow(new Object[]{"Lucro Estimado", currencyFmt.format(relatorioService.getLucroEstimado(startDate, endDate))});

        resultsTable = new JTable(model);
        resultsTable.setRowHeight(28);

        displayChartAndTable(new ChartPanel(chart), resultsTable);
    }

    private void generateProdutosReport(String startDate, String endDate) {
        List<Map<String, Object>> topProdutos = relatorioService.getTopProdutos(startDate, endDate);

        // Build chart
        DefaultPieDataset<String> pieDataset = new DefaultPieDataset<>();
        for (Map<String, Object> prod : topProdutos) {
            String nome = (String) prod.get("produtoNome");
            Double qty = (Double) prod.get("quantidadeVendida");
            pieDataset.setValue(nome.length() > 15 ? nome.substring(0, 15) + "..." : nome, qty);
        }

        JFreeChart chart = ChartFactory.createPieChart(
                "Produtos Mais Vendidos (" + startDate + " - " + endDate + ")",
                pieDataset, true, true, false);

        // Build table
        String[] columns = {"Produto", "Qtd. Vendida", "Receita Estimada"};
        DefaultTableModel model = new DefaultTableModel(columns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) { return false; }
        };

        NumberFormat currencyFmt = NumberFormat.getCurrencyInstance();
        for (Map<String, Object> prod : topProdutos) {
            model.addRow(new Object[]{
                    prod.get("produtoNome"),
                    prod.get("quantidadeVendida"),
                    currencyFmt.format(prod.get("receitaEstimada"))
            });
        }

        resultsTable = new JTable(model);
        resultsTable.setRowHeight(28);

        displayChartAndTable(new ChartPanel(chart), resultsTable);
    }

    private void generateStockReport() {
        String[] columns = {"Produto", "Stock Atual", "Stock M\u00ednimo", "Categoria"};
        DefaultTableModel model = new DefaultTableModel(columns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) { return false; }
        };

        List<String[]> data = relatorioService.getStockReport();
        for (String[] row : data) {
            int stockAtual = Integer.parseInt(row[1]);
            int stockMinimo = Integer.parseInt(row[2]);
            String estado;
            if (stockAtual == 0) {
                estado = "Sem Stock";
            } else if (stockAtual <= stockMinimo / 2) {
                estado = "Cr\u00edtico";
            } else if (stockAtual <= stockMinimo) {
                estado = "Baixo";
            } else {
                estado = "Normal";
            }
            model.addRow(new Object[]{row[0], row[1], row[2], estado});
        }

        resultsTable = new JTable(model);
        resultsTable.setRowHeight(28);

        contentPanel.removeAll();
        contentPanel.setLayout(new BorderLayout());
        contentPanel.add(new JScrollPane(resultsTable), BorderLayout.CENTER);
        contentPanel.revalidate();
        contentPanel.repaint();
    }

    private void generateClientesReport() {
        String[] columns = {"Cliente", "Telefone", "Email", "Limite Cr\u00e9dito", "Cr\u00e9dito Usado"};
        DefaultTableModel model = new DefaultTableModel(columns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) { return false; }
        };

        List<String[]> data = relatorioService.getClientesReport();
        NumberFormat currencyFmt = NumberFormat.getCurrencyInstance();
        for (String[] row : data) {
            String limiteCredito = row[3].equals("N/A") ? "N/A" : currencyFmt.format(Double.parseDouble(row[3]));
            model.addRow(new Object[]{row[0], row[1], row[2], limiteCredito, currencyFmt.format(Double.parseDouble(row[4]))});
        }

        resultsTable = new JTable(model);
        resultsTable.setRowHeight(28);

        contentPanel.removeAll();
        contentPanel.setLayout(new BorderLayout());
        contentPanel.add(new JScrollPane(resultsTable), BorderLayout.CENTER);
        contentPanel.revalidate();
        contentPanel.repaint();
    }

    private void generateContasReport() {
        String[] columns = {"Cliente", "Valor Total", "Valor Pago", "Valor Pendente", "Status", "Vencimento"};
        DefaultTableModel model = new DefaultTableModel(columns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) { return false; }
        };

        List<String[]> data = relatorioService.getContasReceberReport();
        NumberFormat currencyFmt = NumberFormat.getCurrencyInstance();
        for (String[] row : data) {
            model.addRow(new Object[]{
                    row[0],
                    currencyFmt.format(Double.parseDouble(row[1])),
                    currencyFmt.format(Double.parseDouble(row[2])),
                    currencyFmt.format(Double.parseDouble(row[3])),
                    row[4],
                    row[5]
            });
        }

        resultsTable = new JTable(model);
        resultsTable.setRowHeight(28);

        contentPanel.removeAll();
        contentPanel.setLayout(new BorderLayout());
        contentPanel.add(new JScrollPane(resultsTable), BorderLayout.CENTER);
        contentPanel.revalidate();
        contentPanel.repaint();
    }

    private void generateFechoReport(String startDate, String endDate) {
        Map<String, Object> resumo = relatorioService.getVendasResumo(startDate, endDate);

        String[] columns = {"M\u00e9trica", "Valor"};
        DefaultTableModel model = new DefaultTableModel(columns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) { return false; }
        };

        NumberFormat currencyFmt = NumberFormat.getCurrencyInstance();
        model.addRow(new Object[]{"Per\u00edodo", startDate + " - " + endDate});
        model.addRow(new Object[]{"Total Vendas", currencyFmt.format(resumo.get("totalVendas"))});
        model.addRow(new Object[]{"N\u00famero de Vendas", resumo.get("count")});
        model.addRow(new Object[]{"Ticket M\u00e9dio", currencyFmt.format(resumo.get("averageTicket"))});

        resultsTable = new JTable(model);
        resultsTable.setRowHeight(28);

        contentPanel.removeAll();
        contentPanel.setLayout(new BorderLayout());
        contentPanel.add(new JScrollPane(resultsTable), BorderLayout.CENTER);
        contentPanel.revalidate();
        contentPanel.repaint();
    }

    private void displayChartAndTable(ChartPanel chart, JTable table) {
        contentPanel.removeAll();
        contentPanel.setLayout(new BorderLayout());

        JSplitPane split = new JSplitPane(JSplitPane.VERTICAL_SPLIT, chart, new JScrollPane(table));
        split.setResizeWeight(0.6);
        split.setDividerLocation(300);

        contentPanel.add(split, BorderLayout.CENTER);
        contentPanel.revalidate();
        contentPanel.repaint();
    }

    private void exportPdf() {
        if (resultsTable == null) {
            JOptionPane.showMessageDialog(this,
                    "Gere um relat\u00f3rio primeiro.",
                    "Aviso", JOptionPane.WARNING_MESSAGE);
            return;
        }

        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setDialogTitle("Exportar PDF");
        fileChooser.setSelectedFile(new File("relatorio.pdf"));
        if (fileChooser.showSaveDialog(this) != JFileChooser.APPROVE_OPTION) {
            return;
        }

        File file = fileChooser.getSelectedFile();
        if (!file.getName().toLowerCase().endsWith(".pdf")) {
            file = new File(file.getParentFile(), file.getName() + ".pdf");
        }

        try (PDDocument document = new PDDocument()) {
            var page = new org.apache.pdfbox.pdmodel.PDPage();
            document.addPage(page);

            var contentStream = new org.apache.pdfbox.pdmodel.PDPageContentStream(document, page);
            var font = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
            var boldFont = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);

            float margin = 50;
            float yStart = page.getMediaBox().getHeight() - margin;
            float tableWidth = page.getMediaBox().getWidth() - 2 * margin;
            float yPosition = yStart;
            float rowHeight = 20;

            // Title
            contentStream.beginText();
            contentStream.setFont(boldFont, 16);
            contentStream.newLineAtOffset(margin, yPosition);
            contentStream.showText("Relat\u00f3rio");
            contentStream.endText();
            yPosition -= 30;

            // Headers
            DefaultTableModel model = (DefaultTableModel) resultsTable.getModel();
            int colCount = model.getColumnCount();
            float colWidth = tableWidth / colCount;

            contentStream.setLineWidth(1f);
            contentStream.setNonStrokingColor(0.8f, 0.8f, 0.8f);
            contentStream.addRect(margin, yPosition - rowHeight, tableWidth, rowHeight);
            contentStream.fill();
            contentStream.setNonStrokingColor(0f, 0f, 0f);

            contentStream.beginText();
            contentStream.setFont(boldFont, 10);
            for (int c = 0; c < colCount; c++) {
                contentStream.newLineAtOffset(margin + c * colWidth + 5, yPosition - 14);
                String header = model.getColumnName(c);
                contentStream.showText(header.length() > 15 ? header.substring(0, 15) + "..." : header);
                contentStream.newLineAtOffset(-(margin + c * colWidth + 5), -(yPosition - 14));
            }
            contentStream.endText();
            yPosition -= rowHeight;

            // Rows
            contentStream.setFont(font, 9);
            for (int r = 0; r < model.getRowCount(); r++) {
                if (yPosition < margin + 20) {
                    contentStream.close();
                    page = new org.apache.pdfbox.pdmodel.PDPage();
                    document.addPage(page);
                    contentStream = new org.apache.pdfbox.pdmodel.PDPageContentStream(document, page);
                    yPosition = yStart;
                }

                for (int c = 0; c < colCount; c++) {
                    Object val = model.getValueAt(r, c);
                    String text = val != null ? val.toString() : "";
                    if (text.length() > 20) text = text.substring(0, 20) + "...";

                    contentStream.beginText();
                    contentStream.newLineAtOffset(margin + c * colWidth + 5, yPosition - 14);
                    contentStream.showText(text);
                    contentStream.newLineAtOffset(-(margin + c * colWidth + 5), -(yPosition - 14));
                    contentStream.endText();
                }
                yPosition -= rowHeight;
            }

            contentStream.close();
            document.save(file);

            JOptionPane.showMessageDialog(this,
                    "PDF exportado com sucesso: " + file.getName(),
                    "Sucesso", JOptionPane.INFORMATION_MESSAGE);
        } catch (IOException ex) {
            JOptionPane.showMessageDialog(this,
                    "Erro ao exportar PDF: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
        }
    }

    private void exportExcel() {
        if (resultsTable == null) {
            JOptionPane.showMessageDialog(this,
                    "Gere um relat\u00f3rio primeiro.",
                    "Aviso", JOptionPane.WARNING_MESSAGE);
            return;
        }

        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setDialogTitle("Exportar Excel");
        fileChooser.setSelectedFile(new File("relatorio.xlsx"));
        if (fileChooser.showSaveDialog(this) != JFileChooser.APPROVE_OPTION) {
            return;
        }

        File file = fileChooser.getSelectedFile();
        if (!file.getName().toLowerCase().endsWith(".xlsx")) {
            file = new File(file.getParentFile(), file.getName() + ".xlsx");
        }

        try (Workbook workbook = new XSSFWorkbook()) {
            Sheet sheet = workbook.createSheet("Relatorio");

            CellStyle headerStyle = workbook.createCellStyle();
            Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            headerFont.setFontHeightInPoints((short) 12);
            headerStyle.setFont(headerFont);
            headerStyle.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);

            // Header row
            DefaultTableModel model = (DefaultTableModel) resultsTable.getModel();
            Row headerRow = sheet.createRow(0);
            for (int c = 0; c < model.getColumnCount(); c++) {
                Cell cell = headerRow.createCell(c);
                cell.setCellValue(model.getColumnName(c));
                cell.setCellStyle(headerStyle);
            }

            // Data rows
            for (int r = 0; r < model.getRowCount(); r++) {
                Row row = sheet.createRow(r + 1);
                for (int c = 0; c < model.getColumnCount(); c++) {
                    Cell cell = row.createCell(c);
                    Object val = model.getValueAt(r, c);
                    if (val != null) {
                        cell.setCellValue(val.toString());
                    }
                }
            }

            // Auto-size columns
            for (int c = 0; c < model.getColumnCount(); c++) {
                sheet.autoSizeColumn(c);
            }

            try (FileOutputStream out = new FileOutputStream(file)) {
                workbook.write(out);
            }

            JOptionPane.showMessageDialog(this,
                    "Excel exportado com sucesso: " + file.getName(),
                    "Sucesso", JOptionPane.INFORMATION_MESSAGE);
        } catch (IOException ex) {
            JOptionPane.showMessageDialog(this,
                    "Erro ao exportar Excel: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
        }
    }
}
