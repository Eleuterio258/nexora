package tech.omnisyserp.desktop.ui;

import lombok.extern.slf4j.Slf4j;
import net.miginfocom.swing.MigLayout;
import tech.omnisyserp.desktop.model.Assiduidade;
import tech.omnisyserp.desktop.model.Funcionario;
import tech.omnisyserp.desktop.model.TipoRegisto;
import tech.omnisyserp.desktop.service.AssiduidadeService;
import tech.omnisyserp.desktop.service.FuncionarioService;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.filechooser.FileNameExtensionFilter;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.List;

@Slf4j
public class AssiduidadePanel extends JPanel {

    private final AssiduidadeService assiduidadeService;
    private final FuncionarioService funcionarioService;

    // Table and data
    private JTable tabela;
    private DefaultTableModel tableModel;
    private List<Assiduidade> listaAtual;

    // Filters
    private JComboBox<Funcionario> cbFuncionario;
    private JSpinner spinnerDataInicio;
    private JSpinner spinnerDataFim;
    private JButton btnFiltrar;
    private JButton btnHoje;
    private JButton btnExportar;

    // Form
    private JComboBox<Funcionario> cbFormFuncionario;
    private JComboBox<TipoRegisto> cbFormTipo;
    private JSpinner spinnerEntrada;
    private JSpinner spinnerSaida;
    private JCheckBox chkSaidaDefinida;
    private JTextArea txtObservacao;
    private String assiduidadeSelecionadaId = null;

    // Statistics panel
    private JLabel lblTotalRegistos;
    private JLabel lblRegistosAbertos;
    private JLabel lblHorasTrabalhadas;
    private JLabel lblMediaDiaria;

    public AssiduidadePanel(AssiduidadeService assiduidadeService, FuncionarioService funcionarioService) {
        this.assiduidadeService = assiduidadeService;
        this.funcionarioService = funcionarioService;
        setLayout(new BorderLayout(0, 0));
        setBackground(new Color(245, 247, 252));
        construirUI();
        recarregar();
    }

    private void construirUI() {
        JPanel mainPanel = new JPanel(new MigLayout(
                "fillx, ins 15, gap 10",
                "[grow]",
                "[][][grow]"));
        mainPanel.setBackground(new Color(245, 247, 252));

        mainPanel.add(criarPainelEstatisticas(), "growx, wrap");
        mainPanel.add(criarPainelFiltros(), "growx, wrap");
        mainPanel.add(criarPainelInferior(), "grow, wrap");

        add(mainPanel, BorderLayout.CENTER);
    }

    private JPanel criarPainelEstatisticas() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 10, gap 10",
                "[25%][25%][25%][25%]",
                "[][]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(12, 15, 12, 15)));

        // Total Registos
        JPanel pnlTotal = criarCardEstatistica("Total de Registos", "0", new Color(52, 120, 246));
        lblTotalRegistos = (JLabel) pnlTotal.getClientProperty("label");
        panel.add(pnlTotal, "grow, cell 0 0");

        // Registos Abertos
        JPanel pnlAbertos = criarCardEstatistica("Registos Abertos", "0", new Color(255, 140, 0));
        lblRegistosAbertos = (JLabel) pnlAbertos.getClientProperty("label");
        panel.add(pnlAbertos, "grow, cell 1 0");

        // Horas Trabalhadas
        JPanel pnlHoras = criarCardEstatistica("Horas Trabalhadas", "0h 0m", new Color(80, 200, 120));
        lblHorasTrabalhadas = (JLabel) pnlHoras.getClientProperty("label");
        panel.add(pnlHoras, "grow, cell 2 0");

        // Média Diária
        JPanel pnlMedia = criarCardEstatistica("Média Diária", "0h 0m", new Color(156, 89, 209));
        lblMediaDiaria = (JLabel) pnlMedia.getClientProperty("label");
        panel.add(pnlMedia, "grow, cell 3 0");

