package tech.omnisyserp.desktop.ui;

import lombok.extern.slf4j.Slf4j;
import net.miginfocom.swing.MigLayout;
import tech.omnisyserp.desktop.client.BackendApiClient;
import tech.omnisyserp.desktop.dto.EnrollRequestDto;
import tech.omnisyserp.desktop.dto.EnrollResponseDto;
import tech.omnisyserp.desktop.model.Funcionario;
import tech.omnisyserp.desktop.service.CameraService;
import tech.omnisyserp.desktop.service.FuncionarioService;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;
import java.util.UUID;

@Slf4j
public class BiometricEnrollmentPanel extends JPanel {

    private final CameraService cameraService;
    private final FuncionarioService funcionarioService;
    private final BackendApiClient apiClient;

    private JLabel lblCamera;
    private JComboBox<Funcionario> cbFuncionario;
    private JButton btnIniciar;
    private JButton btnCapturar;
    private JButton btnLimpar;
    private JProgressBar progressBar;
    private JLabel lblStatus;
    private JPanel pnlPreviews;

    private List<byte[]> capturas = new ArrayList<>();
    private static final int TOTAL_CAPTURAS = 3;
    private boolean cameraAtiva = false;
    private Timer cameraTimer;

    // Liveness detection
    private enum LivenessEstado { AGUARDAR_ROSTO, AGUARDAR_MOVIMENTO, AGUARDAR_PISCADELA, PRONTO }
    private LivenessEstado estadoLiveness = LivenessEstado.AGUARDAR_ROSTO;
    private JLabel lblOverlay;
    private java.awt.Rectangle ultimoRostoRect = null;
    private int framesEstaticoCount = 0;
    private int piscadelasCount = 0;
    private boolean rostoNaFrameAnterior = false;
    private static final int FRAMES_ESTATICO_MAX = 25;
    private static final double LIMIAR_MOVIMENTO_PX = 7.0;
    private static final double LIMIAR_PROXIMIDADE = 0.18;
    private static final int PISCADELAS_NECESSARIAS = 2;
    private int framesAutoCaptura = 0;
    private static final int INTERVALO_AUTO_CAPTURA = 12; // ~1.2s a 10fps

    public BiometricEnrollmentPanel(CameraService cameraService, 
                                     FuncionarioService funcionarioService,
                                     BackendApiClient apiClient) {
        this.cameraService = cameraService;
        this.funcionarioService = funcionarioService;
        this.apiClient = apiClient;
        
        setLayout(new BorderLayout());
        setBackground(new Color(245, 247, 252));
        construirUI();
        carregarFuncionarios();
    }

    private void construirUI() {
        JPanel mainPanel = new JPanel(new MigLayout("fill, ins 20, gap 15", "[60%][40%]", "[grow]"));
        mainPanel.setOpaque(false);

        // Esquerda: Camera
        mainPanel.add(criarPainelCamera(), "grow");

        // Direita: Controles e Previews
        JPanel pnlDireita = new JPanel(new MigLayout("fillx, ins 0", "[grow]", "[][grow][]"));
        pnlDireita.setOpaque(false);
        pnlDireita.add(criarPainelControle(), "growx, wrap");
        pnlDireita.add(criarPainelPreviews(), "grow, wrap");
        pnlDireita.add(criarPainelAcoes(), "growx");
        
        mainPanel.add(pnlDireita, "grow");

        add(mainPanel, BorderLayout.CENTER);
    }

    private JPanel criarPainelCamera() {
        // JLayeredPane permite sobrepor o overlay directamente na imagem da camera
        JLayeredPane layered = new JLayeredPane() {
            @Override
            public void doLayout() {
                int w = getWidth(), h = getHeight();
                lblCamera.setBounds(0, 0, w, h);
                if (lblOverlay.isVisible()) {
                    lblOverlay.setSize(w, lblOverlay.getPreferredSize().height);
                    lblOverlay.setLocation(0, h - lblOverlay.getHeight());
                }
            }
        };
        layered.setBackground(Color.BLACK);
        layered.setOpaque(true);

        lblCamera = new JLabel("📷 Camera nao iniciada", SwingConstants.CENTER);
        lblCamera.setForeground(Color.GRAY);
        lblCamera.setFont(new Font("Segoe UI", Font.PLAIN, 18));
        lblCamera.setBackground(Color.BLACK);
        lblCamera.setOpaque(true);
        layered.add(lblCamera, JLayeredPane.DEFAULT_LAYER);

        lblOverlay = new JLabel("", SwingConstants.CENTER);
        lblOverlay.setFont(new Font("Segoe UI", Font.BOLD, 15));
        lblOverlay.setForeground(Color.WHITE);
        lblOverlay.setOpaque(true);
        lblOverlay.setBackground(new Color(30, 30, 30));
        lblOverlay.setBorder(BorderFactory.createEmptyBorder(10, 16, 10, 16));
        lblOverlay.setVisible(false);
        layered.add(lblOverlay, JLayeredPane.PALETTE_LAYER);

        JPanel wrapper = new JPanel(new BorderLayout());
        wrapper.setBorder(BorderFactory.createLineBorder(new Color(200, 205, 215), 2));
        wrapper.add(layered, BorderLayout.CENTER);
        return wrapper;
    }

