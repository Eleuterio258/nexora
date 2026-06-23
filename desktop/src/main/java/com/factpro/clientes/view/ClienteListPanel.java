package com.factpro.clientes.view;

import com.factpro.clientes.dao.ClienteDAO;
import com.factpro.clientes.model.Cliente;
import com.factpro.clientes.service.ClienteService;
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
 * Client list panel with search, CRUD actions, and credit tracking.
 */
public class ClienteListPanel extends JPanel {

    private static final Logger logger = LoggerFactory.getLogger(ClienteListPanel.class);

    private final ClienteDAO clienteDAO;
    private final ClienteService clienteService;

    private JTextField searchField;
    private JTable clientsTable;
    private ClienteTableModel tableModel;
    private List<Cliente> allClients;

    private static final Color GREEN = new Color(34, 139, 34);
    private static final Color RED = new Color(220, 53, 69);
    private static final Color BLUE = new Color(57, 113, 227);

    public ClienteListPanel() {
        clienteDAO = new ClienteDAO();
        clienteService = new ClienteService(clienteDAO);
        allClients = new ArrayList<>();

        setLayout(new BorderLayout());
        setBorder(new EmptyBorder(10, 10, 10, 10));

        initComponents();
        setupLayout();
        setupListeners();
        loadClients();
    }

    private void initComponents() {
        searchField = new JTextField();
        searchField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Pesquisar clientes...");

        String[] cols = {"Codigo", "Nome", "Telefone", "Email", "Limite Credito", "Credito Usado", "Acoes"};
        tableModel = new ClienteTableModel(cols);
        clientsTable = new JTable(tableModel);
        clientsTable.setRowHeight(28);
        clientsTable.getTableHeader().setReorderingAllowed(false);
        clientsTable.getColumnModel().getColumn(4).setCellRenderer(new CurrencyRenderer());
        clientsTable.getColumnModel().getColumn(5).setCellRenderer(new CurrencyRenderer());
        clientsTable.getColumnModel().getColumn(5).setCellRenderer(new CreditUsageRenderer());
        clientsTable.getColumnModel().getColumn(6).setCellRenderer(new ActionRenderer());
        clientsTable.getColumnModel().getColumn(6).setCellEditor(new ActionEditor());
    }

    private void setupLayout() {
        JPanel searchPanel = new JPanel(new MigLayout("fillx, ins 0, gap 10", "[grow][][][]"));
        searchPanel.add(searchField, "growx, h 35");

        JButton btnPesquisar = new JButton("Pesquisar");
        JButton btnNovo = new JButton("Novo");
        JButton btnEliminar = new JButton("Eliminar");

        styleBtn(btnPesquisar, BLUE);
        styleBtn(btnNovo, GREEN);
        styleBtn(btnEliminar, RED);

        searchPanel.add(btnPesquisar, "h 35");
        searchPanel.add(btnNovo, "h 35");
        searchPanel.add(btnEliminar, "h 35");

        add(searchPanel, BorderLayout.NORTH);
        add(new JScrollPane(clientsTable), BorderLayout.CENTER);

        btnPesquisar.addActionListener(e -> searchClients());
        btnNovo.addActionListener(e -> openNewDialog());
        btnEliminar.addActionListener(e -> deleteSelectedClient());
    }

