package com.terminar.assiduidade.ui;

import com.github.sarxos.webcam.Webcam;
import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.model.MetodoAutenticacao;
import com.terminar.assiduidade.service.AuthService;
import com.terminar.assiduidade.util.QrCodeUtil;
import lombok.extern.slf4j.Slf4j;
import net.miginfocom.swing.MigLayout;

import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTextField;
import javax.swing.SwingConstants;
import javax.swing.SwingUtilities;
import javax.swing.Timer;
import javax.swing.border.LineBorder;
import java.awt.Color;
import java.awt.Font;
import java.awt.Image;
import java.awt.image.BufferedImage;
import java.awt.event.ActionEvent;
import java.util.List;
import java.util.Optional;

/**
 * Leitura de QR Code — Modo 1 (QR fixo do funcionário, ver documentação de "ler e ver"): a
 * câmara do terminal lê o código permanente do funcionário (impresso no crachá ou mostrado na
 * app Nexo) e identifica-o localmente (AuthService.authenticateByQrToken), sem chamar o ERP —
 * o QR em si não é um segredo temporário, só um identificador. Depois de identificado, segue o
 * mesmo caminho de PIN/NFC (PontoService.registarMarcacao, local + envio assíncrono ao ERP).
 */
@Slf4j
public class QrAuthPanel extends JPanel {

    private static final String INSTRUCAO = "Aponte o QR Code";
    private static final String SEM_CAMARA = "Sem câmara — introduza o código";

    private final int previewW = UiScale.px(150);
    private final int previewH = UiScale.px(84);

    private final AssiduidadeFrame frame;
    private final AuthService authService = new AuthService();
    private final QrCodeUtil qrCodeUtil = new QrCodeUtil();

    private final JLabel previewLabel = new JLabel("", SwingConstants.CENTER);
    private final JLabel statusLabel = new JLabel(INSTRUCAO, SwingConstants.CENTER);
    private final JTextField fallbackField = new JTextField();

    private Webcam webcam;
    private volatile boolean capturando = false;
    private Thread capturaThread;

    public QrAuthPanel(AssiduidadeFrame frame) {
        this.frame = frame;
        setLayout(new MigLayout("fill, insets 8, gap 3", "[grow, center]", "[]6[]6[]4[]"));

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

        previewLabel.setOpaque(true);
        previewLabel.setBackground(new Color(30, 30, 33));
        previewLabel.setBorder(new LineBorder(new Color(90, 90, 96), 1, true));
        previewLabel.setPreferredSize(new java.awt.Dimension(previewW, previewH));
        add(previewLabel, "align center, wrap");

        statusLabel.setFont(statusLabel.getFont().deriveFont(UiScale.f(11f)));
        statusLabel.setForeground(new Color(160, 160, 165));
        add(statusLabel, "align center, wrap");

        fallbackField.setFont(fallbackField.getFont().deriveFont(UiScale.f(9f)));
        fallbackField.setToolTipText("Código do QR (modo de recurso)");
        fallbackField.addActionListener(this::onFallbackSubmit);
        fallbackField.setVisible(false);
        add(fallbackField, "align center, w " + UiScale.px(160) + "!, hidemode 3");
    }

    /** Chamado pelo AssiduidadeFrame ao entrar neste ecrã. */
    public void iniciarCaptura() {
        fallbackField.setText("");
        fallbackField.setVisible(false);
        statusLabel.setText("A abrir câmara...");
        previewLabel.setIcon(null);
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
            SwingUtilities.invokeLater(() -> statusLabel.setText(INSTRUCAO));

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
        statusLabel.setText(SEM_CAMARA);
        fallbackField.setVisible(true);
        revalidate();
        repaint();
        fallbackField.requestFocusInWindow();
    }

    private void atualizarPreview(BufferedImage frameImg) {
        Image escalada = frameImg.getScaledInstance(previewW, previewH, Image.SCALE_FAST);
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
            statusLabel.setText("Código QR não reconhecido");
            Timer restaurar = new Timer(1500, r ->
                statusLabel.setText(fallbackField.isVisible() ? SEM_CAMARA : INSTRUCAO));
            restaurar.setRepeats(false);
            restaurar.start();
        }
    }

    public void pararCaptura() {
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
