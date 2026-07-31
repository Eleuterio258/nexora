package com.terminar.assiduidade.ui;

import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.model.MetodoAutenticacao;
import com.terminar.assiduidade.service.AuthService;
import com.terminar.assiduidade.ui.icons.NfcIcon;
import com.terminar.assiduidade.util.NfcCardUtil;
import lombok.extern.slf4j.Slf4j;
import net.miginfocom.swing.MigLayout;

import javax.smartcardio.CardTerminal;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import javax.swing.SwingUtilities;
import javax.swing.Timer;
import java.awt.Color;
import java.awt.Font;
import java.util.List;
import java.util.Optional;

@Slf4j
public class NfcAuthPanel extends JPanel {

    private static final String INSTRUCAO = "Aproxime o cartão ou dispositivo";
    private static final String SEM_LEITOR = "Sem leitor NFC disponível";

    private final AssiduidadeFrame frame;
    private final AuthService authService = new AuthService();
    private final NfcCardUtil nfcCardUtil = new NfcCardUtil();

    private final JLabel statusLabel = new JLabel(INSTRUCAO, SwingConstants.CENTER);

    private volatile boolean lendo = false;
    private Thread leituraThread;

    public NfcAuthPanel(AssiduidadeFrame frame) {
        this.frame = frame;
        setLayout(new MigLayout("fill, insets 8, gap 4", "[grow, center]", "[]8[]8[]4[]"));

        JLabel titulo = new JLabel("Leitura NFC", SwingConstants.CENTER);
        titulo.setFont(titulo.getFont().deriveFont(Font.BOLD, UiScale.f(13f)));

        JButton cancelar = new JButton("Cancelar");
        cancelar.setFont(cancelar.getFont().deriveFont(UiScale.f(11f)));
        cancelar.setMargin(new java.awt.Insets(3, 10, 3, 10));
        cancelar.setFocusable(false);
        cancelar.addActionListener(e -> frame.goHome());

        JPanel topo = new JPanel(new MigLayout("fillx, insets 0", "[grow][]", "[]"));
        topo.add(titulo, "growx, align center");
        topo.add(cancelar, "align right, top");
        add(topo, "growx, wrap");

        JLabel iconeLabel = new JLabel(new NfcIcon(UiScale.px(56), Color.WHITE, true));
        add(iconeLabel, "align center, wrap");

        statusLabel.setFont(statusLabel.getFont().deriveFont(UiScale.f(11f)));
        statusLabel.setForeground(new Color(160, 160, 165));
        add(statusLabel, "align center, wrap");
    }

    public void iniciarLeitura() {
        statusLabel.setText("A procurar leitor NFC...");

        leituraThread = new Thread(this::loopLeitura, "nfc-pcsc-capture");
        leituraThread.setDaemon(true);
        leituraThread.start();
    }

    private void loopLeitura() {
        try {
            List<CardTerminal> leitores = nfcCardUtil.listarLeitores();
            if (leitores.isEmpty()) {
                SwingUtilities.invokeLater(() -> statusLabel.setText(SEM_LEITOR));
                return;
            }
            CardTerminal terminal = nfcCardUtil.escolherLeitor(leitores);
            log.info("Leitor NFC seleccionado: {}", terminal.getName());
            lendo = true;
            SwingUtilities.invokeLater(() -> statusLabel.setText(INSTRUCAO));

            while (lendo) {
                String uid = nfcCardUtil.lerUid(terminal, 1000);
                if (uid != null && !uid.isBlank()) {
                    lendo = false;
                    SwingUtilities.invokeLater(() -> autenticar(uid));
                }
            }
        } catch (Exception e) {
            log.warn("Falha ao usar leitor NFC (PC/SC)", e);
            SwingUtilities.invokeLater(() -> statusLabel.setText(SEM_LEITOR));
        }
    }

    private void autenticar(String uid) {
        Optional<Employee> employee = authService.authenticateByNfcUid(uid);
        if (employee.isPresent()) {
            pararLeitura();
            frame.goToMarcarPonto(employee.get(), MetodoAutenticacao.NFC);
        } else {
            statusLabel.setText("Cartão NFC não reconhecido");
            Timer restaurar = new Timer(1500, r -> statusLabel.setText(INSTRUCAO));
            restaurar.setRepeats(false);
            restaurar.start();
        }
    }

    public void pararLeitura() {
        lendo = false;
    }
}
