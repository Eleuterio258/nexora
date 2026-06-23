package com.factpro.vendas.view;

import com.factpro.clientes.dao.ClienteDAO;
import com.factpro.clientes.model.Cliente;
import com.factpro.core.util.CurrencyFormatter;
import com.factpro.vendas.model.Pagamento;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.CompoundBorder;
import javax.swing.border.EmptyBorder;
import javax.swing.border.LineBorder;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;
import java.util.ArrayList;
import java.util.List;

/**
 * Payment processing dialog supporting multiple payment methods.
 */
public class PagamentoDialog extends JDialog {

    private static final Logger logger = LoggerFactory.getLogger(PagamentoDialog.class);

    private final double totalPagar;
    private final Long clienteId;
    private boolean confirmed = false;
    private final List<Pagamento> pagamentos = new ArrayList<>();

    private JPanel paymentMethodPanel;
    private final ButtonGroup paymentGroup = new ButtonGroup();
    private final List<JToggleButton> paymentButtons = new ArrayList<>();
    private String selectedMethod = "Dinheiro";

    // Cash panel
    private JPanel cashPanel;
    private JTextField valorRecebidoField;
    private JLabel trocoLabel;

    // Card panel
    private JPanel cardPanel;
    private JTextField referenciaCartaoField;

    // Mobile money panel
    private JPanel mobilePanel;
    private JTextField telefoneField;
    private JTextField transacaoIdField;

    // Credit (Fiado) panel
    private JPanel fiadoPanel;
    private JLabel clienteNomeLabel;
    private JLabel clienteLimiteLabel;
    private JTextField creditoUsadoField;

    public PagamentoDialog(Frame parent, double totalPagar, Long clienteId) {
        super(parent, "Processar Pagamento", true);
        this.totalPagar = totalPagar;
        this.clienteId = clienteId;

        setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
        setSize(450, 500);
        setLocationRelativeTo(parent);

        initComponents();
        setupLayout();
        setupListeners();
        updatePaymentPanel();
    }

    public PagamentoDialog(Frame parent, double totalPagar) {
        this(parent, totalPagar, null);
    }

    private void initComponents() {
        // Payment method buttons
        String[] methods = {"Dinheiro", "Cartao", "M-Pesa", "E-Mola", "Transferencia", "Fiado"};
        for (String method : methods) {
            JToggleButton btn = new JToggleButton(method);
            btn.setFont(btn.getFont().deriveFont(Font.PLAIN, 12f));
            paymentGroup.add(btn);
            paymentButtons.add(btn);
        }
        paymentButtons.get(0).setSelected(true); // Default: Dinheiro

        // Cash panel
        cashPanel = new JPanel(new MigLayout("fillx, ins 5, gap 5", "[][grow]"));
        cashPanel.add(new JLabel("Valor Recebido:"));
        valorRecebidoField = new JTextField(String.format("%.2f", totalPagar), 15);
        cashPanel.add(valorRecebidoField, "growx");
        trocoLabel = new JLabel("Troco: " + CurrencyFormatter.format(0.0));
        trocoLabel.setFont(trocoLabel.getFont().deriveFont(Font.BOLD, 16f));
        trocoLabel.setForeground(new Color(34, 139, 34));
        cashPanel.add(trocoLabel, "span 2, gapy 5");
        updateTroco();

        // Card panel
        cardPanel = new JPanel(new MigLayout("fillx, ins 5, gap 5", "[][grow]"));
        cardPanel.add(new JLabel("Referencia:"));
        referenciaCartaoField = new JTextField(15);
        cardPanel.add(referenciaCartaoField, "growx");

        // Mobile money panel
        mobilePanel = new JPanel(new MigLayout("fillx, ins 5, gap 5", "[][grow]"));
        mobilePanel.add(new JLabel("Telefone:"));
        telefoneField = new JTextField(15);
        mobilePanel.add(telefoneField, "growx");
        mobilePanel.add(new JLabel("ID Transacao:"));
        transacaoIdField = new JTextField(15);
        mobilePanel.add(transacaoIdField, "growx");

        // Fiado panel
        fiadoPanel = new JPanel(new MigLayout("fillx, ins 5, gap 5", "[][grow]"));
        fiadoPanel.setBackground(new Color(255, 250, 240));
        fiadoPanel.setBorder(new CompoundBorder(
                new LineBorder(new Color(255, 152, 0), 2, true),
                new EmptyBorder(5, 10, 5, 10)));

        if (clienteId != null) {
            ClienteDAO clienteDAO = new ClienteDAO();
            Cliente cliente = clienteDAO.findById(clienteId);
            if (cliente != null) {
                clienteNomeLabel = new JLabel("Cliente: " + cliente.getNome());
                fiadoPanel.add(clienteNomeLabel, "span 2");
                fiadoPanel.add(new JLabel("Limite Credito: " +
                        CurrencyFormatter.format(cliente.getLimiteCredito() != null ? cliente.getLimiteCredito() : 0.0)), "span 2");
                fiadoPanel.add(new JLabel("Credito Usado:"));
                creditoUsadoField = new JTextField(String.format("%.2f", cliente.getCreditoUsado() != null ? cliente.getCreditoUsado() : 0.0), 15);
                fiadoPanel.add(creditoUsadoField, "growx");
            } else {
                fiadoPanel.add(new JLabel("Cliente nao encontrado."), "span 2");
            }
        } else {
            fiadoPanel.add(new JLabel("Venda a credito requer selecao de cliente."), "span 2");
        }
    }

