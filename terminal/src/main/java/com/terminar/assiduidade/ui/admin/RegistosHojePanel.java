package com.terminar.assiduidade.ui.admin;

import com.terminar.assiduidade.model.RegistoPonto;
import com.terminar.assiduidade.service.PontoService;
import net.miginfocom.swing.MigLayout;

import javax.swing.JButton;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.table.AbstractTableModel;
import java.time.format.DateTimeFormatter;
import java.util.List;

public class RegistosHojePanel extends javax.swing.JPanel {

    private static final DateTimeFormatter HORA_FMT = DateTimeFormatter.ofPattern("HH:mm:ss");
    private static final String[] COLUNAS = {"Hora", "Nº", "Nome", "Tipo", "Método"};

    private final PontoService pontoService = new PontoService();
    private final RegistosTableModel tableModel = new RegistosTableModel();

    public RegistosHojePanel() {
        setLayout(new MigLayout("fill, insets 2", "[grow]", "[]2[grow]"));

        JButton atualizarButton = new JButton("Actualizar");
        atualizarButton.addActionListener(e -> refrescar());
        add(atualizarButton, "wrap");

        JTable table = new JTable(tableModel);
        add(new JScrollPane(table), "grow");
    }

    public void refrescar() {
        tableModel.setRegistos(pontoService.registosDeHoje());
    }

    private class RegistosTableModel extends AbstractTableModel {
        private List<RegistoPonto> registos = List.of();

        void setRegistos(List<RegistoPonto> registos) {
            this.registos = registos;
            fireTableDataChanged();
        }

        @Override
        public int getRowCount() {
            return registos.size();
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
            RegistoPonto r = registos.get(rowIndex);
            return switch (columnIndex) {
                case 0 -> r.getDataHora().format(HORA_FMT);
                case 1 -> r.getEmployeeNumero();
                case 2 -> r.getEmployeeNome();
                case 3 -> r.getTipo();
                case 4 -> r.getMetodo();
                default -> "";
            };
        }
    }
}
