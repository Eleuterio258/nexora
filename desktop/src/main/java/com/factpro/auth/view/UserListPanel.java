package com.factpro.auth.view;

import com.factpro.auth.dao.RoleDAO;
import com.factpro.auth.dao.UserDAO;
import com.factpro.auth.model.Role;
import com.factpro.auth.model.User;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.table.DefaultTableCellRenderer;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.ArrayList;
import java.util.List;

/**
 * Panel for listing and managing users.
 */
public class UserListPanel extends JPanel {

    private static final Color GREEN_ACTIVE = new Color(34, 139, 34);
    private static final Color RED_INACTIVE = new Color(220, 53, 69);
    private static final Color BLUE = new Color(57, 113, 227);
    private static final Color RED = new Color(220, 53, 69);

    private final UserDAO userDAO;
    private final RoleDAO roleDAO;

    private JTextField searchField;
    private JTable usersTable;
    private UserTableModel tableModel;
    private List<User> allUsers;
    private List<Role> allRoles;

    public UserListPanel() {
        userDAO = new UserDAO();
        roleDAO = new RoleDAO();
        allUsers = new ArrayList<>();
        allRoles = new ArrayList<>();

        setLayout(new BorderLayout());
        setBorder(new EmptyBorder(10, 10, 10, 10));

        initComponents();
        setupLayout();
        setupListeners();
        loadUsers();
        loadRoles();
    }

    private void initComponents() {
        searchField = new JTextField();
        searchField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Pesquisar utilizadores...");

        String[] cols = {"Nome", "Email", "Telefone", "Role", "Ativo", "Ultimo Login"};
        tableModel = new UserTableModel(cols);
        usersTable = new JTable(tableModel);
        usersTable.setRowHeight(30);
        usersTable.getTableHeader().setReorderingAllowed(false);
        usersTable.getColumnModel().getColumn(4).setCellRenderer(new AtivoRenderer());
    }

    private void setupLayout() {
        JPanel toolbar = new JPanel(new MigLayout("fillx, ins 0, gap 10", "[grow][]"));

        JPanel searchPanel = new JPanel(new MigLayout("fillx, ins 0, gap 10", "[grow][][][][]"));
        searchPanel.add(searchField, "growx, h 35");

        JButton btnNovo = new JButton("Novo");
        JButton btnEditar = new JButton("Editar");
        JButton btnEliminar = new JButton("Eliminar");
        JButton btnResetSenha = new JButton("Reset Senha");

        styleBtn(btnNovo, GREEN_ACTIVE);
        styleBtn(btnEditar, BLUE);
        styleBtn(btnEliminar, RED);
        styleBtn(btnResetSenha, new Color(255, 152, 0));

        searchPanel.add(btnNovo, "h 35");
        searchPanel.add(btnEditar, "h 35");
        searchPanel.add(btnEliminar, "h 35");
        searchPanel.add(btnResetSenha, "h 35");

        toolbar.add(searchPanel, "growx");
        add(toolbar, BorderLayout.NORTH);
        add(new JScrollPane(usersTable), BorderLayout.CENTER);

        btnNovo.addActionListener(e -> openNewDialog());
        btnEditar.addActionListener(e -> editSelectedUser());
        btnEliminar.addActionListener(e -> deleteSelectedUser());
        btnResetSenha.addActionListener(e -> resetPasswordSelectedUser());
    }

