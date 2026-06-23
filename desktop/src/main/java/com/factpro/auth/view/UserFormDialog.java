package com.factpro.auth.view;

import com.factpro.auth.dao.PermissionDAO;
import com.factpro.auth.dao.RoleDAO;
import com.factpro.auth.dao.UserDAO;
import com.factpro.auth.model.Role;
import com.factpro.auth.model.User;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;

import javax.swing.*;
import java.awt.*;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Dialog for creating and editing users.
 */
public class UserFormDialog extends JDialog {

    private final UserDAO userDAO;
    private final User user;
    private final List<Role> roles;
    private final boolean isNew;

    private JTextField nomeField;
    private JTextField emailField;
    private JTextField telefoneField;
    private JPasswordField senhaField;
    private JPasswordField confirmSenhaField;
    private JComboBox<String> roleComboBox;
    private JCheckBox ativoCheckBox;

    private boolean saved = false;

    public UserFormDialog(Frame parent, User user, List<Role> roles) {
        super(parent, user == null ? "Novo Utilizador" : "Editar Utilizador", true);
        this.user = user;
        this.roles = roles;
        this.isNew = user == null;
        this.userDAO = new UserDAO();

        initComponents();
        setupLayout();
        loadData();

        setSize(450, 420);
        setLocationRelativeTo(parent);
        setDefaultCloseOperation(DISPOSE_ON_CLOSE);
        getRootPane().setDefaultButton(null);
    }

    private void initComponents() {
        nomeField = new JTextField();
        emailField = new JTextField();
        telefoneField = new JTextField();
        senhaField = new JPasswordField();
        confirmSenhaField = new JPasswordField();
        ativoCheckBox = new JCheckBox("Ativo");

        // Create role items with permissions info
        PermissionDAO permDAO = new PermissionDAO();
        String[] roleItems = roles.stream()
                .map(r -> {
                    String nome = r.getNome() != null ? r.getNome() : "Role ID: " + r.getId();
                    List<String> perms = permDAO.findPermissionNamesByRoleId(r.getId());
                    int menuCount = (int) perms.stream().filter(p -> p.startsWith("menu:")).count();
                    return String.format("%s (%d permissoes, %d modulos)", nome, perms.size(), menuCount);
                })
                .toArray(String[]::new);
        roleComboBox = new JComboBox<>(roleItems);
        roleComboBox.setRenderer(new DefaultListCellRenderer() {
            @Override
            public Component getListCellRendererComponent(JList<?> list, Object value, 
                    int index, boolean isSelected, boolean cellHasFocus) {
                JLabel label = (JLabel) super.getListCellRendererComponent(list, value, index, isSelected, cellHasFocus);
                if (index >= 0 && index < roles.size()) {
                    Role role = roles.get(index);
                    label.setToolTipText(role.getDescricao() != null ? role.getDescricao() : "");
                }
                return label;
            }
        });
    }

    private void setupLayout() {
        JPanel content = new JPanel(new MigLayout("fillx, wrap 2, gap 8, ins 20", "[right]15[grow]"));

        content.add(new JLabel("Nome:"));
        nomeField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Nome completo");
        content.add(nomeField, "growx, h 32");

        content.add(new JLabel("Email:"));
        emailField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "email@exemplo.com");
        content.add(emailField, "growx, h 32");

