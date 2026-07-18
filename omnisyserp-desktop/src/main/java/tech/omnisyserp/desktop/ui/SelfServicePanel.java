package tech.omnisyserp.desktop.ui;

import lombok.extern.slf4j.Slf4j;
import net.miginfocom.swing.MigLayout;
import tech.omnisyserp.desktop.auth.TokenStore;
import tech.omnisyserp.desktop.client.BackendApiClient;
import tech.omnisyserp.desktop.dto.ClockRecordDto;
import tech.omnisyserp.desktop.dto.UserSummaryDto;
import tech.omnisyserp.desktop.model.Assiduidade;
import tech.omnisyserp.desktop.model.TipoRegisto;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.List;

@Slf4j
public class SelfServicePanel extends JPanel {

    private final BackendApiClient apiClient;
    private final TokenStore tokenStore;

    private JTable tabela;
    private DefaultTableModel tableModel;
    private JSpinner spinnerDataInicio;
    private JSpinner spinnerDataFim;
    private JButton btnFiltrar;
    private JButton btnHoje;

    private JLabel lblTotalHoras;
    private JLabel lblDiasTrabalhados;
    private JLabel lblMediaDiaria;
    private JLabel lblUltimoRegisto;

    private List<ClockRecordDto> listaAtual;

    public SelfServicePanel(BackendApiClient apiClient, TokenStore tokenStore) {
        this.apiClient = apiClient;
        this.tokenStore = tokenStore;
        setLayout(new BorderLayout(0, 0));
        setBackground(new Color(245, 247, 252));
        construirUI();
        carregarDados();
    }

    private void construirUI() {
        JPanel mainPanel = new JPanel(new MigLayout(
                "fillx, ins 15, gap 10",
                "[grow]",
                "[][25%][40%][35%]"));
        mainPanel.setBackground(new Color(245, 247, 252));

        mainPanel.add(criarCabecalho(), "growx, wrap");
        mainPanel.add(criarPainelMetricas(), "growx, wrap");
        mainPanel.add(criarPainelFiltros(), "growx, wrap");
        mainPanel.add(criarTabela(), "grow, wrap");

        add(mainPanel, BorderLayout.CENTER);
    }

    private JPanel criarCabecalho() {
        JPanel panel = new JPanel(new MigLayout("fillx, ins 15", "[grow][]", "[][]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(15, 20, 15, 20)));

        UserSummaryDto user = tokenStore.getCurrentUser();
        JLabel lblTitulo = new JLabel("🙋 O Meu Historico de Assiduidade");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 20));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, "cell 0 0");

        JLabel lblSubtitulo = new JLabel("Funcionario: " + (user != null ? user.getFull_name() : "N/A"));
        lblSubtitulo.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        lblSubtitulo.setForeground(new Color(100, 110, 130));
        panel.add(lblSubtitulo, "cell 0 1");

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

