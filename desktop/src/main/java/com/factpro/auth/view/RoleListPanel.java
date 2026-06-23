package com.factpro.auth.view;

import com.factpro.auth.dao.PermissionDAO;
import com.factpro.auth.dao.RoleDAO;
import com.factpro.auth.model.Role;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.ArrayList;
import java.util.List;

/**
 * Panel for listing and managing roles.
 */
public class RoleListPanel extends JPanel {

    private static final Color GREEN = new Color(34, 139, 34);
    private static final Color BLUE = new Color(57, 113, 227);
    private static final Color RED = new Color(220, 53, 69);
    private static final Color PURPLE = new Color(111, 66, 193);

    private final RoleDAO roleDAO;
    private final PermissionDAO permissionDAO;

    private JTable rolesTable;
    private RoleTableModel tableModel;
    private List<Role> allRoles;

    public RoleListPanel() {
        roleDAO = new RoleDAO();
        permissionDAO = new PermissionDAO();
        allRoles = new ArrayList<>();

        setLayout(new BorderLayout());
        setBorder(new EmptyBorder(10, 10, 10, 10));

        initComponents();
        setupLayout();
        setupListeners();
        loadRoles();
    }

    private void initComponents() {
        String[] cols = {"Nome", "Descricao", "Permissoes"};
        tableModel = new RoleTableModel(cols);
        rolesTable = new JTable(tableModel);
        rolesTable.setRowHeight(30);
        rolesTable.getTableHeader().setReorderingAllowed(false);
    }

    private void setupLayout() {
        JPanel toolbar = new JPanel(new MigLayout("fillx, ins 0, gap 10", "[grow][][][][]"));

        JButton btnNovo = new JButton("Novo");
        JButton btnEditar = new JButton("Editar");
        JButton btnPermissoes = new JButton("Permissoes");
        JButton btnEliminar = new JButton("Eliminar");

        styleBtn(btnNovo, GREEN);
        styleBtn(btnEditar, BLUE);
        styleBtn(btnPermissoes, PURPLE);
        styleBtn(btnEliminar, RED);

        toolbar.add(btnNovo, "h 35");
        toolbar.add(btnEditar, "h 35");
        toolbar.add(btnPermissoes, "h 35");
        toolbar.add(btnEliminar, "h 35");

        add(toolbar, BorderLayout.NORTH);
        add(new JScrollPane(rolesTable), BorderLayout.CENTER);

        btnNovo.addActionListener(e -> openNewDialog());
        btnEditar.addActionListener(e -> editSelectedRole());
        btnPermissoes.addActionListener(e -> openPermissionDialog());
        btnEliminar.addActionListener(e -> deleteSelectedRole());
    }

    private void setupListeners() {
        rolesTable.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                if (e.getClickCount() == 2) {
                    int row = rolesTable.rowAtPoint(e.getPoint());
                    if (row >= 0 && row < tableModel.getRowCount()) {
                        Role role = tableModel.getRoleAt(row);
                        if (role != null) openEditDialog(role);
                    }
                }
            }
        });
    }

    private void loadRoles() {
        allRoles = roleDAO.findAll();
        tableModel.setRoles(allRoles);
    }

    private void openNewDialog() {
        Frame parent = (Frame) SwingUtilities.getWindowAncestor(this);
        RoleFormDialog dialog = new RoleFormDialog(parent, null);
        dialog.setVisible(true);
        if (dialog.isSaved()) loadRoles();
    }

    private void openEditDialog(Role role) {
        Frame parent = (Frame) SwingUtilities.getWindowAncestor(this);
        RoleFormDialog dialog = new RoleFormDialog(parent, role);
        dialog.setVisible(true);
        if (dialog.isSaved()) loadRoles();
    }

    private void openPermissionDialog() {
        int row = rolesTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(this, "Selecione um role para configurar permissoes.",
                    "Nenhum Selecionado", JOptionPane.WARNING_MESSAGE);
            return;
        }

        Role role = tableModel.getRoleAt(row);
        if (role == null) return;

        Frame parent = (Frame) SwingUtilities.getWindowAncestor(this);
        RolePermissionDialog dialog = new RolePermissionDialog(parent, role.getId(), role.getNome());
        dialog.setVisible(true);
        
        // Reload to update permission count
        if (dialog.isSaved()) loadRoles();
    }

    private void editSelectedRole() {
        int row = rolesTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(this, "Selecione um role para editar.",
                    "Nenhum Selecionado", JOptionPane.WARNING_MESSAGE);
            return;
        }
        Role role = tableModel.getRoleAt(row);
        if (role != null) openEditDialog(role);
    }

    private void deleteSelectedRole() {
        int row = rolesTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(this, "Selecione um role para eliminar.",
                    "Nenhum Selecionado", JOptionPane.WARNING_MESSAGE);
            return;
        }

        Role role = tableModel.getRoleAt(row);
        if (role == null) return;

        int confirm = JOptionPane.showConfirmDialog(this,
                "Deseja realmente eliminar o role \"" + role.getNome() + "\"?",
                "Confirmar Eliminacao",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.WARNING_MESSAGE);

        if (confirm == JOptionPane.YES_OPTION) {
            boolean deleted = roleDAO.delete(role.getId());
            if (deleted) {
                JOptionPane.showMessageDialog(this, "Role eliminado com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                loadRoles();
            } else {
                JOptionPane.showMessageDialog(this, "Erro ao eliminar o role.",
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

    private static class RoleTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private List<Role> roles = new ArrayList<>();

        RoleTableModel(String[] columns) { this.columns = columns; }

        void setRoles(List<Role> roles) {
            this.roles = roles;
            fireTableDataChanged();
        }

        Role getRoleAt(int row) {
            return (row >= 0 && row < roles.size()) ? roles.get(row) : null;
        }

        @Override public int getRowCount() { return roles.size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= roles.size()) return null;
            Role r = roles.get(row);
            return switch (col) {
                case 0 -> r.getNome() != null ? r.getNome() : "-";
                case 1 -> r.getDescricao() != null ? r.getDescricao() : "-";
                case 2 -> {
                    // Count permissions for this role
                    PermissionDAO permDAO = new PermissionDAO();
                    List<String> perms = permDAO.findPermissionNamesByRoleId(r.getId());
                    yield perms.size() + " permiss" + (perms.size() != 1 ? "oes" : "ao");
                }
                default -> null;
            };
        }
    }
}
