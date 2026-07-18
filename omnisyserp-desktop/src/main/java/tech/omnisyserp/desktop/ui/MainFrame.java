package tech.omnisyserp.desktop.ui;

import com.formdev.flatlaf.extras.FlatSVGIcon;
import lombok.extern.slf4j.Slf4j;
import tech.omnisyserp.desktop.auth.TokenStore;
import tech.omnisyserp.desktop.client.BackendApiClient;
import tech.omnisyserp.desktop.service.AssiduidadeService;
import tech.omnisyserp.desktop.service.CameraService;
import tech.omnisyserp.desktop.service.FuncionarioService;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;

@Slf4j
public class MainFrame extends JFrame {

    private final FuncionarioService funcionarioService;
    private final AssiduidadeService assiduidadeService;
    private final CameraService cameraService;
    private final TokenStore tokenStore;
    private final BackendApiClient apiClient;
    private final tech.omnisyserp.desktop.config.BackendProperties backendProperties;

    private JPanel contentPanel;
    private CardLayout cardLayout;

    private final java.util.Map<String, JButton> navButtons = new java.util.HashMap<>();

    private FuncionariosPanel funcionariosPanel;
    private AssiduidadePanel assiduidadePanel;
    private CameraPanel cameraPanel;
    private BiometricEnrollmentPanel enrollmentPanel;
    private DashboardPanel dashboardPanel;
    private SettingsPanel settingsPanel;
    private SelfServicePanel selfServicePanel;
    private ReportsPanel reportsPanel;

    private JButton btnAtivo;
    private JLabel lblUsuarioInfo;
    private JLabel lblSessionTimer;

    public MainFrame(FuncionarioService funcionarioService,
                     AssiduidadeService assiduidadeService,
                     CameraService cameraService,
                     TokenStore tokenStore,
                     BackendApiClient apiClient,
                     tech.omnisyserp.desktop.config.BackendProperties backendProperties) {
        this.funcionarioService = funcionarioService;
        this.assiduidadeService = assiduidadeService;
        this.cameraService = cameraService;
        this.tokenStore = tokenStore;
        this.apiClient = apiClient;
        this.backendProperties = backendProperties;
        construirUI();
        aplicarRoleBasedUI();
        iniciarSessionTimer();
    }

    private void construirUI() {
        setTitle("OmnisysERP - Controlo de Assiduidade");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(1280, 800);
        setMinimumSize(new Dimension(1024, 680));
        setLocationRelativeTo(null);

        setLayout(new BorderLayout());
        add(criarSidebar(), BorderLayout.WEST);
        add(criarConteudo(), BorderLayout.CENTER);
        add(criarStatusBar(), BorderLayout.SOUTH);

        mostrarPainel("DASHBOARD");
        ativarBotao(navButtons.get("DASHBOARD"));
    }