    private void setupListeners() {
        clientsTable.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                if (e.getClickCount() == 2) {
                    int row = clientsTable.rowAtPoint(e.getPoint());
                    if (row >= 0 && row < tableModel.getRowCount()) {
                        Cliente cliente = tableModel.getClienteAt(row);
                        if (cliente != null) openEditDialog(cliente);
                    }
                }
            }
        });
    }

    private void loadClients() {
        allClients = clienteService.findAll();
        tableModel.setClients(allClients);
    }

    private void searchClients() {
        String query = searchField.getText().trim();
        List<Cliente> results;
        if (query.isEmpty()) {
            results = allClients;
        } else {
            results = clienteService.search(query);
        }
        tableModel.setClients(results);
    }

    private void openNewDialog() {
        ClienteFormDialog dialog = new ClienteFormDialog(
                (Frame) SwingUtilities.getWindowAncestor(this), null);
        dialog.setVisible(true);
        if (dialog.isSaved()) loadClients();
    }

    private void openEditDialog(Cliente cliente) {
        ClienteFormDialog dialog = new ClienteFormDialog(
                (Frame) SwingUtilities.getWindowAncestor(this), cliente);
        dialog.setVisible(true);
        if (dialog.isSaved()) loadClients();
    }

    private void deleteSelectedClient() {
        int row = clientsTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(this, "Selecione um cliente para eliminar.",
                    "Nenhum Selecionado", JOptionPane.WARNING_MESSAGE);
            return;
        }

        Cliente cliente = tableModel.getClienteAt(row);
        if (cliente == null) return;

        int confirm = JOptionPane.showConfirmDialog(this,
                "Deseja realmente eliminar o cliente \"" + cliente.getNome() + "\"?",
                "Confirmar Eliminacao",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.WARNING_MESSAGE);

        if (confirm == JOptionPane.YES_OPTION) {
            boolean deleted = clienteService.delete(cliente.getId());
            if (deleted) {
                JOptionPane.showMessageDialog(this, "Cliente eliminado com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                loadClients();
            } else {
                JOptionPane.showMessageDialog(this, "Erro ao eliminar o cliente.",
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

    private static class ClienteTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private List<Cliente> clients = new ArrayList<>();

        ClienteTableModel(String[] columns) { this.columns = columns; }

        void setClients(List<Cliente> clients) {
            this.clients = clients;
            fireTableDataChanged();
        }

        Cliente getClienteAt(int row) {
            return (row >= 0 && row < clients.size()) ? clients.get(row) : null;
        }

        @Override public int getRowCount() { return clients.size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= clients.size()) return null;
            Cliente c = clients.get(row);
            return switch (col) {
                case 0 -> c.getCodigo() != null ? c.getCodigo() : "CLI-" + c.getId();
                case 1 -> c.getNome();
                case 2 -> c.getTelefone() != null ? c.getTelefone() : "-";
                case 3 -> c.getEmail() != null ? c.getEmail() : "-";
                case 4 -> c.getLimiteCredito() != null ? c.getLimiteCredito() : 0.0;
                case 5 -> c.getCreditoUsado() != null ? c.getCreditoUsado() : 0.0;
                case 6 -> "Editar | Eliminar";
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
            if (value instanceof Number) {
                setText(String.format("%,.2f MT", ((Number) value).doubleValue()));
            }
            setHorizontalAlignment(SwingConstants.RIGHT);
            return this;
        }
    }

    private static class CreditUsageRenderer extends DefaultTableCellRenderer {
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            if (value instanceof Number) {
                double used = ((Number) value).doubleValue();
                if (used > 0) {
                    setForeground(RED);
                } else {
                    setForeground(GREEN);
                }
            }
            setHorizontalAlignment(SwingConstants.RIGHT);
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
        private Cliente currentCliente;

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
                if (currentCliente != null) openEditDialog(currentCliente);
            });
            deleteBtn.addActionListener(e -> {
                fireEditingStopped();
                if (currentCliente != null) {
                    int confirm = JOptionPane.showConfirmDialog(ClienteListPanel.this,
                            "Deseja eliminar \"" + currentCliente.getNome() + "\"?",
                            "Eliminar", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
                    if (confirm == JOptionPane.YES_OPTION) {
                        clienteService.delete(currentCliente.getId());
                        loadClients();
                    }
                }
            });

            panel.add(editBtn);
            panel.add(deleteBtn);
        }

        @Override
        public Component getTableCellEditorComponent(JTable table, Object value,
                                                     boolean isSelected, int row, int col) {
            currentCliente = tableModel.getClienteAt(row);
            panel.setBackground(isSelected ? table.getSelectionBackground() : table.getBackground());
            return panel;
        }

        @Override public Object getCellEditorValue() { return ""; }
    }
}
