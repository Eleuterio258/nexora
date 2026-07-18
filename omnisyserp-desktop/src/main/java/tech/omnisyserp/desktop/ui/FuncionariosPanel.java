package tech.omnisyserp.desktop.ui;

import lombok.extern.slf4j.Slf4j;
import net.miginfocom.swing.MigLayout;
import tech.omnisyserp.desktop.model.Funcionario;
import tech.omnisyserp.desktop.service.FuncionarioService;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.time.LocalDate;
import java.util.List;

@Slf4j
public class FuncionariosPanel extends JPanel {

    private final FuncionarioService funcionarioService;

    private JTable tabela;
    private DefaultTableModel tableModel;
    private JTextField txtPesquisa;
    private JTextField txtNome;
    private JTextField txtApelido;
    private JTextField txtEmail;
    private JTextField txtTelefone;
    private JTextField txtNif;
    private JComboBox<String> cbCargo;
    private JPasswordField txtPassword;
    private JTextArea txtObservacoes;
    private JCheckBox chkAtivo;
    private JSpinner spinnerDataAdmissao;

    // ID e String UUID do backend (null para novo registo)
    private String funcionarioSelecionadoId = null;

    private static final String[] ROLES = {
            "COLABORADOR", "GESTOR_RH", "ADMIN_SISTEMA", "AUDITOR"
    };

    public FuncionariosPanel(FuncionarioService funcionarioService) {
        this.funcionarioService = funcionarioService;
        setLayout(new BorderLayout(0, 0));
        setBackground(new Color(245, 247, 252));
        construirUI();
        recarregar();
    }

    private void construirUI() {
        JPanel mainPanel = new JPanel(new MigLayout(
                "fillx, ins 20, gap 10", "[grow]", "[][grow]"));
        mainPanel.setBackground(new Color(245, 247, 252));
        mainPanel.add(criarPainelSuperior(), "growx, wrap");
        mainPanel.add(criarPainelInferior(), "grow, wrap");
        add(mainPanel, BorderLayout.CENTER);
    }