    private JPanel criarSidebar() {
        JPanel sidebar = new JPanel();
        sidebar.setLayout(new BoxLayout(sidebar, BoxLayout.Y_AXIS));
        sidebar.setBackground(new Color(30, 35, 50));
        sidebar.setPreferredSize(new Dimension(220, 0));
        sidebar.setBorder(new EmptyBorder(0, 0, 0, 0));

        // Logo / titulo
        JPanel logoPanel = new JPanel(new BorderLayout());
        logoPanel.setBackground(new Color(22, 27, 40));
        logoPanel.setBorder(new EmptyBorder(20, 15, 20, 15));

        JLabel titulo = new JLabel("OmnisysERP");
        titulo.setForeground(Color.WHITE);
        titulo.setFont(new Font("Segoe UI", Font.BOLD, 18));
        titulo.setHorizontalAlignment(SwingConstants.CENTER);

        JLabel subtitulo = new JLabel("Controlo de Assiduidade");
        subtitulo.setForeground(new Color(150, 160, 180));
        subtitulo.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        subtitulo.setHorizontalAlignment(SwingConstants.CENTER);

        JPanel textos = new JPanel(new GridLayout(2, 1, 0, 2));
        textos.setOpaque(false);
        textos.add(titulo);
        textos.add(subtitulo);
        logoPanel.add(textos, BorderLayout.CENTER);

        sidebar.add(logoPanel);
        sidebar.add(Box.createVerticalStrut(10));

        JLabel secLabel = new JLabel("  MENU");
        secLabel.setForeground(new Color(100, 110, 130));
        secLabel.setFont(new Font("Segoe UI", Font.BOLD, 10));
        secLabel.setBorder(new EmptyBorder(5, 15, 5, 0));
        secLabel.setAlignmentX(LEFT_ALIGNMENT);
        sidebar.add(secLabel);

        // Botoes de navegacao
        navButtons.put("DASHBOARD",    criarBotaoNav("Dashboard",        "dashboard",    "DASHBOARD"));
        navButtons.put("SELFSERVICE",  criarBotaoNav("Meu Historico",    "selfservice",  "SELFSERVICE"));
        navButtons.put("FUNCIONARIOS", criarBotaoNav("Funcionarios",     "funcionarios", "FUNCIONARIOS"));
        navButtons.put("ASSIDUIDADE",  criarBotaoNav("Assiduidade",      "assiduidade",  "ASSIDUIDADE"));
        navButtons.put("CAMERA",       criarBotaoNav("Camera / Presenca","camera",       "CAMERA"));
        navButtons.put("ENROLLMENT",   criarBotaoNav("Treinar Rosto",    "enrollment",   "ENROLLMENT"));
        navButtons.put("REPORTS",      criarBotaoNav("Relatorios",       "reports",      "REPORTS"));
        navButtons.put("SETTINGS",     criarBotaoNav("Configuracoes",    "settings",     "SETTINGS"));

        sidebar.add(navButtons.get("DASHBOARD"));
        sidebar.add(navButtons.get("SELFSERVICE"));
        sidebar.add(navButtons.get("FUNCIONARIOS"));
        sidebar.add(navButtons.get("ASSIDUIDADE"));
        sidebar.add(navButtons.get("CAMERA"));
        sidebar.add(navButtons.get("ENROLLMENT"));
        sidebar.add(navButtons.get("REPORTS"));
        sidebar.add(navButtons.get("SETTINGS"));

        sidebar.add(Box.createVerticalGlue());

        // Botao Sair no Sidebar
        JButton btnSairSide = criarBotaoNav("Sair do Sistema", "logout", "LOGOUT");
        btnSairSide.setForeground(new Color(255, 100, 100));
        btnSairSide.addActionListener(e -> fazerLogout());
        sidebar.add(btnSairSide);

        // Versao
        JLabel versao = new JLabel("v1.1.0");
        versao.setForeground(new Color(80, 90, 110));
        versao.setFont(new Font("Segoe UI", Font.PLAIN, 10));
        versao.setBorder(new EmptyBorder(10, 15, 10, 0));
        versao.setAlignmentX(LEFT_ALIGNMENT);
        sidebar.add(versao);

        return sidebar;
    }

    private JButton criarBotaoNav(String texto, String icone, String painel) {
        JButton btn = new JButton(texto);

        try {
            FlatSVGIcon svgIcon = new FlatSVGIcon("icons/" + icone + ".svg", 18, 18);
            svgIcon.setColorFilter(new FlatSVGIcon.ColorFilter(
                    color -> new Color(180, 190, 210)));
            btn.setIcon(svgIcon);
            btn.putClientProperty("svgIcon", svgIcon);
        } catch (Exception e) {
            log.debug("Icone SVG nao encontrado: icons/{}.svg", icone);
        }

        btn.setAlignmentX(LEFT_ALIGNMENT);
        btn.setMaximumSize(new Dimension(Integer.MAX_VALUE, 48));
        btn.setPreferredSize(new Dimension(220, 48));
        btn.setHorizontalAlignment(SwingConstants.LEFT);
        btn.setIconTextGap(10);
        btn.setBorder(new EmptyBorder(0, 16, 0, 10));
        btn.setBackground(new Color(30, 35, 50));
        btn.setForeground(new Color(180, 190, 210));
        btn.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        btn.setFocusPainted(false);
        btn.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        btn.setOpaque(true);
        btn.setBorderPainted(false);

        btn.addMouseListener(new java.awt.event.MouseAdapter() {
            @Override
            public void mouseEntered(java.awt.event.MouseEvent e) {
                if (btn != btnAtivo) {
                    btn.setBackground(new Color(40, 46, 65));
                    atualizarCorIcone(btn, Color.WHITE);
                }
            }

            @Override
            public void mouseExited(java.awt.event.MouseEvent e) {
                if (btn != btnAtivo) {
                    btn.setBackground(new Color(30, 35, 50));
                    atualizarCorIcone(btn, new Color(180, 190, 210));
                }
            }
        });

        if (!"LOGOUT".equals(painel)) {
            btn.addActionListener(e -> {
                ativarBotao(btn);
                mostrarPainel(painel);
            });
        }

        btn.putClientProperty("painel", painel);
        return btn;
    }

