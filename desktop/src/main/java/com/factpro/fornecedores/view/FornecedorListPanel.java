package com.factpro.fornecedores.view;

import com.factpro.core.util.CurrencyFormatter;
import com.factpro.fornecedores.dao.FornecedorDAO;
import com.factpro.fornecedores.model.Fornecedor;
import com.factpro.fornecedores.service.FornecedorService;
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
import java.util.ArrayList;
import java.util.List;

/**
 * Supplier list panel with search, CRUD actions, and double-click editing.
 */
public class FornecedorListPanel extends JPanel {

    private static final Logger logger = LoggerFactory.getLogger(FornecedorListPanel.class);

    private final FornecedorDAO fornecedorDAO;
    private final FornecedorService fornecedorService;

    private JTextField searchField;
    private JTable fornecedoresTable;
    private FornecedorTableModel tableModel;
    private List<Fornecedor> allFornecedores;

    private static final Color GREEN = new Color(34, 139, 34);
    private static final Color RED = new Color(220, 53, 69);
    private static final Color BLUE = new Color(57, 113, 227);

    public FornecedorListPanel() {
        fornecedorDAO = new FornecedorDAO();
        fornecedorService = new FornecedorService(fornecedorDAO);
        allFornecedores = new ArrayList<>();

        setLayout(new BorderLayout());
        setBorder(new EmptyBorder(10, 10, 10, 10));

        initComponents();
        setupLayout();
        setupListeners();
        loadFornecedores();
    }

    private void initComponents() {
        searchField = new JTextField();
        searchField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Pesquisar fornecedores...");

        String[] cols = {"Nome", "Telefone", "Email", "NIF", "Acoes"};
        tableModel = new FornecedorTableModel(cols);
        fornecedoresTable = new JTable(tableModel);
        fornecedoresTable.setRowHeight(28);
        fornecedoresTable.getTableHeader().setReorderingAllowed(false);
        fornecedoresTable.getColumnModel().getColumn(4).setCellRenderer(new ActionRenderer());
        fornecedoresTable.getColumnModel().getColumn(4).setCellEditor(new ActionEditor());
    }

    private void setupLayout() {
        JPanel searchPanel = new JPanel(new MigLayout("fillx, ins 0, gap 10", "[grow][][][]"));
        searchPanel.add(searchField, "growx, h 35");

        JButton btnSearch = new JButton("Pesquisar");
        JButton btnNovo = new JButton("Novo");
        JButton btnEditar = new JButton("Editar");
        JButton btnEliminar = new JButton("Eliminar");

        styleBtn(btnSearch, BLUE);
        styleBtn(btnNovo, GREEN);
        styleBtn(btnEditar, BLUE);
        styleBtn(btnEliminar, RED);

        searchPanel.add(btnSearch, "h 35");
        searchPanel.add(btnNovo, "h 35");
        searchPanel.add(btnEditar, "h 35");
        searchPanel.add(btnEliminar, "h 35");

        add(searchPanel, BorderLayout.NORTH);
        add(new JScrollPane(fornecedoresTable), BorderLayout.CENTER);

        btnSearch.addActionListener(e -> searchFornecedores());
        btnNovo.addActionListener(e -> openNovoFornecedor());
        btnEditar.addActionListener(e -> openEditarFornecedor());
        btnEliminar.addActionListener(e -> eliminarFornecedor());
    }

