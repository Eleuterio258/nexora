package com.factpro.contas.view;

import com.factpro.contas.model.ContaReceber;
import com.factpro.contas.service.ContaReceberService;
import com.factpro.core.util.CurrencyFormatter;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;
import java.util.Map;

/**
 * Dialog to register a payment for an accounts receivable entry.
 */
public class PagamentoContaDialog extends JDialog {

    private static final Logger logger = LoggerFactory.getLogger(PagamentoContaDialog.class);

    private final ContaReceberService service;
    private final ContaReceber conta;
    private boolean saved = false;

    private JLabel clienteLabel;
    private JLabel valorTotalLabel;
    private JLabel valorPagoLabel;
    private JLabel valorPendenteLabel;
    private JTextField valorPagamentoField;
    private JTextArea observacoesArea;

    public PagamentoContaDialog(Frame parent, ContaReceberService service,
                                 Map<Long, String> clienteNames, ContaReceber conta) {
        super(parent, "Registar Pagamento", true);
        this.service = service;
        this.conta = conta;

        setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
        setSize(450, 400);
        setLocationRelativeTo(parent);

        initComponents(clienteNames);
        setupLayout();
    }

    private void initComponents(Map<Long, String> clienteNames) {
        String clienteNome = conta != null
                ? clienteNames.getOrDefault(conta.getClienteId(), "CLI-" + conta.getClienteId())
                : "";

        clienteLabel = new JLabel("Cliente: " + clienteNome);
        valorTotalLabel = new JLabel("Valor Total: " + (conta != null ? CurrencyFormatter.format(conta.getValorTotal()) : ""));
        valorPagoLabel = new JLabel("Valor Pago: " + (conta != null ? CurrencyFormatter.format(conta.getValorPago()) : ""));
        double pendente = conta != null ? (conta.getValorPendente() != null ? conta.getValorPendente() : 0.0) : 0.0;
        valorPendenteLabel = new JLabel("Pendente: " + CurrencyFormatter.format(pendente));

        valorPagamentoField = new JTextField(15);
        valorPagamentoField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, String.format("%.2f", pendente));

        observacoesArea = new JTextArea(3, 20);
        observacoesArea.setLineWrap(true);
        observacoesArea.setWrapStyleWord(true);
    }

    private void setupLayout() {
        setLayout(new MigLayout("fill, wrap 2, ins 20, gap 8 12",
                "[right, 120][grow, 250]"));

        add(new JLabel("<html><b>Registar Pagamento</b></html>"), "span 2, gapy 0 10");

        add(clienteLabel, "span 2");
        add(valorTotalLabel, "span 2");
        add(valorPagoLabel, "span 2");
        add(valorPendenteLabel, "span 2, gapy 0 10");

        add(new JLabel("Valor do Pagamento:"));
        add(valorPagamentoField, "growx");

        add(new JLabel("Observacoes:"));
        add(new JScrollPane(observacoesArea), "growx, h 60");

        // Buttons
        add(new JLabel(), "gapy 15");
        JPanel btnPanel = new JPanel(new MigLayout("ins 0, gap 10"));
        JButton saveBtn = new JButton("Registar");
        JButton cancelBtn = new JButton("Cancelar");
        saveBtn.setFont(saveBtn.getFont().deriveFont(Font.BOLD, 13f));
        saveBtn.setBackground(new Color(34, 139, 34));
        saveBtn.setForeground(Color.WHITE);
        btnPanel.add(saveBtn);
        btnPanel.add(cancelBtn);
        add(btnPanel, "span 2, center");

        saveBtn.addActionListener(e -> registarPagamento());
        cancelBtn.addActionListener(e -> dispose());

        getRootPane().setDefaultButton(saveBtn);
        KeyStroke escape = KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(escape, "cancel");
        getRootPane().getActionMap().put("cancel", new AbstractAction() {
            @Override public void actionPerformed(ActionEvent e) { dispose(); }
        });
    }

    private void registarPagamento() {
        if (conta == null) {
            JOptionPane.showMessageDialog(this, "Nenhuma conta selecionada.",
                    "Erro", JOptionPane.ERROR_MESSAGE);
            return;
        }

        String valorText = valorPagamentoField.getText().trim().replace(",", ".");
        if (valorText.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Informe o valor do pagamento.",
                    "Validacao", JOptionPane.WARNING_MESSAGE);
            return;
        }

        double valor;
        try {
            valor = Double.parseDouble(valorText);
        } catch (NumberFormatException e) {
            JOptionPane.showMessageDialog(this, "Valor invalido.",
                    "Validacao", JOptionPane.ERROR_MESSAGE);
            return;
        }

        if (valor <= 0) {
            JOptionPane.showMessageDialog(this, "O valor deve ser positivo.",
                    "Validacao", JOptionPane.WARNING_MESSAGE);
            return;
        }

        double pendente = conta.getValorPendente() != null ? conta.getValorPendente() : 0.0;
        if (valor > pendente + 0.01) {
            int confirm = JOptionPane.showConfirmDialog(this,
                    "O valor do pagamento excede o pendente (" + CurrencyFormatter.format(pendente) + "). Deseja continuar?",
                    "Valor Excedido", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
            if (confirm != JOptionPane.YES_OPTION) return;
        }

        try {
            service.registarPagamento(conta.getId(), valor);
            JOptionPane.showMessageDialog(this, "Pagamento registado com sucesso.",
                    "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            saved = true;
            dispose();
        } catch (Exception ex) {
            logger.error("Erro ao registar pagamento", ex);
            JOptionPane.showMessageDialog(this, "Erro ao registar pagamento: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
        }
    }

    public boolean isSaved() {
        return saved;
    }
}
