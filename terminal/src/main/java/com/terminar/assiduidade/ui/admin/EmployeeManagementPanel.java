package com.terminar.assiduidade.ui.admin;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.exception.AssiduidadeException;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.service.EmployeeService;
import com.terminar.assiduidade.service.ErpSyncService;
import com.terminar.assiduidade.ui.AssiduidadeFrame;
import net.miginfocom.swing.MigLayout;

import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JPasswordField;
import javax.swing.JScrollPane;
import javax.swing.JTabbedPane;
import javax.swing.JTable;
import javax.swing.ListSelectionModel;
import javax.swing.SwingUtilities;
import javax.swing.table.AbstractTableModel;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.List;

public class EmployeeManagementPanel extends JPanel {

    private static final String[] COLUNAS =
        {"Número", "Nome", "Departamento", "Activo", "PIN definido", "QR", "Digital", "NFC"};

    private final AssiduidadeFrame frame;
    private final EmployeeService employeeService = new EmployeeService();
    private final ErpSyncService erpSyncService = new ErpSyncService();
    private final EmployeeTableModel tableModel = new EmployeeTableModel();
    private final JTable table = new JTable(tableModel);
    private final RegistosHojePanel registosHojePanel = new RegistosHojePanel();
    private final JButton novoButton = new JButton("Novo");

    public EmployeeManagementPanel(AssiduidadeFrame frame) {
        this.frame = frame;
        setLayout(new MigLayout("fill, insets 4", "[grow]", "[]4[grow]4[]"));

        JLabel titulo = new JLabel("Administração — Terminal");
        titulo.setFont(titulo.getFont().deriveFont(java.awt.Font.BOLD, 12f));
        add(titulo, "wrap");

        JTabbedPane tabs = new JTabbedPane();
        tabs.addTab("Funcionários", criarTabFuncionarios());
        tabs.addTab("Registos de Hoje", registosHojePanel);
        tabs.addTab("Configurações", new ConfiguracaoPanel());
        add(tabs, "grow, wrap");

        JButton voltarButton = new JButton("Voltar ao terminal");
        voltarButton.addActionListener(e -> frame.goHome());
        add(voltarButton, "align right");
    }

