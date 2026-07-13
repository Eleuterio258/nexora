package tech.omnisyserp.desktop.ui;

import lombok.extern.slf4j.Slf4j;
import net.miginfocom.swing.MigLayout;
import tech.omnisyserp.desktop.auth.TokenStore;
import tech.omnisyserp.desktop.dto.UserSummaryDto;
import tech.omnisyserp.desktop.service.AssiduidadeService;
import tech.omnisyserp.desktop.service.FuncionarioService;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Slf4j
public class DashboardPanel extends JPanel {

    private final FuncionarioService funcionarioService;
    private final AssiduidadeService assiduidadeService;
    private final TokenStore tokenStore;

    private JLabel lblBomDia;
    private JLabel lblDataAtual;
    private JList<String> lstActividadeRecente;
    private DefaultListModel<String> listModel;

    public DashboardPanel(FuncionarioService funcionarioService, 
                         AssiduidadeService assiduidadeService,
                         TokenStore tokenStore) {
        this.funcionarioService = funcionarioService;
        this.assiduidadeService = assiduidadeService;
        this.tokenStore = tokenStore;
        setLayout(new BorderLayout(0, 0));
        setBackground(new Color(245, 247, 252));
        construirUI();
        carregarDados();
    }

    private void construirUI() {
        JPanel mainPanel = new JPanel(new MigLayout(
                "fill, ins 20, gap 15",
                "[grow]",
                "[][25%][45%][30%]"));
        mainPanel.setBackground(new Color(245, 247, 252));

        mainPanel.add(criarCabecalho(), "growx, wrap");
        mainPanel.add(criarPainelMetricas(), "growx, wrap");
        mainPanel.add(criarPainelActividade(), "grow, wrap");
        mainPanel.add(criarPainelAcoesRapidas(), "grow, wrap");

        add(mainPanel, BorderLayout.CENTER);
    }

    private JPanel criarCabecalho() {
        JPanel panel = new JPanel(new MigLayout("fillx, ins 15, gap 10", "[grow][]", "[][]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(15, 20, 15, 20)));

        // Saudacao personalizada
        UserSummaryDto user = tokenStore.getCurrentUser();
        String hora = java.time.LocalTime.now().getHour() < 12 ? "Bom dia" : "Boa tarde";
        String nome = user != null ? user.getFull_name() : "Utilizador";
        
        lblBomDia = new JLabel(hora + ", " + nome + "!");
        lblBomDia.setFont(new Font("Segoe UI", Font.BOLD, 24));
        lblBomDia.setForeground(new Color(30, 35, 50));
        panel.add(lblBomDia, "cell 0 0");

        lblDataAtual = new JLabel(LocalDate.now().format(
                DateTimeFormatter.ofPattern("EEEE, dd 'de' MMMM 'de' yyyy")));
        lblDataAtual.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        lblDataAtual.setForeground(new Color(100, 110, 130));
        panel.add(lblDataAtual, "cell 0 1");

        // Role badge
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

    private JLabel lblValorFuncionarios;
    private JLabel lblValorAtivos;
    private JLabel lblValorHoje;
    private JLabel lblValorAbertos;

    private JPanel criarPainelMetricas() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 10, gap 10",
                "[25%][25%][25%][25%]",
                "[][]"));
        panel.setBackground(new Color(245, 247, 252));

        // Total Funcionarios
        lblValorFuncionarios = new JLabel("0");
        panel.add(criarCardMetrica("Total Funcionarios", lblValorFuncionarios, new Color(52, 120, 246)), "grow, cell 0 0");

        // Funcionarios Ativos
        lblValorAtivos = new JLabel("0");
        panel.add(criarCardMetrica("Funcionarios Ativos", lblValorAtivos, new Color(80, 200, 120)), "grow, cell 1 0");

        // Registos Hoje
        lblValorHoje = new JLabel("0");
        panel.add(criarCardMetrica("Registos Hoje", lblValorHoje, new Color(255, 140, 0)), "grow, cell 2 0");

        // Registos Abertos
        lblValorAbertos = new JLabel("0");
        panel.add(criarCardMetrica("Registos Abertos", lblValorAbertos, new Color(220, 53, 69)), "grow, cell 3 0");

        return panel;
    }

