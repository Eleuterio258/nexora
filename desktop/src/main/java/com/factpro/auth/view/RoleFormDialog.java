package com.factpro.auth.view;

import com.factpro.auth.dao.RoleDAO;
import com.factpro.auth.model.Role;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;

import javax.swing.*;
import java.awt.*;

/**
 * Dialog for creating and editing roles.
 */
public class RoleFormDialog extends JDialog {

    private final RoleDAO roleDAO;
    private Role role;
    private final boolean isNew;

    private JTextField nomeField;
    private JTextArea descricaoArea;
    private JTextArea responsabilidadesArea;

    private boolean saved = false;

    public RoleFormDialog(Frame parent, Role role) {
        super(parent, role == null ? "Novo Role" : "Editar Role", true);
        this.role = role;
        this.isNew = role == null;
        this.roleDAO = new RoleDAO();

        initComponents();
        setupLayout();
        loadData();

        setSize(450, 320);
        setLocationRelativeTo(parent);
        setDefaultCloseOperation(DISPOSE_ON_CLOSE);
    }

    private void initComponents() {
        nomeField = new JTextField();
        descricaoArea = new JTextArea(4, 20);
        descricaoArea.setLineWrap(true);
        descricaoArea.setWrapStyleWord(true);
        responsabilidadesArea = new JTextArea(4, 20);
        responsabilidadesArea.setLineWrap(true);
        responsabilidadesArea.setWrapStyleWord(true);
    }

    private void setupLayout() {
        JPanel content = new JPanel(new MigLayout("fillx, wrap 2, gap 8, ins 20", "[right]15[grow]"));

        content.add(new JLabel("Nome:"));
        nomeField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Nome do role");
        content.add(nomeField, "growx, h 32");

        content.add(new JLabel("Descricao:"));
        JScrollPane scrollPane = new JScrollPane(descricaoArea);
        scrollPane.setBorder(BorderFactory.createLineBorder(new Color(200, 200, 200)));
        content.add(scrollPane, "growx, h 80");

        content.add(new JLabel("Responsabilidades:"));
        JScrollPane respScrollPane = new JScrollPane(responsabilidadesArea);
        respScrollPane.setBorder(BorderFactory.createLineBorder(new Color(200, 200, 200)));
        content.add(respScrollPane, "growx, h 80");

        // Buttons panel
        JPanel btnPanel = new JPanel(new MigLayout("ins 0, gap 10", "[]push[][][]"));
        JButton btnSave = new JButton("Guardar");
        JButton btnPermissoes = new JButton("Gerir Permissoes");
        JButton btnCancel = new JButton("Cancelar");

        btnSave.setFont(btnSave.getFont().deriveFont(Font.PLAIN, 13f));
        btnSave.setBackground(new Color(34, 139, 34));
        btnSave.setForeground(Color.WHITE);
        btnSave.setFocusPainted(false);
        btnPermissoes.setFont(btnPermissoes.getFont().deriveFont(Font.PLAIN, 13f));
        btnPermissoes.setBackground(new Color(111, 66, 193));
        btnPermissoes.setForeground(Color.WHITE);
        btnPermissoes.setFocusPainted(false);
        btnCancel.setFont(btnCancel.getFont().deriveFont(Font.PLAIN, 13f));
        btnCancel.setBackground(new Color(108, 117, 125));
        btnCancel.setForeground(Color.WHITE);
        btnCancel.setFocusPainted(false);

        // Only show permissions button for existing roles
        if (!isNew) {
            btnPanel.add(btnSave, "h 35, w 100");
            btnPanel.add(btnPermissoes, "h 35, w 140");
            btnPanel.add(btnCancel, "h 35, w 100");
        } else {
            btnPanel.add(btnSave, "h 35, w 100");
            btnPanel.add(btnCancel, "h 35, w 100");
        }

        content.add(btnPanel, "span 2, growx");

        btnSave.addActionListener(e -> saveRole());
        btnPermissoes.addActionListener(e -> openPermissionManager());
        btnCancel.addActionListener(e -> dispose());

        add(content);
    }

    private void loadData() {
        if (!isNew && role != null) {
            nomeField.setText(role.getNome());
            descricaoArea.setText(role.getDescricao());
            responsabilidadesArea.setText(role.getResponsabilidades() != null ? role.getResponsabilidades() : "");
        }
    }

    private void saveRole() {
        String nome = nomeField.getText().trim();
        String descricao = descricaoArea.getText().trim();
        String responsabilidades = responsabilidadesArea.getText().trim();

        if (nome.isEmpty()) {
            JOptionPane.showMessageDialog(this, "O nome e obrigatorio.",
                    "Erro de Validacao", JOptionPane.WARNING_MESSAGE);
            return;
        }

        Role roleToSave;
        if (isNew) {
            roleToSave = new Role();
        } else {
            roleToSave = role;
        }

        roleToSave.setNome(nome);
        roleToSave.setDescricao(descricao);
        roleToSave.setResponsabilidades(responsabilidades);

        boolean success;
        if (isNew) {
            Long id = roleDAO.save(roleToSave);
            success = id != null;
            if (success) {
                // Update the role reference with the new ID
                roleToSave.setId(id);
            }
        } else {
            success = roleDAO.update(roleToSave);
        }

        if (success) {
            JOptionPane.showMessageDialog(this,
                    isNew ? "Role criado com sucesso." : "Role atualizado com sucesso.",
                    "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            saved = true;
            // Update the local role reference
            if (isNew && roleToSave.getId() != null) {
                this.role = roleToSave;
            }
            dispose();
        } else {
            JOptionPane.showMessageDialog(this,
                    "Erro ao " + (isNew ? "criar" : "atualizar") + " o role.",
                    "Erro", JOptionPane.ERROR_MESSAGE);
        }
    }

    private void openPermissionManager() {
        if (role == null || role.getId() == null) {
            JOptionPane.showMessageDialog(this,
                    "Guarde o role primeiro antes de gerir permissoes.",
                    "Erro", JOptionPane.WARNING_MESSAGE);
            return;
        }

        Frame parent = (Frame) SwingUtilities.getWindowAncestor(this);
        RolePermissionDialog dialog = new RolePermissionDialog(parent, role.getId(), role.getNome());
        dialog.setVisible(true);
        // Don't dispose this dialog, just close the permission dialog
    }

    public boolean isSaved() {
        return saved;
    }
}
