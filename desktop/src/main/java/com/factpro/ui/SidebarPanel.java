package com.factpro.ui;

import com.factpro.auth.SessionManager;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionListener;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Painel lateral esquerdo com botoes de navegacao.
 * Usa BoxLayout vertical e destaca o botao ativo.
 * Suporta filtragem por permissoes baseadas no role do utilizador.
 */
public class SidebarPanel extends JPanel {

    private final Map<String, JButton> buttons = new LinkedHashMap<>();
    private final Map<String, String[]> buttonPermissions = new LinkedHashMap<>();
    private String activeView = "Dashboard";

    private final Color activeBackground = new Color(57, 113, 227);
    private final Color activeForeground = Color.WHITE;
    private final Color inactiveBackground = new Color(43, 43, 43);
    private final Color inactiveForeground = new Color(187, 187, 187);
    private final Color hoverBackground = new Color(60, 60, 60);

    public SidebarPanel() {
        setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
        setBackground(new Color(43, 43, 43));
        setPreferredSize(new Dimension(200, getPreferredSize().height));
        setBorder(BorderFactory.createEmptyBorder(10, 8, 10, 8));

        initializeButtons();
        layoutButtons();
    }

    private void initializeButtons() {
        // Define navigation buttons with unicode icons and required permissions
        // Permission format: "menu:<name>" (at least one required)
        String[][] items = {
                {"Dashboard", "\uD83D\uDCCA", "menu:dashboard"},
                {"POS", "\uD83D\uDED2", "menu:pos"},
                {"Vendas", "\uD83D\uDCB0", "menu:vendas"},
                {"Produtos", "\uD83D\uDCE6", "menu:produtos"},
                {"Clientes", "\uD83D\uDC65", "menu:clientes"},
                {"Stock", "\uD83D\uDCE3", "menu:stock"},
                {"Compras", "\uD83D\uDCD6", "menu:compras"},
                {"Fornecedores", "\uD83C\uDE5A", "menu:fornecedores"},
                {"ContasReceber", "\uD83D\uDCB3", "menu:contas_receber"},
                {"Notificacoes", "\uD83D\uDD14", "menu:notificacoes"},
                {"Relatorios", "\uD83D\uDCC8", "menu:relatorios"},
                {"Configuracoes", "\u2699\uFE0F", "menu:configuracoes"}
        };

        for (String[] item : items) {
            String name = item[0];
            String icon = item[1];
            String permission = item[2];
            JButton button = createNavButton(icon + "  " + name, name);
            buttons.put(name, button);
            buttonPermissions.put(name, new String[]{permission});
        }

        // Set initial active state
        setActiveView("Dashboard");
    }

    private JButton createNavButton(String text, String viewName) {
        JButton button = new JButton(text);
        button.setAlignmentX(Component.LEFT_ALIGNMENT);
        button.setMaximumSize(new Dimension(Integer.MAX_VALUE, 45));
        button.setHorizontalAlignment(SwingConstants.LEFT);
        button.setFocusPainted(false);
        button.setBorderPainted(false);
        button.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        button.setFont(button.getFont().deriveFont(Font.PLAIN, 14f));

        // Set initial inactive styling
        button.setBackground(inactiveBackground);
        button.setForeground(inactiveForeground);

        // Hover effect
        button.addMouseListener(new java.awt.event.MouseAdapter() {
            @Override
            public void mouseEntered(java.awt.event.MouseEvent e) {
                if (!viewName.equals(activeView)) {
                    button.setBackground(hoverBackground);
                }
            }

            @Override
            public void mouseExited(java.awt.event.MouseEvent e) {
                if (!viewName.equals(activeView)) {
                    button.setBackground(inactiveBackground);
                }
            }
        });

        return button;
    }

    private void layoutButtons() {
        // Add a title/header
        JLabel headerLabel = new JLabel("FactPro");
        headerLabel.setFont(headerLabel.getFont().deriveFont(Font.BOLD, 18f));
        headerLabel.setForeground(Color.WHITE);
        headerLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
        headerLabel.setBorder(BorderFactory.createEmptyBorder(0, 10, 20, 0));
        add(headerLabel);

        // Add separator
        JSeparator separator = new JSeparator();
        separator.setMaximumSize(new Dimension(Integer.MAX_VALUE, 1));
        separator.setBackground(new Color(70, 70, 70));
        add(separator);
        add(Box.createVerticalStrut(10));

        // Add all buttons (will be filtered by permissions)
        refreshButtonVisibility();
        
        for (Map.Entry<String, JButton> entry : buttons.entrySet()) {
            add(entry.getValue());
            add(Box.createVerticalStrut(2));
        }

        // Add glue to push everything to the top
        add(Box.createVerticalGlue());
    }

    /**
     * Filtra botoes visiveis baseado nas permissoes do utilizador.
     */
    public void refreshButtonVisibility() {
        SessionManager session = SessionManager.getInstance();
        
        // If not authenticated or no permissions, show all buttons (fallback)
        if (!session.isAuthenticated() || session.getUserPermissions() == null) {
            buttons.values().forEach(btn -> btn.setVisible(true));
            return;
        }
        
        // Filter buttons based on permissions
        for (Map.Entry<String, String[]> entry : buttonPermissions.entrySet()) {
            String buttonName = entry.getKey();
            String[] requiredPermissions = entry.getValue();
            JButton button = buttons.get(buttonName);
            
            if (button != null) {
                boolean hasAccess = session.hasAnyPermission(requiredPermissions);
                button.setVisible(hasAccess);
            }
        }
    }

    /**
     * Define a view ativa e destaca o botao correspondente.
     */
    public void setActiveView(String viewName) {
        String previousActive = this.activeView;
        this.activeView = viewName;

        // Update styling for all buttons
        for (Map.Entry<String, JButton> entry : buttons.entrySet()) {
            JButton btn = entry.getValue();
            if (entry.getKey().equals(viewName)) {
                btn.setBackground(activeBackground);
                btn.setForeground(activeForeground);
                btn.setFont(btn.getFont().deriveFont(Font.BOLD, 14f));
            } else {
                btn.setBackground(inactiveBackground);
                btn.setForeground(inactiveForeground);
                btn.setFont(btn.getFont().deriveFont(Font.PLAIN, 14f));
            }
        }
    }

    /**
     * Adiciona um ActionListener a um botao especifico.
     */
    public void addButtonAction(String viewName, ActionListener action) {
        JButton button = buttons.get(viewName);
        if (button != null) {
            button.addActionListener(e -> {
                setActiveView(viewName);
                action.actionPerformed(e);
            });
        }
    }

    public String getActiveView() {
        return activeView;
    }
}
