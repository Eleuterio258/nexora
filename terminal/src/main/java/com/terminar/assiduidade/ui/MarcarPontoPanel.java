package com.terminar.assiduidade.ui;

import com.terminar.assiduidade.exception.AssiduidadeException;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.model.MetodoAutenticacao;
import com.terminar.assiduidade.model.TipoMarcacao;
import com.terminar.assiduidade.service.PontoService;
import net.miginfocom.swing.MigLayout;

import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import java.awt.Font;

/** Optimizado para um painel táctil pequeno (6,5", 200x200). */
public class MarcarPontoPanel extends JPanel {

    private final AssiduidadeFrame frame;
    private final PontoService pontoService = new PontoService();

    private final JLabel nomeLabel = new JLabel("", SwingConstants.CENTER);
    private final JLabel detalheLabel = new JLabel("", SwingConstants.CENTER);
    private final JLabel tipoSugeridoLabel = new JLabel("", SwingConstants.CENTER);

    private Employee employeeAtual;
    private MetodoAutenticacao metodoAtual;

    public MarcarPontoPanel(AssiduidadeFrame frame) {
        this.frame = frame;
        setLayout(new MigLayout("fill, insets 3, gap 1", "[grow, center]", "[]1[]1[]1[grow]1[]"));

        nomeLabel.setFont(nomeLabel.getFont().deriveFont(Font.BOLD, UiScale.f(10f)));
        add(nomeLabel, "wrap");

        detalheLabel.setFont(detalheLabel.getFont().deriveFont(UiScale.f(7f)));
        add(detalheLabel, "wrap");

        tipoSugeridoLabel.setFont(tipoSugeridoLabel.getFont().deriveFont(Font.BOLD, UiScale.f(12f)));
        add(tipoSugeridoLabel, "wrap");

        JPanel opcoes = new JPanel(new MigLayout("insets 0, gap 1", "[grow,fill][grow,fill]", "[grow,fill]1[grow,fill]"));
        for (TipoMarcacao tipo : TipoMarcacao.values()) {
            JButton botao = new JButton(rotuloCurto(tipo));
            botao.setFont(botao.getFont().deriveFont(Font.BOLD, UiScale.f(7f)));
            botao.setMargin(new java.awt.Insets(0, 0, 0, 0));
            botao.addActionListener(e -> confirmar(tipo));
            opcoes.add(botao);
        }
        add(opcoes, "grow, wrap");

        JButton cancelar = new JButton("Cancelar");
        cancelar.setFont(cancelar.getFont().deriveFont(UiScale.f(8f)));
        cancelar.setMargin(new java.awt.Insets(0, 2, 0, 2));
        cancelar.addActionListener(e -> frame.goHome());
        add(cancelar);
    }

    public void exibir(Employee employee, MetodoAutenticacao metodo) {
        this.employeeAtual = employee;
        this.metodoAtual = metodo;
        nomeLabel.setText(employee.getNome());
        detalheLabel.setText("Nº " + employee.getNumero());
        TipoMarcacao sugerido = pontoService.determineNextTipo(employee.getId());
        tipoSugeridoLabel.setText(rotulo(sugerido));
    }

    private void confirmar(TipoMarcacao tipo) {
        try {
            pontoService.registarMarcacao(employeeAtual, tipo, metodoAtual);
            frame.goToResult(employeeAtual.getNome() + " — " + rotulo(tipo) + " registada com sucesso", true);
        } catch (AssiduidadeException e) {
            frame.goToResult(e.getMessage(), false);
        }
    }

    private String rotulo(TipoMarcacao tipo) {
        return switch (tipo) {
            case ENTRADA -> "Entrada";
            case SAIDA -> "Saída";
            case INICIO_PAUSA -> "Início de Pausa";
            case FIM_PAUSA -> "Fim de Pausa";
        };
    }

    private String rotuloCurto(TipoMarcacao tipo) {
        return switch (tipo) {
            case ENTRADA -> "Entrada";
            case SAIDA -> "Saída";
            case INICIO_PAUSA -> "Iníc. Pausa";
            case FIM_PAUSA -> "Fim Pausa";
        };
    }
}
