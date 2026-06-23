package com.factpro.fornecedores.view;

import com.factpro.fornecedores.model.Fornecedor;
import com.factpro.fornecedores.service.FornecedorService;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;

/**
 * Supplier form dialog for creating and editing suppliers.
 */
public class FornecedorFormDialog extends JDialog {

    private static final Logger logger = LoggerFactory.getLogger(FornecedorFormDialog.class);

    private final FornecedorService fornecedorService;
    private final Fornecedor editingFornecedor;
    private boolean saved = false;

    private JTextField nomeField;
    private JTextField contatoField;
    private JTextField telefoneField;
    private JTextField emailField;
    private JTextField nifField;
    private JTextArea enderecoArea;
    private JCheckBox ativoCheckBox;

    public FornecedorFormDialog(Frame parent, Fornecedor fornecedor, FornecedorService fornecedorService) {
        super(parent, fornecedor == null ? "Novo Fornecedor" : "Editar Fornecedor", true);
        this.editingFornecedor = fornecedor;
        this.fornecedorService = fornecedorService;

        setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
        setSize(500, 450);
        setLocationRelativeTo(parent);

        initComponents();
        setupLayout();
        setupListeners();

        if (editingFornecedor != null) populateForm();
    }

    private void initComponents() {
        nomeField = new JTextField(25);
        contatoField = new JTextField(20);
        telefoneField = new JTextField(15);
        emailField = new JTextField(20);
        emailField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "email@exemplo.com");
        nifField = new JTextField(15);
        nifField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "NIF do fornecedor");

        enderecoArea = new JTextArea(3, 25);
        enderecoArea.setLineWrap(true);
        enderecoArea.setWrapStyleWord(true);

        ativoCheckBox = new JCheckBox("Ativo", true);
    }

    private void setupLayout() {
        setLayout(new MigLayout("fill, wrap 2, ins 20, gap 8 12",
                "[right, 130][grow, 250]"));

        add(new JLabel("<html><b>Dados do Fornecedor</b></html>"), "span 2, gapy 0 10");

        add(new JLabel("Nome: *"));
        add(nomeField, "growx");

        add(new JLabel("Contato:"));
        add(contatoField, "growx");

        add(new JLabel("Telefone:"));
        add(telefoneField, "growx");

        add(new JLabel("Email:"));
        add(emailField, "growx");

        add(new JLabel("NIF:"));
        add(nifField, "growx");

        add(new JLabel("Endereco:"));
        add(new JScrollPane(enderecoArea), "growx, h 70");

        add(ativoCheckBox, "span 2, gapy 5");

        // Buttons
        add(new JLabel(), "gapy 15");
        JPanel btnPanel = new JPanel(new MigLayout("ins 0, gap 10"));
        JButton saveBtn = new JButton("Guardar");
        JButton cancelBtn = new JButton("Cancelar");
        saveBtn.setFont(saveBtn.getFont().deriveFont(Font.BOLD, 13f));
        cancelBtn.setFont(cancelBtn.getFont().deriveFont(Font.PLAIN, 13f));
        btnPanel.add(saveBtn);
        btnPanel.add(cancelBtn);
        add(btnPanel, "span 2, center");

        saveBtn.addActionListener(e -> saveFornecedor());
        cancelBtn.addActionListener(e -> dispose());

        getRootPane().setDefaultButton(saveBtn);
        KeyStroke escape = KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(escape, "cancel");
        getRootPane().getActionMap().put("cancel", new AbstractAction() {
            @Override public void actionPerformed(ActionEvent e) { dispose(); }
        });
    }

    private void setupListeners() {
        // No additional listeners needed
    }

    private void populateForm() {
        if (editingFornecedor == null) return;

        nomeField.setText(editingFornecedor.getNome());
        contatoField.setText(editingFornecedor.getContato());
        telefoneField.setText(editingFornecedor.getTelefone());
        emailField.setText(editingFornecedor.getEmail());
        nifField.setText(editingFornecedor.getNif());
        enderecoArea.setText(editingFornecedor.getEndereco());
        ativoCheckBox.setSelected(editingFornecedor.getAtivo() == null || editingFornecedor.getAtivo());
    }

    private void saveFornecedor() {
        // Validation
        String nome = nomeField.getText().trim();
        if (nome.isEmpty()) {
            JOptionPane.showMessageDialog(this, "O campo Nome e obrigatorio.",
                    "Validacao", JOptionPane.WARNING_MESSAGE);
            nomeField.requestFocusInWindow();
            return;
        }

        try {
            Fornecedor fornecedor = editingFornecedor != null ? editingFornecedor : new Fornecedor();
            fornecedor.setNome(nome);
            fornecedor.setContato(contatoField.getText().trim());
            fornecedor.setTelefone(telefoneField.getText().trim());
            fornecedor.setEmail(emailField.getText().trim());
            fornecedor.setNif(nifField.getText().trim());
            fornecedor.setEndereco(enderecoArea.getText().trim());
            fornecedor.setAtivo(ativoCheckBox.isSelected());

            if (editingFornecedor == null) {
                fornecedorService.save(fornecedor);
                JOptionPane.showMessageDialog(this, "Fornecedor criado com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            } else {
                fornecedorService.update(fornecedor);
                JOptionPane.showMessageDialog(this, "Fornecedor atualizado com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            }
            saved = true;
            dispose();
        } catch (Exception ex) {
            logger.error("Erro ao guardar fornecedor", ex);
            JOptionPane.showMessageDialog(this, "Erro ao guardar fornecedor: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
        }
    }

    public boolean isSaved() {
        return saved;
    }
}
