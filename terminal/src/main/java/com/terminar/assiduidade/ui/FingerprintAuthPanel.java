package com.terminar.assiduidade.ui;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.model.MetodoAutenticacao;
import com.terminar.assiduidade.service.AuthService;
import com.terminar.assiduidade.ui.icons.GlowFingerprintIcon;
import net.miginfocom.swing.MigLayout;

import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import javax.swing.Timer;
import java.awt.Color;
import java.awt.Cursor;
import java.awt.Font;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.Optional;

/** Ecrã de leitura de impressão digital, optimizado para um painel táctil 400x200. */
public class FingerprintAuthPanel extends JPanel {

    private static final Color GLOW_COLOR = new Color(41, 151, 224);
    private static final String INSTRUCAO = "Coloque o dedo no leitor";

    private final AssiduidadeFrame frame;
    private final AuthService authService = new AuthService();

    private final JLabel iconeLabel = new JLabel(new GlowFingerprintIcon(UiScale.px(72), GLOW_COLOR));
    private final JLabel statusLabel = new JLabel(INSTRUCAO, SwingConstants.CENTER);

    private boolean aLer = false;

    public FingerprintAuthPanel(AssiduidadeFrame frame) {
        this.frame = frame;
        setLayout(new MigLayout("fill, insets 8, gap 4", "[grow, center]", "[]8[]8[]"));

        JLabel marca = new JLabel(AppConfig.getCompanyName(), SwingConstants.CENTER);
        marca.setFont(marca.getFont().deriveFont(Font.PLAIN, UiScale.f(13f)));

        JButton cancelar = new JButton("Cancelar");
        cancelar.setFont(cancelar.getFont().deriveFont(UiScale.f(11f)));
        cancelar.setMargin(new java.awt.Insets(3, 10, 3, 10));
        cancelar.setFocusable(false);
        cancelar.addActionListener(e -> frame.goHome());

        JPanel topo = new JPanel(new MigLayout("fillx, insets 0", "[grow][]", "[]"));
        topo.add(marca, "growx, align center");
        topo.add(cancelar, "align right, top");
        add(topo, "growx, wrap");

        iconeLabel.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        iconeLabel.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                simularLeitura();
            }
        });
        add(iconeLabel, "align center, wrap");

        statusLabel.setFont(statusLabel.getFont().deriveFont(UiScale.f(11f)));
        statusLabel.setForeground(new Color(160, 160, 165));
        add(statusLabel, "align center");
    }

    private void simularLeitura() {
        if (aLer || !AppConfig.isFingerprintSimulation()) {
            return;
        }
        aLer = true;
        statusLabel.setText("A ler...");
        Timer atraso = new Timer(900, e -> {
            aLer = false;
            Optional<Employee> employee = authService.authenticateByFingerprintSimulado();
            if (employee.isPresent()) {
                frame.goToMarcarPonto(employee.get(), MetodoAutenticacao.FINGERPRINT);
            } else {
                statusLabel.setText("Digital não reconhecida");
                Timer restaurar = new Timer(1500, r -> statusLabel.setText(INSTRUCAO));
                restaurar.setRepeats(false);
                restaurar.start();
            }
        });
        atraso.setRepeats(false);
        atraso.start();
    }

    public void reiniciar() {
        aLer = false;
        statusLabel.setText(INSTRUCAO);
    }
}
