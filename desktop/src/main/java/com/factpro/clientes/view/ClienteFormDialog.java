package com.factpro.clientes.view;

import com.factpro.clientes.model.Cliente;
import com.factpro.clientes.service.ClienteService;
import com.factpro.clientes.dao.ClienteDAO;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;

/**
 * Client form dialog for creating and editing clients.
 */
public class ClienteFormDialog extends JDialog {

    private static final Logger logger = LoggerFactory.getLogger(ClienteFormDialog.class);

    private final ClienteService clienteService;
    private final Cliente editingCliente;
    private boolean saved = false;

    private JTextField nomeField;
    private JTextField codigoField;
    private JTextField telefoneField;
    private JTextField emailField;
    private JTextField nifField;
    private JTextArea enderecoArea;
    private JTextField limiteCreditoField;
    private JComboBox<String> tipoPrecoCombo;

    public ClienteFormDialog(Frame parent, Cliente cliente) {
        super(parent, cliente == null ? "Novo Cliente" : "Editar Cliente", true);
        this.editingCliente = cliente;

        ClienteDAO clienteDAO = new ClienteDAO();
        clienteService = new ClienteService(clienteDAO);

        setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
        setSize(500, 520);
        setLocationRelativeTo(parent);

        initComponents();
        setupLayout();
        setupListeners();

        if (editingCliente != null) populateForm();
    }

    private void initComponents() {
        nomeField = new JTextField(25);
        codigoField = new JTextField(15);
        telefoneField = new JTextField(15);
        emailField = new JTextField(20);
        nifField = new JTextField(15);
        enderecoArea = new JTextArea(2, 20);
        enderecoArea.setLineWrap(true);
        enderecoArea.setWrapStyleWord(true);
        limiteCreditoField = new JTextField(12);
        tipoPrecoCombo = new JComboBox<>(new String[]{"Normal", "Revendedor", "Grossista", "VIP"});
    }

    private void setupLayout() {
        setLayout(new MigLayout("fill, wrap 2, ins 20, gap 8 12",
                "[right, 130][grow, 250]"));

        add(new JLabel("<html><b>Dados do Cliente</b></html>"), "span 2, gapy 0 10");

        add(new JLabel("Nome: *"));
        add(nomeField, "growx");

        add(new JLabel("Codigo:"));
        add(codigoField, "growx");

        add(new JLabel("Telefone:"));
        add(telefoneField, "growx");

        add(new JLabel("Email:"));
        add(emailField, "growx");

        add(new JLabel("NIF:"));
        add(nifField, "growx");

        add(new JLabel("Endereco:"));
        add(new JScrollPane(enderecoArea), "growx, h 50");

        add(new JLabel("Limite de Credito:"));
        add(limiteCreditoField);

        add(new JLabel("Tipo de Preco:"));
        add(tipoPrecoCombo, "growx");

        // Buttons
        add(new JLabel(), "gapy 15");
        JPanel btnPanel = new JPanel(new MigLayout("ins 0, gap 10"));
        JButton saveBtn = new JButton("Guardar");
        JButton cancelBtn = new JButton("Cancelar");
        saveBtn.setFont(saveBtn.getFont().deriveFont(Font.BOLD, 13f));
        btnPanel.add(saveBtn);
        btnPanel.add(cancelBtn);
        add(btnPanel, "span 2, center");

        saveBtn.addActionListener(e -> saveCliente());
        cancelBtn.addActionListener(e -> dispose());

        getRootPane().setDefaultButton(saveBtn);
        KeyStroke escape = KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(escape, "cancel");
        getRootPane().getActionMap().put("cancel", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) { dispose(); }
        });
    }

    private void setupListeners() {
        // Auto-generate code if empty on new
        if (editingCliente == null) {
            nomeField.addFocusListener(new java.awt.event.FocusAdapter() {
                @Override
                public void focusLost(java.awt.event.FocusEvent e) {
                    if (codigoField.getText().trim().isEmpty() && !nomeField.getText().trim().isEmpty()) {
                        // Generate a simple code from name
                        String name = nomeField.getText().trim().toUpperCase();
                        String code = "CLI-" + name.replaceAll("[^A-Z]", "").substring(0, Math.min(4, name.replaceAll("[^A-Z]", "").length()));
                        codigoField.setText(code);
                    }
                }
            });
        }
    }

    private void populateForm() {
        if (editingCliente == null) return;

        nomeField.setText(editingCliente.getNome());
        codigoField.setText(editingCliente.getCodigo());
        telefoneField.setText(editingCliente.getTelefone());
        emailField.setText(editingCliente.getEmail());
        nifField.setText(editingCliente.getNif());
        enderecoArea.setText(editingCliente.getEndereco());
        if (editingCliente.getLimiteCredito() != null)
            limiteCreditoField.setText(String.valueOf(editingCliente.getLimiteCredito()));
        if (editingCliente.getTipoPreco() != null)
            tipoPrecoCombo.setSelectedItem(editingCliente.getTipoPreco());
    }

    private void saveCliente() {
        String nome = nomeField.getText().trim();
        if (nome.isEmpty()) {
            JOptionPane.showMessageDialog(this, "O campo Nome e obrigatorio.",
                    "Validacao", JOptionPane.WARNING_MESSAGE);
            nomeField.requestFocusInWindow();
            return;
        }

        Cliente cliente = editingCliente != null ? editingCliente : new Cliente();
        cliente.setNome(nome);
        cliente.setCodigo(codigoField.getText().trim());
        cliente.setTelefone(telefoneField.getText().trim());
        cliente.setEmail(emailField.getText().trim());
        cliente.setNif(nifField.getText().trim());
        cliente.setEndereco(enderecoArea.getText().trim());

        String limiteText = limiteCreditoField.getText().trim();
        if (!limiteText.isEmpty()) {
            try { cliente.setLimiteCredito(Double.parseDouble(limiteText.replace(",", "."))); }
            catch (NumberFormatException e) { cliente.setLimiteCredito(null); }
        } else {
            cliente.setLimiteCredito(null);
        }

        cliente.setTipoPreco((String) tipoPrecoCombo.getSelectedItem());
        cliente.setAtivo(true);

        try {
            if (editingCliente == null) {
                clienteService.save(cliente);
                JOptionPane.showMessageDialog(this, "Cliente criado com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            } else {
                clienteService.update(cliente);
                JOptionPane.showMessageDialog(this, "Cliente atualizado com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            }
            saved = true;
            dispose();
        } catch (Exception ex) {
            logger.error("Erro ao guardar cliente", ex);
            JOptionPane.showMessageDialog(this, "Erro ao guardar cliente: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
        }
    }

    public boolean isSaved() {
        return saved;
    }
}
