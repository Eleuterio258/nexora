package com.factpro.compras.view;

import com.factpro.auth.SessionManager;
import com.factpro.compras.dao.CompraDAO;
import com.factpro.compras.dao.CompraItemDAO;
import com.factpro.compras.model.Compra;
import com.factpro.compras.service.CompraService;
import com.factpro.core.util.CurrencyFormatter;
import com.factpro.fornecedores.dao.FornecedorDAO;
import com.factpro.fornecedores.model.Fornecedor;
import com.factpro.fornecedores.service.FornecedorService;
import com.factpro.stock.dao.StockMovimentoDAO;
import com.factpro.produtos.dao.ProdutoDAO;
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
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.ArrayList;
import java.util.List;

/**
 * Purchase list panel with search, status badges, and CRUD actions.
 */
public class CompraListPanel extends JPanel {

    private static final Logger logger = LoggerFactory.getLogger(CompraListPanel.class);

    private final CompraDAO compraDAO;
    private final CompraService compraService;
    private final FornecedorDAO fornecedorDAO;
    private final FornecedorService fornecedorService;

    private JTextField searchField;
    private JTable comprasTable;
    private CompraTableModel tableModel;
    private List<Compra> allCompras;

    private static final Color GREEN = new Color(34, 139, 34);
    private static final Color RED = new Color(220, 53, 69);
    private static final Color ORANGE = new Color(255, 152, 0);
    private static final Color BLUE = new Color(57, 113, 227);

    public CompraListPanel() {
        compraDAO = new CompraDAO();
        ProdutoDAO produtoDAO = new ProdutoDAO();
        StockMovimentoDAO stockMovimentoDAO = new StockMovimentoDAO();
        compraService = new CompraService(compraDAO, new CompraItemDAO(), produtoDAO, stockMovimentoDAO);
        fornecedorDAO = new FornecedorDAO();
        fornecedorService = new FornecedorService(fornecedorDAO);
        allCompras = new ArrayList<>();

        setLayout(new BorderLayout());
        setBorder(new EmptyBorder(10, 10, 10, 10));

        initComponents();
        setupLayout();
        setupListeners();
        loadCompras();
    }

    private void initComponents() {
        searchField = new JTextField();
        searchField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Pesquisar compras...");

        String[] cols = {"Nº", "Fornecedor", "Data", "Total", "Status", "Acoes"};
        tableModel = new CompraTableModel(cols);
        comprasTable = new JTable(tableModel);
        comprasTable.setRowHeight(30);
        comprasTable.getTableHeader().setReorderingAllowed(false);
        comprasTable.getColumnModel().getColumn(3).setCellRenderer(new CurrencyRenderer());
        comprasTable.getColumnModel().getColumn(4).setCellRenderer(new StatusBadgeRenderer());
        comprasTable.getColumnModel().getColumn(5).setCellRenderer(new ActionRenderer());
        comprasTable.getColumnModel().getColumn(5).setCellEditor(new ActionEditor());
    }

    private void setupLayout() {
        JPanel searchPanel = new JPanel(new MigLayout("fillx, ins 0, gap 10", "[grow][][][][][]"));
        searchPanel.add(searchField, "growx, h 35");

        JButton btnSearch = new JButton("Pesquisar");
        JButton btnNova = new JButton("Nova Compra");
        JButton btnEditar = new JButton("Editar");
        JButton btnReceber = new JButton("Receber");

        styleBtn(btnSearch, BLUE);
        styleBtn(btnNova, GREEN);
        styleBtn(btnEditar, BLUE);
        styleBtn(btnReceber, ORANGE);

        searchPanel.add(btnSearch, "h 35");
        searchPanel.add(btnNova, "h 35");
        searchPanel.add(btnEditar, "h 35");
        searchPanel.add(btnReceber, "h 35");

        add(searchPanel, BorderLayout.NORTH);
        add(new JScrollPane(comprasTable), BorderLayout.CENTER);

        btnSearch.addActionListener(e -> searchCompras());
        btnNova.addActionListener(e -> openNovaCompra());
        btnEditar.addActionListener(e -> openEditarCompra());
        btnReceber.addActionListener(e -> receiveSelectedCompra());
    }

