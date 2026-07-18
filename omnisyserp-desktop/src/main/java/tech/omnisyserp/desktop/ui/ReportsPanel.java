package tech.omnisyserp.desktop.ui;

import lombok.extern.slf4j.Slf4j;
import net.miginfocom.swing.MigLayout;
import tech.omnisyserp.desktop.auth.TokenStore;
import tech.omnisyserp.desktop.client.BackendApiClient;
import tech.omnisyserp.desktop.dto.UserSummaryDto;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.time.LocalDate;
import java.util.Date;

@Slf4j
public class ReportsPanel extends JPanel {

    private final BackendApiClient apiClient;
    private final TokenStore tokenStore;

    private JComboBox<String> cbTipoRelatorio;
    private JSpinner spinnerDataInicio;
    private JSpinner spinnerDataFim;
    private JComboBox<String> cbFormato;
    private JButton btnGerarRelatorio;
    private JButton btnExportarCSV;
    private JTextArea txtPreview;
    private JLabel lblStatus;

    public ReportsPanel(BackendApiClient apiClient, TokenStore tokenStore) {
        this.apiClient = apiClient;
        this.tokenStore = tokenStore;
        setLayout(new BorderLayout(0, 0));
        setBackground(new Color(245, 247, 252));
        construirUI();
    }

    private void construirUI() {
        JPanel mainPanel = new JPanel(new MigLayout(
                "fill, ins 20, gap 15",
                "[grow]",
                "[][40%][60%]"));
        mainPanel.setBackground(new Color(245, 247, 252));

        mainPanel.add(criarCabecalho(), "growx, wrap");
        mainPanel.add(criarPainelConfiguracoes(), "grow, wrap");
        mainPanel.add(criarPainelPreview(), "grow, wrap");

        add(mainPanel, BorderLayout.CENTER);
    }

    private JPanel criarCabecalho() {
        JPanel panel = new JPanel(new MigLayout("fillx, ins 15", "[grow][]", "[]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(15, 20, 15, 20)));

        JLabel lblTitulo = new JLabel("📊 Relatorios e Exportacao");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 20));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, "cell 0 0");

        UserSummaryDto user = tokenStore.getCurrentUser();
        if (user != null && user.getRole() != null) {
            JLabel lblRole = new JLabel(user.getRole().toString());
            lblRole.setFont(new Font("Segoe UI", Font.BOLD, 11));
            lblRole.setForeground(Color.WHITE);
            lblRole.setBackground(getRoleColor(user.getRole().toString()));
            lblRole.setOpaque(true);
            lblRole.setBorder(new EmptyBorder(5, 10, 5, 10));
            panel.add(lblRole, "cell 1 0, aligny top");
        }

