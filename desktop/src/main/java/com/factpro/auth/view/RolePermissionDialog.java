package com.factpro.auth.view;

import com.factpro.auditoria.AuditLogger;
import com.factpro.auth.dao.PermissionDAO;
import com.factpro.auth.dao.RoleDAO;
import com.factpro.auth.model.Permission;
import net.miginfocom.swing.MigLayout;

import javax.swing.*;
import java.awt.*;
import java.util.*;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Dialogo para gerir permissoes de um role.
 * Apresenta permissoes agrupadas por recurso com checkboxes.
 */
public class RolePermissionDialog extends JDialog {

    private final PermissionDAO permissionDAO;
    private final RoleDAO roleDAO;
    private final Long roleId;
    private final String roleName;

    private JPanel permissionsPanel;
    private final Map<Long, JCheckBox> permissionCheckboxes = new HashMap<>();
    private final Map<String, JCheckBox> quickMenuCheckboxes = new HashMap<>();

    private boolean saved = false;

    // Definicao de recursos e suas permissoes
    private static final String[][] MENU_PERMISSIONS = {
        {"menu:dashboard", "Dashboard"},
        {"menu:pos", "POS (Ponto de Venda)"},
        {"menu:vendas", "Vendas"},
        {"menu:produtos", "Produtos"},
        {"menu:clientes", "Clientes"},
        {"menu:stock", "Stock"},
        {"menu:compras", "Compras"},
        {"menu:fornecedores", "Fornecedores"},
        {"menu:relatorios", "Relatorios"},
        {"menu:configuracoes", "Configuracoes"},
        {"menu:usuarios", "Usuarios"},
        {"menu:roles", "Gestao de Roles"},
        {"menu:auditoria", "Auditoria"},
        {"menu:contas_receber", "Contas a Receber"}
    };

    public RolePermissionDialog(Frame parent, Long roleId, String roleName) {
        super(parent, "Permissoes - " + roleName, true);
        this.roleId = roleId;
        this.roleName = roleName;
        this.permissionDAO = new PermissionDAO();
        this.roleDAO = new RoleDAO();

        initComponents();
        setupLayout();
        loadPermissions();

        setSize(750, 600);
        setLocationRelativeTo(parent);
        setDefaultCloseOperation(DISPOSE_ON_CLOSE);
    }

    private void initComponents() {
        permissionsPanel = new JPanel();
    }

    private void setupLayout() {
        setLayout(new BorderLayout());

        // Header panel
        JPanel headerPanel = new JPanel(new MigLayout("ins 20, fillx", "[grow]", "[][]"));
        headerPanel.setBackground(new Color(240, 245, 255));

        JLabel titleLabel = new JLabel("Configurar Permissoes");
        titleLabel.setFont(titleLabel.getFont().deriveFont(Font.BOLD, 18f));
        headerPanel.add(titleLabel, "cell 0 0");

        JLabel subtitleLabel = new JLabel("Role: " + roleName);
        subtitleLabel.setFont(subtitleLabel.getFont().deriveFont(Font.PLAIN, 13f));
        subtitleLabel.setForeground(new Color(100, 100, 100));
        headerPanel.add(subtitleLabel, "cell 0 1");

        add(headerPanel, BorderLayout.NORTH);

        // Main content with scroll
        JPanel mainPanel = new JPanel(new MigLayout("fillx, wrap 1, gap 15, ins 20"));

        // Quick menu permissions
        JPanel menuGroupPanel = createPermissionGroupPanel("Acesso a Modulos", buildMenuPermissions());
        mainPanel.add(menuGroupPanel, "growx");

        // Additional permissions from database
        JPanel additionalPanel = createAdditionalPermissionsPanel();
        if (additionalPanel != null) {
            mainPanel.add(additionalPanel, "growx");
        }

        JScrollPane scrollPane = new JScrollPane(mainPanel);
        scrollPane.setBorder(null);
        add(scrollPane, BorderLayout.CENTER);

        // Button panel
        JPanel btnPanel = new JPanel(new MigLayout("ins 20, flowx, gap 10", "[]push[][][]"));
        btnPanel.setBorder(BorderFactory.createMatteBorder(1, 0, 0, 0, new Color(220, 220, 220)));

        JButton btnSelectAll = new JButton("Selecionar Tudo");
        JButton btnDeselectAll = new JButton("Limpar Tudo");
        JButton btnSave = new JButton("Guardar");
        JButton btnCancel = new JButton("Cancelar");

        styleButton(btnSelectAll, new Color(59, 130, 246));
        styleButton(btnDeselectAll, new Color(107, 114, 128));
        styleButton(btnSave, new Color(34, 139, 34));
        styleButton(btnCancel, new Color(108, 117, 125));

        btnPanel.add(btnSelectAll, "w 140!, h 35!");
        btnPanel.add(btnDeselectAll, "w 140!, h 35!");
        btnPanel.add(btnSave, "w 120!, h 35!");
        btnPanel.add(btnCancel, "w 120!, h 35!");

        btnSelectAll.addActionListener(e -> selectAll(true));
        btnDeselectAll.addActionListener(e -> selectAll(false));
        btnSave.addActionListener(e -> savePermissions());
        btnCancel.addActionListener(e -> dispose());

        add(btnPanel, BorderLayout.SOUTH);
    }

