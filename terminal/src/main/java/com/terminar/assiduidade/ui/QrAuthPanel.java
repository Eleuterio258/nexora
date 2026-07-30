package com.terminar.assiduidade.ui;

import com.github.sarxos.webcam.Webcam;
import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.model.MetodoAutenticacao;
import com.terminar.assiduidade.service.AuthService;
import com.terminar.assiduidade.util.QrCodeUtil;
import lombok.extern.slf4j.Slf4j;
import net.miginfocom.swing.MigLayout;

import javax.swing.ButtonGroup;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTextField;
import javax.swing.JToggleButton;
import javax.swing.SwingConstants;
import javax.swing.SwingUtilities;
import javax.swing.Timer;
import javax.swing.border.LineBorder;
import java.awt.CardLayout;
import java.awt.Color;
import java.awt.Font;
import java.awt.Image;
import java.awt.image.BufferedImage;
import java.awt.event.ActionEvent;
import java.util.List;
import java.util.Optional;

/**
 * Ecrã de QR Code com dois modos: "Ler QR" (a câmara do terminal lê um QR — crachá estático
 * ou código dinâmico de 60s vindo de uma app externa) e "Mostrar QR" (o terminal mostra o
 * QR do próprio funcionário no seu ecrã, para ser lido por outro dispositivo/câmara).
 */
@Slf4j
public class QrAuthPanel extends JPanel {

    private static final String CARD_LER = "ler";
    private static final String CARD_MOSTRAR = "mostrar";

    private static final String INSTRUCAO_LER = "Aponte o QR Code";
    private static final String SEM_CAMARA = "Sem câmara — introduza o código";

    private final int previewW = UiScale.px(150);
    private final int previewH = UiScale.px(84);
    private final int qrMostrarTamanho = UiScale.px(84);

    private final AssiduidadeFrame frame;
    private final AuthService authService = new AuthService();
    private final QrCodeUtil qrCodeUtil = new QrCodeUtil();

    private final CardLayout cardLayout = new CardLayout();
    private final JPanel content = new JPanel(cardLayout);

    private final JToggleButton lerToggle = new JToggleButton("Ler QR", true);
    private final JToggleButton mostrarToggle = new JToggleButton("Mostrar QR");

    // Cartão "Ler QR"
    private final JLabel previewLabel = new JLabel("", SwingConstants.CENTER);
    private final JLabel statusLerLabel = new JLabel(INSTRUCAO_LER, SwingConstants.CENTER);
    private final JTextField fallbackField = new JTextField();

    // Cartão "Mostrar QR"
    private final JTextField numeroField = new JTextField();
    private final JLabel qrMostrarLabel = new JLabel("", SwingConstants.CENTER);
    private final JLabel statusMostrarLabel = new JLabel("Introduza o seu número", SwingConstants.CENTER);

    private Webcam webcam;
    private volatile boolean capturando = false;
    private Thread capturaThread;
    private Timer avancoTimer;

    public QrAuthPanel(AssiduidadeFrame frame) {
        this.frame = frame;
        setLayout(new MigLayout("fill, insets 8, gap 3", "[grow, center]", "[]6[]6[grow]"));

        JLabel titulo = new JLabel("Leitura de QR Code", SwingConstants.CENTER);
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

        JPanel modos = new JPanel(new MigLayout("insets 0, gap 4", "[][]", "[]"));
        ButtonGroup grupoModos = new ButtonGroup();
        for (JToggleButton toggle : new JToggleButton[]{lerToggle, mostrarToggle}) {
            toggle.setFont(toggle.getFont().deriveFont(UiScale.f(9f)));
            toggle.setMargin(new java.awt.Insets(1, 6, 1, 6));
            toggle.setFocusable(false);
            grupoModos.add(toggle);
            modos.add(toggle);
        }
        lerToggle.addActionListener(e -> ativarModoLer());
        mostrarToggle.addActionListener(e -> ativarModoMostrar());
        add(modos, "align center, wrap");

        content.add(criarCardLer(), CARD_LER);
        content.add(criarCardMostrar(), CARD_MOSTRAR);
        add(content, "grow");
    }