    private void setupListeners() {
        usersTable.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                if (e.getClickCount() == 2) {
                    int row = usersTable.rowAtPoint(e.getPoint());
                    if (row >= 0 && row < tableModel.getRowCount()) {
                        User user = tableModel.getUserAt(row);
                        if (user != null) openEditDialog(user);
                    }
                }
            }
        });

        searchField.addActionListener(e -> searchUsers());
    }

    private void loadUsers() {
        allUsers = userDAO.findAll();
        tableModel.setUsers(allUsers);
    }

    private void loadRoles() {
        allRoles = roleDAO.findAll();
    }

    private void searchUsers() {
        String query = searchField.getText().trim();
        List<User> results;
        if (query.isEmpty()) {
            results = allUsers;
        } else {
            results = userDAO.findByCriteria(query);
        }
        tableModel.setUsers(results);
    }

    private void openNewDialog() {
        loadRoles();
        Frame parent = (Frame) SwingUtilities.getWindowAncestor(this);
        UserFormDialog dialog = new UserFormDialog(parent, null, allRoles);
        dialog.setVisible(true);
        if (dialog.isSaved()) loadUsers();
    }

    private void openEditDialog(User user) {
        loadRoles();
        Frame parent = (Frame) SwingUtilities.getWindowAncestor(this);
        UserFormDialog dialog = new UserFormDialog(parent, user, allRoles);
        dialog.setVisible(true);
        if (dialog.isSaved()) loadUsers();
    }

    private void editSelectedUser() {
        int row = usersTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(this, "Selecione um utilizador para editar.",
                    "Nenhum Selecionado", JOptionPane.WARNING_MESSAGE);
            return;
        }
        User user = tableModel.getUserAt(row);
        if (user != null) openEditDialog(user);
    }

    private void deleteSelectedUser() {
        int row = usersTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(this, "Selecione um utilizador para eliminar.",
                    "Nenhum Selecionado", JOptionPane.WARNING_MESSAGE);
            return;
        }

        User user = tableModel.getUserAt(row);
        if (user == null) return;

        int confirm = JOptionPane.showConfirmDialog(this,
                "Deseja realmente eliminar o utilizador \"" + user.getNome() + "\"?",
                "Confirmar Eliminacao",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.WARNING_MESSAGE);

        if (confirm == JOptionPane.YES_OPTION) {
            boolean deleted = userDAO.delete(user.getId());
            if (deleted) {
                JOptionPane.showMessageDialog(this, "Utilizador eliminado com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                loadUsers();
            } else {
                JOptionPane.showMessageDialog(this, "Erro ao eliminar o utilizador.",
                        "Erro", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    private void resetPasswordSelectedUser() {
        int row = usersTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(this, "Selecione um utilizador para resetar a senha.",
                    "Nenhum Selecionado", JOptionPane.WARNING_MESSAGE);
            return;
        }

        User user = tableModel.getUserAt(row);
        if (user == null) return;

        JPasswordField passwordField = new JPasswordField();
        JPasswordField confirmField = new JPasswordField();

        JPanel panel = new JPanel(new MigLayout("fillx, wrap 2, gap 5, ins 10", "[right]20[grow]"));
        panel.add(new JLabel("Nova Senha:"));
        panel.add(passwordField, "growx, h 30");
        panel.add(new JLabel("Confirmar Senha:"));
        panel.add(confirmField, "growx, h 30");

        int result = JOptionPane.showConfirmDialog(this, panel,
                "Reset Senha - " + user.getNome(),
                JOptionPane.OK_CANCEL_OPTION,
                JOptionPane.PLAIN_MESSAGE);

        if (result == JOptionPane.OK_OPTION) {
            String password = new String(passwordField.getPassword());
            String confirm = new String(confirmField.getPassword());

            if (password.length() < 8) {
                JOptionPane.showMessageDialog(this, "A senha deve ter pelo menos 8 caracteres.",
                        "Erro de Validacao", JOptionPane.WARNING_MESSAGE);
                return;
            }

            if (!password.equals(confirm)) {
                JOptionPane.showMessageDialog(this, "As senhas nao coincidem.",
                        "Erro de Validacao", JOptionPane.WARNING_MESSAGE);
                return;
            }

            String hash = org.mindrot.jbcrypt.BCrypt.hashpw(password, org.mindrot.jbcrypt.BCrypt.gensalt(12));
            user.setSenhaHash(hash);

            boolean updated = userDAO.update(user);
            if (updated) {
                JOptionPane.showMessageDialog(this, "Senha atualizada com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            } else {
                JOptionPane.showMessageDialog(this, "Erro ao atualizar a senha.",
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

    private static class UserTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private List<User> users = new ArrayList<>();

        UserTableModel(String[] columns) { this.columns = columns; }

        void setUsers(List<User> users) {
            this.users = users;
            fireTableDataChanged();
        }

        User getUserAt(int row) {
            return (row >= 0 && row < users.size()) ? users.get(row) : null;
        }

        @Override public int getRowCount() { return users.size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= users.size()) return null;
            User u = users.get(row);
            return switch (col) {
                case 0 -> u.getNome() != null ? u.getNome() : "-";
                case 1 -> u.getEmail() != null ? u.getEmail() : "-";
                case 2 -> u.getTelefone() != null ? u.getTelefone() : "-";
                case 3 -> u.getRoleId() != null ? "Role ID: " + u.getRoleId() : "-";
                case 4 -> u.getAtivo() != null && u.getAtivo();
                case 5 -> u.getUltimoLogin() != null ? u.getUltimoLogin() : "Nunca";
                default -> null;
            };
        }
    }

    // ==================== Renderers ====================

    private static class AtivoRenderer extends DefaultTableCellRenderer {
        public AtivoRenderer() {
            setHorizontalAlignment(SwingConstants.CENTER);
        }

        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            boolean ativo = value instanceof Boolean && (Boolean) value;
            setText(ativo ? "Ativo" : "Inativo");
            setForeground(ativo ? GREEN_ACTIVE : RED_INACTIVE);
            setHorizontalAlignment(SwingConstants.CENTER);
            return this;
        }
    }
}
