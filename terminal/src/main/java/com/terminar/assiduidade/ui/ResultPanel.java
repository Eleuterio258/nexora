package com.terminar.assiduidade.ui;

import net.miginfocom.swing.MigLayout;

import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import javax.swing.Timer;
import java.awt.Color;
import java.awt.Font;

public class ResultPanel extends JPanel {

    private static final int SEGUNDOS_AUTO_REGRESSO = 4;

    private final AssiduidadeFrame frame;
    private final JLabel iconeLabel = new JLabel("", SwingConstants.CENTER);
    private final JLabel mensagemLabel = new JLabel("", SwingConstants.CENTER);
    private Timer autoRegressoTimer;

    public ResultPanel(AssiduidadeFrame frame) {
        this.frame = frame;
        setLayout(new MigLayout("fill, insets 3, gap 1", "[grow, center]", "[grow]1[]1[]"));

        iconeLabel.setFont(iconeLabel.getFont().deriveFont(Font.BOLD, UiScale.f(28f)));
        add(iconeLabel, "align center, wrap");

        mensagemLabel.setFont(mensagemLabel.getFont().deriveFont(Font.BOLD, UiScale.f(8f)));
        add(mensagemLabel, "growx, align center, wrap");

        JButton voltarButton = new JButton("Voltar");
        voltarButton.setFont(voltarButton.getFont().deriveFont(UiScale.f(8f)));
        voltarButton.setMargin(new java.awt.Insets(0, 2, 0, 2));
        voltarButton.addActionListener(e -> frame.goHome());
        add(voltarButton, "align center");
    }

    public void exibir(String mensagem, boolean sucesso) {
        iconeLabel.setText(sucesso ? "✔" : "✘");
        iconeLabel.setForeground(sucesso ? new Color(0, 150, 70) : new Color(200, 40, 40));
        mensagemLabel.setText("<html><center>" + mensagem + "</center></html>");

        if (autoRegressoTimer != null) {
            autoRegressoTimer.stop();
        }
        autoRegressoTimer = new Timer(SEGUNDOS_AUTO_REGRESSO * 1000, e -> frame.goHome());
        autoRegressoTimer.setRepeats(false);
        autoRegressoTimer.start();
    }
}
