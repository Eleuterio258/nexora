package com.factpro.ui.charts;

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.PiePlot;
import org.jfree.chart.plot.RingPlot;
import org.jfree.chart.ui.ApplicationFrame;
import org.jfree.data.general.DefaultPieDataset;
import org.jfree.data.general.DefaultCategoryDataset;
import org.jfree.chart.ChartUtils;

import java.awt.*;
import java.io.File;
import java.io.IOException;
import java.util.Map;

/**
 * Utilitario para criacao de graficos.
 */
public class ChartUtils {

    /**
     * Cria grafico de pizza (pie chart).
     */
    public static ChartPanel createPieChart(String title, Map<String, Integer> data) {
        DefaultPieDataset dataset = new DefaultPieDataset();
        data.forEach(dataset::setValue);

        JFreeChart chart = ChartFactory.createPieChart(
            title,
            dataset,
            true,
            true,
            false
        );

        // Customizacao
        PiePlot plot = (PiePlot) chart.getPlot();
        plot.setSectionPaint("SUCESSO", new Color(40, 167, 69));
        plot.setSectionPaint("NEGADO", new Color(220, 53, 69));
        plot.setLabelFont(new Font("Segoe UI", Font.PLAIN, 11));
        plot.setNoDataMessage("Sem dados disponiveis");
        plot.setCircular(true);
        plot.setLabelGap(0.02);

        ChartPanel chartPanel = new ChartPanel(chart);
        chartPanel.setPreferredSize(new Dimension(400, 300));
        return chartPanel;
    }

    /**
     * Cria grafico de anel (ring chart) - mais moderno.
     */
    public static ChartPanel createRingChart(String title, Map<String, Integer> data) {
        DefaultPieDataset dataset = new DefaultPieDataset();
        data.forEach(dataset::setValue);

        JFreeChart chart = ChartFactory.createRingChart(
            title,
            dataset,
            true,
            true,
            false
        );

        RingPlot plot = (RingPlot) chart.getPlot();
        plot.setSectionDepth(0.35);
        plot.setSeparation(0.02);
        plot.setLabelFont(new Font("Segoe UI", Font.PLAIN, 11));
        plot.setNoDataMessage("Sem dados disponiveis");

        ChartPanel chartPanel = new ChartPanel(chart);
        chartPanel.setPreferredSize(new Dimension(400, 300));
        return chartPanel;
    }

    /**
     * Cria grafico de barras.
     */
    public static ChartPanel createBarChart(String title, String categoryLabel, 
                                             String valueLabel, Map<String, Integer> data) {
        DefaultCategoryDataset dataset = new DefaultCategoryDataset();
        data.forEach((key, value) -> dataset.addValue(value, "Dados", key));

        JFreeChart chart = ChartFactory.createBarChart(
            title,
            categoryLabel,
            valueLabel,
            dataset,
            org.jfree.chart.plot.PlotOrientation.VERTICAL,
            true,
            true,
            false
        );

        ChartPanel chartPanel = new ChartPanel(chart);
        chartPanel.setPreferredSize(new Dimension(500, 300));
        return chartPanel;
    }

    /**
     * Exporta grafico para arquivo de imagem.
     */
    public static void exportChartAsImage(ChartPanel chartPanel, File file, 
                                          int width, int height) throws IOException {
        ChartUtils.saveChartAsPNG(file, chartPanel.getChart(), width, height);
    }
}