    private void setupListeners() {
        comprasTable.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                if (e.getClickCount() == 2) {
                    int row = comprasTable.rowAtPoint(e.getPoint());
                    if (row >= 0 && row < tableModel.getRowCount()) {
                        Compra compra = tableModel.getCompraAt(row);
                        if (compra != null) openDetailDialog(compra);
                    }
                }
            }
        });
    }

    private void loadCompras() {
        allCompras = compraService.findAll();
        tableModel.setCompras(allCompras);
    }

    private void searchCompras() {
        String query = searchField.getText().trim();
        if (query.isEmpty()) {
            tableModel.setCompras(allCompras);
            return;
        }
        // Filter client-side
        List<Compra> filtered = allCompras.stream()
                .filter(c -> {
                    Fornecedor f = fornecedorDAO.findById(c.getFornecedorId());
                    String nome = f != null ? f.getNome().toLowerCase() : "";
                    return nome.contains(query.toLowerCase())
                            || (c.getDataCompra() != null && c.getDataCompra().contains(query));
                })
                .toList();
        tableModel.setCompras(filtered);
    }

    private void openNovaCompra() {
        CompraFormDialog dialog = new CompraFormDialog(
                (Frame) SwingUtilities.getWindowAncestor(this), null,
                compraService, fornecedorService);
        dialog.setVisible(true);
        if (dialog.isSaved()) loadCompras();
    }

    private void openEditarCompra() {
        int row = comprasTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(this, "Selecione uma compra para editar.",
                    "Nenhuma Selecionada", JOptionPane.WARNING_MESSAGE);
            return;
        }
        Compra compra = tableModel.getCompraAt(row);
        if (compra != null) {
            CompraFormDialog dialog = new CompraFormDialog(
                    (Frame) SwingUtilities.getWindowAncestor(this), compra,
                    compraService, fornecedorService);
            dialog.setVisible(true);
            if (dialog.isSaved()) loadCompras();
        }
    }

    private void receiveSelectedCompra() {
        int row = comprasTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(this, "Selecione uma compra para receber.",
                    "Nenhuma Selecionada", JOptionPane.WARNING_MESSAGE);
            return;
        }
        Compra compra = tableModel.getCompraAt(row);
        if (compra == null) return;

        if (!"pendente".equals(compra.getStatus())) {
            JOptionPane.showMessageDialog(this,
                    "Apenas compras pendentes podem ser recebidas.\nStatus atual: " + compra.getStatus(),
                    "Nao e Possivel Receber",
                    JOptionPane.WARNING_MESSAGE);
            return;
        }

        int confirm = JOptionPane.showConfirmDialog(this,
                "Deseja marcar a compra #" + compra.getId() + " como recebida?\n"
                        + "O stock dos produtos sera atualizado.",
                "Confirmar Recebimento",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.QUESTION_MESSAGE);

        if (confirm == JOptionPane.YES_OPTION) {
            try {
                Long userId = SessionManager.getInstance().getCurrentUserId();
                compraService.receiveCompra(compra.getId(), userId);
                JOptionPane.showMessageDialog(this, "Compra recebida com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                loadCompras();
            } catch (Exception ex) {
                logger.error("Erro ao receber compra", ex);
                JOptionPane.showMessageDialog(this, "Erro ao receber compra: " + ex.getMessage(),
                        "Erro", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    private void openDetailDialog(Compra compra) {
        CompraDetailDialog dialog = new CompraDetailDialog(
                (Frame) SwingUtilities.getWindowAncestor(this), compra, compraService, fornecedorService);
        dialog.setVisible(true);
        if (dialog.isUpdated()) loadCompras();
    }

    private void styleBtn(JButton btn, Color bgColor) {
        btn.setFont(btn.getFont().deriveFont(Font.PLAIN, 12f));
        btn.setBackground(bgColor);
        btn.setForeground(Color.WHITE);
        btn.setFocusPainted(false);
    }

    // ==================== Table Model ====================

    private static class CompraTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private List<Compra> compras = new ArrayList<>();
        private final FornecedorDAO fornecedorDAO = new FornecedorDAO();

        CompraTableModel(String[] columns) { this.columns = columns; }

        void setCompras(List<Compra> compras) {
            this.compras = compras;
            fireTableDataChanged();
        }

        Compra getCompraAt(int row) {
            return (row >= 0 && row < compras.size()) ? compras.get(row) : null;
        }

        @Override public int getRowCount() { return compras.size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= compras.size()) return null;
            Compra c = compras.get(row);
            return switch (col) {
                case 0 -> c.getId() != null ? "#" + c.getId() : "-";
                case 1 -> getFornecedorNome(c.getFornecedorId());
                case 2 -> c.getDataCompra() != null ? c.getDataCompra() : "-";
                case 3 -> c.getTotal() != null ? c.getTotal() : 0.0;
                case 4 -> c.getStatus() != null ? c.getStatus() : "pendente";
                case 5 -> "Acoes";
                default -> null;
            };
        }

        private String getFornecedorNome(Long fornecedorId) {
            if (fornecedorId == null) return "-";
            Fornecedor f = fornecedorDAO.findById(fornecedorId);
            return f != null ? f.getNome() : "Fornecedor #" + fornecedorId;
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
                    case "pendente" -> { setForeground(ORANGE); setText("\u25CF Pendente"); }
                    case "recebida" -> { setForeground(GREEN); setText("\u2714 Recebida"); }
                    case "cancelada" -> { setForeground(RED); setText("\u2716 Cancelada"); }
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
        private Compra currentCompra;

        ActionEditor() {
            detailBtn.setFont(detailBtn.getFont().deriveFont(Font.PLAIN, 10f));
            detailBtn.setBackground(BLUE);
            detailBtn.setForeground(Color.WHITE);
            detailBtn.setFocusPainted(false);
            detailBtn.setPreferredSize(new Dimension(45, 20));
            detailBtn.addActionListener(e -> {
                fireEditingStopped();
                if (currentCompra != null) openDetailDialog(currentCompra);
            });
            panel.add(detailBtn);
        }

        @Override
        public Component getTableCellEditorComponent(JTable table, Object value,
                                                     boolean isSelected, int row, int col) {
            currentCompra = tableModel.getCompraAt(row);
            panel.setBackground(isSelected ? table.getSelectionBackground() : table.getBackground());
            return panel;
        }

        @Override public Object getCellEditorValue() { return ""; }
    }
}