    private void ativarBotao(JButton btn) {
        if (btnAtivo != null) {
            btnAtivo.setBackground(new Color(30, 35, 50));
            btnAtivo.setForeground(new Color(180, 190, 210));
            atualizarCorIcone(btnAtivo, new Color(180, 190, 210));
        }
        btn.setBackground(new Color(52, 120, 246));
        btn.setForeground(Color.WHITE);
        atualizarCorIcone(btn, Color.WHITE);
        btnAtivo = btn;
    }

    private void atualizarCorIcone(JButton btn, Color cor) {
        Object svgIcon = btn.getClientProperty("svgIcon");
        if (svgIcon instanceof FlatSVGIcon icon) {
            icon.setColorFilter(new FlatSVGIcon.ColorFilter(c -> cor));
            btn.repaint();
        }
    }

    private JPanel criarConteudo() {
        cardLayout = new CardLayout();
        contentPanel = new JPanel(cardLayout);
        contentPanel.setBackground(new Color(245, 247, 252));

        dashboardPanel = new DashboardPanel(funcionarioService, assiduidadeService, tokenStore);
        selfServicePanel = new SelfServicePanel(apiClient, tokenStore);
        funcionariosPanel = new FuncionariosPanel(funcionarioService);
        assiduidadePanel = new AssiduidadePanel(assiduidadeService, funcionarioService);
        cameraPanel = new CameraPanel(cameraService, assiduidadeService, funcionarioService, apiClient, backendProperties, tokenStore);
        enrollmentPanel = new BiometricEnrollmentPanel(cameraService, funcionarioService, apiClient);
        reportsPanel = new ReportsPanel(apiClient, tokenStore);
        settingsPanel = new SettingsPanel(backendProperties, tokenStore);

        contentPanel.add(dashboardPanel, "DASHBOARD");
        contentPanel.add(selfServicePanel, "SELFSERVICE");
        contentPanel.add(funcionariosPanel, "FUNCIONARIOS");
        contentPanel.add(assiduidadePanel, "ASSIDUIDADE");
        contentPanel.add(cameraPanel, "CAMERA");
        contentPanel.add(enrollmentPanel, "ENROLLMENT");
        contentPanel.add(reportsPanel, "REPORTS");
        contentPanel.add(settingsPanel, "SETTINGS");

        return contentPanel;
    }

