package com.terminar.assiduidade.ui;

import com.terminar.assiduidade.ui.icons.QrIcon;
import net.miginfocom.swing.MigLayout;

import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import java.awt.Color;
import java.awt.Font;

/**
 * Menu QR Code — dois cartões: "Ler QR" (câmara, valida no ERP — QrAuthPanel) e
 * "Ver QR" (mostra o QR estático do próprio funcionário no ecrã — QrMostrarPanel).
 */
public class QrMenuPanel extends JPanel {

    public QrMenuPanel(AssiduidadeFrame frame) {
        setLayout(new MigLayout("fill, insets 8, gap 3", "[grow, center]", "[]8[grow]"));

        JLabel titulo = new JLabel("Menu QR Code", SwingConstants.CENTER);
        titulo.setFont(titulo.getFont().deriveFont(Font.BOLD, UiScale.f(13f)));
        add(titulo, "wrap");

        int iconSize = UiScale.px(28);
        JPanel cards = new JPanel(new MigLayout("insets 0, gap 6", "[grow, fill][grow, fill]", "[grow, fill]"));
        cards.add(criarCard("Ler QR", new QrIcon(iconSize, Color.WHITE), e -> frame.goToQrLer()));
        cards.add(criarCard("Ver QR", new QrIcon(iconSize, Color.WHITE), e -> frame.goToQrMostrar()));
        add(cards, "grow, wrap");

        JButton cancelar = new JButton("Cancelar");
        cancelar.setFont(cancelar.getFont().deriveFont(UiScale.f(9f)));
        cancelar.setFocusable(false);
        cancelar.addActionListener(e -> frame.goHome());
        add(cancelar);
    }

    private JButton criarCard(String titulo, javax.swing.Icon icon, java.awt.event.ActionListener onClick) {
        JButton botao = new JButton(titulo, icon);
        botao.setHorizontalTextPosition(SwingConstants.CENTER);
        botao.setVerticalTextPosition(SwingConstants.BOTTOM);
        botao.setFont(botao.getFont().deriveFont(Font.BOLD, UiScale.f(10f)));
        botao.setFocusable(false);
        botao.addActionListener(onClick);
        return botao;
    }
}