    private JPanel criarTabFuncionarios() {
        JPanel painel = new JPanel(new MigLayout("fill, insets 2", "[grow]", "[]2[]4[grow]"));

        JPanel toolbar = new JPanel(new MigLayout("insets 0, gap 2, wrap 2", "[grow, fill]", "[]2[]"));
        JButton sincronizarErpButton = new JButton("Sincronizar ERP");
        toolbar.add(novoButton);
        toolbar.add(sincronizarErpButton);
        painel.add(toolbar, "growx, wrap");

        JLabel dicaLabel = new JLabel("Duplo-clique num funcionário para ver acções (PIN, NFC, Digital, Activo...)");
        dicaLabel.setFont(dicaLabel.getFont().deriveFont(java.awt.Font.ITALIC, 9f));
        painel.add(dicaLabel, "wrap");

        table.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        table.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                if (e.getClickCount() != 2) {
                    return;
                }
                int linha = table.rowAtPoint(e.getPoint());
                if (linha < 0) {
                    return;
                }
                table.setRowSelectionInterval(linha, linha);
                abrirAcoes();
            }
        });
        painel.add(new JScrollPane(table), "grow");

        novoButton.addActionListener(e -> criarFuncionario());
        sincronizarErpButton.addActionListener(e -> sincronizarComErp());

        return painel;
    }

    /** Abre o modal de acções para o funcionário seleccionado (ver EmployeeActionsDialog). */
    private void abrirAcoes() {
        Employee employee = funcionarioSelecionado();
        if (employee == null) {
            return;
        }
        boolean mostrarEditar = !AppConfig.isApiSyncAtivo();
        new EmployeeActionsDialog(frame, employee, mostrarEditar,
            this::editarFuncionario, this::alternarAtivo, this::definirPin, this::verQrCode,
            this::enrolarDigital, this::associarNfc)
            .setVisible(true);
    }

    private Employee funcionarioSelecionado() {
        int linha = table.getSelectedRow();
        if (linha < 0) {
            JOptionPane.showMessageDialog(this, "Seleccione um funcionário na tabela");
            return null;
        }
        return tableModel.getEmployeeAt(linha);
    }

    private void criarFuncionario() {
        EmployeeFormDialog dialog = new EmployeeFormDialog(frame, "Novo funcionário", null, null, null, true);
        dialog.setVisible(true);
        if (dialog.isConfirmado()) {
            try {
                employeeService.criar(dialog.getNumero(), dialog.getNome(), dialog.getDepartamento());
                refrescar();
            } catch (AssiduidadeException e) {
                JOptionPane.showMessageDialog(this, e.getMessage(), "Erro", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    private void editarFuncionario() {
        Employee employee = funcionarioSelecionado();
        if (employee == null) {
            return;
        }
        EmployeeFormDialog dialog = new EmployeeFormDialog(frame, "Editar funcionário",
            employee.getNumero(), employee.getNome(), employee.getDepartamento(), false);
        dialog.setVisible(true);
        if (dialog.isConfirmado()) {
            employee.setNome(dialog.getNome());
            employee.setDepartamento(dialog.getDepartamento());
            employeeService.actualizar(employee);
            refrescar();
        }
    }

    private void alternarAtivo() {
        Employee employee = funcionarioSelecionado();
        if (employee == null) {
            return;
        }
        employeeService.definirAtivo(employee, !employee.isAtivo());
        refrescar();
    }

    private void definirPin() {
        Employee employee = funcionarioSelecionado();
        if (employee == null) {
            return;
        }
        JPasswordField pin1 = new JPasswordField();
        JPasswordField pin2 = new JPasswordField();
        Object[] mensagem = {"Novo PIN (mín. 4 dígitos):", pin1, "Confirmar PIN:", pin2};
        int opcao = JOptionPane.showConfirmDialog(this, mensagem, "Definir PIN — " + employee.getNome(),
            JOptionPane.OK_CANCEL_OPTION);
        if (opcao != JOptionPane.OK_OPTION) {
            return;
        }
        String p1 = new String(pin1.getPassword());
        String p2 = new String(pin2.getPassword());
        if (!p1.equals(p2)) {
            JOptionPane.showMessageDialog(this, "Os PINs não coincidem", "Erro", JOptionPane.ERROR_MESSAGE);
            return;
        }
        try {
            employeeService.definirPin(employee, p1);
            refrescar();
        } catch (AssiduidadeException e) {
            JOptionPane.showMessageDialog(this, e.getMessage(), "Erro", JOptionPane.ERROR_MESSAGE);
        }
    }

    private void verQrCode() {
        Employee employee = funcionarioSelecionado();
        if (employee == null) {
            return;
        }
        new QrBadgeDialog(frame, employee).setVisible(true);
    }

    private void enrolarDigital() {
        Employee employee = funcionarioSelecionado();
        if (employee == null) {
            return;
        }
        int opcao = JOptionPane.showConfirmDialog(this,
            "Simular o registo da impressão digital de " + employee.getNome() + "?\n"
                + "(não existe leitora biométrica real integrada nesta aplicação)",
            "Enrolar digital (simulada)", JOptionPane.YES_NO_OPTION);
        if (opcao == JOptionPane.YES_OPTION) {
            employeeService.enrolarDigitalSimulada(employee);
            refrescar();
        }
    }

    private void associarNfc() {
        Employee employee = funcionarioSelecionado();
        if (employee == null) {
            return;
        }
        NfcEnrollDialog dialog = new NfcEnrollDialog(frame, employee);
        dialog.setVisible(true);
        if (dialog.isConfirmado()) {
            try {
                if (dialog.getUid().isBlank()) {
                    employeeService.removerNfc(employee);
                } else {
                    employeeService.associarNfc(employee, dialog.getUid());
                }
                refrescar();
            } catch (AssiduidadeException e) {
                JOptionPane.showMessageDialog(this, e.getMessage(), "Erro", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    private void sincronizarComErp() {
        if (!AppConfig.isApiSyncAtivo()) {
            JOptionPane.showMessageDialog(this,
                "Integração com o ERP não configurada (api.base.url / api.device.key em application.properties).",
                "Sincronizar ERP", JOptionPane.WARNING_MESSAGE);
            return;
        }
        new Thread(() -> {
            try {
                ErpSyncService.ResultadoSincronizacao resultado = erpSyncService.sincronizarFuncionarios();
                SwingUtilities.invokeLater(() -> {
                    refrescar();
                    JOptionPane.showMessageDialog(this,
                        "Sincronizado: " + resultado.total() + " funcionário(s) — "
                            + resultado.novos() + " novo(s), " + resultado.actualizados() + " actualizado(s).",
                        "Sincronizar ERP", JOptionPane.INFORMATION_MESSAGE);
                });
            } catch (Exception e) {
                SwingUtilities.invokeLater(() -> JOptionPane.showMessageDialog(this,
                    "Erro ao sincronizar com o ERP: " + e.getMessage(), "Erro", JOptionPane.ERROR_MESSAGE));
            }
        }, "erp-sync-funcionarios").start();
    }

    public void refrescar() {
        tableModel.setEmployees(employeeService.listar());
        registosHojePanel.refrescar();
        // Com a integração ligada, o ERP é autoritativo para nome/número/activo
        // (ver ErpSyncService) — criar esses campos aqui ficaria sempre substituído
        // pela próxima sincronização, por isso "Novo" deixa de fazer sentido; "Editar"
        // é escondido do mesmo modo dentro do EmployeeActionsDialog (ver abrirAcoes).
        novoButton.setVisible(!AppConfig.isApiSyncAtivo());
    }

    private static class EmployeeTableModel extends AbstractTableModel {
        private List<Employee> employees = List.of();

        void setEmployees(List<Employee> employees) {
            this.employees = employees;
            fireTableDataChanged();
        }

        Employee getEmployeeAt(int row) {
            return employees.get(row);
        }

        @Override
        public int getRowCount() {
            return employees.size();
        }

        @Override
        public int getColumnCount() {
            return COLUNAS.length;
        }

        @Override
        public String getColumnName(int column) {
            return COLUNAS[column];
        }

        @Override
        public Object getValueAt(int rowIndex, int columnIndex) {
            Employee employee = employees.get(rowIndex);
            return switch (columnIndex) {
                case 0 -> employee.getNumero();
                case 1 -> employee.getNome();
                case 2 -> employee.getDepartamento();
                case 3 -> employee.isAtivo() ? "Sim" : "Não";
                case 4 -> employee.getPinHash() != null ? "Sim" : "Não";
                case 5 -> employee.getFingerprintTemplate() != null ? "Sim" : "Não";
                case 6 -> employee.getNfcUid() != null ? "Sim" : "Não";
                default -> "";
            };
        }
    }
}
