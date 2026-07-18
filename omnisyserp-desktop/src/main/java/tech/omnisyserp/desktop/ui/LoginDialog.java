package tech.omnisyserp.desktop.ui;

import lombok.extern.slf4j.Slf4j;
import tech.omnisyserp.desktop.auth.TokenStore;
import tech.omnisyserp.desktop.client.BackendApiClient;
import tech.omnisyserp.desktop.dto.LoginResponseDto;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;

/**
 * Dialog de autenticacao contra o backend controle.
 * Bloqueia a inicializacao da aplicacao ate o login ser bem-sucedido.
 */
@Slf4j
public class LoginDialog extends JDialog {

    private final BackendApiClient apiClient;
    private final TokenStore tokenStore;

    private JTextField txtUsername;
    private JPasswordField txtPassword;
    private JButton btnLogin;
    private JLabel lblErro;
    private boolean autenticado = false;

    public LoginDialog(BackendApiClient apiClient, TokenStore tokenStore) {
        super((Frame) null, "OmnisysERP – Autenticacao", true);
        this.apiClient = apiClient;
        this.tokenStore = tokenStore;
        construirUI();
    }

    private void construirUI() {
        setDefaultCloseOperation(DO_NOTHING_ON_CLOSE);
        setResizable(false);
        setSize(400, 340);
        setLocationRelativeTo(null);

        JPanel root = new JPanel(new BorderLayout());
        root.setBackground(new Color(22, 27, 40));
        setContentPane(root);

        // Cabecalho
        JPanel header = new JPanel(new GridLayout(2, 1, 0, 4));
        header.setBackground(new Color(22, 27, 40));
        header.setBorder(new EmptyBorder(30, 40, 20, 40));

        JLabel lblTitulo = new JLabel("OmnisysERP", SwingConstants.CENTER);
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 26));
        lblTitulo.setForeground(Color.WHITE);
        header.add(lblTitulo);

        JLabel lblSub = new JLabel("Controlo de Assiduidade", SwingConstants.CENTER);
        lblSub.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        lblSub.setForeground(new Color(150, 160, 180));
        header.add(lblSub);

        root.add(header, BorderLayout.NORTH);

        // Formulario
        JPanel form = new JPanel(new GridBagLayout());
        form.setBackground(new Color(30, 35, 50));
        form.setBorder(new EmptyBorder(20, 40, 10, 40));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.insets = new Insets(6, 0, 6, 0);
        gbc.weightx = 1.0;

        // Username
        gbc.gridy = 0;
        JLabel lblUser = new JLabel("Utilizador");
        lblUser.setForeground(new Color(180, 190, 210));
        lblUser.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        form.add(lblUser, gbc);

        gbc.gridy = 1;
        txtUsername = new JTextField();
        estilizarCampo(txtUsername);
        form.add(txtUsername, gbc);

        // Password
        gbc.gridy = 2;
        JLabel lblPass = new JLabel("Palavra-passe");
        lblPass.setForeground(new Color(180, 190, 210));
        lblPass.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        form.add(lblPass, gbc);

        gbc.gridy = 3;
        txtPassword = new JPasswordField();
        estilizarCampo(txtPassword);
        txtPassword.addKeyListener(new KeyAdapter() {
            @Override
            public void keyPressed(KeyEvent e) {
                if (e.getKeyCode() == KeyEvent.VK_ENTER) fazerLogin();
            }
        });
        form.add(txtPassword, gbc);

        // Mensagem de erro
        gbc.gridy = 4;
        lblErro = new JLabel(" ");
        lblErro.setForeground(new Color(220, 80, 80));
        lblErro.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        lblErro.setHorizontalAlignment(SwingConstants.CENTER);
        form.add(lblErro, gbc);

        // Botao
        gbc.gridy = 5;
        gbc.insets = new Insets(10, 0, 10, 0);
        btnLogin = new JButton("Entrar");
        btnLogin.setBackground(new Color(52, 120, 246));
        btnLogin.setForeground(Color.WHITE);
        btnLogin.setFont(new Font("Segoe UI", Font.BOLD, 14));
        btnLogin.setFocusPainted(false);
        btnLogin.setBorderPainted(false);
        btnLogin.setOpaque(true);
        btnLogin.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        btnLogin.setPreferredSize(new Dimension(0, 42));
        btnLogin.addActionListener(e -> fazerLogin());
        form.add(btnLogin, gbc);

        root.add(form, BorderLayout.CENTER);

        // Footer
        JLabel lblBackend = new JLabel("Backend: controle API", SwingConstants.CENTER);
        lblBackend.setForeground(new Color(80, 90, 110));
        lblBackend.setFont(new Font("Segoe UI", Font.PLAIN, 10));
        lblBackend.setBorder(new EmptyBorder(0, 0, 10, 0));
        lblBackend.setBackground(new Color(22, 27, 40));
        lblBackend.setOpaque(true);
        root.add(lblBackend, BorderLayout.SOUTH);
    }

    private void estilizarCampo(JTextField campo) {
        campo.setBackground(new Color(45, 52, 70));
        campo.setForeground(Color.WHITE);
        campo.setCaretColor(Color.WHITE);
        campo.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        campo.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(70, 80, 100)),
                new EmptyBorder(8, 10, 8, 10)));
        campo.setPreferredSize(new Dimension(0, 38));
    }

    private void fazerLogin() {
        String username = txtUsername.getText().trim();
        String password = new String(txtPassword.getPassword());

        if (username.isBlank() || password.isBlank()) {
            lblErro.setText("Preencha o utilizador e a palavra-passe.");
            return;
        }

        btnLogin.setEnabled(false);
        btnLogin.setText("A autenticar...");
        lblErro.setText(" ");

        SwingWorker<LoginResponseDto, Void> worker = new SwingWorker<>() {
            @Override
            protected LoginResponseDto doInBackground() {
                return apiClient.login(username, password);
            }

            @Override
            protected void done() {
                btnLogin.setEnabled(true);
                btnLogin.setText("Entrar");
                try {
                    LoginResponseDto resp = get();
                    if (resp != null && resp.getAccess_token() != null) {
                        tokenStore.store(resp.getAccess_token(), resp.getRefresh_token(), resp.getUser());
                        autenticado = true;
                        log.info("Login bem-sucedido: {} ({})",
                                resp.getUser().getFull_name(), resp.getUser().getRole());
                        dispose();
                    } else {
                        lblErro.setText("Resposta invalida do servidor.");
                    }
                } catch (Exception ex) {
                    String msg = extrairMensagemErro(ex);
                    lblErro.setText(msg);
                    log.warn("Falha no login: {}", ex.getMessage());
                }
            }
        };
        worker.execute();
    }

    private String extrairMensagemErro(Exception ex) {
        String msg = ex.getMessage();
        if (msg == null) return "Erro desconhecido.";
        if (msg.contains("401") || msg.contains("Unauthorized")) return "Credenciais invalidas.";
        if (msg.contains("Connection refused") || msg.contains("connect")) return "Backend indisponivel. Verifique a conexao.";
        if (msg.contains("timeout")) return "Tempo limite excedido.";
        return "Erro: " + msg;
    }

    public boolean isAutenticado() {
        return autenticado;
    }
}
