package com.terminar.assiduidade.ui.admin;

import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.util.NfcCardUtil;
import net.miginfocom.swing.MigLayout;

import javax.smartcardio.CardTerminal;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JTextField;
import javax.swing.SwingUtilities;
import java.awt.Frame;
import java.util.List;

public class NfcEnrollDialog extends JDialog {

    private final NfcCardUtil nfcCardUtil = new NfcCardUtil();
    private final JTextField uidField = new JTextField(20);
    private final JLabel statusLabel = new JLabel(" ");
    private boolean confirmado = false;

    public NfcEnrollDialog(Frame owner, Employee employee) {
        super(owner, "Cartão NFC — " + employee.getNome(), true);
        setLayout(new MigLayout("insets 6, wrap 1", "[grow, center]", "[]6[grow]3[]6[]10[]"));

        add(new JLabel("UID do cartão (vazio para remover):"));
        uidField.setText(employee.getNfcUid() == null ? "" : employee.getNfcUid());
        add(uidField, "growx");
        add(statusLabel);

        JButton lerButton = new JButton("Ler do leitor NFC agora");
        lerButton.addActionListener(e -> lerDoLeitor(lerButton));
        add(lerButton);

        JButton guardarButton = new JButton("Guardar");
        guardarButton.addActionListener(e -> {
            confirmado = true;
            dispose();
        });
        JButton cancelarButton = new JButton("Cancelar");
        cancelarButton.addActionListener(e -> dispose());
        add(cancelarButton, "split 2, align right");
        add(guardarButton);

        setResizable(false);
        pack();
        setLocationRelativeTo(owner);
    }

    private void lerDoLeitor(JButton lerButton) {
        lerButton.setEnabled(false);
        statusLabel.setText("A aguardar cartão (5s)...");
        Thread leitura = new Thread(() -> {
            String uidLido = null;
            String erro = null;
            try {
                List<CardTerminal> leitores = nfcCardUtil.listarLeitores();
                if (leitores.isEmpty()) {
                    erro = "Nenhum leitor NFC (PC/SC) encontrado";
                } else {
                    uidLido = nfcCardUtil.lerUid(leitores.get(0), 5000);
                    if (uidLido == null) {
                        erro = "Nenhum cartão detectado a tempo";
                    }
                }
            } catch (Exception e) {
                erro = "Leitor NFC indisponível: " + e.getMessage();
            }
            String uidFinal = uidLido;
            String erroFinal = erro;
            SwingUtilities.invokeLater(() -> {
                lerButton.setEnabled(true);
                if (uidFinal != null) {
                    uidField.setText(uidFinal);
                    statusLabel.setText("Cartão lido com sucesso");
                } else {
                    statusLabel.setText(erroFinal);
                }
            });
        }, "nfc-enroll-read");
        leitura.setDaemon(true);
        leitura.start();
    }

    public boolean isConfirmado() {
        return confirmado;
    }

    public String getUid() {
        return uidField.getText().trim();
    }
}
