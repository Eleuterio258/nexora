package com.terminar.assiduidade.ui.admin;

import com.terminar.assiduidade.config.AppConfig;
import lombok.extern.slf4j.Slf4j;
import net.miginfocom.swing.MigLayout;

import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JPasswordField;
import javax.swing.SwingUtilities;
import java.awt.Frame;
import java.awt.event.ActionEvent;

@Slf4j
public class AdminLoginDialog extends JDialog {

    private static final int MAX_TENTATIVAS = 5;
    private static final long BLOQUEIO_MS = 60_000;

    /**
     * Estado de bloqueio partilhado por todas as instâncias (cada acesso ao admin cria um
     * dialog novo) — se fosse por instância, bastava cancelar e reabrir para reiniciar as
     * tentativas. Só em memória, não sobrevive a reiniciar a aplicação.
     */
    private static int tentativasFalhadas = 0;
    private static long bloqueadoAte = 0;

    private final JPasswordField pinField = new JPasswordField(10);
    private final JButton entrarButton = new JButton("Entrar");
    private final JLabel erroLabel = new JLabel(" ");
    private boolean autenticado = false;

    public AdminLoginDialog(Frame owner) {
        super(owner, "Acesso à administração", true);
        setLayout(new MigLayout("insets 8, wrap 1", "[grow, center]", "[]6[]3[]10[]"));

        add(new JLabel("Introduza o PIN de administração:"));
        add(pinField, "growx");
        add(erroLabel);

        entrarButton.addActionListener(this::onEntrar);
        pinField.addActionListener(this::onEntrar);
        add(entrarButton, "align center");

        setResizable(false);
        pack();
        setLocationRelativeTo(owner);

        if (emBloqueio()) {
            aplicarBloqueioUI();
        } else {
            SwingUtilities.invokeLater(pinField::requestFocusInWindow);
        }
    }

    private boolean emBloqueio() {
        return System.currentTimeMillis() < bloqueadoAte;
    }

    private void aplicarBloqueioUI() {
        long restanteS = (bloqueadoAte - System.currentTimeMillis()) / 1000 + 1;
        erroLabel.setText("Demasiadas tentativas — tente novamente em " + restanteS + "s");
        pinField.setEnabled(false);
        entrarButton.setEnabled(false);
    }

    private void onEntrar(ActionEvent event) {
        if (emBloqueio()) {
            aplicarBloqueioUI();
            return;
        }
        String pin = new String(pinField.getPassword());
        if (pin.equals(AppConfig.getAdminPin())) {
            tentativasFalhadas = 0;
            log.info("Acesso ao painel de administração concedido");
            autenticado = true;
            dispose();
            return;
        }

        pinField.setText("");
        tentativasFalhadas++;
        log.warn("Tentativa falhada de acesso ao painel de administração ({}/{})", tentativasFalhadas, MAX_TENTATIVAS);
        if (tentativasFalhadas >= MAX_TENTATIVAS) {
            bloqueadoAte = System.currentTimeMillis() + BLOQUEIO_MS;
            log.warn("Acesso ao painel de administração bloqueado por {}s após tentativas repetidas",
                BLOQUEIO_MS / 1000);
            aplicarBloqueioUI();
        } else {
            erroLabel.setText("PIN incorrecto");
        }
    }

    public boolean isAutenticado() {
        return autenticado;
    }
}