    private void setupLayout() {
        setLayout(new MigLayout("fill, wrap 1, ins 15, gap 10", "[grow]"));

        // Total label
        JLabel totalLabel = new JLabel("Total a Pagar: " + CurrencyFormatter.format(totalPagar));
        totalLabel.setFont(totalLabel.getFont().deriveFont(Font.BOLD, 24f));
        totalLabel.setForeground(new Color(57, 113, 227));
        totalLabel.setHorizontalAlignment(SwingConstants.CENTER);
        add(totalLabel, "center, gapy 0 10");

        // Payment method buttons
        paymentMethodPanel = new JPanel(new MigLayout("fillx, ins 5, gap 3, wrap 3", "[grow][grow][grow]"));
        for (JToggleButton btn : paymentButtons) {
            paymentMethodPanel.add(btn, "grow, h 35");
        }
        add(paymentMethodPanel, "growx");

        add(new JSeparator(), "growx");

        // Dynamic payment panel container
        JPanel dynamicPanel = new JPanel(new CardLayout());
        dynamicPanel.add(cashPanel, "Dinheiro");
        dynamicPanel.add(cardPanel, "Cartao");
        dynamicPanel.add(mobilePanel, "M-Pesa");
        dynamicPanel.add(mobilePanel, "E-Mola");
        dynamicPanel.add(cardPanel, "Transferencia");
        dynamicPanel.add(fiadoPanel, "Fiado");
        add(dynamicPanel, "growx");
        dynamicPanel.setName("dynamicPanel");

        // Buttons
        JPanel btnPanel = new JPanel(new MigLayout("ins 0, gap 10"));
        JButton confirmBtn = new JButton("Confirmar Pagamento");
        JButton cancelBtn = new JButton("Cancelar");
        styleBtn(confirmBtn, new Color(34, 139, 34));
        btnPanel.add(confirmBtn, "grow");
        btnPanel.add(cancelBtn);
        add(btnPanel, "center");

        confirmBtn.addActionListener(e -> confirmPayment());
        cancelBtn.addActionListener(e -> dispose());

        getRootPane().setDefaultButton(confirmBtn);
        KeyStroke escape = KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(escape, "cancel");
        getRootPane().getActionMap().put("cancel", new AbstractAction() {
            @Override public void actionPerformed(ActionEvent e) { dispose(); }
        });
    }

    private void setupListeners() {
        for (JToggleButton btn : paymentButtons) {
            btn.addActionListener(e -> {
                selectedMethod = btn.getText();
                updatePaymentPanel();
            });
        }

        valorRecebidoField.addActionListener(e -> updateTroco());
        valorRecebidoField.addKeyListener(new java.awt.event.KeyAdapter() {
            @Override
            public void keyReleased(java.awt.event.KeyEvent e) {
                updateTroco();
            }
        });
    }

