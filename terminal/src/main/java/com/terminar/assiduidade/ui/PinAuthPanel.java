package com.terminar.assiduidade.ui;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.model.MetodoAutenticacao;
import com.terminar.assiduidade.service.AuthService;
import net.miginfocom.swing.MigLayout;

import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import javax.swing.border.CompoundBorder;
import javax.swing.border.EmptyBorder;
import javax.swing.border.LineBorder;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Insets;
import java.awt.RenderingHints;
import java.util.Optional;

/**
 * Ecrã de entrada de PIN, optimizado para um painel táctil 400x200.
 * O PIN identifica o funcionário por si só, sem nº de funcionário separado.
 */
public class PinAuthPanel extends JPanel {

    private static final int PIN_LENGTH = 4;
    private static final Color COR_BOTAO = new Color(70, 70, 76);
    private static final Color COR_BOTAO_PRESSIONADO = new Color(90, 90, 96);

    private final AssiduidadeFrame frame;
    private final AuthService authService = new AuthService();

    private final JLabel pinDisplay = new JLabel("", SwingConstants.CENTER);
    private final StringBuilder pinAtual = new StringBuilder();

    public PinAuthPanel(AssiduidadeFrame frame) {
        this.frame = frame;
        setLayout(new MigLayout("fill, insets 6, gap 2", "[grow, center]", "[]2[]6[]8[grow]"));

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

        JLabel titulo = new JLabel("Entrada de PIN", SwingConstants.CENTER);
        titulo.setFont(titulo.getFont().deriveFont(Font.BOLD, UiScale.f(13f)));
        add(titulo, "align center, wrap");

        pinDisplay.setFont(pinDisplay.getFont().deriveFont(UiScale.f(16f)));
        pinDisplay.setForeground(Color.WHITE);
        pinDisplay.setBorder(new CompoundBorder(
            new LineBorder(new Color(90, 90, 96), 1, true),
            new EmptyBorder(UiScale.px(4), UiScale.px(14), UiScale.px(4), UiScale.px(14))));
        atualizarDisplay();
        add(pinDisplay, "align center, w " + UiScale.px(150) + "!, wrap");

        add(criarTeclado(), "align center");
    }

    private JPanel criarTeclado() {
        int diametro = UiScale.px(34);
        JPanel teclado = new JPanel(new MigLayout("insets 0, gap " + UiScale.px(8) + " " + UiScale.px(8),
            "[]", "[]"));
        teclado.add(criarBotao("1", diametro));
        teclado.add(criarBotao("2", diametro));
        teclado.add(criarBotao("3", diametro), "wrap");
        teclado.add(criarBotao("4", diametro));
        teclado.add(criarBotao("5", diametro));
        teclado.add(criarBotao("6", diametro), "wrap");
        teclado.add(criarBotao("7", diametro));
        teclado.add(criarBotao("8", diametro));
        teclado.add(criarBotao("9", diametro), "wrap");
        teclado.add(criarBotao("0", diametro), "skip 1");
        return teclado;
    }

    private JButton criarBotao(String texto, int diametro) {
        JButton botao = new JButton(texto) {
            @Override
            protected void paintComponent(Graphics g) {
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
                g2.setColor(getModel().isPressed() ? COR_BOTAO_PRESSIONADO : COR_BOTAO);
                g2.fillOval(0, 0, getWidth(), getHeight());
                g2.dispose();
                super.paintComponent(g);
            }
        };
        botao.setPreferredSize(new Dimension(diametro, diametro));
        botao.setContentAreaFilled(false);
        botao.setBorderPainted(false);
        botao.setFocusPainted(false);
        botao.setForeground(Color.WHITE);
        botao.setFont(botao.getFont().deriveFont(Font.BOLD, UiScale.f(14f)));
        botao.setFocusable(false);
        botao.setMargin(new Insets(0, 0, 0, 0));
        botao.addActionListener(e -> onTecla(texto));
        return botao;
    }

    private void onTecla(String tecla) {
        if (pinAtual.length() >= PIN_LENGTH) {
            return;
        }
        pinAtual.append(tecla);
        atualizarDisplay();
        if (pinAtual.length() == PIN_LENGTH) {
            confirmar();
        }
    }

    private void atualizarDisplay() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < PIN_LENGTH; i++) {
            if (i > 0) {
                sb.append("   ");
            }
            sb.append(i < pinAtual.length() ? '●' : '○');
        }
        pinDisplay.setText(sb.toString());
    }

    private void confirmar() {
        Optional<Employee> employee = authService.authenticateByPin(pinAtual.toString());
        if (employee.isPresent()) {
            frame.goToMarcarPonto(employee.get(), MetodoAutenticacao.PIN);
        } else {
            pinAtual.setLength(0);
            atualizarDisplay();
        }
    }

    public void reiniciar() {
        pinAtual.setLength(0);
        atualizarDisplay();
    }
}
