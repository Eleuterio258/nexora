package com.terminar.assiduidade.ui;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.ui.icons.FingerprintIcon;
import com.terminar.assiduidade.ui.icons.NfcIcon;
import com.terminar.assiduidade.ui.icons.PinIcon;
import com.terminar.assiduidade.ui.icons.QrIcon;
import net.miginfocom.swing.MigLayout;

import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import javax.swing.Timer;
import java.awt.Color;
import java.awt.Font;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

/** Ecrã inicial optimizado para um painel táctil pequeno (6,5", 200x200). */
public class HomeClockPanel extends JPanel {

    private static final Locale LOCALE_PT = new Locale("pt", "PT");
    private static final DateTimeFormatter HORA_FMT = DateTimeFormatter.ofPattern("HH:mm:ss");
    private static final DateTimeFormatter DATA_FMT = DateTimeFormatter.ofPattern("dd/MM/yy");

    private final AssiduidadeFrame frame;
    private final JLabel relogioLabel = new JLabel("", SwingConstants.CENTER);
    private final JLabel dataLabel = new JLabel("", SwingConstants.CENTER);

    public HomeClockPanel(AssiduidadeFrame frame) {
        this.frame = frame;
        setLayout(new MigLayout("fill, insets 4, gap 2", "[grow]", "[]2[]2[grow]"));

        JLabel empresaLabel = new JLabel(AppConfig.getCompanyName(), SwingConstants.CENTER);
        empresaLabel.setFont(empresaLabel.getFont().deriveFont(Font.BOLD, UiScale.f(11f)));

        JButton adminButton = new JButton("⚙");
        adminButton.setFont(adminButton.getFont().deriveFont(UiScale.f(16f)));
        adminButton.setMargin(new java.awt.Insets(2, 8, 2, 8));
        adminButton.setFocusable(false);
        adminButton.setToolTipText("Administração");
        adminButton.addActionListener(e -> frame.goToAdminGated());

        JPanel topo = new JPanel(new MigLayout("fillx, insets 0", "[grow][]", "[]"));
        topo.add(empresaLabel, "growx, align center");
        topo.add(adminButton, "align right, top");
        add(topo, "growx, wrap");

        relogioLabel.setFont(relogioLabel.getFont().deriveFont(Font.BOLD, UiScale.f(22f)));
        dataLabel.setFont(dataLabel.getFont().deriveFont(UiScale.f(9f)));

        JPanel centro = new JPanel(new MigLayout("insets 0, fillx, gap 0", "[grow, center]", "[]0[]"));
        centro.add(relogioLabel, "growx, wrap, align center");
        centro.add(dataLabel, "growx, align center");
        add(centro, "growx, wrap");

        int iconSize = UiScale.px(18);
        JPanel botoes = new JPanel(new MigLayout("insets 0, gap 2", "[grow, fill]2[grow, fill]", "[grow, fill]2[grow, fill]"));
        botoes.add(criarBotaoMetodo("PIN", new PinIcon(iconSize, Color.WHITE), e -> frame.goToPin()));
        botoes.add(criarBotaoMetodo("QR", new QrIcon(iconSize, Color.WHITE), e -> frame.goToQr()));
        botoes.add(criarBotaoMetodo("Digital", new FingerprintIcon(iconSize, Color.WHITE), e -> frame.goToFingerprint()));
        botoes.add(criarBotaoMetodo("NFC", new NfcIcon(iconSize, Color.WHITE), e -> frame.goToNfc()));
        add(botoes, "grow");

        Timer relogio = new Timer(1000, e -> atualizarRelogio());
        relogio.start();
        atualizarRelogio();
    }

    private JButton criarBotaoMetodo(String titulo, javax.swing.Icon icon, java.awt.event.ActionListener onClick) {
        JButton botao = new JButton(titulo, icon);
        botao.setHorizontalTextPosition(SwingConstants.CENTER);
        botao.setVerticalTextPosition(SwingConstants.BOTTOM);
        botao.setFont(botao.getFont().deriveFont(Font.BOLD, UiScale.f(9f)));
        botao.setMargin(new java.awt.Insets(1, 1, 1, 1));
        botao.setFocusable(false);
        botao.addActionListener(onClick);
        return botao;
    }

    private void atualizarRelogio() {
        LocalDateTime agora = LocalDateTime.now();
        relogioLabel.setText(agora.format(HORA_FMT));
        dataLabel.setText(agora.format(DATA_FMT));
    }

    public void refrescar() {
        atualizarRelogio();
    }
}