    private JPanel criarPainelMetricas() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 10, gap 10",
                "[25%][25%][25%][25%]",
                "[][]"));
        panel.setBackground(new Color(245, 247, 252));

        lblTotalHoras = new JLabel("0h 0m");
        panel.add(criarCardMetrica("Total Horas (Periodo)", lblTotalHoras, new Color(52, 120, 246)), "grow, cell 0 0");

        lblDiasTrabalhados = new JLabel("0");
        panel.add(criarCardMetrica("Dias Trabalhados", lblDiasTrabalhados, new Color(80, 200, 120)), "grow, cell 1 0");

        lblMediaDiaria = new JLabel("0h 0m");
        panel.add(criarCardMetrica("Media Diaria", lblMediaDiaria, new Color(255, 140, 0)), "grow, cell 2 0");

        lblUltimoRegisto = new JLabel("--");
        panel.add(criarCardMetrica("Ultimo Registo", lblUltimoRegisto, new Color(156, 89, 209)), "grow, cell 3 0");

        return panel;
    }

    private JPanel criarCardMetrica(String titulo, JLabel lblValor, Color cor) {
        JPanel card = new JPanel(new MigLayout("fillx, ins 10, gap 3", "[grow]", "[][]"));
        card.setBackground(Color.WHITE);
        card.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(cor, 2),
                new EmptyBorder(2, 2, 2, 2)));

        JLabel lblTitulo = new JLabel(titulo);
        lblTitulo.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        lblTitulo.setForeground(new Color(100, 110, 130));
        card.add(lblTitulo, "cell 0 0");

        lblValor.setFont(new Font("Segoe UI", Font.BOLD, 20));
        lblValor.setForeground(cor);
        card.add(lblValor, "cell 0 1");

        return card;
    }

    private JPanel criarPainelFiltros() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 15, gap 10",
                "[][][130px][][grow][]",
                "[]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(10, 15, 10, 15)));

        panel.add(new JLabel("De:"), "gapright 5");
        SpinnerDateModel modelInicio = new SpinnerDateModel();
        spinnerDataInicio = new JSpinner(modelInicio);
        spinnerDataInicio.setEditor(new JSpinner.DateEditor(spinnerDataInicio, "yyyy-MM-dd"));
        spinnerDataInicio.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        spinnerDataInicio.setValue(Date.from(
                LocalDate.now().minusDays(30).atStartOfDay()
                        .atZone(ZoneId.systemDefault()).toInstant()));
        panel.add(spinnerDataInicio, "width 130, gapright 10");

        panel.add(new JLabel("Ate:"), "gapright 5");
        SpinnerDateModel modelFim = new SpinnerDateModel();
        spinnerDataFim = new JSpinner(modelFim);
        spinnerDataFim.setEditor(new JSpinner.DateEditor(spinnerDataFim, "yyyy-MM-dd"));
        spinnerDataFim.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        spinnerDataFim.setValue(Date.from(
                LocalDate.now().atTime(23, 59)
                        .atZone(ZoneId.systemDefault()).toInstant()));
        panel.add(spinnerDataFim, "width 130, gapright 10");

        btnFiltrar = criarBotao("🔍 Filtrar", new Color(52, 120, 246));
        btnFiltrar.addActionListener(e -> carregarDados());
        panel.add(btnFiltrar, "gapright 5");

        btnHoje = criarBotao("📅 Hoje", new Color(100, 160, 240));
        btnHoje.addActionListener(e -> filtrarHoje());
        panel.add(btnHoje);

        return panel;
    }

    private JScrollPane criarTabela() {
        String[] colunas = {"Entrada", "Saida", "Duracao", "Tipo", "Status"};
        tableModel = new DefaultTableModel(colunas, 0) {
            @Override public boolean isCellEditable(int row, int column) { return false; }
        };

        tabela = new JTable(tableModel);
        tabela.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        tabela.setRowHeight(32);
        tabela.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        tabela.getTableHeader().setFont(new Font("Segoe UI", Font.BOLD, 13));
        tabela.getTableHeader().setBackground(new Color(30, 35, 50));
        tabela.getTableHeader().setForeground(Color.WHITE);
        tabela.setGridColor(new Color(220, 225, 235));
        tabela.setShowGrid(true);

        // Renderizador para Status
        tabela.getColumnModel().getColumn(4).setCellRenderer(new DefaultTableCellRenderer() {
            @Override
            public Component getTableCellRendererComponent(JTable table, Object value,
                    boolean isSelected, boolean hasFocus, int row, int column) {
                JLabel label = new JLabel(value.toString(), CENTER);
                label.setOpaque(true);
                if (isSelected) {
                    label.setBackground(table.getSelectionBackground());
                    label.setForeground(table.getSelectionForeground());
                } else {
                    if ("Aberto".equals(value)) {
                        label.setBackground(new Color(255, 200, 100));
                        label.setForeground(Color.BLACK);
                    } else {
                        label.setBackground(new Color(200, 255, 200));
                        label.setForeground(Color.BLACK);
                    }
                }
                return label;
            }
        });

        JScrollPane scroll = new JScrollPane(tabela);
        scroll.setBorder(BorderFactory.createLineBorder(new Color(220, 225, 235)));
        
        return scroll;
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
        btn.setPreferredSize(new Dimension(110, 32));
        return btn;
    }

    private void filtrarHoje() {
        LocalDate hoje = LocalDate.now();
        Date dataHoje = Date.from(hoje.atStartOfDay().atZone(ZoneId.systemDefault()).toInstant());
        spinnerDataInicio.setValue(dataHoje);
        spinnerDataFim.setValue(dataHoje);
        carregarDados();
    }

    private void carregarDados() {
        SwingWorker<Void, Void> worker = new SwingWorker<Void, Void>() {
            @Override
            protected Void doInBackground() throws Exception {
                try {
                    UserSummaryDto user = tokenStore.getCurrentUser();
                    if (user == null || user.getId() == null) {
                        return null;
                    }

                    Date utilInicio = (Date) spinnerDataInicio.getValue();
                    Date utilFim = (Date) spinnerDataFim.getValue();
                    LocalDate inicio = utilInicio.toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
                    LocalDate fim = utilFim.toInstant().atZone(ZoneId.systemDefault()).toLocalDate();

                    // Buscar registos do utilizador atual
                    listaAtual = apiClient.withTokenRetry(() ->
                            apiClient.listClockRecords(user.getId(), null, inicio.toString(), fim.toString()));

                    SwingUtilities.invokeLater(() -> {
                        atualizarTabela(listaAtual);
                        atualizarMetricas(listaAtual);
                    });

                } catch (Exception e) {
                    log.error("Erro ao carregar dados do self-service", e);
                    SwingUtilities.invokeLater(() -> {
                        JOptionPane.showMessageDialog(SelfServicePanel.this,
                                "Erro ao carregar dados: " + e.getMessage(),
                                "Erro", JOptionPane.ERROR_MESSAGE);
                    });
                }
                return null;
            }
        };
        worker.execute();
    }

    private void atualizarTabela(List<ClockRecordDto> records) {
        tableModel.setRowCount(0);
        
        // Agrupar por sessoes (ENTRY + EXIT)
        List<Map<String, Object>> sessoes = agruparEmSessoes(records);
        
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
        
        for (Map<String, Object> sessao : sessoes) {
            LocalDateTime entrada = (LocalDateTime) sessao.get("entrada");
            LocalDateTime saida = (LocalDateTime) sessao.get("saida");
            String tipo = (String) sessao.get("tipo");
            String duracao = (String) sessao.get("duracao");
            String status = saida != null ? "Fechado" : "Aberto";
            
            tableModel.addRow(new Object[]{
                    entrada != null ? entrada.format(fmt) : "-",
                    saida != null ? saida.format(fmt) : "-",
                    duracao,
                    tipo,
                    status
            });
        }
    }

    private void atualizarMetricas(List<ClockRecordDto> records) {
        // Agrupar em sessoes
        List<Map<String, Object>> sessoes = agruparEmSessoes(records);
        
        long totalMinutos = sessoes.stream()
                .filter(s -> s.get("saida") != null)
                .mapToLong(s -> ChronoUnit.MINUTES.between(
                        (LocalDateTime) s.get("entrada"),
                        (LocalDateTime) s.get("saida")))
                .sum();
        
        long horas = totalMinutos / 60;
        long minutos = totalMinutos % 60;
        
        long diasUnicos = sessoes.stream()
                .map(s -> ((LocalDateTime) s.get("entrada")).toLocalDate())
                .distinct()
                .count();
        
        long mediaMinutos = diasUnicos > 0 ? totalMinutos / diasUnicos : 0;
        long mediaHoras = mediaMinutos / 60;
        long mediaMinutosResto = mediaMinutos % 60;
        
        lblTotalHoras.setText(horas + "h " + minutos + "m");
        lblDiasTrabalhados.setText(String.valueOf(diasUnicos));
        lblMediaDiaria.setText(mediaHoras + "h " + mediaMinutosResto + "m");
        
        // Ultimo registo
        if (!sessoes.isEmpty()) {
            Map<String, Object> ultima = sessoes.get(sessoes.size() - 1);
            LocalDateTime entrada = (LocalDateTime) ultima.get("entrada");
            lblUltimoRegisto.setText(entrada.format(DateTimeFormatter.ofPattern("dd/MM HH:mm")));
        } else {
            lblUltimoRegisto.setText("--");
        }
    }

    private List<Map<String, Object>> agruparEmSessoes(List<ClockRecordDto> records) {
        List<Map<String, Object>> sessoes = new ArrayList<>();
        Map<String, Object> sessaoAtual = null;
        
        for (ClockRecordDto record : records) {
            LocalDateTime dataHora = Assiduidade.parseDateTime(record.getRecorded_at());
            if (dataHora == null) continue;
            
            if ("ENTRY".equals(record.getEvent_type())) {
                sessaoAtual = new HashMap<>();
                sessaoAtual.put("entrada", dataHora);
                sessaoAtual.put("saida", null);
                sessaoAtual.put("tipo", "Presencial");
                sessoes.add(sessaoAtual);
            } else if ("EXIT".equals(record.getEvent_type()) && sessaoAtual != null && sessaoAtual.get("saida") == null) {
                sessaoAtual.put("saida", dataHora);
                
                // Calcular duracao
                LocalDateTime entrada = (LocalDateTime) sessaoAtual.get("entrada");
                long minutos = ChronoUnit.MINUTES.between(entrada, dataHora);
                long horas = minutos / 60;
                long mins = minutos % 60;
                sessaoAtual.put("duracao", horas + "h " + mins + "m");
            }
        }
        
        // Marcar sessoes abertas
        for (Map<String, Object> sessao : sessoes) {
            if (sessao.get("saida") == null) {
                sessao.put("duracao", "Em curso");
            }
            if (sessao.get("tipo") == null) {
                sessao.put("tipo", "Presencial");
            }
        }
        
        return sessoes;
    }

    private Color getRoleColor(String role) {
        return switch (role) {
            case "ADMIN_SISTEMA" -> new Color(220, 53, 69);
            case "GESTOR_RH" -> new Color(52, 120, 246);
            case "AUDITOR" -> new Color(156, 89, 209);
            default -> new Color(80, 200, 120);
        };
    }

    public void atualizar() {
        carregarDados();
    }
}