    private JPanel criarCardLer() {
        JPanel card = new JPanel(new MigLayout("fill, insets 0, gap 6", "[grow, center]", "[]6[]4[]"));

        previewLabel.setOpaque(true);
        previewLabel.setBackground(new Color(30, 30, 33));
        previewLabel.setBorder(new LineBorder(new Color(90, 90, 96), 1, true));
        previewLabel.setPreferredSize(new java.awt.Dimension(previewW, previewH));
        card.add(previewLabel, "align center, wrap");

        statusLerLabel.setFont(statusLerLabel.getFont().deriveFont(UiScale.f(11f)));
        statusLerLabel.setForeground(new Color(160, 160, 165));
        card.add(statusLerLabel, "align center, wrap");

        fallbackField.setFont(fallbackField.getFont().deriveFont(UiScale.f(9f)));
        fallbackField.setToolTipText("Código do QR (modo de recurso)");
        fallbackField.addActionListener(this::onFallbackSubmit);
        fallbackField.setVisible(false);
        card.add(fallbackField, "align center, w " + UiScale.px(160) + "!, hidemode 3");
        return card;
    }

    private JPanel criarCardMostrar() {
        JPanel card = new JPanel(new MigLayout("fill, insets 0, gap 4", "[grow, center]", "[]6[]4[]"));

        JPanel entrada = new JPanel(new MigLayout("insets 0, gap 4", "[grow][]", "[]"));
        numeroField.setFont(numeroField.getFont().deriveFont(UiScale.f(10f)));
        numeroField.setToolTipText("Nº de funcionário");
        numeroField.addActionListener(this::onMostrarSubmit);
        entrada.add(numeroField, "growx, h " + UiScale.px(20) + "!");
        JButton mostrarButton = new JButton("Mostrar");
        mostrarButton.setFont(mostrarButton.getFont().deriveFont(UiScale.f(9f)));
        mostrarButton.setMargin(new java.awt.Insets(1, 4, 1, 4));
        mostrarButton.setFocusable(false);
        mostrarButton.addActionListener(this::onMostrarSubmit);
        entrada.add(mostrarButton);
        card.add(entrada, "growx, wrap");

        qrMostrarLabel.setPreferredSize(new java.awt.Dimension(qrMostrarTamanho, qrMostrarTamanho));
        card.add(qrMostrarLabel, "align center, wrap");

        statusMostrarLabel.setFont(statusMostrarLabel.getFont().deriveFont(UiScale.f(11f)));
        statusMostrarLabel.setForeground(new Color(160, 160, 165));
        card.add(statusMostrarLabel, "align center");
        return card;
    }

    private void ativarModoLer() {
        pararAvanco();
        qrMostrarLabel.setIcon(null);
        numeroField.setText("");
        statusMostrarLabel.setText("Introduza o seu número");
        cardLayout.show(content, CARD_LER);
        if (!capturando) {
            iniciarCapturaCamara();
        }
    }

    private void ativarModoMostrar() {
        pararCapturaCamara();
        cardLayout.show(content, CARD_MOSTRAR);
        SwingUtilities.invokeLater(numeroField::requestFocusInWindow);
    }

    /** Chamado pelo AssiduidadeFrame ao entrar neste ecrã — repõe sempre o modo "Ler QR". */
    public void iniciarCaptura() {
        lerToggle.setSelected(true);
        fallbackField.setText("");
        fallbackField.setVisible(false);
        statusLerLabel.setText("A abrir câmara...");
        previewLabel.setIcon(null);
        cardLayout.show(content, CARD_LER);
        iniciarCapturaCamara();
    }

    private void iniciarCapturaCamara() {
        capturaThread = new Thread(this::loopCaptura, "qr-webcam-capture");
        capturaThread.setDaemon(true);
        capturaThread.start();
    }

