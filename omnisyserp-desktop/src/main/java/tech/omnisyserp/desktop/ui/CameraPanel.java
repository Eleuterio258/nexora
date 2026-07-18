package tech.omnisyserp.desktop.ui;

import lombok.extern.slf4j.Slf4j;
import net.miginfocom.swing.MigLayout;
import tech.omnisyserp.desktop.model.Assiduidade;
import tech.omnisyserp.desktop.model.Funcionario;
import tech.omnisyserp.desktop.model.TipoRegisto;
import tech.omnisyserp.desktop.service.AssiduidadeService;
import tech.omnisyserp.desktop.service.CameraService;
import tech.omnisyserp.desktop.service.FuncionarioService;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

@Slf4j
public class CameraPanel extends JPanel {

    private final CameraService cameraService;
    private final AssiduidadeService assiduidadeService;
    private final FuncionarioService funcionarioService;
    private final tech.omnisyserp.desktop.client.BackendApiClient apiClient;
    private final tech.omnisyserp.desktop.config.BackendProperties props;
    private final tech.omnisyserp.desktop.auth.TokenStore tokenStore;

    // Camera display
    private JLabel lblCamera;
    private ImageIcon cameraIcon;
    private Timer cameraTimer;
    private JLabel lblFacesDetectadas;
    private JLabel lblUltimoReconhecimento;
    private JPanel pnlUltimoReconhecimento;
    
    // Controls
    private JComboBox<Funcionario> cbFuncionario;
    private JComboBox<TipoRegisto> cbTipoEvento;
    private JButton btnIniciarCamera;
    private JButton btnRegistarEntrada;
    private JButton btnRegistarSaida;
    private JCheckBox chkAutoDetect;
    
    // Status and activity
    private JLabel lblStatus;
    private JTextArea txtActivityLog;
    private JPanel pnlUltimoRegisto;
    private JLabel lblUltimoFuncionario;
    private JLabel lblUltimoTipo;
    private JLabel lblUltimoHora;
    
    private boolean cameraAtiva = false;
    private boolean autoDetectAtivo = false;
    private long ultimoVerifyTime = 0;
    private static final long VERIFY_COOLDOWN_MS = 5000;

    public CameraPanel(CameraService cameraService, AssiduidadeService assiduidadeService,
                       FuncionarioService funcionarioService,
                       tech.omnisyserp.desktop.client.BackendApiClient apiClient,
                       tech.omnisyserp.desktop.config.BackendProperties props,
                       tech.omnisyserp.desktop.auth.TokenStore tokenStore) {
        this.cameraService = cameraService;
        this.assiduidadeService = assiduidadeService;
        this.funcionarioService = funcionarioService;
        this.apiClient = apiClient;
        this.props = props;
        this.tokenStore = tokenStore;
        setLayout(new BorderLayout(0, 0));
        setBackground(new Color(245, 247, 252));
        construirUI();
        carregarFuncionarios();
    }

    private void construirUI() {
        JPanel mainPanel = new JPanel(new MigLayout(
                "fill, ins 15, gap 10",
                "[65%][35%]",
                "[55%][45%]"));
        mainPanel.setBackground(new Color(245, 247, 252));

        // Left column: Camera + Activity log
        mainPanel.add(criarPainelCamera(), "grow, cell 0 0");
        mainPanel.add(criarPainelActividade(), "grow, cell 0 1");
        
        // Right column: Controls + Last registration
        mainPanel.add(criarPainelControlo(), "grow, cell 1 0");
        mainPanel.add(criarPainelUltimoRegisto(), "grow, cell 1 1");

        add(mainPanel, BorderLayout.CENTER);
    }

