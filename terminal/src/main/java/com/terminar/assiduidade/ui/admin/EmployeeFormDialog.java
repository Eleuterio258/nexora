package com.terminar.assiduidade.ui.admin;

import net.miginfocom.swing.MigLayout;

import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JTextField;
import java.awt.Frame;

public class EmployeeFormDialog extends JDialog {

    private final JTextField numeroField = new JTextField(15);
    private final JTextField nomeField = new JTextField(20);
    private final JTextField departamentoField = new JTextField(20);
    private boolean confirmado = false;

    public EmployeeFormDialog(Frame owner, String titulo, String numero, String nome, String departamento,
                               boolean numeroEditavel) {
        super(owner, titulo, true);
        setLayout(new MigLayout("insets 6, wrap 2", "[]6[grow]", "[]6[]6[]10[]"));

        add(new JLabel("Número:"));
        numeroField.setText(numero == null ? "" : numero);
        numeroField.setEditable(numeroEditavel);
        add(numeroField, "growx");

        add(new JLabel("Nome:"));
        nomeField.setText(nome == null ? "" : nome);
        add(nomeField, "growx");

        add(new JLabel("Departamento:"));
        departamentoField.setText(departamento == null ? "" : departamento);
        add(departamentoField, "growx");

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

    public boolean isConfirmado() {
        return confirmado;
    }

    public String getNumero() {
        return numeroField.getText().trim();
    }

    public String getNome() {
        return nomeField.getText().trim();
    }

    public String getDepartamento() {
        return departamentoField.getText().trim();
    }
}