    private void loopCaptura() {
        try {
            List<Webcam> webcams = Webcam.getWebcams();
            int index = AppConfig.getWebcamDefaultIndex();
            if (webcams.isEmpty()) {
                SwingUtilities.invokeLater(this::ativarFallback);
                return;
            }
            webcam = webcams.get(Math.min(index, webcams.size() - 1));
            webcam.open();
            capturando = true;
            SwingUtilities.invokeLater(() -> statusLerLabel.setText(INSTRUCAO_LER));

            while (capturando) {
                BufferedImage img = webcam.getImage();
                if (img == null) {
                    continue;
                }
                atualizarPreview(img);
                String token = qrCodeUtil.descodificar(img);
                if (token != null && !token.isBlank()) {
                    capturando = false;
                    SwingUtilities.invokeLater(() -> autenticarPorLeitura(token));
                }
            }
        } catch (Exception e) {
            log.warn("Falha ao usar webcam para leitura de QR Code", e);
            SwingUtilities.invokeLater(this::ativarFallback);
        } finally {
            fecharWebcam();
        }
    }

    private void ativarFallback() {
        statusLerLabel.setText(SEM_CAMARA);
        fallbackField.setVisible(true);
        revalidate();
        repaint();
        fallbackField.requestFocusInWindow();
    }

    private void atualizarPreview(BufferedImage frame) {
        Image escalada = frame.getScaledInstance(previewW, previewH, Image.SCALE_FAST);
        ImageIcon icon = new ImageIcon(escalada);
        SwingUtilities.invokeLater(() -> previewLabel.setIcon(icon));
    }

    private void onFallbackSubmit(ActionEvent event) {
        String token = fallbackField.getText().trim();
        if (!token.isEmpty()) {
            autenticarPorLeitura(token);
        }
    }

    private void autenticarPorLeitura(String token) {
        Optional<Employee> employee = authService.authenticateByQrToken(token);
        if (employee.isPresent()) {
            pararCapturaCamara();
            frame.goToMarcarPonto(employee.get(), MetodoAutenticacao.QR_CODE);
        } else {
            fallbackField.setText("");
            statusLerLabel.setText("Código QR não reconhecido");
            Timer restaurar = new Timer(1500, r ->
                statusLerLabel.setText(fallbackField.isVisible() ? SEM_CAMARA : INSTRUCAO_LER));
            restaurar.setRepeats(false);
            restaurar.start();
        }
    }

    private void onMostrarSubmit(ActionEvent event) {
        String numero = numeroField.getText().trim();
        if (numero.isEmpty()) {
            return;
        }
        Optional<Employee> employeeOpt = authService.authenticateByNumero(numero);
        if (employeeOpt.isEmpty()) {
            statusMostrarLabel.setText("Funcionário não encontrado");
            qrMostrarLabel.setIcon(null);
            return;
        }
        Employee employee = employeeOpt.get();
        if (employee.getQrCodeToken() == null || employee.getQrCodeToken().isBlank()) {
            statusMostrarLabel.setText("Sem QR Code atribuído");
            qrMostrarLabel.setIcon(null);
            return;
        }
        BufferedImage imagem = qrCodeUtil.gerar(employee.getQrCodeToken(), AppConfig.getQrCodeSize());
        Image escalada = imagem.getScaledInstance(qrMostrarTamanho, qrMostrarTamanho, Image.SCALE_SMOOTH);
        qrMostrarLabel.setIcon(new ImageIcon(escalada));
        statusMostrarLabel.setText("Mostre este QR Code a quem o vai ler");

        pararAvanco();
        avancoTimer = new Timer(2000, e -> frame.goToMarcarPonto(employee, MetodoAutenticacao.QR_CODE));
        avancoTimer.setRepeats(false);
        avancoTimer.start();
    }

    private void pararAvanco() {
        if (avancoTimer != null) {
            avancoTimer.stop();
            avancoTimer = null;
        }
    }

    public void pararCaptura() {
        pararAvanco();
        pararCapturaCamara();
    }

    private void pararCapturaCamara() {
        capturando = false;
        fecharWebcam();
    }

    private void fecharWebcam() {
        if (webcam != null && webcam.isOpen()) {
            try {
                webcam.close();
            } catch (Exception e) {
                log.debug("Erro ao fechar webcam", e);
            }
        }
    }
}