    private JPanel criarPainelSuperior() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 15, gap 10", "[grow][]", "[]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(10, 15, 10, 15)));

        JLabel lblTitulo = new JLabel("Funcionarios");
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 20));
        lblTitulo.setForeground(new Color(30, 35, 50));
        panel.add(lblTitulo, "gapright 20");

        panel.add(new JLabel("Pesquisar:"), "gapright 5");
        txtPesquisa = new JTextField(20);
        txtPesquisa.addActionListener(e -> pesquisar());
        panel.add(txtPesquisa, "width 200, gapright 10");

        JButton btnPesquisar = new JButton("Pesquisar");
        estilizarBotao(btnPesquisar, new Color(52, 120, 246));
        btnPesquisar.addActionListener(e -> pesquisar());
        panel.add(btnPesquisar, "gapright 10");

        JButton btnNovo = new JButton("Novo");
        estilizarBotao(btnNovo, new Color(80, 200, 120));
        btnNovo.addActionListener(e -> limparFormulario());
        panel.add(btnNovo, "gapright 10");

        JButton btnGuardar = new JButton("Guardar");
        estilizarBotao(btnGuardar, new Color(52, 120, 246));
        btnGuardar.addActionListener(e -> guardar());
        panel.add(btnGuardar, "gapright 10");

        JButton btnDesativar = new JButton("Desativar");
        estilizarBotao(btnDesativar, new Color(220, 53, 69));
        btnDesativar.addActionListener(e -> desativar());
        panel.add(btnDesativar);

        return panel;
    }

    private JPanel criarPainelInferior() {
        JPanel panel = new JPanel(new MigLayout(
                "fill, ins 0, gap 0", "[60%][40%]", "[grow]"));
        panel.setBackground(new Color(245, 247, 252));
        panel.add(criarTabela(), "grow, cell 0 0");
        panel.add(criarFormulario(), "grow, cell 1 0");
        return panel;
    }

    private JScrollPane criarTabela() {
        String[] colunas = {"ID", "Nome", "Email", "Cargo", "Ativo"};
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

        // Ocultar coluna ID (UUID longo) — usada apenas internamente
        tabela.getColumnModel().getColumn(0).setMinWidth(0);
        tabela.getColumnModel().getColumn(0).setMaxWidth(0);
        tabela.getColumnModel().getColumn(0).setWidth(0);

        // Renderizador coluna Ativo
        tabela.getColumnModel().getColumn(4).setCellRenderer(new DefaultTableCellRenderer() {
            @Override
            public Component getTableCellRendererComponent(JTable table, Object value,
                    boolean isSelected, boolean hasFocus, int row, int column) {
                boolean ativo = Boolean.TRUE.equals(value);
                JLabel label = new JLabel(ativo ? "Sim" : "Nao");
                label.setHorizontalAlignment(CENTER);
                label.setOpaque(true);
                if (isSelected) {
                    label.setBackground(table.getSelectionBackground());
                    label.setForeground(table.getSelectionForeground());
                } else {
                    label.setBackground(ativo ? new Color(200, 255, 200) : new Color(255, 200, 200));
                    label.setForeground(Color.BLACK);
                }
                return label;
            }
        });

        tabela.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting() && tabela.getSelectedRow() >= 0) {
                carregarFuncionarioSelecionado();
            }
        });

        JScrollPane scroll = new JScrollPane(tabela);
        scroll.setBorder(BorderFactory.createLineBorder(new Color(220, 225, 235)));
        return scroll;
    }

    private JPanel criarFormulario() {
        JPanel panel = new JPanel(new MigLayout(
                "fillx, ins 15, gap 8", "[110px][grow]",
                "[][][][][][][][][][grow]"));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 225, 235)),
                new EmptyBorder(15, 15, 15, 15)));

        panel.add(new JLabel("Nome:"), "cell 0 0");
        txtNome = new JTextField();
        panel.add(txtNome, "cell 1 0, growx");

        panel.add(new JLabel("Apelido:"), "cell 0 1");
        txtApelido = new JTextField();
        panel.add(txtApelido, "cell 1 1, growx");

        panel.add(new JLabel("Email:"), "cell 0 2");
        txtEmail = new JTextField();
        panel.add(txtEmail, "cell 1 2, growx");

        panel.add(new JLabel("Telefone:"), "cell 0 3");
        txtTelefone = new JTextField();
        panel.add(txtTelefone, "cell 1 3, growx");

        panel.add(new JLabel("Cod. Func.:"), "cell 0 4");
        txtNif = new JTextField();
        panel.add(txtNif, "cell 1 4, growx");

        panel.add(new JLabel("Cargo/Role:"), "cell 0 5");
        cbCargo = new JComboBox<>(ROLES);
        panel.add(cbCargo, "cell 1 5, growx");

        panel.add(new JLabel("Data Admissao:"), "cell 0 6");
        SpinnerDateModel dateModel = new SpinnerDateModel();
        spinnerDataAdmissao = new JSpinner(dateModel);
        JSpinner.DateEditor dateEditor = new JSpinner.DateEditor(spinnerDataAdmissao, "yyyy-MM-dd");
        spinnerDataAdmissao.setEditor(dateEditor);
        panel.add(spinnerDataAdmissao, "cell 1 6, growx");

        panel.add(new JLabel("Ativo:"), "cell 0 7");
        chkAtivo = new JCheckBox();
        chkAtivo.setSelected(true);
        panel.add(chkAtivo, "cell 1 7");

        JLabel lblPass = new JLabel("Palavra-passe:");
        lblPass.setForeground(new Color(150, 80, 80));
        panel.add(lblPass, "cell 0 8");
        txtPassword = new JPasswordField();
        panel.add(txtPassword, "cell 1 8, growx");

        JLabel notaPass = new JLabel("(obrigatoria apenas ao criar)");
        notaPass.setFont(new Font("Segoe UI", Font.ITALIC, 10));
        notaPass.setForeground(new Color(130, 130, 130));
        panel.add(notaPass, "cell 1 9, growx");

        return panel;
    }

    private void pesquisar() {
        try {
            String termo = txtPesquisa.getText().trim();
            List<Funcionario> lista = funcionarioService.pesquisar(termo);
            atualizarTabela(lista);
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(this, "Erro ao pesquisar: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
            log.error("Erro ao pesquisar funcionarios", ex);
        }
    }

    public void recarregar() {
        try {
            List<Funcionario> lista = funcionarioService.listarTodos();
            atualizarTabela(lista);
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(this, "Erro ao carregar funcionarios: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
            log.error("Erro ao carregar funcionarios", ex);
        }
    }

    private void atualizarTabela(List<Funcionario> lista) {
        tableModel.setRowCount(0);
        for (Funcionario f : lista) {
            tableModel.addRow(new Object[]{
                    f.getId(),
                    f.getNomeCompleto(),
                    f.getEmail() != null ? f.getEmail() : "-",
                    f.getCargo() != null ? f.getCargo() : "-",
                    f.getAtivo()
            });
        }
    }

    private void carregarFuncionarioSelecionado() {
        int row = tabela.getSelectedRow();
        if (row < 0) return;

        String id = (String) tableModel.getValueAt(row, 0);
        funcionarioSelecionadoId = id;

        try {
            Funcionario f = funcionarioService.buscarPorId(id).orElse(null);
            if (f != null) {
                txtNome.setText(f.getNome() != null ? f.getNome() : "");
                txtApelido.setText(f.getApelido() != null ? f.getApelido() : "");
                txtEmail.setText(f.getEmail() != null ? f.getEmail() : "");
                txtTelefone.setText(f.getTelefone() != null ? f.getTelefone() : "");
                txtNif.setText(f.getNif() != null ? f.getNif() : "");
                cbCargo.setSelectedItem(f.getCargo() != null ? f.getCargo() : "COLABORADOR");
                chkAtivo.setSelected(Boolean.TRUE.equals(f.getAtivo()));
                txtPassword.setText("");

                if (f.getDataAdmissao() != null) {
                    spinnerDataAdmissao.setValue(
                            java.util.Date.from(f.getDataAdmissao().atStartOfDay()
                                    .atZone(java.time.ZoneId.systemDefault()).toInstant()));
                }
            }
        } catch (Exception ex) {
            log.error("Erro ao carregar funcionario", ex);
        }
    }

    private void limparFormulario() {
        funcionarioSelecionadoId = null;
        txtNome.setText("");
        txtApelido.setText("");
        txtEmail.setText("");
        txtTelefone.setText("");
        txtNif.setText("");
        cbCargo.setSelectedIndex(0);
        chkAtivo.setSelected(true);
        txtPassword.setText("");
        spinnerDataAdmissao.setValue(new java.util.Date());
        tabela.clearSelection();
    }

    private void guardar() {
        try {
            if (txtNome.getText().isBlank() || txtApelido.getText().isBlank()) {
                JOptionPane.showMessageDialog(this, "Nome e Apelido sao obrigatorios.",
                        "Validacao", JOptionPane.WARNING_MESSAGE);
                return;
            }

            Funcionario f = new Funcionario();
            f.setId(funcionarioSelecionadoId);
            f.setNome(txtNome.getText().trim());
            f.setApelido(txtApelido.getText().trim());
            f.setEmail(txtEmail.getText().isBlank() ? null : txtEmail.getText().trim());
            f.setTelefone(txtTelefone.getText().isBlank() ? null : txtTelefone.getText().trim());
            f.setNif(txtNif.getText().isBlank() ? null : txtNif.getText().trim());
            f.setCargo((String) cbCargo.getSelectedItem());
            f.setAtivo(chkAtivo.isSelected());

            String pwd = new String(txtPassword.getPassword());
            f.setPassword(pwd.isBlank() ? null : pwd);

            java.util.Date utilDate = (java.util.Date) spinnerDataAdmissao.getValue();
            LocalDate localDate = utilDate.toInstant()
                    .atZone(java.time.ZoneId.systemDefault()).toLocalDate();
            f.setDataAdmissao(localDate);

            funcionarioService.guardar(f);
            JOptionPane.showMessageDialog(this, "Funcionario guardado com sucesso!",
                    "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            recarregar();
            limparFormulario();
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(this, "Erro ao guardar: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
            log.error("Erro ao guardar funcionario", ex);
        }
    }

    private void desativar() {
        if (funcionarioSelecionadoId == null) {
            JOptionPane.showMessageDialog(this, "Selecione um funcionario para desativar.",
                    "Atencao", JOptionPane.WARNING_MESSAGE);
            return;
        }

        int opcao = JOptionPane.showConfirmDialog(this,
                "Tem certeza que deseja desativar este funcionario no backend?",
                "Confirmar Desativacao",
                JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);

        if (opcao == JOptionPane.YES_OPTION) {
            try {
                funcionarioService.eliminar(funcionarioSelecionadoId);
                JOptionPane.showMessageDialog(this, "Funcionario desativado com sucesso!",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                recarregar();
                limparFormulario();
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(this, "Erro ao desativar: " + ex.getMessage(),
                        "Erro", JOptionPane.ERROR_MESSAGE);
                log.error("Erro ao desativar funcionario", ex);
            }
        }
    }

    private void estilizarBotao(JButton btn, Color cor) {
        btn.setBackground(cor);
        btn.setForeground(Color.WHITE);
        btn.setFont(new Font("Segoe UI", Font.BOLD, 12));
        btn.setFocusPainted(false);
        btn.setBorderPainted(false);
        btn.setOpaque(true);
        btn.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        btn.setPreferredSize(new Dimension(100, 32));
    }

    public void atualizar() {
        recarregar();
    }
}