    private void setupListeners() {
        fornecedoresTable.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                if (e.getClickCount() == 2) {
                    int row = fornecedoresTable.rowAtPoint(e.getPoint());
                    if (row >= 0 && row < tableModel.getRowCount()) {
                        Fornecedor f = tableModel.getFornecedorAt(row);
                        if (f != null) openEditDialog(f);
                    }
                }
            }
        });
    }

    private void loadFornecedores() {
        allFornecedores = fornecedorService.findAll();
        tableModel.setFornecedores(allFornecedores);
    }

    private void searchFornecedores() {
        String query = searchField.getText().trim();
        if (query.isEmpty()) {
            tableModel.setFornecedores(allFornecedores);
            return;
        }
        List<Fornecedor> filtered = allFornecedores.stream()
                .filter(f -> {
                    String nome = f.getNome() != null ? f.getNome().toLowerCase() : "";
                    String email = f.getEmail() != null ? f.getEmail().toLowerCase() : "";
                    String nif = f.getNif() != null ? f.getNif() : "";
                    return nome.contains(query.toLowerCase())
                            || email.contains(query.toLowerCase())
                            || nif.contains(query);
                })
                .toList();
        tableModel.setFornecedores(filtered);
    }

    private void openNovoFornecedor() {
        FornecedorFormDialog dialog = new FornecedorFormDialog(
                (Frame) SwingUtilities.getWindowAncestor(this), null, fornecedorService);
        dialog.setVisible(true);
        if (dialog.isSaved()) loadFornecedores();
    }

    private void openEditarFornecedor() {
        int row = fornecedoresTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(this, "Selecione um fornecedor para editar.",
                    "Nenhum Selecionado", JOptionPane.WARNING_MESSAGE);
            return;
        }
        Fornecedor f = tableModel.getFornecedorAt(row);
        if (f != null) openEditDialog(f);
    }

    private void openEditDialog(Fornecedor f) {
        FornecedorFormDialog dialog = new FornecedorFormDialog(
                (Frame) SwingUtilities.getWindowAncestor(this), f, fornecedorService);
        dialog.setVisible(true);
        if (dialog.isSaved()) loadFornecedores();
    }

    private void eliminarFornecedor() {
        int row = fornecedoresTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(this, "Selecione um fornecedor para eliminar.",
                    "Nenhum Selecionado", JOptionPane.WARNING_MESSAGE);
            return;
        }
        Fornecedor f = tableModel.getFornecedorAt(row);
        if (f == null) return;

        int confirm = JOptionPane.showConfirmDialog(this,
                "Deseja realmente eliminar o fornecedor \"" + f.getNome() + "\"?",
                "Confirmar Eliminacao",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.WARNING_MESSAGE);

        if (confirm == JOptionPane.YES_OPTION) {
            boolean deleted = fornecedorService.delete(f.getId());
            if (deleted) {
                JOptionPane.showMessageDialog(this, "Fornecedor eliminado com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                loadFornecedores();
            } else {
                JOptionPane.showMessageDialog(this, "Erro ao eliminar o fornecedor.",
                        "Erro", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    private void styleBtn(JButton btn, Color bgColor) {
        btn.setFont(btn.getFont().deriveFont(Font.PLAIN, 12f));
        btn.setBackground(bgColor);
        btn.setForeground(Color.WHITE);
        btn.setFocusPainted(false);
    }

    // ==================== Table Model ====================

    private static class FornecedorTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private List<Fornecedor> fornecedores = new ArrayList<>();

        FornecedorTableModel(String[] columns) { this.columns = columns; }

        void setFornecedores(List<Fornecedor> fornecedores) {
            this.fornecedores = fornecedores;
            fireTableDataChanged();
        }

        Fornecedor getFornecedorAt(int row) {
            return (row >= 0 && row < fornecedores.size()) ? fornecedores.get(row) : null;
        }

        @Override public int getRowCount() { return fornecedores.size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= fornecedores.size()) return null;
            Fornecedor f = fornecedores.get(row);
            return switch (col) {
                case 0 -> f.getNome() != null ? f.getNome() : "-";
                case 1 -> f.getTelefone() != null ? f.getTelefone() : "-";
                case 2 -> f.getEmail() != null ? f.getEmail() : "-";
                case 3 -> f.getNif() != null ? f.getNif() : "-";
                case 4 -> "Editar | Eliminar";
                default -> null;
            };
        }
    }

    // ==================== Renderers ====================

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
        private Fornecedor currentFornecedor;

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
                if (currentFornecedor != null) openEditDialog(currentFornecedor);
            });
            deleteBtn.addActionListener(e -> {
                fireEditingStopped();
                if (currentFornecedor != null) eliminarFornecedor();
            });

            panel.add(editBtn);
            panel.add(deleteBtn);
        }

        @Override
        public Component getTableCellEditorComponent(JTable table, Object value,
                                                     boolean isSelected, int row, int col) {
            currentFornecedor = tableModel.getFornecedorAt(row);
            panel.setBackground(isSelected ? table.getSelectionBackground() : table.getBackground());
            return panel;
        }

        @Override public Object getCellEditorValue() { return ""; }
    }
}