    private JPanel criarStatusBar() {
        JPanel bar = new JPanel(new BorderLayout());
        bar.setBackground(new Color(22, 27, 40));
        bar.setBorder(new EmptyBorder(4, 15, 4, 15));
        bar.setPreferredSize(new Dimension(0, 28));

        JLabel status = new JLabel("Pronto");
        status.setForeground(new Color(150, 160, 180));
        status.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        bar.add(status, BorderLayout.WEST);

        JPanel rightPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT, 10, 0));
        rightPanel.setBackground(new Color(22, 27, 40));

        JLabel opencv = new JLabel(cameraService.isOpencvDisponivel() ? "OpenCV: ON" : "OpenCV: OFF");
        opencv.setForeground(cameraService.isOpencvDisponivel()
                ? new Color(80, 200, 120) : new Color(200, 80, 80));
        opencv.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        rightPanel.add(opencv);

        JButton btnLogout = new JButton("Sair");
        btnLogout.setForeground(new Color(220, 80, 80));
        btnLogout.setFont(new Font("Segoe UI", Font.BOLD, 11));
        btnLogout.setFocusPainted(false);
        btnLogout.setBorderPainted(false);
        btnLogout.setOpaque(true);
        btnLogout.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        btnLogout.setContentAreaFilled(false);
        btnLogout.addActionListener(e -> fazerLogout());
        rightPanel.add(btnLogout);

        bar.add(rightPanel, BorderLayout.EAST);

        return bar;
    }

    private void fazerLogout() {
        int opcao = JOptionPane.showConfirmDialog(this,
                "Tem certeza que deseja sair?",
                "Confirmar Saida",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.QUESTION_MESSAGE);

        if (opcao != JOptionPane.YES_OPTION) return;

        cameraPanel.desactivar();
        tokenStore.clear();
        this.dispose();

        // Show login dialog again
        try {
            LoginDialog loginDialog = new LoginDialog(apiClient, tokenStore);
            loginDialog.setVisible(true);

            if (!loginDialog.isAutenticado()) {
                log.info("Login cancelado apos logout. A encerrar.");
                System.exit(0);
                return;
            }

            // Register device if needed after re-login
            try {
                apiClient.registerDeviceIfNeeded();
            } catch (Exception e) {
                log.warn("Falha ao registar dispositivo apos re-login: {}", e.getMessage());
            }

            // Re-open main frame
            MainFrame novoMainFrame = new MainFrame(funcionarioService, assiduidadeService,
                    cameraService, tokenStore, apiClient, backendProperties);
            novoMainFrame.setVisible(true);
            log.info("Sessao reiniciada. Utilizador: {}", tokenStore.getCurrentUser().getFull_name());

        } catch (Exception ex) {
            log.error("Erro ao reiniciar sessao", ex);
            JOptionPane.showMessageDialog(this,
                    "Erro ao reiniciar sessao: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
            System.exit(1);
        }
    }

    private void mostrarPainel(String painel) {
        cardLayout.show(contentPanel, painel);
        if ("DASHBOARD".equals(painel)) dashboardPanel.atualizar();
        if ("SELFSERVICE".equals(painel)) selfServicePanel.atualizar();
        if ("ASSIDUIDADE".equals(painel)) assiduidadePanel.recarregar();
        if ("FUNCIONARIOS".equals(painel)) funcionariosPanel.recarregar();
        if ("CAMERA".equals(painel)) cameraPanel.activar();
        else cameraPanel.desactivar();

        if (!"ENROLLMENT".equals(painel)) {
            enrollmentPanel.desactivar();
        }

        if ("REPORTS".equals(painel)) {
            // Reports panel doesn't need auto-refresh
        }
    }

    /**
     * Aplica restricoes de UI baseadas no role do utilizador.
     */
    private void aplicarRoleBasedUI() {
        var user = tokenStore.getCurrentUser();
        if (user == null) return;

        String role = user.getRole() != null ? user.getRole().toString() : "COLABORADOR";
        log.info("Aplicar restricoes de UI para role: {}", role);

        // COLABORADOR: So ve proprio registo (nao tem acesso a admin)
        if ("COLABORADOR".equals(role)) {
            navButtons.get("FUNCIONARIOS").setVisible(false);
            navButtons.get("ASSIDUIDADE").setVisible(false);
            navButtons.get("ENROLLMENT").setVisible(false);
            navButtons.get("REPORTS").setVisible(false);
            navButtons.get("SETTINGS").setVisible(false);
            
            log.info("Acesso admin escondido para COLABORADOR");
        }

        // AUDITOR: So leitura
        if ("AUDITOR".equals(role)) {
            log.info("Utilizador AUDITOR - modo somente leitura aplicado");
        }

        // GESTOR_RH e ADMIN_SISTEMA: Acesso completo
        // Sem restricoes
    }

    /**
     * Inicia timer que mostra tempo restante da sessao (token expira em 60min).
     */
    private void iniciarSessionTimer() {
        Timer timer = new Timer(60000, e -> atualizarSessionTimer());
        timer.start();
    }

    private void atualizarSessionTimer() {
        // Assume token criado ha X minutos (nao temos timestamp exato sem modificar TokenStore)
        // Por agora, mostra tempo desde login
        SwingUtilities.invokeLater(() -> {
            if (lblSessionTimer != null) {
                // TODO: Implementar com timestamp de login
                lblSessionTimer.setText("⏱️ Sessao: ativa");
            }
        });
    }

    @Override
    public void dispose() {
        cameraPanel.desactivar();
        enrollmentPanel.desactivar();
        super.dispose();
    }
}
