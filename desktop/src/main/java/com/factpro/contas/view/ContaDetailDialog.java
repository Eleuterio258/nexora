package com.factpro.contas.view;

import com.factpro.contas.model.ContaReceber;
import com.factpro.core.util.CurrencyFormatter;
import net.miginfocom.swing.MigLayout;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;
import java.util.Map;

/**
 * Dialog showing full details of an accounts receivable entry.
 */
public class ContaDetailDialog extends JDialog {

    public ContaDetailDialog(Frame parent, ContaReceber conta, Map<Long, String> clienteNames) {
        super(parent, "Detalhes da Conta a Receber", false);

        setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
        setSize(450, 350);
        setLocationRelativeTo(parent);

        setupLayout(conta, clienteNames);
    }

    private void setupLayout(ContaReceber conta, Map<Long, String> clienteNames) {
        setLayout(new MigLayout("fill, wrap 2, ins 20, gap 8 12",
                "[right, 130][grow, 250]"));

        add(new JLabel("<html><b>Detalhes da Conta</b></html>"), "span 2, gapy 0 10");

        String clienteNome = clienteNames.getOrDefault(conta.getClienteId(), "CLI-" + conta.getClienteId());

        addLabel("Cliente:", clienteNome);
        addLabel("Referencia Venda:", conta.getVendaId() != null ? "VENDA-" + conta.getVendaId() : "-");
        addLabel("Valor Total:", CurrencyFormatter.format(conta.getValorTotal()));
        addLabel("Valor Pago:", CurrencyFormatter.format(conta.getValorPago() != null ? conta.getValorPago() : 0.0));
        addLabel("Valor Pendente:", CurrencyFormatter.format(conta.getValorPendente() != null ? conta.getValorPendente() : 0.0));
        addLabel("Status:", capitalize(conta.getStatus()));
        addLabel("Data Vencimento:", conta.getDataVencimento() != null ? conta.getDataVencimento() : "-");
        addLabel("Criado Em:", conta.getCriadoEm() != null ? conta.getCriadoEm() : "-");

        // Close button
        add(new JLabel(), "gapy 15");
        JPanel btnPanel = new JPanel(new MigLayout("ins 0"));
        JButton closeBtn = new JButton("Fechar");
        closeBtn.setFont(closeBtn.getFont().deriveFont(Font.BOLD, 13f));
        closeBtn.setBackground(new Color(128, 128, 128));
        closeBtn.setForeground(Color.WHITE);
        btnPanel.add(closeBtn);
        add(btnPanel, "span 2, center");

        closeBtn.addActionListener(e -> dispose());
        getRootPane().setDefaultButton(closeBtn);
        KeyStroke escape = KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(escape, "close");
        getRootPane().getActionMap().put("close", new AbstractAction() {
            @Override public void actionPerformed(ActionEvent e) { dispose(); }
        });
    }

    private void addLabel(String text, String value) {
        add(new JLabel(text));
        JLabel valueLabel = new JLabel(value);
        valueLabel.setFont(valueLabel.getFont().deriveFont(Font.BOLD));
        add(valueLabel, "growx");
    }

    private String capitalize(String s) {
        if (s == null) return "";
        return s.substring(0, 1).toUpperCase() + s.substring(1).toLowerCase();
    }
}