    private JPanel criarCardMetrica(String titulo, JLabel lblValor, Color cor) {
        JPanel card = new JPanel(new MigLayout("fillx, ins 12, gap 5", "[grow]", "[][]"));
        card.setBackground(Color.WHITE);
        card.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(cor, 2),
                new EmptyBorder(2, 2, 2, 2)));

        JLabel lblTitulo = new JLabel(titulo);
        lblTitulo.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        lblTitulo.setForeground(new Color(100, 110, 130));
        card.add(lblTitulo, "cell 0 0");

        lblValor.setFont(new Font("Segoe UI", Font.BOLD, 22));
        lblValor.setForeground(cor);
        card.add(lblValor, "cell 0 1");

        return card;
    }

    private JPanel criarPainelActividade() {
        JPanel panel = new JPanel(new BorderLayout(0, 0));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(15, 15, 15, 15)));

        JLabel lblTitulo = new JLabel("Actividade Recente");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 16));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, BorderLayout.NORTH);

        listModel = new DefaultListModel<>();
        listModel.addElement("Carregando dados...");
        lstActividadeRecente = new JList<>(listModel);
        lstActividadeRecente.setFont(new Font("Consolas", Font.PLAIN, 12));
        lstActividadeRecente.setForeground(new Color(50, 55, 70));
        lstActividadeRecente.setBackground(new Color(250, 251, 252));
        lstActividadeRecente.setSelectionBackground(new Color(220, 235, 255));
        lstActividadeRecente.setCellRenderer(new ActivityListCellRenderer());

        JScrollPane scroll = new JScrollPane(lstActividadeRecente);
        scroll.setBorder(BorderFactory.createLineBorder(new Color(230, 235, 245)));
        panel.add(scroll, BorderLayout.CENTER);

        return panel;
    }

    private JPanel criarPainelAcoesRapidas() {
        JPanel panel = new JPanel(new MigLayout("fillx, ins 15, gap 10", "[grow][grow][grow]", "[]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(15, 15, 15, 15)));

        JLabel lblTitulo = new JLabel("Acoes Rapidas");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 14));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, "span 3, wrap, gapbottom 5");

        JButton btnNovoFuncionario = criarBotaoAcao("➕ Novo Funcionario", new Color(80, 200, 120));
        btnNovoFuncionario.addActionListener(e -> {
            // Trigger navigation to FUNCIONARIOS
            JOptionPane.showMessageDialog(this, 
                    "Funcionalidade em desenvolvimento.\nSerá disponivel na proxima versao.",
                    "Em breve", JOptionPane.INFORMATION_MESSAGE);
        });
        panel.add(btnNovoFuncionario, "grow, cell 0 0");

        JButton btnRegistoManual = criarBotaoAcao("📝 Registo Manual", new Color(52, 120, 246));
        btnRegistoManual.addActionListener(e -> {
            JOptionPane.showMessageDialog(this, 
                    "Funcionalidade em desenvolvimento.\nSerá disponivel na proxima versao.",
                    "Em breve", JOptionPane.INFORMATION_MESSAGE);
        });
        panel.add(btnRegistoManual, "grow, cell 1 0");

        JButton btnExportarRelatorio = criarBotaoAcao("📄 Exportar Relatorio", new Color(156, 89, 209));
        btnExportarRelatorio.addActionListener(e -> {
            JOptionPane.showMessageDialog(this, 
                    "Funcionalidade em desenvolvimento.\nSerá disponivel na proxima versao.",
                    "Em breve", JOptionPane.INFORMATION_MESSAGE);
        });
        panel.add(btnExportarRelatorio, "grow, cell 2 0");

        return panel;
    }

    private JButton criarBotaoAcao(String texto, Color cor) {
        JButton btn = new JButton(texto);
        btn.setBackground(cor);
        btn.setForeground(Color.WHITE);
        btn.setFont(new Font("Segoe UI", Font.BOLD, 12));
        btn.setFocusPainted(false);
        btn.setBorderPainted(false);
        btn.setOpaque(true);
        btn.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        btn.setPreferredSize(new Dimension(180, 45));
        btn.setMaximumSize(new Dimension(Integer.MAX_VALUE, 45));
        return btn;
    }

    private void carregarDados() {
        SwingWorker<Void, Void> worker = new SwingWorker<Void, Void>() {
            @Override
            protected Void doInBackground() throws Exception {
                try {
                    // Carregar metricas de funcionarios
                    List<tech.omnisyserp.desktop.model.Funcionario> todosFuncionarios = 
                            funcionarioService.listarTodos();
                    List<tech.omnisyserp.desktop.model.Funcionario> ativos = 
                            funcionarioService.listarAtivos();

                    SwingUtilities.invokeLater(() -> {
                        lblValorFuncionarios.setText(String.valueOf(todosFuncionarios.size()));
                        lblValorAtivos.setText(String.valueOf(ativos.size()));
                    });

                    // Carregar metricas de assiduidade
                    LocalDate hoje = LocalDate.now();
                    List<tech.omnisyserp.desktop.model.Assiduidade> registosHoje = 
                            assiduidadeService.listarPorPeriodo(hoje, hoje);
                    long abertos = registosHoje.stream()
                            .filter(r -> r.getDataHoraSaida() == null)
                            .count();

                    SwingUtilities.invokeLater(() -> {
                        lblValorHoje.setText(String.valueOf(registosHoje.size()));
                        lblValorAbertos.setText(String.valueOf(abertos));
                    });

                    // Carregar actividade recente (ultimos 20 registos)
                    List<tech.omnisyserp.desktop.model.Assiduidade> recentes = 
                            assiduidadeService.listarTodos().stream()
                            .limit(20)
                            .toList();

                    SwingUtilities.invokeLater(() -> {
                        listModel.clear();
                        if (recentes.isEmpty()) {
                            listModel.addElement("Nenhuma actividade registada");
                        } else {
                            DateTimeFormatter fmt = DateTimeFormatter.ofPattern("HH:mm:ss");
                            for (var registo : recentes) {
                                String tipo = registo.getTipo() != null ? registo.getTipo().getLabel() : "?";
                                String hora = registo.getDataHoraEntrada() != null 
                                        ? registo.getDataHoraEntrada().format(fmt) : "??:??:??";
                                String func = registo.getFuncionario() != null 
                                        ? registo.getFuncionario().getNome() : "Desconhecido";
                                String status = registo.getDataHoraSaida() != null ? "✓" : "⏳";
                                
                                listModel.addElement(String.format("[%s] %s %s - %s (%s)", 
                                        hora, status, func, tipo, 
                                        registo.getDuracaoFormatada()));
                            }
                        }
                    });

                } catch (Exception e) {
                    log.error("Erro ao carregar dados do dashboard", e);
                    SwingUtilities.invokeLater(() -> {
                        listModel.clear();
                        listModel.addElement("Erro ao carregar dados: " + e.getMessage());
                    });
                }
                return null;
            }
        };
        worker.execute();
    }

    private Color getRoleColor(String role) {
        return switch (role) {
            case "ADMIN_SISTEMA" -> new Color(220, 53, 69);
            case "GESTOR_RH" -> new Color(52, 120, 246);
            case "AUDITOR" -> new Color(156, 89, 209);
            default -> new Color(80, 200, 120);
        };
    }

    private static class ActivityListCellRenderer extends DefaultListCellRenderer {
        @Override
        public Component getListCellRendererComponent(JList<?> list, Object value, int index,
                boolean isSelected, boolean cellHasFocus) {
            JLabel label = (JLabel) super.getListCellRendererComponent(list, value, index, isSelected, cellHasFocus);
            label.setBorder(new EmptyBorder(5, 8, 5, 8));
            if (isSelected) {
                label.setBackground(list.getSelectionBackground());
                label.setForeground(list.getSelectionForeground());
            }
            return label;
        }
    }

    public void atualizar() {
        carregarDados();
    }
}