    private JPanel createPermissionGroupPanel(String title, JPanel content) {
        JPanel panel = new JPanel(new MigLayout("fillx, wrap 1, gap 10, ins 15"));
        panel.setBorder(BorderFactory.createTitledBorder(
            BorderFactory.createLineBorder(new Color(200, 200, 200)),
            title,
            javax.swing.border.TitledBorder.LEFT,
            javax.swing.border.TitledBorder.TOP,
            new Font("Segoe UI", Font.BOLD, 13),
            new Color(50, 50, 50)
        ));

        panel.add(content, "growx");
        return panel;
    }

    private JPanel buildMenuPermissions() {
        JPanel panel = new JPanel(new MigLayout("fillx, wrap 4, gap 12, ins 5"));

        for (String[] menuPerm : MENU_PERMISSIONS) {
            String permName = menuPerm[0];
            String label = menuPerm[1];

            JCheckBox checkbox = new JCheckBox(label);
            checkbox.setFont(checkbox.getFont().deriveFont(Font.PLAIN, 13f));
            checkbox.putClientProperty("permission_name", permName);
            
            permissionCheckboxes.put(null, checkbox); // Will use permission_name instead
            quickMenuCheckboxes.put(permName, checkbox);
            panel.add(checkbox, "growx");
        }

        return panel;
    }

    private JPanel createAdditionalPermissionsPanel() {
        // Fetch permissions that are not menu-related
        List<Permission> additionalPerms = permissionDAO.findAll().stream()
            .filter(p -> !p.getNome().startsWith("menu:"))
            .collect(Collectors.toList());

        if (additionalPerms.isEmpty()) {
            return null;
        }

        // Group by recurso
        Map<String, List<Permission>> groupedByResource = additionalPerms.stream()
            .collect(Collectors.groupingBy(Permission::getRecurso));

        JPanel panel = new JPanel(new MigLayout("fillx, wrap 1, gap 15"));

        for (Map.Entry<String, List<Permission>> entry : groupedByResource.entrySet()) {
            String recurso = entry.getKey();
            List<Permission> perms = entry.getValue();

            JPanel resourcePanel = new JPanel(new MigLayout("fillx, wrap 3, gap 10, ins 5"));
            
            for (Permission perm : perms) {
                JCheckBox checkbox = new JCheckBox(perm.getDescricao() != null ? perm.getDescricao() : perm.getNome());
                checkbox.setFont(checkbox.getFont().deriveFont(Font.PLAIN, 13f));
                checkbox.putClientProperty("permission_id", perm.getId());
                permissionCheckboxes.put(perm.getId(), checkbox);
                resourcePanel.add(checkbox, "growx");
            }

            JPanel groupPanel = createPermissionGroupPanel(
                recurso.substring(0, 1).toUpperCase() + recurso.substring(1), 
                resourcePanel
            );
            panel.add(groupPanel, "growx");
        }

        return panel;
    }

    private void loadPermissions() {
        // Get current permissions for this role
        List<String> currentPermissionNames = permissionDAO.findPermissionNamesByRoleId(roleId);

        // Check the checkboxes that match
        for (Map.Entry<String, JCheckBox> entry : quickMenuCheckboxes.entrySet()) {
            if (currentPermissionNames.contains(entry.getKey())) {
                entry.getValue().setSelected(true);
            }
        }

        // Load additional permissions by ID
        for (Map.Entry<Long, JCheckBox> entry : permissionCheckboxes.entrySet()) {
            if (entry.getKey() != null) {
                Permission perm = permissionDAO.findById(entry.getKey());
                if (perm != null && currentPermissionNames.contains(perm.getNome())) {
                    entry.getValue().setSelected(true);
                }
            }
        }
    }

    private void selectAll(boolean select) {
        quickMenuCheckboxes.values().forEach(cb -> cb.setSelected(select));
        permissionCheckboxes.values().forEach(cb -> cb.setSelected(select));
    }

    private void savePermissions() {
        // Collect selected menu permissions
        List<Long> selectedPermissionIds = new ArrayList<>();

        // From menu checkboxes
        for (Map.Entry<String, JCheckBox> entry : quickMenuCheckboxes.entrySet()) {
            if (entry.getValue().isSelected()) {
                Permission perm = permissionDAO.findByNome(entry.getKey());
                if (perm != null) {
                    selectedPermissionIds.add(perm.getId());
                }
            }
        }

        // From additional permission checkboxes
        for (Map.Entry<Long, JCheckBox> entry : permissionCheckboxes.entrySet()) {
            if (entry.getKey() != null && entry.getValue().isSelected()) {
                selectedPermissionIds.add(entry.getKey());
            }
        }

        // Sync permissions
        boolean success = permissionDAO.syncRolePermissions(roleId, selectedPermissionIds);

        if (success) {
            // Registrar log de auditoria
            AuditLogger.logPermissionChange(roleId, roleName, selectedPermissionIds.size());
            
            JOptionPane.showMessageDialog(this,
                "Permissoes atualizadas com sucesso!",
                "Sucesso",
                JOptionPane.INFORMATION_MESSAGE);
            saved = true;
            dispose();
        } else {
            JOptionPane.showMessageDialog(this,
                "Erro ao atualizar permissoes.",
                "Erro",
                JOptionPane.ERROR_MESSAGE);
        }
    }

    private void styleButton(JButton button, Color bgColor) {
        button.setFont(button.getFont().deriveFont(Font.PLAIN, 13f));
        button.setBackground(bgColor);
        button.setForeground(Color.WHITE);
        button.setFocusPainted(false);
        button.setBorderPainted(false);
        button.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
    }

    public boolean isSaved() {
        return saved;
    }
}