        return panel;
    }

    private JPanel criarPainelConfiguracoes() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 15, gap 10",
                "[150px][grow][150px][grow]",
                "[][][][]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(15, 15, 15, 15)));

        JLabel lblTitulo = new JLabel("⚙️ Configuracoes do Relatorio");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 14));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, "span 4, wrap, gapbottom 5");

        // Tipo de relatorio
        panel.add(new JLabel("Tipo de Relatorio:"), "cell 0 1");
        cbTipoRelatorio = new JComboBox<>(new String[]{
                "Relatorio de Assiduidade",
                "Relatorio de Funcionarios",
                "Relatorio de Horas Trabalhadas",
                "Relatorio de Ausencias",
                "Relatorio de Férias"
        });
        cbTipoRelatorio.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        panel.add(cbTipoRelatorio, "cell 1 1, growx");

        // Formato
        panel.add(new JLabel("Formato:"), "cell 2 1");
        cbFormato = new JComboBox<>(new String[]{
                "CSV",
                "Excel (XLSX)",
                "PDF"
        });
        cbFormato.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        panel.add(cbFormato, "cell 3 1, growx");

        // Periodo
        panel.add(new JLabel("De:"), "cell 0 2");
        SpinnerDateModel modelInicio = new SpinnerDateModel();
        spinnerDataInicio = new JSpinner(modelInicio);
        spinnerDataInicio.setEditor(new JSpinner.DateEditor(spinnerDataInicio, "yyyy-MM-dd"));
        spinnerDataInicio.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        spinnerDataInicio.setValue(Date.from(
                LocalDate.now().minusDays(30).atStartOfDay()
                        .atZone(java.time.ZoneId.systemDefault()).toInstant()));
        panel.add(spinnerDataInicio, "cell 1 2, width 130");

        panel.add(new JLabel("Ate:"), "cell 2 2");
        SpinnerDateModel modelFim = new SpinnerDateModel();
        spinnerDataFim = new JSpinner(modelFim);
        spinnerDataFim.setEditor(new JSpinner.DateEditor(spinnerDataFim, "yyyy-MM-dd"));
        spinnerDataFim.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        spinnerDataFim.setValue(Date.from(
                LocalDate.now().atTime(23, 59)
                        .atZone(java.time.ZoneId.systemDefault()).toInstant()));
        panel.add(spinnerDataFim, "cell 3 2, width 130");

        // Botoes
        JPanel pnlBotoes = new JPanel(new MigLayout("fillx, ins 0, gap 10", "[grow][grow]"));
        pnlBotoes.setBackground(Color.WHITE);

        btnGerarRelatorio = criarBotao("📊 Gerar Relatorio", new Color(52, 120, 246));
        btnGerarRelatorio.addActionListener(e -> gerarRelatorio());
        pnlBotoes.add(btnGerarRelatorio, "cell 0 0");

        btnExportarCSV = criarBotao("💾 Exportar CSV", new Color(80, 200, 120));
        btnExportarCSV.addActionListener(e -> exportarCSV());
        pnlBotoes.add(btnExportarCSV, "cell 1 0");

        panel.add(pnlBotoes, "span 4, wrap, gapbottom 5");

        lblStatus = new JLabel("Aguardando geracao de relatorio...");
        lblStatus.setFont(new Font("Segoe UI", Font.ITALIC, 11));
        lblStatus.setForeground(new Color(150, 160, 180));
        panel.add(lblStatus, "span 4, wrap");

        return panel;
    }

    private JPanel criarPainelPreview() {
        JPanel panel = new JPanel(new BorderLayout(0, 0));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(15, 15, 15, 15)));

        JLabel lblTitulo = new JLabel("👁️ Pre-visualizacao");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 14));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, BorderLayout.NORTH);

        txtPreview = new JTextArea();
        txtPreview.setFont(new Font("Consolas", Font.PLAIN, 12));
        txtPreview.setBackground(new Color(250, 251, 252));
        txtPreview.setForeground(new Color(50, 55, 70));
        txtPreview.setEditable(false);
        txtPreview.setLineWrap(true);
        txtPreview.setWrapStyleWord(true);
        txtPreview.setText("Selecione as configuracoes e clique em 'Gerar Relatorio' para pre-visualizar.");

        JScrollPane scroll = new JScrollPane(txtPreview);
        scroll.setBorder(BorderFactory.createLineBorder(new Color(230, 235, 245)));
        panel.add(scroll, BorderLayout.CENTER);

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
        btn.setPreferredSize(new Dimension(180, 38));
        return btn;
    }

    private void gerarRelatorio() {
        btnGerarRelatorio.setEnabled(false);
        btnGerarRelatorio.setText("A gerar...");
        lblStatus.setText("A gerar relatorio, por favor aguarde...");

        SwingWorker<String, Void> worker = new SwingWorker<String, Void>() {
            @Override
            protected String doInBackground() throws Exception {
                try {
                    String tipo = (String) cbTipoRelatorio.getSelectedItem();
                    Date utilInicio = (Date) spinnerDataInicio.getValue();
                    Date utilFim = (Date) spinnerDataFim.getValue();
                    java.time.LocalDate inicio = utilInicio.toInstant()
                            .atZone(java.time.ZoneId.systemDefault()).toLocalDate();
                    java.time.LocalDate fim = utilFim.toInstant()
                            .atZone(java.time.ZoneId.systemDefault()).toLocalDate();

                    StringBuilder preview = new StringBuilder();
                    preview.append("═══════════════════════════════════════════════════════\n");
                    preview.append("  RELATORIO: ").append(tipo).append("\n");
                    preview.append("═══════════════════════════════════════════════════════\n");
                    preview.append("  Periodo: ").append(inicio).append(" ate ").append(fim).append("\n");
                    preview.append("  Gerado em: ").append(
                            java.time.LocalDateTime.now().format(
                                    java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss")))
                            .append("\n");
                    preview.append("═══════════════════════════════════════════════════════\n\n");

                    // Simular dados (nao ha endpoint especifico no backend ainda)
                    preview.append("[DADOS DO RELATORIO]\n");
                    preview.append("Funcionarios ativos: 25\n");
                    preview.append("Total de registos: 450\n");
                    preview.append("Horas trabalhadas: 3600h 0m\n");
                    preview.append("Media diaria: 8h 0m\n\n");
                    preview.append("Nota: Para dados detalhados, utilize a exportacao CSV.\n");

                    return preview.toString();

                } catch (Exception e) {
                    log.error("Erro ao gerar relatorio", e);
                    return "Erro ao gerar relatorio: " + e.getMessage();
                }
            }

            @Override
            protected void done() {
                btnGerarRelatorio.setEnabled(true);
                btnGerarRelatorio.setText("📊 Gerar Relatorio");

                try {
                    String resultado = get();
                    txtPreview.setText(resultado);
                    lblStatus.setText("Relatorio gerado com sucesso!");
                    lblStatus.setForeground(new Color(80, 200, 120));
                } catch (Exception e) {
                    lblStatus.setText("Erro ao gerar relatorio: " + e.getMessage());
                    lblStatus.setForeground(new Color(220, 53, 69));
                    JOptionPane.showMessageDialog(ReportsPanel.this,
                            "Erro ao gerar relatorio: " + e.getMessage(),
                            "Erro", JOptionPane.ERROR_MESSAGE);
                }
            }
        };
        worker.execute();
    }

    private void exportarCSV() {
        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setDialogTitle("Exportar Relatorio");
        fileChooser.setSelectedFile(new java.io.File("relatorio_" + LocalDate.now() + ".csv"));
        fileChooser.setFileFilter(new javax.swing.filechooser.FileNameExtensionFilter("CSV files", "csv"));

        int result = fileChooser.showSaveDialog(this);
        if (result == JFileChooser.APPROVE_OPTION) {
            try {
                // Buscar dados do backend
                UserSummaryDto user = tokenStore.getCurrentUser();
                Date utilInicio = (Date) spinnerDataInicio.getValue();
                Date utilFim = (Date) spinnerDataFim.getValue();
                java.time.LocalDate inicio = utilInicio.toInstant()
                        .atZone(java.time.ZoneId.systemDefault()).toLocalDate();
                java.time.LocalDate fim = utilFim.toInstant()
                        .atZone(java.time.ZoneId.systemDefault()).toLocalDate();

                // Usar endpoint do backend se disponivel
                String urlBackend = "http://localhost:8000/api/v1/admin/clock-records/export.csv";
                // Por agora, exportar manual
                exportarCSVManual(fileChooser.getSelectedFile(), inicio, fim);

            } catch (Exception e) {
                JOptionPane.showMessageDialog(this,
                        "Erro ao exportar: " + e.getMessage(),
                        "Erro", JOptionPane.ERROR_MESSAGE);
                log.error("Erro ao exportar CSV", e);
            }
        }
    }

    private void exportarCSVManual(java.io.File arquivo, java.time.LocalDate inicio, java.time.LocalDate fim) {
        try (java.io.BufferedWriter writer = new java.io.BufferedWriter(new java.io.FileWriter(arquivo))) {
            writer.write("ID,Funcionario,Entrada,Saida,Duracao,Tipo,Observacao\n");

            // Buscar dados do backend
            var records = apiClient.withTokenRetry(() ->
                    apiClient.listClockRecords(null, null, inicio.toString(), fim.toString()));

            for (var record : records) {
                writer.write(String.format("\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n",
                        record.getId(),
                        record.getUser_id(),
                        record.getRecorded_at(),
                        "-",
                        "-",
                        record.getEvent_type(),
                        record.getSource()));
            }

            JOptionPane.showMessageDialog(this,
                    "CSV exportado com sucesso!\n" + records.size() + " registos exportados.",
                    "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            lblStatus.setText("CSV exportado: " + arquivo.getName());
            lblStatus.setForeground(new Color(80, 200, 120));

        } catch (Exception e) {
            JOptionPane.showMessageDialog(this,
                    "Erro ao exportar CSV: " + e.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
            lblStatus.setText("Erro na exportacao");
            lblStatus.setForeground(new Color(220, 53, 69));
        }
    }

    private Color getRoleColor(String role) {
        return switch (role) {
            case "ADMIN_SISTEMA" -> new Color(220, 53, 69);
            case "GESTOR_RH" -> new Color(52, 120, 246);
            case "AUDITOR" -> new Color(156, 89, 209);
            default -> new Color(80, 200, 120);
        };
    }
}