    private JPanel criarPainelControle() {
        JPanel panel = new JPanel(new MigLayout("fillx, ins 15, gap 10", "[grow]", "[]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createLineBorder(new Color(220, 225, 235)));

        JLabel titulo = new JLabel("👤 Seleccionar Funcionario");
        titulo.setFont(new Font("Segoe UI", Font.BOLD, 14));
        panel.add(titulo, "wrap, gapbottom 5");

        cbFuncionario = new JComboBox<>();
        panel.add(cbFuncionario, "growx, wrap, gapbottom 10");

        btnIniciar = new JButton("▶ Iniciar Camera");
        estilizarBotao(btnIniciar, new Color(52, 120, 246));
        btnIniciar.addActionListener(e -> toggleCamera());
        panel.add(btnIniciar, "growx");

        return panel;
    }

    private JPanel criarPainelPreviews() {
        JPanel panel = new JPanel(new MigLayout("fill, ins 15, gap 10", "[grow][grow][grow]", "[grow]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)), "Capturas (0/3)"));
        pnlPreviews = panel;
        return panel;
    }

    private JPanel criarPainelAcoes() {
        JPanel panel = new JPanel(new MigLayout("fillx, ins 15, gap 10", "[grow]", "[][][]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createLineBorder(new Color(220, 225, 235)));

        btnCapturar = new JButton("📸 Capturar Foto");
        btnCapturar.setEnabled(false);
        btnCapturar.setVisible(false);
        estilizarBotao(btnCapturar, new Color(80, 200, 120));
        btnCapturar.addActionListener(e -> capturarFoto());

        btnLimpar = new JButton("🗑️ Recomecar");
        btnLimpar.setEnabled(false);
        estilizarBotao(btnLimpar, new Color(220, 53, 69));
        btnLimpar.addActionListener(e -> limparCapturas());
        panel.add(btnLimpar, "growx, wrap, gapbottom 10");

        progressBar = new JProgressBar(0, TOTAL_CAPTURAS);
        panel.add(progressBar, "growx, wrap, gapbottom 5");

        lblStatus = new JLabel("Aguardando inicio...");
        lblStatus.setFont(new Font("Segoe UI", Font.ITALIC, 11));
        panel.add(lblStatus, "center");

        return panel;
    }

    private void carregarFuncionarios() {
        try {
            List<Funcionario> funcionarios = funcionarioService.listarAtivos();
            cbFuncionario.removeAllItems();
            for (Funcionario f : funcionarios) {
                cbFuncionario.addItem(f);
            }
        } catch (Exception e) {
            log.error("Erro ao carregar funcionarios", e);
        }
    }

    private void toggleCamera() {
        if (!cameraAtiva) {
            if (cameraService.abrirCamera(0)) {
                cameraAtiva = true;
                btnIniciar.setText("⏹ Parar Camera");
                btnIniciar.setBackground(new Color(220, 53, 69));
                btnCapturar.setEnabled(false);
                reiniciarLiveness();

                cameraTimer = new Timer();
                cameraTimer.scheduleAtFixedRate(new TimerTask() {
                    @Override public void run() { atualizarFrame(); }
                }, 0, 100);
            }
        } else {
            pararCamera();
        }
    }

    private void reiniciarLiveness() {
        estadoLiveness = LivenessEstado.AGUARDAR_ROSTO;
        ultimoRostoRect = null;
        framesEstaticoCount = 0;
        piscadelasCount = 0;
        rostoNaFrameAnterior = false;
        framesAutoCaptura = 0;
        atualizarOverlay();
    }

    private void pararCamera() {
        if (cameraTimer != null) { cameraTimer.cancel(); cameraTimer = null; }
        cameraService.fecharCamera();
        cameraAtiva = false;
        estadoLiveness = LivenessEstado.AGUARDAR_ROSTO;
        btnIniciar.setText("▶ Iniciar Camera");
        btnIniciar.setBackground(new Color(52, 120, 246));
        btnCapturar.setEnabled(false);
        lblCamera.setIcon(null);
        lblCamera.setText("📷 Camera nao iniciada");
        lblOverlay.setVisible(false);
        lblStatus.setText("Aguardando inicio...");
    }

    private void atualizarFrame() {
        CameraService.FrameResult result = cameraService.capturarFrame();
        if (result == null || result.imagem() == null) return;

        processarLiveness(result);

        SwingUtilities.invokeLater(() -> {
            Image img = result.imagem().getScaledInstance(lblCamera.getWidth(), lblCamera.getHeight(), Image.SCALE_SMOOTH);
            lblCamera.setIcon(new ImageIcon(img));
            lblCamera.setText("");
        });
    }

    private void processarLiveness(CameraService.FrameResult result) {
        boolean rostoPresente = result.facesDetectadas() > 0;
        java.awt.Rectangle rosto = result.primeirRosto();
        int larguraFrame = result.larguraFrame();

        switch (estadoLiveness) {
            case AGUARDAR_ROSTO -> {
                boolean perto = rostoPresente && larguraFrame > 0
                        && ((double) rosto.width / larguraFrame) >= LIMIAR_PROXIMIDADE;
                if (perto) {
                    ultimoRostoRect = rosto;
                    framesEstaticoCount = 0;
                    estadoLiveness = LivenessEstado.AGUARDAR_MOVIMENTO;
                    SwingUtilities.invokeLater(this::atualizarOverlay);
                }
            }
            case AGUARDAR_MOVIMENTO -> {
                if (!rostoPresente) {
                    estadoLiveness = LivenessEstado.AGUARDAR_ROSTO;
                    SwingUtilities.invokeLater(this::atualizarOverlay);
                    break;
                }
                double deslocamento = ultimoRostoRect != null
                        ? Math.hypot(rosto.getCenterX() - ultimoRostoRect.getCenterX(),
                                     rosto.getCenterY() - ultimoRostoRect.getCenterY())
                        : 0;
                ultimoRostoRect = rosto;
                if (deslocamento > LIMIAR_MOVIMENTO_PX) {
                    framesEstaticoCount = 0;
                    piscadelasCount = 0;
                    rostoNaFrameAnterior = true;
                    estadoLiveness = LivenessEstado.AGUARDAR_PISCADELA;
                    SwingUtilities.invokeLater(this::atualizarOverlay);
                } else {
                    framesEstaticoCount++;
                    if (framesEstaticoCount > FRAMES_ESTATICO_MAX) {
                        SwingUtilities.invokeLater(this::atualizarOverlay);
                    }
                }
            }
            case AGUARDAR_PISCADELA -> {
                // piscadela = rosto desaparece brevemente e reaparece
                if (!rostoPresente && rostoNaFrameAnterior) {
                    piscadelasCount++;
                    SwingUtilities.invokeLater(this::atualizarOverlay);
                }
                rostoNaFrameAnterior = rostoPresente;
                if (piscadelasCount >= PISCADELAS_NECESSARIAS) {
                    estadoLiveness = LivenessEstado.PRONTO;
                    framesAutoCaptura = 0;
                    SwingUtilities.invokeLater(this::atualizarOverlay);
                }
            }
            case PRONTO -> {
                if (!rostoPresente) {
                    framesAutoCaptura = 0;
                    reiniciarLiveness();
                    break;
                }
                framesAutoCaptura++;
                int countdown = INTERVALO_AUTO_CAPTURA - framesAutoCaptura;
                if (framesAutoCaptura >= INTERVALO_AUTO_CAPTURA) {
                    framesAutoCaptura = 0;
                    byte[] jpeg = result.jpegBytes();
                    if (jpeg != null) {
                        SwingUtilities.invokeLater(() -> registarCaptura(jpeg));
                    }
                } else {
                    SwingUtilities.invokeLater(() -> atualizarOverlayContagem(countdown));
                }
            }
        }
    }

    private void atualizarOverlay() {
        if (!cameraAtiva) {
            lblOverlay.setVisible(false);
            return;
        }
        switch (estadoLiveness) {
            case AGUARDAR_ROSTO -> {
                lblOverlay.setText("  Aproxime o rosto da camera  ");
                lblOverlay.setBackground(new Color(40, 40, 40));
                lblOverlay.setVisible(true);
                lblStatus.setText("A aguardar deteccao do rosto...");
            }
            case AGUARDAR_MOVIMENTO -> {
                lblOverlay.setText("  Nao detectamos movimento — mova ligeiramente a cabeca  ");
                lblOverlay.setBackground(new Color(160, 90, 0));
                lblOverlay.setVisible(true);
                lblStatus.setText("Movimento necessario para verificar vivacidade.");
            }
            case AGUARDAR_PISCADELA -> {
                int restantes = PISCADELAS_NECESSARIAS - piscadelasCount;
                lblOverlay.setText("  Pisque " + (restantes > 1 ? "duas vezes" : "uma vez") + "  (" + piscadelasCount + "/" + PISCADELAS_NECESSARIAS + ")  ");
                lblOverlay.setBackground(new Color(0, 90, 170));
                lblOverlay.setVisible(true);
                lblStatus.setText("Piscadelas detectadas: " + piscadelasCount + "/" + PISCADELAS_NECESSARIAS);
            }
            case PRONTO -> {
                lblOverlay.setText("  Vivacidade confirmada — a capturar automaticamente...  ");
                lblOverlay.setBackground(new Color(0, 130, 55));
                lblOverlay.setVisible(true);
                lblStatus.setText("Pronto. A capturar " + capturas.size() + "/" + TOTAL_CAPTURAS + " ...");
            }
        }
    }

    private void atualizarOverlayContagem(int countdown) {
        int feitas = capturas.size();
        lblOverlay.setText("  Captura " + (feitas + 1) + "/" + TOTAL_CAPTURAS + " em " + countdown + "...  ");
        lblOverlay.setBackground(new Color(0, 110, 50));
        lblOverlay.setVisible(true);
        lblStatus.setText("Captura automatica: " + (feitas + 1) + "/" + TOTAL_CAPTURAS);
    }

    private void registarCaptura(byte[] frame) {
        if (capturas.size() >= TOTAL_CAPTURAS || estadoLiveness != LivenessEstado.PRONTO) return;

        capturas.add(frame);
        btnLimpar.setEnabled(true);
        progressBar.setValue(capturas.size());

        ImageIcon icon = new ImageIcon(new ImageIcon(frame).getImage().getScaledInstance(100, 100, Image.SCALE_SMOOTH));
        JLabel lblPreview = new JLabel(icon);
        lblPreview.setBorder(BorderFactory.createLineBorder(new Color(0, 130, 55), 2));
        pnlPreviews.add(lblPreview);
        pnlPreviews.revalidate();
        pnlPreviews.repaint();
        pnlPreviews.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                "Capturas (" + capturas.size() + "/3)"));

        if (capturas.size() == TOTAL_CAPTURAS) {
            lblOverlay.setVisible(false);
            finalizarTreino();
        }
    }

    private void capturarFoto() {
        if (capturas.size() >= TOTAL_CAPTURAS) return;
        if (estadoLiveness != LivenessEstado.PRONTO) {
            lblStatus.setText("Complete a verificacao de vivacidade primeiro.");
            return;
        }

        // botao manual oculto: nao e chamado em modo de captura automatica
        byte[] frame = cameraService.capturarFrameBytes();
        if (frame == null) {
            lblStatus.setText("Nenhum rosto detectado. Posicione o rosto no centro da camera.");
            return;
        }
        capturas.add(frame);
        btnLimpar.setEnabled(true);
        progressBar.setValue(capturas.size());

        // Adicionar preview
        ImageIcon icon = new ImageIcon(new ImageIcon(frame).getImage().getScaledInstance(100, 100, Image.SCALE_SMOOTH));
        JLabel lblPreview = new JLabel(icon);
        lblPreview.setBorder(BorderFactory.createLineBorder(Color.GRAY));
        pnlPreviews.add(lblPreview);
        pnlPreviews.revalidate();

        pnlPreviews.setBorder(BorderFactory.createTitledBorder(
            BorderFactory.createLineBorder(new Color(220, 225, 235)),
            "Capturas (" + capturas.size() + "/3)"));

        if (capturas.size() == TOTAL_CAPTURAS) {
            finalizarTreino();
        } else {
            lblStatus.setText("Foto " + capturas.size() + " capturada. Capture mais " + (TOTAL_CAPTURAS - capturas.size()) + ".");
        }
    }

    private void finalizarTreino() {
        btnCapturar.setEnabled(false);
        lblStatus.setText("A verificar consentimento...");
        
        Funcionario func = (Funcionario) cbFuncionario.getSelectedItem();
        if (func == null) return;

        SwingWorker<EnrollResponseDto, Void> worker = new SwingWorker<>() {
            @Override
            protected EnrollResponseDto doInBackground() throws Exception {
                // 1. Verificar consentimento ativo
                tech.omnisyserp.desktop.dto.ConsentResponseDto consent = apiClient.getActiveConsent(func.getId());
                
                if (consent == null) {
                    // Mostrar termo de consentimento
                    int choice = JOptionPane.showConfirmDialog(BiometricEnrollmentPanel.this,
                            "O funcionario " + func.getNomeCompleto() + " nao tem consentimento biometrico ativo.\n\n" +
                            "Termo de Consentimento (v1.0):\n" +
                            "Autorizo a recolha e processamento dos meus dados biometricos faciais\n" +
                            "para fins exclusivos de controlo de assiduidade e seguranca.\n\n" +
                            "Deseja registar o consentimento agora?",
                            "Consentimento Obrigatorio", JOptionPane.YES_NO_OPTION);
                    
                    if (choice == JOptionPane.YES_OPTION) {
                        tech.omnisyserp.desktop.dto.ConsentCreateDto newConsent = tech.omnisyserp.desktop.dto.ConsentCreateDto.builder()
                                .user_id(UUID.fromString(func.getId()))
                                .term_version("1.0")
                                .consent_hash("hash-desktop-" + System.currentTimeMillis())
                                .accepted_at(java.time.OffsetDateTime.now().toString())
                                .legal_basis("CONSENT")
                                .build();
                        apiClient.createConsent(newConsent);
                    } else {
                        throw new IllegalStateException("O consentimento e obrigatorio para continuar.");
                    }
                }

                // 2. Prosseguir com enrollment
                List<EnrollRequestDto.CaptureInput> capturesDto = new ArrayList<>();
                for (byte[] c : capturas) {
                    capturesDto.add(EnrollRequestDto.CaptureInput.builder()
                            .image_base64(Base64.getEncoder().encodeToString(c))
                            .build());
                }

                EnrollRequestDto req = EnrollRequestDto.builder()
                        .user_id(UUID.fromString(func.getId()))
                        .captures(capturesDto)
                        .build();

                return apiClient.enrollBiometric(req);
            }

            @Override
            protected void done() {
                try {
                    EnrollResponseDto res = get();
                    JOptionPane.showMessageDialog(BiometricEnrollmentPanel.this,
                            "✓ Rosto treinado com sucesso!\nO funcionario " + func.getNomeCompleto() + " ja pode usar reconhecimento facial.",
                            "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                    limparCapturas();
                } catch (Exception e) {
                    log.error("Erro no enrollment", e);
                    JOptionPane.showMessageDialog(BiometricEnrollmentPanel.this,
                            "Erro ao treinar rosto: " + e.getMessage(),
                            "Erro", JOptionPane.ERROR_MESSAGE);
                    btnCapturar.setEnabled(true);
                }
            }
        };
        worker.execute();
    }

    private void limparCapturas() {
        capturas.clear();
        pnlPreviews.removeAll();
        pnlPreviews.revalidate();
        pnlPreviews.repaint();
        pnlPreviews.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)), "Capturas (0/3)"));
        progressBar.setValue(0);
        btnCapturar.setEnabled(cameraAtiva);
        btnLimpar.setEnabled(false);
        lblStatus.setText("Pronto para capturar.");
    }

    private void estilizarBotao(JButton btn, Color cor) {
        btn.setBackground(cor);
        btn.setForeground(Color.WHITE);
        btn.setFont(new Font("Segoe UI", Font.BOLD, 12));
        btn.setFocusPainted(false);
        btn.setBorderPainted(false);
        btn.setOpaque(true);
        btn.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        btn.setPreferredSize(new Dimension(150, 38));
    }

    public void desactivar() {
        if (cameraAtiva) pararCamera();
    }
}
