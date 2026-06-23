package com.factpro.configuracoes.view;

import com.factpro.config.AppConfig;
import com.factpro.core.database.DatabaseManager;
import com.formdev.flatlaf.FlatClientProperties;

import javax.swing.*;
import java.awt.*;

/**
 * About dialog for FactPro application.
 */
public class SobreDialog extends JDialog {

    public SobreDialog(Frame parent) {
        super(parent, "Sobre - FactPro", true);
        initComponents();
        setupLayout();
        setSize(420, 340);
        setLocationRelativeTo(parent);
        setResizable(false);
    }

    private JLabel logoLabel;
    private JLabel versionLabel;
    private JLabel descLabel;
    private JLabel copyrightLabel;
    private JLabel javaLabel;
    private JLabel dbLabel;
    private JButton closeButton;

    private void initComponents() {
        logoLabel = new JLabel("FactPro Desktop");
        logoLabel.putClientProperty(FlatClientProperties.STYLE_CLASS, "h1");
        logoLabel.setHorizontalAlignment(SwingConstants.CENTER);

        versionLabel = new JLabel("Versão: 1.0.0");
        versionLabel.setHorizontalAlignment(SwingConstants.CENTER);

        descLabel = new JLabel("Sistema de Faturação e Vendas");
        descLabel.setHorizontalAlignment(SwingConstants.CENTER);
        descLabel.setForeground(new Color(100, 100, 100));

        copyrightLabel = new JLabel("\u00a9 2026 FactPro Lda");
        copyrightLabel.setHorizontalAlignment(SwingConstants.CENTER);

        javaLabel = new JLabel("Java: " + System.getProperty("java.version"));
        javaLabel.setHorizontalAlignment(SwingConstants.CENTER);
        javaLabel.setForeground(new Color(100, 100, 100));

        try {
            String dbType = DatabaseManager.getInstance().getType().toString();
            dbLabel = new JLabel("Base de Dados: " + dbType);
        } catch (Exception e) {
            dbLabel = new JLabel("Base de Dados: (indispon\u00edvel)");
        }
        dbLabel.setHorizontalAlignment(SwingConstants.CENTER);
        dbLabel.setForeground(new Color(100, 100, 100));

        closeButton = new JButton("Fechar");
        closeButton.addActionListener(e -> dispose());
    }

    private void setupLayout() {
        setLayout(new BorderLayout(10, 10));

        JPanel centerPanel = new JPanel();
        centerPanel.setLayout(new BoxLayout(centerPanel, BoxLayout.Y_AXIS));
        centerPanel.setBorder(BorderFactory.createEmptyBorder(20, 20, 10, 20));

        centerPanel.add(logoLabel);
        centerPanel.add(Box.createVerticalStrut(6));
        centerPanel.add(versionLabel);
        centerPanel.add(Box.createVerticalStrut(4));
        centerPanel.add(descLabel);
        centerPanel.add(Box.createVerticalStrut(10));
        centerPanel.add(copyrightLabel);
        centerPanel.add(Box.createVerticalStrut(6));
        centerPanel.add(javaLabel);
        centerPanel.add(Box.createVerticalStrut(4));
        centerPanel.add(dbLabel);

        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.CENTER));
        buttonPanel.setBorder(BorderFactory.createEmptyBorder(0, 10, 15, 10));
        buttonPanel.add(closeButton);

        add(centerPanel, BorderLayout.CENTER);
        add(buttonPanel, BorderLayout.SOUTH);

        getRootPane().setDefaultButton(closeButton);
    }
}