        return panel;
    }

    private JPanel criarCardEstatistica(String titulo, String valorInicial, Color cor) {
        JPanel card = new JPanel(new MigLayout("fillx, ins 8, gap 3", "[grow]", "[][]"));
        card.setBackground(new Color(250, 251, 252));
        card.setBorder(BorderFactory.createLineBorder(cor, 1));

        JLabel lblTitulo = new JLabel(titulo);
        lblTitulo.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        lblTitulo.setForeground(new Color(100, 110, 130));
        card.add(lblTitulo, "cell 0 0");

        JLabel lblValor = new JLabel(valorInicial);
        lblValor.setFont(new Font("Segoe UI", Font.BOLD, 18));
        lblValor.setForeground(cor);
        lblValor.putClientProperty("card", card);
        card.putClientProperty("label", lblValor);
        card.add(lblValor, "cell 0 1");

        return card;
    }

    private JPanel criarPainelFiltros() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 15, gap 10",
                "[][200px][][][grow][]",
                "[]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(10, 15, 10, 15)));

        JLabel lblTitulo = new JLabel("📊 Registos de Assiduidade");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 16));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, "gapright 15");

        panel.add(new JLabel("Funcionario:"), "gapright 5");
        cbFuncionario = new JComboBox<>();
        cbFuncionario.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        panel.add(cbFuncionario, "gapright 10");

        panel.add(new JLabel("De:"), "gapright 5");
        SpinnerDateModel modelInicio = new SpinnerDateModel();
        spinnerDataInicio = new JSpinner(modelInicio);
        spinnerDataInicio.setEditor(new JSpinner.DateEditor(spinnerDataInicio, "yyyy-MM-dd"));
        spinnerDataInicio.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        spinnerDataInicio.setValue(Date.from(
                LocalDate.now().minusDays(30).atStartOfDay()
                        .atZone(ZoneId.systemDefault()).toInstant()));
        panel.add(spinnerDataInicio, "width 120, gapright 10");

        panel.add(new JLabel("Ate:"), "gapright 5");
        SpinnerDateModel modelFim = new SpinnerDateModel();
        spinnerDataFim = new JSpinner(modelFim);
        spinnerDataFim.setEditor(new JSpinner.DateEditor(spinnerDataFim, "yyyy-MM-dd"));
        spinnerDataFim.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        spinnerDataFim.setValue(Date.from(
                LocalDate.now().atTime(23, 59)
                        .atZone(ZoneId.systemDefault()).toInstant()));
        panel.add(spinnerDataFim, "width 120, gapright 10");

        btnFiltrar = new JButton("🔍 Filtrar");
        estilizarBotao(btnFiltrar, new Color(52, 120, 246));
        btnFiltrar.addActionListener(e -> filtrar());
        panel.add(btnFiltrar, "gapright 5");

        btnHoje = new JButton("📅 Hoje");
        estilizarBotao(btnHoje, new Color(100, 160, 240));
        btnHoje.addActionListener(e -> filtrarHoje());
        panel.add(btnHoje, "gapright 5");

        btnExportar = new JButton("📄 Exportar CSV");
        estilizarBotao(btnExportar, new Color(80, 200, 120));
        btnExportar.addActionListener(e -> exportarCSV());
        panel.add(btnExportar);

        carregarFuncionarios();
        return panel;
    }

    private JPanel criarPainelInferior() {
        JPanel panel = new JPanel(new MigLayout(
                "fill, ins 0, gap 10",
                "[65%][35%]",
                "[grow]"));
        panel.setBackground(new Color(245, 247, 252));
        panel.add(criarTabela(), "grow, cell 0 0");
        panel.add(criarFormulario(), "grow, cell 1 0");
        return panel;
    }

    private JScrollPane criarTabela() {
        String[] colunas = {"ID", "Funcionario", "Entrada", "Saida", "Duração", "Tipo", "Obs"};
        tableModel = new DefaultTableModel(colunas, 0) {
            @Override public boolean isCellEditable(int row, int column) { return false; }
        };

        tabela = new JTable(tableModel);
        tabela.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        tabela.setRowHeight(30);
        tabela.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        tabela.getTableHeader().setFont(new Font("Segoe UI", Font.BOLD, 12));
        tabela.getTableHeader().setBackground(new Color(30, 35, 50));
        tabela.getTableHeader().setForeground(Color.WHITE);
        tabela.setGridColor(new Color(230, 235, 245));
        tabela.setShowGrid(true);
        tabela.setSelectionBackground(new Color(220, 235, 255));
        tabela.setSelectionForeground(Color.BLACK);

        // Hide ID column
        tabela.getColumnModel().getColumn(0).setMinWidth(0);
        tabela.getColumnModel().getColumn(0).setMaxWidth(0);
        tabela.getColumnModel().getColumn(0).setWidth(0);

        // Column widths
        tabela.getColumnModel().getColumn(1).setPreferredWidth(150);
        tabela.getColumnModel().getColumn(2).setPreferredWidth(120);
        tabela.getColumnModel().getColumn(3).setPreferredWidth(120);
        tabela.getColumnModel().getColumn(4).setPreferredWidth(80);
        tabela.getColumnModel().getColumn(5).setPreferredWidth(80);
        tabela.getColumnModel().getColumn(6).setPreferredWidth(100);

        // Duration renderer
        tabela.getColumnModel().getColumn(4).setCellRenderer(new DefaultTableCellRenderer() {
            @Override
            public Component getTableCellRendererComponent(JTable table, Object value,
                    boolean isSelected, boolean hasFocus, int row, int column) {
                Component c = super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);
                if ("Em curso".equals(value)) {
                    c.setForeground(new Color(255, 140, 0));
                    c.setFont(c.getFont().deriveFont(Font.BOLD));
                } else if (isSelected) {
                    c.setForeground(table.getSelectionForeground());
                } else {
                    c.setForeground(new Color(80, 200, 120));
                }
                return c;
            }
        });

        // Open record highlight
        tabela.getColumnModel().getColumn(3).setCellRenderer(new DefaultTableCellRenderer() {
            @Override
            public Component getTableCellRendererComponent(JTable table, Object value,
                    boolean isSelected, boolean hasFocus, int row, int column) {
                Component c = super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);
                if ("-".equals(value) || value.toString().trim().isEmpty()) {
                    c.setForeground(new Color(255, 100, 100));
                    c.setFont(c.getFont().deriveFont(Font.BOLD));
                }
                return c;
            }
        });

        tabela.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting() && tabela.getSelectedRow() >= 0) {
                carregarAssiduidadeSelecionada();
            }
        });

        JScrollPane scroll = new JScrollPane(tabela);
        scroll.setBorder(BorderFactory.createLineBorder(new Color(220, 225, 235)));
        
        JLabel lblInfo = new JLabel("💡 Clique num registo para ver/editar detalhes");
        lblInfo.setFont(new Font("Segoe UI", Font.ITALIC, 10));
        lblInfo.setForeground(new Color(130, 140, 160));
        
        JPanel pnlTable = new JPanel(new BorderLayout());
        pnlTable.setBackground(new Color(245, 247, 252));
        pnlTable.add(scroll, BorderLayout.CENTER);
        pnlTable.add(lblInfo, BorderLayout.SOUTH);
        
        return scroll;
    }

    private JPanel criarFormulario() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 15, gap 8",
                "[110px][grow]",
                "[][][][][][][grow][]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(15, 15, 15, 15)));

        JLabel lblTitulo = new JLabel("📝 Registo Manual");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 14));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, "span 2, wrap, gapbottom 5");

        panel.add(new JLabel("Funcionario:"), "cell 0 1");
        cbFormFuncionario = new JComboBox<>();
        cbFormFuncionario.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        carregarFuncionarios();
        panel.add(cbFormFuncionario, "cell 1 1, growx");

        panel.add(new JLabel("Tipo de Registo:"), "cell 0 2");
        cbFormTipo = new JComboBox<>(TipoRegisto.values());
        cbFormTipo.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        panel.add(cbFormTipo, "cell 1 2, growx");

        panel.add(new JLabel("Data/Hora Entrada:"), "cell 0 3");
        SpinnerDateModel modelEntrada = new SpinnerDateModel();
        spinnerEntrada = new JSpinner(modelEntrada);
        spinnerEntrada.setEditor(new JSpinner.DateEditor(spinnerEntrada, "yyyy-MM-dd HH:mm"));
        spinnerEntrada.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        panel.add(spinnerEntrada, "cell 1 3, growx");

        panel.add(new JLabel("Definir Saida:"), "cell 0 4");
        chkSaidaDefinida = new JCheckBox("Registar saida agora");
        chkSaidaDefinida.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        chkSaidaDefinida.addActionListener(e -> {
            boolean enabled = chkSaidaDefinida.isSelected();
            spinnerSaida.setEnabled(enabled);
            if (!enabled) {
                spinnerSaida.setValue(new Date());
            }
        });
        panel.add(chkSaidaDefinida, "cell 1 4");

        panel.add(new JLabel("Data/Hora Saida:"), "cell 0 5");
        SpinnerDateModel modelSaida = new SpinnerDateModel();
        spinnerSaida = new JSpinner(modelSaida);
        spinnerSaida.setEditor(new JSpinner.DateEditor(spinnerSaida, "yyyy-MM-dd HH:mm"));
        spinnerSaida.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        spinnerSaida.setEnabled(false);
        panel.add(spinnerSaida, "cell 1 5, growx");

        panel.add(new JLabel("Observacao:"), "cell 0 6");
        txtObservacao = new JTextArea(4, 20);
        txtObservacao.setFont(new Font("Segoe UI", Font.PLAIN, 11));
        txtObservacao.setLineWrap(true);
        txtObservacao.setWrapStyleWord(true);
        JScrollPane scrollObs = new JScrollPane(txtObservacao);
        scrollObs.setBorder(BorderFactory.createLineBorder(new Color(220, 225, 235)));
        panel.add(scrollObs, "cell 1 6, grow");

        // Action buttons
        JPanel pnlBotoes = new JPanel(new MigLayout("fillx, ins 0, gap 5", "[grow][grow][grow]"));
        pnlBotoes.setBackground(Color.WHITE);
        
        JButton btnNovo = new JButton("🆕 Novo");
        estilizarBotao(btnNovo, new Color(100, 160, 240));
        btnNovo.addActionListener(e -> limparFormulario());
        pnlBotoes.add(btnNovo, "cell 0 0");

        JButton btnGuardar = new JButton("✓ Guardar");
        estilizarBotao(btnGuardar, new Color(80, 200, 120));
        btnGuardar.addActionListener(e -> guardar());
        pnlBotoes.add(btnGuardar, "cell 1 0");

        JButton btnEliminar = new JButton("Ajuste Horario");
        estilizarBotao(btnEliminar, new Color(220, 53, 69));
        btnEliminar.addActionListener(e -> {
            JOptionPane.showMessageDialog(this,
                    "A eliminacao de registos nao e disponivel nesta aplicacao.\n" +
                    "Contacte o administrador para ajustes de horario.",
                    "Ajuste de Horario",
                    JOptionPane.INFORMATION_MESSAGE);
        });
        pnlBotoes.add(btnEliminar, "cell 2 0");
        
        panel.add(pnlBotoes, "span 2, wrap, gapbottom 5");

        JLabel nota = new JLabel("Nota: Registos via camera sao automaticos");
        nota.setFont(new Font("Segoe UI", Font.ITALIC, 10));
        nota.setForeground(new Color(130, 140, 160));
        panel.add(nota, "span 2, cell 0 8");

        return panel;
    }

    private void carregarFuncionarios() {
        try {
            List<Funcionario> funcionarios = funcionarioService.listarAtivos();
            if (cbFuncionario != null) {
                cbFuncionario.removeAllItems();
                cbFuncionario.addItem(null); // "Todos"
                for (Funcionario f : funcionarios) {
                    cbFuncionario.addItem(f);
                }
            }
            if (cbFormFuncionario != null) {
                cbFormFuncionario.removeAllItems();
                for (Funcionario f : funcionarios) {
                    cbFormFuncionario.addItem(f);
                }
            }
        } catch (Exception ex) {
            log.error("Erro ao carregar funcionarios", ex);
        }
    }

    private void filtrar() {
        try {
            Funcionario funcionario = (Funcionario) cbFuncionario.getSelectedItem();
            Date utilInicio = (Date) spinnerDataInicio.getValue();
            Date utilFim = (Date) spinnerDataFim.getValue();

            LocalDate inicio = utilInicio.toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
            LocalDate fim = utilFim.toInstant().atZone(ZoneId.systemDefault()).toLocalDate();

            List<Assiduidade> lista;
            if (funcionario != null) {
                lista = assiduidadeService.listarPorFuncionarioEPeriodo(funcionario, inicio, fim);
            } else {
                lista = assiduidadeService.listarPorPeriodo(inicio, fim);
            }
            atualizarTabela(lista);
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(this, "Erro ao filtrar: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
            log.error("Erro ao filtrar assiduidade", ex);
        }
    }

    private void filtrarHoje() {
        LocalDate hoje = LocalDate.now();
        Date dataHoje = Date.from(hoje.atStartOfDay().atZone(ZoneId.systemDefault()).toInstant());
        spinnerDataInicio.setValue(dataHoje);
        spinnerDataFim.setValue(dataHoje);
        cbFuncionario.setSelectedIndex(0);
        filtrar();
    }

    public void recarregar() {
        try {
            List<Assiduidade> lista = assiduidadeService.listarTodos();
            atualizarTabela(lista);
            atualizarEstatisticas(lista);
            carregarFuncionarios();
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(this, "Erro ao carregar assiduidade: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
            log.error("Erro ao carregar assiduidade", ex);
        }
    }

    private void atualizarTabela(List<Assiduidade> lista) {
        this.listaAtual = lista;
        tableModel.setRowCount(0);
        for (Assiduidade a : lista) {
            String nomeFunc = a.getFuncionario() != null ? a.getFuncionario().getNomeCompleto() : "-";
            String entrada = a.getDataHoraEntrada() != null
                    ? a.getDataHoraEntrada().format(DateTimeFormatter.ofPattern("dd/MM HH:mm")) : "-";
            String saida = a.getDataHoraSaida() != null
                    ? a.getDataHoraSaida().format(DateTimeFormatter.ofPattern("dd/MM HH:mm")) : "-";
            String obs = a.getObservacao() != null && !a.getObservacao().isBlank()
                    ? (a.getObservacao().length() > 15 ? a.getObservacao().substring(0, 15) + "..." : a.getObservacao())
                    : "-";
            tableModel.addRow(new Object[]{
                    a.getId(),
                    nomeFunc,
                    entrada,
                    saida,
                    a.getDuracaoFormatada(),
                    a.getTipo() != null ? a.getTipo().getLabel() : "-",
                    obs
            });
        }
    }

    private void atualizarEstatisticas(List<Assiduidade> lista) {
        int total = lista.size();
        long abertos = lista.stream().filter(a -> a.getDataHoraSaida() == null).count();
        
        long totalMinutos = lista.stream()
                .filter(a -> a.getDataHoraSaida() != null)
                .mapToLong(a -> ChronoUnit.MINUTES.between(a.getDataHoraEntrada(), a.getDataHoraSaida()))
                .sum();
        
        long horas = totalMinutos / 60;
        long minutos = totalMinutos % 60;
        
        long diasUnicos = lista.stream()
                .map(a -> a.getDataHoraEntrada().toLocalDate())
                .distinct()
                .count();
        
        long mediaMinutos = diasUnicos > 0 ? totalMinutos / diasUnicos : 0;
        long mediaHoras = mediaMinutos / 60;
        long mediaMinutosResto = mediaMinutos % 60;

        lblTotalRegistos.setText(String.valueOf(total));
        lblRegistosAbertos.setText(String.valueOf(abertos));
        lblHorasTrabalhadas.setText(horas + "h " + minutos + "m");
        lblMediaDiaria.setText(mediaHoras + "h " + mediaMinutosResto + "m");
    }

    private void carregarAssiduidadeSelecionada() {
        int row = tabela.getSelectedRow();
        if (row < 0) return;

        String id = (String) tableModel.getValueAt(row, 0);
        assiduidadeSelecionadaId = id;

        try {
            Assiduidade a = assiduidadeService.buscarPorId(id).orElse(null);
            if (a != null) {
                if (a.getFuncionario() != null && cbFormFuncionario != null) {
                    for (int i = 0; i < cbFormFuncionario.getItemCount(); i++) {
                        Funcionario f = cbFormFuncionario.getItemAt(i);
                        if (f.getId() != null && f.getId().equals(a.getFuncionario().getId())) {
                            cbFormFuncionario.setSelectedIndex(i);
                            break;
                        }
                    }
                }
                if (a.getTipo() != null) cbFormTipo.setSelectedItem(a.getTipo());

                if (a.getDataHoraEntrada() != null) {
                    spinnerEntrada.setValue(Date.from(
                            a.getDataHoraEntrada().atZone(ZoneId.systemDefault()).toInstant()));
                }

                boolean temSaida = a.getDataHoraSaida() != null;
                chkSaidaDefinida.setSelected(temSaida);
                spinnerSaida.setEnabled(temSaida);
                if (temSaida) {
                    spinnerSaida.setValue(Date.from(
                            a.getDataHoraSaida().atZone(ZoneId.systemDefault()).toInstant()));
                }

                txtObservacao.setText(a.getObservacao() != null ? a.getObservacao() : "");
            }
        } catch (Exception ex) {
            log.error("Erro ao carregar assiduidade", ex);
        }
    }

    private void limparFormulario() {
        assiduidadeSelecionadaId = null;
        if (cbFormFuncionario.getItemCount() > 0) cbFormFuncionario.setSelectedIndex(0);
        cbFormTipo.setSelectedIndex(0);
        spinnerEntrada.setValue(new Date());
        chkSaidaDefinida.setSelected(false);
        spinnerSaida.setEnabled(false);
        spinnerSaida.setValue(new Date());
        txtObservacao.setText("");
        tabela.clearSelection();
    }

    private void guardar() {
        try {
            Funcionario funcionario = (Funcionario) cbFormFuncionario.getSelectedItem();
            if (funcionario == null) {
                JOptionPane.showMessageDialog(this, "Selecione um funcionario.",
                        "Validacao", JOptionPane.WARNING_MESSAGE);
                return;
            }

            TipoRegisto tipo = (TipoRegisto) cbFormTipo.getSelectedItem();

            Date utilEntrada = (Date) spinnerEntrada.getValue();
            LocalDateTime entrada = LocalDateTime.ofInstant(utilEntrada.toInstant(), ZoneId.systemDefault());

            LocalDateTime saida = null;
            if (chkSaidaDefinida.isSelected()) {
                Date utilSaida = (Date) spinnerSaida.getValue();
                saida = LocalDateTime.ofInstant(utilSaida.toInstant(), ZoneId.systemDefault());
                
                if (saida.isBefore(entrada)) {
                    JOptionPane.showMessageDialog(this, "A saida deve ser posterior a entrada.",
                            "Validacao", JOptionPane.WARNING_MESSAGE);
                    return;
                }
            }

            String observacao = txtObservacao.getText().isBlank() ? null : txtObservacao.getText().trim();

            assiduidadeService.registarManual(funcionario, entrada, saida, tipo, observacao);

            JOptionPane.showMessageDialog(this, 
                    "✓ Registo guardado com sucesso!\n\n" +
                    "Funcionario: " + funcionario.getNomeCompleto() + "\n" +
                    "Entrada: " + entrada.format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")) +
                    (saida != null ? "\nSaida: " + saida.format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")) : "\nSaida: Em curso") +
                    "\nTipo: " + tipo.getLabel(),
                    "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            
            recarregar();
            limparFormulario();
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(this, "Erro ao guardar: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
            log.error("Erro ao guardar assiduidade", ex);
        }
    }

    private void eliminar() {
        if (assiduidadeSelecionadaId == null) {
            JOptionPane.showMessageDialog(this, "Selecione um registo para eliminar.",
                    "Atencao", JOptionPane.WARNING_MESSAGE);
            return;
        }

        int opcao = JOptionPane.showConfirmDialog(this,
                "Tem certeza que deseja eliminar este registo?",
                "Confirmar Eliminacao",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.WARNING_MESSAGE);

        if (opcao == JOptionPane.YES_OPTION) {
            try {
                assiduidadeService.eliminar(assiduidadeSelecionadaId);
                JOptionPane.showMessageDialog(this, "Registo eliminado com sucesso!",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                recarregar();
                limparFormulario();
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(this, "Erro ao eliminar: " + ex.getMessage(),
                        "Erro", JOptionPane.ERROR_MESSAGE);
                log.error("Erro ao eliminar assiduidade", ex);
            }
        }
    }

    private void exportarCSV() {
        if (listaAtual == null || listaAtual.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Nao ha registos para exportar.",
                    "Atencao", JOptionPane.WARNING_MESSAGE);
            return;
        }

        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setDialogTitle("Exportar Registos");
        fileChooser.setSelectedFile(new File("assiduidade_" + LocalDate.now() + ".csv"));
        fileChooser.setFileFilter(new FileNameExtensionFilter("CSV files", "csv"));
        
        int result = fileChooser.showSaveDialog(this);
        if (result == JFileChooser.APPROVE_OPTION) {
            try (BufferedWriter writer = new BufferedWriter(new FileWriter(fileChooser.getSelectedFile()))) {
                // Header
                writer.write("ID,Funcionario,Entrada,Saida,Duracao,Tipo,Observacao\n");
                
                // Data
                for (Assiduidade a : listaAtual) {
                    String func = a.getFuncionario() != null ? a.getFuncionario().getNomeCompleto() : "-";
                    String entrada = a.getDataHoraEntrada() != null ? a.getDataHoraEntrada().toString() : "-";
                    String saida = a.getDataHoraSaida() != null ? a.getDataHoraSaida().toString() : "-";
                    String duracao = a.getDuracaoFormatada();
                    String tipo = a.getTipo() != null ? a.getTipo().getLabel() : "-";
                    String obs = a.getObservacao() != null ? a.getObservacao().replace("\"", "\"\"") : "";
                    
                    writer.write(String.format("\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n",
                            a.getId(), func, entrada, saida, duracao, tipo, obs));
                }
                
                JOptionPane.showMessageDialog(this, 
                        "CSV exportado com sucesso!\n" + listaAtual.size() + " registos exportados.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                log.info("CSV exportado: {}", fileChooser.getSelectedFile().getPath());
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(this, "Erro ao exportar CSV: " + ex.getMessage(),
                        "Erro", JOptionPane.ERROR_MESSAGE);
                log.error("Erro ao exportar CSV", ex);
            }
        }
    }

    private void estilizarBotao(JButton btn, Color cor) {
        btn.setBackground(cor);
        btn.setForeground(Color.WHITE);
        btn.setFont(new Font("Segoe UI", Font.BOLD, 11));
        btn.setFocusPainted(false);
        btn.setBorderPainted(false);
        btn.setOpaque(true);
        btn.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        btn.setPreferredSize(new Dimension(110, 32));
    }
}
