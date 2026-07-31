package com.terminar.assiduidade.ui.admin;

import com.terminar.assiduidade.model.Employee;
import net.miginfocom.swing.MigLayout;

import javax.swing.JButton;
import javax.swing.JDialog;
import java.awt.Frame;

/**
 * Modal com as acções disponíveis para o funcionário seleccionado na tabela —
 * substitui a fila de botões que antes vivia directamente na toolbar
 * (padrão comum em tabelas de admin web: acções por linha num menu/modal em
 * vez de um botão fixo por acção). Cada botão fecha o modal e só depois
 * corre a acção, que já trata do seu próprio refrescar().
 */
public class EmployeeActionsDialog extends JDialog {

    public EmployeeActionsDialog(Frame owner, Employee employee, boolean mostrarEditar,
            Runnable onEditar, Runnable onActivo, Runnable onPin, Runnable onQr,
            Runnable onDigital, Runnable onNfc) {
        super(owner, "Acções — " + employee.getNome(), true);
        setLayout(new MigLayout("insets 10, wrap 1", "[grow, fill]", ""));

        if (mostrarEditar) {
            add(criarBotao("Editar", onEditar));
        }
        add(criarBotao(employee.isAtivo() ? "Desactivar" : "Activar", onActivo));
        add(criarBotao("Definir PIN", onPin));
        add(criarBotao("Ver QR Code (crachá)", onQr));
        add(criarBotao("Digital (simulada)", onDigital));
        add(criarBotao("NFC", onNfc));

        JButton fecharButton = new JButton("Fechar");
        fecharButton.addActionListener(e -> dispose());
        add(fecharButton, "align right, gaptop 10");

        setResizable(false);
        pack();
        setLocationRelativeTo(owner);
    }

    private JButton criarBotao(String texto, Runnable accao) {
        JButton botao = new JButton(texto);
        botao.addActionListener(e -> {
            dispose();
            accao.run();
        });
        return botao;
    }
}
