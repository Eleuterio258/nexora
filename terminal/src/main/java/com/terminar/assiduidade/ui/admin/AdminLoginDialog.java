package com.terminar.assiduidade.ui.admin;

import com.terminar.assiduidade.config.AppConfig;
import net.miginfocom.swing.MigLayout;

import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JPasswordField;
import javax.swing.SwingUtilities;
import java.awt.Frame;
import java.awt.event.ActionEvent;

public class AdminLoginDialog extends JDialog {

    private final JPasswordField pinField = new JPasswordField(10);
    private final JLabel erroLabel = new JLabel(" ");
    private boolean autenticado = false;

    public AdminLoginDialog(Frame owner) {
        super(owner, "Acesso à administração", true);
        setLayout(new MigLayout("insets 8, wrap 1", "[grow, center]", "[]6[]3[]10[]"));

        add(new JLabel("Introduza o PIN de administração:"));
        add(pinField, "growx");
        add(erroLabel);

        JButton entrarButton = new JButton("Entrar");
        entrarButton.addActionListener(this::onEntrar);
        pinField.addActionListener(this::onEntrar);
        add(entrarButton, "align center");

        setResizable(false);
        pack();
        setLocationRelativeTo(owner);
        SwingUtilities.invokeLater(pinField::requestFocusInWindow);
    }

    private void onEntrar(ActionEvent event) {
        String pin = new String(pinField.getPassword());
        if (pin.equals(AppConfig.getAdminPin())) {
            autenticado = true;
            dispose();
        } else {
            erroLabel.setText("PIN incorrecto");
            pinField.setText("");
        }
    }

    public boolean isAutenticado() {
        return autenticado;
    }
}