        content.add(new JLabel("Telefone:"));
        telefoneField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "+258 84 000 0000");
        content.add(telefoneField, "growx, h 32");

        content.add(new JLabel("Senha:"));
        if (isNew) {
            senhaField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Minimo 8 caracteres");
        } else {
            senhaField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Deixe vazio para manter a atual");
        }
        content.add(senhaField, "growx, h 32");

        content.add(new JLabel("Confirmar Senha:"));
        confirmSenhaField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, isNew ? "Confirmar senha" : "Confirmar nova senha");
        content.add(confirmSenhaField, "growx, h 32");

        content.add(new JLabel("Role:"));
        JPanel rolePanel = new JPanel(new MigLayout("ins 0, gap 5", "[grow][]"));
        rolePanel.add(roleComboBox, "growx, h 32");
        
        JButton btnVerPermissoes = new JButton("Ver Permissoes");
        btnVerPermissoes.setFont(btnVerPermissoes.getFont().deriveFont(Font.PLAIN, 11f));
        btnVerPermissoes.setBackground(new Color(111, 66, 193));
        btnVerPermissoes.setForeground(Color.WHITE);
        btnVerPermissoes.setFocusPainted(false);
        btnVerPermissoes.setPreferredSize(new Dimension(120, 32));
        btnVerPermissoes.addActionListener(e -> showRolePermissions());
        rolePanel.add(btnVerPermissoes, "h 32!");
        
        content.add(rolePanel, "growx");
        
        // Role description label
        JLabel roleDescLabel = new JLabel();
        roleDescLabel.setFont(roleDescLabel.getFont().deriveFont(Font.PLAIN, 11f));
        roleDescLabel.setForeground(new Color(100, 100, 100));
        content.add(roleDescLabel, "span 2, growx");
        
        // Update role description when selection changes
        roleComboBox.addActionListener(e -> {
            int idx = roleComboBox.getSelectedIndex();
            if (idx >= 0 && idx < roles.size()) {
                Role r = roles.get(idx);
                String desc = r.getResponsabilidades() != null ? r.getResponsabilidades() : r.getDescricao();
                roleDescLabel.setText(desc != null ? "Responsabilidades: " + desc : "");
            }
        });

        content.add(new JLabel(""));
        ativoCheckBox.setFont(ativoCheckBox.getFont().deriveFont(Font.PLAIN, 13f));
        content.add(ativoCheckBox, "gap left 0");

        // Buttons panel
        JPanel btnPanel = new JPanel(new MigLayout("ins 0, gap 10", "[]push[][]"));
        JButton btnSave = new JButton("Guardar");
        JButton btnCancel = new JButton("Cancelar");

        btnSave.setFont(btnSave.getFont().deriveFont(Font.PLAIN, 13f));
        btnSave.setBackground(new Color(34, 139, 34));
        btnSave.setForeground(Color.WHITE);
        btnSave.setFocusPainted(false);
        btnCancel.setFont(btnCancel.getFont().deriveFont(Font.PLAIN, 13f));
        btnCancel.setBackground(new Color(108, 117, 125));
        btnCancel.setForeground(Color.WHITE);
        btnCancel.setFocusPainted(false);

        btnPanel.add(btnSave, "h 35, w 100");
        btnPanel.add(btnCancel, "h 35, w 100");

        content.add(btnPanel, "span 2, growx");

        btnSave.addActionListener(e -> saveUser());
        btnCancel.addActionListener(e -> dispose());

        add(content);
    }

    private void loadData() {
        if (!isNew && user != null) {
            nomeField.setText(user.getNome());
            emailField.setText(user.getEmail());
            telefoneField.setText(user.getTelefone());
            ativoCheckBox.setSelected(user.getAtivo() != null && user.getAtivo());

            // Select the correct role
            if (user.getRoleId() != null) {
                for (int i = 0; i < roles.size(); i++) {
                    if (roles.get(i).getId().equals(user.getRoleId())) {
                        roleComboBox.setSelectedIndex(i);
                        break;
                    }
                }
            }
        } else {
            ativoCheckBox.setSelected(true);
        }
    }

    private void saveUser() {
        String nome = nomeField.getText().trim();
        String email = emailField.getText().trim();
        String telefone = telefoneField.getText().trim();
        String senha = new String(senhaField.getPassword());
        String confirmSenha = new String(confirmSenhaField.getPassword());
        boolean ativo = ativoCheckBox.isSelected();

        // Validation
        if (nome.isEmpty()) {
            JOptionPane.showMessageDialog(this, "O nome e obrigatorio.",
                    "Erro de Validacao", JOptionPane.WARNING_MESSAGE);
            return;
        }

        if (email.isEmpty()) {
            JOptionPane.showMessageDialog(this, "O email e obrigatorio.",
                    "Erro de Validacao", JOptionPane.WARNING_MESSAGE);
            return;
        }

        // Password validation
        if (isNew) {
            if (senha.length() < 8) {
                JOptionPane.showMessageDialog(this, "A senha deve ter pelo menos 8 caracteres.",
                        "Erro de Validacao", JOptionPane.WARNING_MESSAGE);
                return;
            }
            if (!senha.equals(confirmSenha)) {
                JOptionPane.showMessageDialog(this, "As senhas nao coincidem.",
                        "Erro de Validacao", JOptionPane.WARNING_MESSAGE);
                return;
            }
        }

        // Build user object
        User userToSave;
        if (isNew) {
            userToSave = new User();
            String hash = org.mindrot.jbcrypt.BCrypt.hashpw(senha, org.mindrot.jbcrypt.BCrypt.gensalt(12));
            userToSave.setSenhaHash(hash);
        } else {
            userToSave = user;
            // Only update password if provided
            if (!senha.isEmpty()) {
                if (senha.length() < 8) {
                    JOptionPane.showMessageDialog(this, "A senha deve ter pelo menos 8 caracteres.",
                            "Erro de Validacao", JOptionPane.WARNING_MESSAGE);
                    return;
                }
                if (!senha.equals(confirmSenha)) {
                    JOptionPane.showMessageDialog(this, "As senhas nao coincidem.",
                            "Erro de Validacao", JOptionPane.WARNING_MESSAGE);
                    return;
                }
                String hash = org.mindrot.jbcrypt.BCrypt.hashpw(senha, org.mindrot.jbcrypt.BCrypt.gensalt(12));
                userToSave.setSenhaHash(hash);
            }
        }

        userToSave.setNome(nome);
        userToSave.setEmail(email);
        userToSave.setTelefone(telefone);
        userToSave.setAtivo(ativo);

        // Set role ID
        if (!roles.isEmpty() && roleComboBox.getSelectedIndex() >= 0) {
            Role selectedRole = roles.get(roleComboBox.getSelectedIndex());
            userToSave.setRoleId(selectedRole.getId());
        }

        boolean success;
        if (isNew) {
            Long id = userDAO.save(userToSave);
            success = id != null;
        } else {
            success = userDAO.update(userToSave);
        }

        if (success) {
            JOptionPane.showMessageDialog(this,
                    isNew ? "Utilizador criado com sucesso." : "Utilizador atualizado com sucesso.",
                    "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            saved = true;
            dispose();
        } else {
            JOptionPane.showMessageDialog(this,
                    "Erro ao " + (isNew ? "criar" : "atualizar") + " o utilizador.",
                    "Erro", JOptionPane.ERROR_MESSAGE);
        }
    }

    public boolean isSaved() {
        return saved;
    }

    private void showRolePermissions() {
        int idx = roleComboBox.getSelectedIndex();
        if (idx < 0 || idx >= roles.size()) {
            JOptionPane.showMessageDialog(this,
                "Selecione um role primeiro.",
                "Atencao",
                JOptionPane.WARNING_MESSAGE);
            return;
        }

        Role role = roles.get(idx);
        PermissionDAO permDAO = new PermissionDAO();
        List<String> perms = permDAO.findPermissionNamesByRoleId(role.getId());

        // Group permissions by resource
        String menuPerms = perms.stream()
            .filter(p -> p.startsWith("menu:"))
            .map(p -> p.replace("menu:", ""))
            .collect(Collectors.joining(", "));

        String otherPerms = perms.stream()
            .filter(p -> !p.startsWith("menu:"))
            .collect(Collectors.joining(", "));

        StringBuilder sb = new StringBuilder();
        sb.append("<html><body style='width: 400px'>");
        sb.append("<h3>").append(role.getNome()).append("</h3>");
        
        if (role.getResponsabilidades() != null) {
            sb.append("<p><b>Responsabilidades:</b> ").append(role.getResponsabilidades()).append("</p>");
        }
        
        sb.append("<hr>");
        sb.append("<p><b>Modulos Acesso:</b></p><ul>");
        for (String menu : menuPerms.split(", ")) {
            sb.append("<li>").append(menu.substring(0, 1).toUpperCase()).append(menu.substring(1)).append("</li>");
        }
        sb.append("</ul>");
        
        if (!otherPerms.isEmpty()) {
            sb.append("<p><b>Operacoes:</b></p><ul>");
            for (String perm : otherPerms.split(", ")) {
                sb.append("<li>").append(perm).append("</li>");
            }
            sb.append("</ul>");
        }
        
        sb.append("<hr><p style='color: #666'>Total: ").append(perms.size()).append(" permissoes</p>");
        sb.append("</body></html>");

        JDialog dialog = new JDialog((Frame) SwingUtilities.getWindowAncestor(this), 
            "Permissoes - " + role.getNome(), true);
        JEditorPane textArea = new JEditorPane();
        textArea.setEditable(false);
        textArea.setContentType("text/html");
        textArea.setText(sb.toString());
        textArea.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        textArea.setMargin(new Insets(10, 10, 10, 10));
        
        JScrollPane scrollPane = new JScrollPane(textArea);
        scrollPane.setPreferredSize(new Dimension(450, 400));
        
        dialog.setLayout(new BorderLayout());
        dialog.add(scrollPane, BorderLayout.CENTER);
        
        JButton btnClose = new JButton("Fechar");
        btnClose.addActionListener(e -> dialog.dispose());
        JPanel btnPanel = new JPanel();
        btnPanel.add(btnClose);
        dialog.add(btnPanel, BorderLayout.SOUTH);
        
        dialog.setSize(480, 450);
        dialog.setLocationRelativeTo(this);
        dialog.setDefaultCloseOperation(DISPOSE_ON_CLOSE);
        dialog.setVisible(true);
    }
}