    private JPanel criarPainelCamera() {
        JPanel panel = new JPanel(new MigLayout("fill, ins 0", "[grow]", "[grow][30px]"));
        panel.setBackground(Color.BLACK);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235), 2),
                new EmptyBorder(2, 2, 2, 2)));

        lblCamera = new JLabel();
        lblCamera.setHorizontalAlignment(SwingConstants.CENTER);
        lblCamera.setBackground(Color.BLACK);
        lblCamera.setOpaque(true);
        lblCamera.setText("📷 Camera nao iniciada");
        lblCamera.setForeground(new Color(150, 160, 180));
        lblCamera.setFont(new Font("Segoe UI", Font.PLAIN, 18));
        panel.add(lblCamera, "grow, cell 0 0");

        pnlUltimoReconhecimento = new JPanel(new MigLayout("fillx, ins 5, gap 10", "[grow][100px]"));
        pnlUltimoReconhecimento.setBackground(new Color(40, 45, 60));
        
        lblFacesDetectadas = new JLabel("Faces detectadas: 0");
        lblFacesDetectadas.setForeground(new Color(80, 200, 120));
        lblFacesDetectadas.setFont(new Font("Segoe UI", Font.BOLD, 11));
        pnlUltimoReconhecimento.add(lblFacesDetectadas, "cell 0 0");
        
        lblUltimoReconhecimento = new JLabel("Ultimo: --");
        lblUltimoReconhecimento.setForeground(new Color(150, 160, 180));
        lblUltimoReconhecimento.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        pnlUltimoReconhecimento.add(lblUltimoReconhecimento, "cell 1 0");
        
        panel.add(pnlUltimoReconhecimento, "growx, cell 0 1");
        
        return panel;
    }

    private JPanel criarPainelActividade() {
        JPanel panel = new JPanel(new BorderLayout(0, 0));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(10, 10, 10, 10)));
        
        JLabel lblTitulo = new JLabel("Actividade Recente");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 13));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, BorderLayout.NORTH);
        
        txtActivityLog = new JTextArea();
        txtActivityLog.setFont(new Font("Consolas", Font.PLAIN, 11));
        txtActivityLog.setBackground(new Color(250, 251, 252));
        txtActivityLog.setForeground(new Color(50, 55, 70));
        txtActivityLog.setEditable(false);
        txtActivityLog.setLineWrap(true);
        txtActivityLog.setWrapStyleWord(true);
        txtActivityLog.setBorder(new EmptyBorder(5, 5, 5, 5));
        
        JScrollPane scroll = new JScrollPane(txtActivityLog);
        scroll.setBorder(BorderFactory.createLineBorder(new Color(230, 235, 245)));
        panel.add(scroll, BorderLayout.CENTER);
        
        JButton btnLimparLog = new JButton("Limpar Log");
        btnLimparLog.setFont(new Font("Segoe UI", Font.PLAIN, 10));
        btnLimparLog.addActionListener(e -> txtActivityLog.setText(""));
        panel.add(btnLimparLog, BorderLayout.SOUTH);
        
        return panel;
    }

    private JPanel criarPainelControlo() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 15, gap 8",
                "[grow]",
                "[][][][][][][][]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(15, 15, 15, 15)));

        JLabel lblTitulo = new JLabel("Controlo de Camera");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 15));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, "wrap, gapbottom 5");
        
        JSeparator sep = new JSeparator();
        panel.add(sep, "growx, wrap, gapbottom 10");

        panel.add(new JLabel("Funcionario:"), "gapbottom 3");
        cbFuncionario = new JComboBox<>();
        cbFuncionario.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        panel.add(cbFuncionario, "growx, wrap, gapbottom 8");

        panel.add(new JLabel("Tipo de Evento:"), "gapbottom 3");
        cbTipoEvento = new JComboBox<>(new TipoRegisto[]{
                TipoRegisto.PRESENCIAL, 
                TipoRegisto.FORMACAO,
                TipoRegisto.REMOTO
        });
        cbTipoEvento.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        panel.add(cbTipoEvento, "growx, wrap, gapbottom 8");

        chkAutoDetect = new JCheckBox("Detecao automatica de rosto");
        chkAutoDetect.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        chkAutoDetect.addActionListener(e -> {
            autoDetectAtivo = chkAutoDetect.isSelected();
            logInfo("Detecao automatica " + (autoDetectAtivo ? "ATIVADA" : "DESATIVADA"));
        });
        panel.add(chkAutoDetect, "growx, wrap, gapbottom 8");

        btnIniciarCamera = new JButton("▶ Iniciar Camera");
        estilizarBotao(btnIniciarCamera, new Color(52, 120, 246));
        btnIniciarCamera.addActionListener(e -> toggleCamera());
        panel.add(btnIniciarCamera, "growx, wrap, gapbottom 5");

        btnRegistarEntrada = new JButton("✓ Registar Entrada");
        estilizarBotao(btnRegistarEntrada, new Color(80, 200, 120));
        btnRegistarEntrada.setEnabled(false);
        btnRegistarEntrada.addActionListener(e -> registarEntrada());
        panel.add(btnRegistarEntrada, "growx, wrap, gapbottom 5");

        btnRegistarSaida = new JButton("⏹ Registar Saida");
        estilizarBotao(btnRegistarSaida, new Color(255, 140, 0));
        btnRegistarSaida.setEnabled(false);
        btnRegistarSaida.addActionListener(e -> registarSaida());
        panel.add(btnRegistarSaida, "growx, wrap");

        return panel;
    }

    private JPanel criarPainelUltimoRegisto() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 15, gap 8",
                "[100px][grow]",
                "[][][][]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(15, 15, 15, 15)));
        
        JLabel lblTitulo = new JLabel("Ultimo Registo");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 15));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, "span 2, wrap, gapbottom 5");
        
        JSeparator sep = new JSeparator();
        panel.add(sep, "span 2, growx, wrap, gapbottom 10");

        panel.add(new JLabel("Funcionario:"), "cell 0 0");
        lblUltimoFuncionario = new JLabel("--");
        lblUltimoFuncionario.setFont(new Font("Segoe UI", Font.BOLD, 12));
        lblUltimoFuncionario.setForeground(new Color(30, 35, 50));
        panel.add(lblUltimoFuncionario, "cell 1 0");

        panel.add(new JLabel("Tipo:"), "cell 0 1");
        lblUltimoTipo = new JLabel("--");
        lblUltimoTipo.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        lblUltimoTipo.setForeground(new Color(100, 110, 130));
        panel.add(lblUltimoTipo, "cell 1 1");

        panel.add(new JLabel("Hora:"), "cell 0 2");
        lblUltimoHora = new JLabel("--");
        lblUltimoHora.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        lblUltimoHora.setForeground(new Color(100, 110, 130));
        panel.add(lblUltimoHora, "cell 1 2");
        
        lblStatus = new JLabel("Aguardando registo...");
        lblStatus.setFont(new Font("Segoe UI", Font.ITALIC, 11));
        lblStatus.setForeground(new Color(150, 160, 180));
        panel.add(lblStatus, "span 2, wrap, gapbottom 5");

        return panel;
    }

    private void carregarFuncionarios() {
        try {
            var currentUser = tokenStore.getCurrentUser();
            String role = currentUser != null && currentUser.getRole() != null ? 
                    currentUser.getRole().toString() : "COLABORADOR";

            List<Funcionario> funcionarios = funcionarioService.listarAtivos();
            cbFuncionario.removeAllItems();
            
            if ("COLABORADOR".equals(role) && currentUser != null) {
                // Se for colaborador, so pode registar para si proprio
                funcionarios.stream()
                        .filter(f -> f.getId().equals(currentUser.getId()))
                        .forEach(cbFuncionario::addItem);
                
                if (cbFuncionario.getItemCount() > 0) {
                    cbFuncionario.setSelectedIndex(0);
                    cbFuncionario.setEnabled(false); // Bloquear combo
                }
            } else {
                for (Funcionario f : funcionarios) {
                    cbFuncionario.addItem(f);
                }
                cbFuncionario.setEnabled(true);
            }
        } catch (Exception ex) {
            log.error("Erro ao carregar funcionarios", ex);
            logInfo("ERRO: Falha ao carregar lista de funcionarios");
        }
    }

    private void toggleCamera() {
        if (!cameraAtiva) iniciarCamera(); else pararCamera();
    }

    private void iniciarCamera() {
        try {
            if (!cameraService.isOpencvDisponivel()) {
                JOptionPane.showMessageDialog(this,
                        "OpenCV nao disponivel. Verifique a instalacao.",
                        "Erro", JOptionPane.ERROR_MESSAGE);
                return;
            }
            if (!cameraService.abrirCamera(0)) {
                JOptionPane.showMessageDialog(this,
                        "Nao foi possivel abrir a camera.",
                        "Erro", JOptionPane.ERROR_MESSAGE);
                return;
            }
            
            cameraAtiva = true;
            btnIniciarCamera.setText("⏹ Parar Camera");
            btnIniciarCamera.setBackground(new Color(220, 53, 69));
            btnRegistarEntrada.setEnabled(true);
            btnRegistarSaida.setEnabled(true);
            
            lblStatus.setText("Camera ativa - Pronta para registar");
            lblStatus.setForeground(new Color(80, 200, 120));
            logInfo("Camera iniciada com sucesso");
            
            cameraTimer = new Timer();
            cameraTimer.scheduleAtFixedRate(new TimerTask() {
                @Override public void run() { atualizarFrame(); }
            }, 0, 100);
            
            log.info("Camera iniciada");
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(this, "Erro ao iniciar camera: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
            log.error("Erro ao iniciar camera", ex);
            logInfo("ERRO: " + ex.getMessage());
        }
    }

    private void pararCamera() {
        try {
            if (cameraTimer != null) { cameraTimer.cancel(); cameraTimer = null; }
            cameraService.fecharCamera();
            cameraAtiva = false;
            autoDetectAtivo = false;
            chkAutoDetect.setSelected(false);
            
            btnIniciarCamera.setText("▶ Iniciar Camera");
            btnIniciarCamera.setBackground(new Color(52, 120, 246));
            btnRegistarEntrada.setEnabled(false);
            btnRegistarSaida.setEnabled(false);
            
            lblStatus.setText("Camera parada");
            lblStatus.setForeground(new Color(150, 160, 180));
            lblCamera.setIcon(null);
            lblCamera.setText("📷 Camera nao iniciada");
            lblFacesDetectadas.setText("Faces detectadas: 0");
            
            logInfo("Camera parada");
        } catch (Exception ex) {
            log.error("Erro ao parar camera", ex);
        }
    }

    private void atualizarFrame() {
        try {
            CameraService.FrameResult result = cameraService.capturarFrame();
            if (result != null && result.imagem() != null) {
                SwingUtilities.invokeLater(() -> {
                    cameraIcon = new ImageIcon(
                            resizeImage(result.imagem(), lblCamera.getWidth(), lblCamera.getHeight()));
                    lblCamera.setIcon(cameraIcon);
                    lblCamera.setText("");
                    lblFacesDetectadas.setText("Faces detectadas: " + result.facesDetectadas());
                    
                    if (autoDetectAtivo && result.facesDetectadas() > 0) {
                        tentarAutoVerificacao();
                    }
                });
            }
        } catch (Exception ex) {
            log.error("Erro ao capturar frame", ex);
        }
    }

    private void tentarAutoVerificacao() {
        long now = System.currentTimeMillis();
        if (now - ultimoVerifyTime < VERIFY_COOLDOWN_MS) return;

        Funcionario f = (Funcionario) cbFuncionario.getSelectedItem();
        if (f == null || f.getId() == null) return;

        ultimoVerifyTime = now;
        
        SwingWorker<tech.omnisyserp.desktop.dto.VerifyResponseDto, Void> worker = 
                new SwingWorker<>() {
            @Override
            protected tech.omnisyserp.desktop.dto.VerifyResponseDto doInBackground() throws Exception {
                byte[] frame = cameraService.capturarFrameBytes();
                if (frame == null) return null;

                String base64 = java.util.Base64.getEncoder().encodeToString(frame);
                
                tech.omnisyserp.desktop.dto.VerifyRequestDto req = tech.omnisyserp.desktop.dto.VerifyRequestDto.builder()
                        .user_id(java.util.UUID.fromString(f.getId()))
                        .image_base64(base64)
                        .build();
                
                if (props != null && props.getDevice() != null && props.getDevice().getId() != null) {
                    try {
                        req.setDevice_id(java.util.UUID.fromString(props.getDevice().getId()));
                    } catch (Exception e) {
                        log.warn("ID de dispositivo invalido: {}", props.getDevice().getId());
                        // Fallback para UUID nulo ou um valor que o backend aceite se necessario
                        req.setDevice_id(java.util.UUID.fromString("00000000-0000-0000-0000-000000000099"));
                    }
                } else {
                    req.setDevice_id(java.util.UUID.fromString("00000000-0000-0000-0000-000000000099"));
                }

                return apiClient.withTokenRetry(() -> apiClient.verifyBiometric(req));
            }

            @Override
            protected void done() {
                try {
                    tech.omnisyserp.desktop.dto.VerifyResponseDto resp = get();
                    if (resp != null) {
                        lblUltimoReconhecimento.setText("Match: " + (resp.isMatch() ? "SIM" : "NAO") + 
                                " (" + String.format("%.0f%%", resp.getConfidence_score() * 100) + ")");
                        
                        if (resp.isMatch()) {
                            lblUltimoReconhecimento.setForeground(new Color(80, 200, 120));
                            logInfo("RECONHECIMENTO: " + f.getNomeCompleto() + " identificado (Conf: " + 
                                    String.format("%.1f%%", resp.getConfidence_score() * 100) + ")");
                        } else {
                            lblUltimoReconhecimento.setForeground(new Color(220, 53, 69));
                            logInfo("RECONHECIMENTO: Falha ao identificar " + f.getNomeCompleto() + 
                                    " (Motivo: " + resp.getReason() + ")");
                        }
                    }
                } catch (Exception e) {
                    log.error("Erro na auto-verificacao", e);
                }
            }
        };
        worker.execute();
    }

    private Image resizeImage(BufferedImage original, int width, int height) {
        return new ImageIcon(original.getScaledInstance(width, height, Image.SCALE_SMOOTH)).getImage();
    }

    private void registarEntrada() {
        try {
            Funcionario funcionario = (Funcionario) cbFuncionario.getSelectedItem();
            if (funcionario == null) {
                JOptionPane.showMessageDialog(this, "Selecione um funcionario.",
                        "Validacao", JOptionPane.WARNING_MESSAGE);
                return;
            }

            TipoRegisto tipo = (TipoRegisto) cbTipoEvento.getSelectedItem();
            byte[] foto = cameraService.capturarFrameBytes();

            boolean temEntradaAberta = assiduidadeService.buscarRegistoAberto(funcionario).isPresent();
            if (temEntradaAberta) {
                int opcao = JOptionPane.showConfirmDialog(this,
                        funcionario.getNomeCompleto() + " ja tem uma entrada registada sem saida.\n" +
                                "Deseja registar saida primeiro?",
                        "Entrada em Aberto", JOptionPane.YES_NO_OPTION, JOptionPane.QUESTION_MESSAGE);
                if (opcao == JOptionPane.YES_OPTION) {
                    registarSaida();
                }
                return;
            }

            Assiduidade registo = assiduidadeService.registarEntrada(funcionario, tipo, foto);
            
            JOptionPane.showMessageDialog(this,
                    "✓ Entrada registada com sucesso!\n\n" +
                            "Funcionario: " + funcionario.getNomeCompleto() +
                            "\nHora: " + registo.getDataHoraEntrada().format(
                                    DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss")) +
                            "\nTipo: " + tipo.getLabel(),
                    "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            
            atualizarUltimoRegisto(funcionario, tipo, registo.getDataHoraEntrada());
            logInfo("ENTRADA: " + funcionario.getNomeCompleto() + " às " + 
                    registo.getDataHoraEntrada().format(DateTimeFormatter.ofPattern("HH:mm:ss")));
            
            log.info("Entrada registada via camera: {}", funcionario.getNomeCompleto());
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(this, "Erro ao registar entrada: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
            log.error("Erro ao registar entrada", ex);
            logInfo("ERRO ao registar entrada: " + ex.getMessage());
        }
    }

    private void registarSaida() {
        try {
            Funcionario funcionario = (Funcionario) cbFuncionario.getSelectedItem();
            if (funcionario == null) {
                JOptionPane.showMessageDialog(this, "Selecione um funcionario.",
                        "Validacao", JOptionPane.WARNING_MESSAGE);
                return;
            }

            if (assiduidadeService.buscarRegistoAberto(funcionario).isEmpty()) {
                JOptionPane.showMessageDialog(this,
                        funcionario.getNomeCompleto() + " nao tem entrada registada em aberto.",
                        "Erro", JOptionPane.ERROR_MESSAGE);
                return;
            }

            byte[] foto = cameraService.capturarFrameBytes();
            Assiduidade registo = assiduidadeService.registarSaida(funcionario, foto);
            
            JOptionPane.showMessageDialog(this,
                    "✓ Saida registada com sucesso!\n\n" +
                            "Funcionario: " + funcionario.getNomeCompleto() +
                            "\nDuracao: " + registo.getDuracaoFormatada() +
                            "\nHora saida: " + registo.getDataHoraSaida().format(
                                    DateTimeFormatter.ofPattern("HH:mm:ss")),
                    "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            
            atualizarUltimoRegisto(funcionario, registo.getTipo(), registo.getDataHoraSaida());
            logInfo("SAIDA: " + funcionario.getNomeCompleto() + " às " + 
                    registo.getDataHoraSaida().format(DateTimeFormatter.ofPattern("HH:mm:ss")) +
                    " (Duracao: " + registo.getDuracaoFormatada() + ")");
            
            log.info("Saida registada via camera: {}", funcionario.getNomeCompleto());
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(this, "Erro ao registar saida: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
            log.error("Erro ao registar saida", ex);
            logInfo("ERRO ao registar saida: " + ex.getMessage());
        }
    }

    private void atualizarUltimoRegisto(Funcionario funcionario, TipoRegisto tipo, LocalDateTime hora) {
        lblUltimoFuncionario.setText(funcionario.getNomeCompleto());
        lblUltimoTipo.setText(tipo.getLabel());
        lblUltimoHora.setText(hora.format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss")));
        lblStatus.setText("Registo registado com sucesso!");
    }

    private void logInfo(String mensagem) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss"));
        txtActivityLog.append("[" + timestamp + "] " + mensagem + "\n");
        txtActivityLog.setCaretPosition(txtActivityLog.getDocument().getLength());
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

    public void activar() {
        carregarFuncionarios();
    }

    public void desactivar() {
        if (cameraAtiva) pararCamera();
    }
}