    private void updatePaymentPanel() {
        JPanel container = (JPanel) getComponent(getComponentCount() - 2); // dynamicPanel
        CardLayout cl = (CardLayout) container.getLayout();

        String cardName = selectedMethod;
        if ("E-Mola".equals(selectedMethod) || "M-Pesa".equals(selectedMethod)) {
            cardName = "M-Pesa"; // Both use mobilePanel
        } else if ("Transferencia".equals(selectedMethod)) {
            cardName = "Cartao"; // Use cardPanel for reference
        }

        cl.show(container, cardName);
    }

    private void updateTroco() {
        try {
            double recebido = Double.parseDouble(valorRecebidoField.getText().replace(",", "."));
            double troco = recebido - totalPagar;
            trocoLabel.setText("Troco: " + CurrencyFormatter.format(Math.max(0, troco)));
            if (troco < 0) {
                trocoLabel.setForeground(new Color(220, 53, 69));
            } else {
                trocoLabel.setForeground(new Color(34, 139, 34));
            }
        } catch (NumberFormatException e) {
            trocoLabel.setText("Troco: " + CurrencyFormatter.format(0.0));
        }
    }

    private void confirmPayment() {
        pagamentos.clear();

        switch (selectedMethod) {
            case "Dinheiro" -> {
                try {
                    double recebido = Double.parseDouble(valorRecebidoField.getText().replace(",", "."));
                    if (recebido < totalPagar) {
                        JOptionPane.showMessageDialog(this,
                                "O valor recebido e inferior ao total a pagar.",
                                "Valor Insuficiente", JOptionPane.WARNING_MESSAGE);
                        return;
                    }
                    Pagamento pg = new Pagamento();
                    pg.setMetodo("Dinheiro");
                    pg.setValor(recebido);
                    pg.setStatus("processado");
                    pagamentos.add(pg);
                } catch (NumberFormatException e) {
                    JOptionPane.showMessageDialog(this, "Valor recebido invalido.",
                            "Erro", JOptionPane.ERROR_MESSAGE);
                    return;
                }
            }
            case "Cartao" -> {
                Pagamento pg = new Pagamento();
                pg.setMetodo("Cartao");
                pg.setValor(totalPagar);
                pg.setReferencia(referenciaCartaoField.getText().trim());
                pg.setStatus("processado");
                pagamentos.add(pg);
            }
            case "M-Pesa", "E-Mola" -> {
                String telefone = telefoneField.getText().trim();
                if (telefone.isEmpty()) {
                    JOptionPane.showMessageDialog(this, "Informe o numero de telefone.",
                            "Validacao", JOptionPane.WARNING_MESSAGE);
                    return;
                }
                Pagamento pg = new Pagamento();
                pg.setMetodo(selectedMethod);
                pg.setValor(totalPagar);
                pg.setTransacaoId(transacaoIdField.getText().trim());
                pg.setStatus("pendente"); // API confirmation pending
                pagamentos.add(pg);
                // TODO: Integrate with M-Pesa/E-Mola API
                logger.info("Mobile money payment initiated for {} - phone: {}", selectedMethod, telefone);
            }
            case "Transferencia" -> {
                Pagamento pg = new Pagamento();
                pg.setMetodo("Transferencia");
                pg.setValor(totalPagar);
                pg.setReferencia(referenciaCartaoField.getText().trim());
                pg.setStatus("pendente");
                pagamentos.add(pg);
            }
            case "Fiado" -> {
                if (clienteId == null) {
                    JOptionPane.showMessageDialog(this, "Venda a credito requer selecao de cliente.",
                            "Erro", JOptionPane.ERROR_MESSAGE);
                    return;
                }
                Pagamento pg = new Pagamento();
                pg.setMetodo("Fiado");
                pg.setValor(totalPagar);
                pg.setStatus("pendente");
                pagamentos.add(pg);
            }
        }

        confirmed = true;
        dispose();
    }

    private void styleBtn(JButton btn, Color bgColor) {
        btn.setFont(btn.getFont().deriveFont(Font.BOLD, 13f));
        btn.setBackground(bgColor);
        btn.setForeground(Color.WHITE);
        btn.setFocusPainted(false);
    }

    public boolean isConfirmed() { return confirmed; }
    public List<Pagamento> getPagamentos() { return new ArrayList<>(pagamentos); }
    public String getSelectedMethod() { return selectedMethod; }
}
