package tech.omnisyserp.desktop.ui;

import lombok.extern.slf4j.Slf4j;
import net.miginfocom.swing.MigLayout;
import tech.omnisyserp.desktop.auth.TokenStore;
import tech.omnisyserp.desktop.config.BackendProperties;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

@Slf4j
public class SettingsPanel extends JPanel {

    private final BackendProperties backendProperties;
    private final TokenStore tokenStore;

    private JTextField txtBackendUrl;
    private JTextField txtTimeout;
    private JTextField txtDefaultPageSize;
    private JCheckBox chkAutoRefresh;
    private JComboBox<String> cbTheme;
    private JButton btnGuardar;
    private JButton btnRestaurar;
    private JButton btnTestarConexao;

    public SettingsPanel(BackendProperties backendProperties, TokenStore tokenStore) {
        this.backendProperties = backendProperties;
        this.tokenStore = tokenStore;
        setLayout(new BorderLayout(0, 0));
        setBackground(new Color(245, 247, 252));
        construirUI();
        carregarConfiguracoes();
    }

    private void construirUI() {
        JPanel mainPanel = new JPanel(new MigLayout(
                "fillx, ins 20, gap 15",
                "[grow]",
                "[][grow][]"));
        mainPanel.setBackground(new Color(245, 247, 252));

        mainPanel.add(criarCabecalho(), "growx, wrap");
        mainPanel.add(criarPainelConfiguracoes(), "grow, wrap");
        mainPanel.add(criarPainelBotoes(), "growx, wrap");

        add(mainPanel, BorderLayout.CENTER);
    }

    private JPanel criarCabecalho() {
        JPanel panel = new JPanel(new MigLayout("fillx, ins 15", "[grow][]", "[]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(15, 20, 15, 20)));

        JLabel lblTitulo = new JLabel("⚙️ Configuracoes da Aplicacao");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 20));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, "cell 0 0");

        JLabel lblVersao = new JLabel("v1.1.0");
        lblVersao.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        lblVersao.setForeground(new Color(150, 160, 180));
        panel.add(lblVersao, "cell 1 0");

        return panel;
    }

    private JPanel criarPainelConfiguracoes() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 15, gap 10",
                "[grow]",
                "[][][][][]"));
        panel.setBackground(new Color(245, 247, 252));

        // Backend
        panel.add(criarCardBackend(), "growx, wrap");
        
        // Apariencia
        panel.add(criarCardApariencia(), "growx, wrap");
        
        return panel;
    }

    private JPanel criarCardBackend() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 15, gap 10",
                "[150px][grow]",
                "[][][][]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(15, 15, 15, 15)));

        JLabel lblTitulo = new JLabel("🌐 Backend API");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 14));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, "span 2, wrap, gapbottom 5");

        panel.add(new JLabel("URL do Backend:"), "cell 0 1");
        txtBackendUrl = new JTextField(30);
        txtBackendUrl.setFont(new Font("Consolas", Font.PLAIN, 12));
        panel.add(txtBackendUrl, "cell 1 1, growx");

        panel.add(new JLabel("Timeout (segundos):"), "cell 0 2");
        txtTimeout = new JTextField(5);
        txtTimeout.setFont(new Font("Consolas", Font.PLAIN, 12));
        panel.add(txtTimeout, "cell 1 2, width 100");

        panel.add(new JLabel("Tamanho de Pagina:"), "cell 0 3");
        txtDefaultPageSize = new JTextField(5);
        txtDefaultPageSize.setFont(new Font("Consolas", Font.PLAIN, 12));
        panel.add(txtDefaultPageSize, "cell 1 3, width 100");

        panel.add(new JLabel("Auto-refresh Token:"), "cell 0 4");
        chkAutoRefresh = new JCheckBox("Ativado");
        chkAutoRefresh.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        chkAutoRefresh.setSelected(true);
        panel.add(chkAutoRefresh, "cell 1 4");

        return panel;
    }

    private JPanel criarCardApariencia() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 15, gap 10",
                "[150px][grow]",
                "[][]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(15, 15, 15, 15)));

        JLabel lblTitulo = new JLabel("🎨 Apariencia");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 14));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, "span 2, wrap, gapbottom 5");

        panel.add(new JLabel("Tema:"), "cell 0 0");
        cbTheme = new JComboBox<>(new String[]{
                "FlatLaf Light (Default)",
                "FlatLaf Dark",
                "FlatLaf IntelliJ",
                "FlatLaf Darcula"
        });
        cbTheme.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        cbTheme.setSelectedIndex(0);
        panel.add(cbTheme, "cell 1 0, growx");

        return panel;
    }

    private JPanel criarPainelBotoes() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 15, gap 10",
                "[grow][][150px][150px]",
                "[]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(10, 15, 10, 15)));

        JLabel lblInfo = new JLabel("💡 Alteracoes necessitam reiniciar a aplicacao");
        lblInfo.setFont(new Font("Segoe UI", Font.ITALIC, 11));
        lblInfo.setForeground(new Color(150, 160, 180));
        panel.add(lblInfo, "cell 0 0");

        btnTestarConexao = criarBotao("🔌 Testar Conexao", new Color(52, 120, 246));
        btnTestarConexao.addActionListener(e -> testarConexao());
        panel.add(btnTestarConexao, "cell 2 0");

        btnGuardar = criarBotao("✓ Guardar", new Color(80, 200, 120));
        btnGuardar.addActionListener(e -> guardarConfiguracoes());
        panel.add(btnGuardar, "cell 3 0");

        btnRestaurar = criarBotao("↺ Restaurar Padrao", new Color(255, 140, 0));
        btnRestaurar.addActionListener(e -> restaurarConfiguracoes());
        panel.add(btnRestaurar, "cell 4 0");

        return panel;
    }

    private JButton criarBotao(String texto, Color cor) {
        JButton btn = new JButton(texto);
        btn.setBackground(cor);
        btn.setForeground(Color.WHITE);
        btn.setFont(new Font("Segoe UI", Font.BOLD, 12));
        btn.setFocusPainted(false);
        btn.setBorderPainted(false);
        btn.setOpaque(true);
        btn.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        btn.setPreferredSize(new Dimension(150, 35));
        return btn;
    }

    private void carregarConfiguracoes() {
        txtBackendUrl.setText(backendProperties.getApi().getUrl());
        txtTimeout.setText(String.valueOf(backendProperties.getApi().getTimeoutSeconds()));
        txtDefaultPageSize.setText("100"); // Default
        chkAutoRefresh.setSelected(true); // Default enabled
    }

    private void guardarConfiguracoes() {
        try {
            // Validate URL
            String url = txtBackendUrl.getText().trim();
            if (url.isEmpty()) {
                JOptionPane.showMessageDialog(this, 
                        "URL do backend e obrigatorio.",
                        "Validacao", JOptionPane.WARNING_MESSAGE);
                return;
            }

            // Validate timeout
            int timeout = Integer.parseInt(txtTimeout.getText().trim());
            if (timeout < 5 || timeout > 300) {
                JOptionPane.showMessageDialog(this, 
                        "Timeout deve estar entre 5 e 300 segundos.",
                        "Validacao", JOptionPane.WARNING_MESSAGE);
                return;
            }

            // Validate page size
            int pageSize = Integer.parseInt(txtDefaultPageSize.getText().trim());
            if (pageSize < 10 || pageSize > 1000) {
                JOptionPane.showMessageDialog(this, 
                        "Tamanho de pagina deve estar entre 10 e 1000.",
                        "Validacao", JOptionPane.WARNING_MESSAGE);
                return;
            }

            // Save to properties
            backendProperties.getApi().setUrl(url);
            backendProperties.getApi().setTimeoutSeconds(timeout);

            JOptionPane.showMessageDialog(this, 
                    "✓ Configuracoes guardadas com sucesso!\n\n" +
                    "Reinicie a aplicacao para aplicar as alteracoes.",
                    "Sucesso", JOptionPane.INFORMATION_MESSAGE);

            log.info("Configuracoes guardadas: URL={}, Timeout={}", url, timeout);

        } catch (NumberFormatException e) {
            JOptionPane.showMessageDialog(this, 
                    "Valores numericos invalidos.\nVerifique timeout e tamanho de pagina.",
                    "Erro", JOptionPane.ERROR_MESSAGE);
            log.error("Erro ao guardar configuracoes", e);
        }
    }

    private void restaurarConfiguracoes() {
        int opcao = JOptionPane.showConfirmDialog(this,
                "Restaurar configuracoes padrao?",
                "Confirmar",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.QUESTION_MESSAGE);

        if (opcao == JOptionPane.YES_OPTION) {
            txtBackendUrl.setText("http://localhost:8000");
            txtTimeout.setText("30");
            txtDefaultPageSize.setText("100");
            chkAutoRefresh.setSelected(true);
            cbTheme.setSelectedIndex(0);

            JOptionPane.showMessageDialog(this, 
                    "Configuracoes restauradas para valores padrao.",
                    "Sucesso", JOptionPane.INFORMATION_MESSAGE);
        }
    }

    private void testarConexao() {
        btnTestarConexao.setEnabled(false);
        btnTestarConexao.setText("A testar...");

        SwingWorker<Boolean, Void> worker = new SwingWorker<Boolean, Void>() {
            @Override
            protected Boolean doInBackground() throws Exception {
                try {
                    String url = txtBackendUrl.getText().trim();
                    // Try to reach the health endpoint
                    java.net.HttpURLConnection conn = (java.net.HttpURLConnection) 
                            new java.net.URL(url + "/health").openConnection();
                    conn.setRequestMethod("GET");
                    conn.setConnectTimeout(5000);
                    conn.setReadTimeout(5000);
                    int responseCode = conn.getResponseCode();
                    conn.disconnect();
                    return responseCode == 200;
                } catch (Exception e) {
                    log.error("Erro ao testar conexao", e);
                    return false;
                }
            }

            @Override
            protected void done() {
                btnTestarConexao.setEnabled(true);
                btnTestarConexao.setText("🔌 Testar Conexao");

                try {
                    boolean sucesso = get();
                    if (sucesso) {
                        JOptionPane.showMessageDialog(SettingsPanel.this, 
                                "✓ Conexao com backend estabelecida com sucesso!",
                                "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                    } else {
                        JOptionPane.showMessageDialog(SettingsPanel.this, 
                                "✗ Nao foi possivel conectar ao backend.\n\n" +
                                "Verifique o URL e se o backend esta em execucao.",
                                "Erro de Conexao", JOptionPane.ERROR_MESSAGE);
                    }
                } catch (Exception e) {
                    JOptionPane.showMessageDialog(SettingsPanel.this, 
                            "Erro ao testar conexao: " + e.getMessage(),
                            "Erro", JOptionPane.ERROR_MESSAGE);
                }
            }
        };
        worker.execute();
    }
}
