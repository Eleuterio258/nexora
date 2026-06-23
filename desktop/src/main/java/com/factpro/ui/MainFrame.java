package com.factpro.ui;

import com.factpro.FactProApplication;
import com.factpro.auth.SessionManager;
import com.factpro.compras.view.CompraListPanel;
import com.factpro.fornecedores.view.FornecedorListPanel;
import com.factpro.stock.view.StockPanel;
import com.factpro.vendas.view.DashboardPanel;
import com.factpro.vendas.view.POSPanel;
import com.factpro.vendas.view.VendaListPanel;
import com.factpro.produtos.view.ProdutoListPanel;
import com.factpro.clientes.view.ClienteListPanel;
import com.formdev.flatlaf.FlatClientProperties;

import javax.swing.*;
import java.awt.*;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;

/**
 * Janela principal da aplicacao FactPro.
 * Contem sidebar, area de conteudo com CardLayout, e barra de status.
 */
public class MainFrame extends JFrame {

    private SidebarPanel sidebarPanel;
    private JPanel contentPanel;
    private CardLayout cardLayout;
    private StatusBarPanel statusBarPanel;

    // Panel references for lazy loading
    private JPanel dashboardPanel;
    private JPanel posPanel;
    private JPanel vendasPanel;
    private JPanel produtosPanel;
    private JPanel clientesPanel;
    private JPanel stockPanel;
    private JPanel comprasPanel;
    private JPanel fornecedoresPanel;
    private JPanel relatoriosPanel;
    private JPanel configuracoesPanel;

    public MainFrame() {
        setTitle("FactPro - Sistema de Faturacao v1.0.0");
        setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
        setMinimumSize(new Dimension(1280, 720));
        setLocationRelativeTo(null);

        initComponents();
        setupLayout();
        setupMenuBar();
        setupListeners();
        
        // Refresh sidebar permissions after frame is initialized
        sidebarPanel.refreshButtonVisibility();
    }

    private void initComponents() {
        sidebarPanel = new SidebarPanel();

        cardLayout = new CardLayout();
        contentPanel = new JPanel(cardLayout);

        // Add placeholder panels for each view
        String[] views = {"Dashboard", "POS", "Vendas", "Produtos", "Clientes", "Stock", "Compras", "Fornecedores", "Relatorios", "Configuracoes"};
        for (String view : views) {
            contentPanel.add(createPlaceholderPanel(view), view);
        }

        statusBarPanel = new StatusBarPanel();
    }

    private JPanel createPlaceholderPanel(String viewName) {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBackground(new Color(245, 245, 245));

        JLabel label = new JLabel(viewName, SwingConstants.CENTER);
        label.setFont(label.getFont().deriveFont(Font.BOLD, 28f));
        label.setForeground(new Color(150, 150, 150));
        panel.add(label, BorderLayout.CENTER);

        JLabel subLabel = new JLabel("Modulo " + viewName + " - Em desenvolvimento");
        subLabel.setFont(subLabel.getFont().deriveFont(Font.PLAIN, 14f));
        subLabel.setForeground(new Color(180, 180, 180));
        subLabel.setHorizontalAlignment(SwingConstants.CENTER);
        panel.add(subLabel, BorderLayout.SOUTH);

        return panel;
    }

    private void setupLayout() {
        setLayout(new BorderLayout());

        // Left sidebar
        add(sidebarPanel, BorderLayout.WEST);

        // Center content
        add(contentPanel, BorderLayout.CENTER);

        // Bottom status bar
        add(statusBarPanel, BorderLayout.SOUTH);
    }

    private void setupMenuBar() {
        JMenuBar menuBar = new JMenuBar();

        // File menu
        JMenu fileMenu = new JMenu("Ficheiro");
        fileMenu.setMnemonic('F');

        JMenuItem exitItem = new JMenuItem("Sair");
        exitItem.setMnemonic('S');
        exitItem.setAccelerator(KeyStroke.getKeyStroke('F', java.awt.event.InputEvent.ALT_DOWN_MASK));
        exitItem.addActionListener(e -> FactProApplication.exit());
        fileMenu.add(exitItem);

        // View menu
        JMenu viewMenu = new JMenu("Ver");
        viewMenu.setMnemonic('V');

        JMenuItem themeToggleItem = new JMenuItem("Alternar Tema Escuro/Claro");
        themeToggleItem.setMnemonic('T');
        themeToggleItem.setAccelerator(KeyStroke.getKeyStroke('T', java.awt.event.InputEvent.CTRL_DOWN_MASK));
        themeToggleItem.addActionListener(e -> FactProApplication.toggleTheme());
        viewMenu.add(themeToggleItem);

        // Refresh permissions
        JMenuItem refreshPermsItem = new JMenuItem("Atualizar Permissoes");
        refreshPermsItem.setMnemonic('A');
        refreshPermsItem.setAccelerator(KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_F5, 0));
        refreshPermsItem.addActionListener(e -> refreshPermissions());
        viewMenu.add(refreshPermsItem);

        // Help menu
        JMenu helpMenu = new JMenu("Ajuda");
        helpMenu.setMnemonic('A');

        JMenuItem aboutItem = new JMenuItem("Sobre");
        aboutItem.setMnemonic('S');
        aboutItem.addActionListener(e -> showAboutDialog());
        helpMenu.add(aboutItem);

        menuBar.add(fileMenu);
        menuBar.add(viewMenu);
        menuBar.add(helpMenu);

        setJMenuBar(menuBar);
    }

    private void setupListeners() {
        // Sidebar navigation - load panels lazily
        setupNavigation("Dashboard", e -> showPanel("Dashboard", this::getDashboardPanel));
        setupNavigation("POS", e -> showPanel("POS", this::getPOSPanel));
        setupNavigation("Vendas", e -> showPanel("Vendas", this::getVendasPanel));
        setupNavigation("Produtos", e -> showPanel("Produtos", this::getProdutosPanel));
        setupNavigation("Clientes", e -> showPanel("Clientes", this::getClientesPanel));
        setupNavigation("Stock", e -> showPanel("Stock", this::getStockPanel));
        setupNavigation("Compras", e -> showPanel("Compras", this::getComprasPanel));
        setupNavigation("Fornecedores", e -> showPanel("Fornecedores", this::getFornecedoresPanel));
        setupNavigation("Relatorios", e -> showPanel("Relatorios", this::getRelatoriosPanel));
        setupNavigation("Configuracoes", e -> showPanel("Configuracoes", this::getConfiguracoesPanel));

        // Handle window close
        addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                FactProApplication.exit();
            }
        });
    }

    private void setupNavigation(String viewName, java.awt.event.ActionListener action) {
        sidebarPanel.addButtonAction(viewName, action);
    }

    private void showPanel(String viewName, java.util.function.Supplier<JPanel> panelSupplier) {
        JPanel panel = panelSupplier.get();
        // Check if we need to replace the placeholder
        Component existing = null;
        for (Component comp : contentPanel.getComponents()) {
            if (comp.getName() != null && comp.getName().equals(viewName)) {
                existing = comp;
                break;
            }
        }

        // If the current component is a placeholder, replace it
        if (existing != null && existing == contentPanel.getComponent(0)) {
            // Find if it's actually a placeholder
            String placeholderText = findPlaceholderText(existing);
            if (placeholderText != null && placeholderText.equals(viewName)) {
                contentPanel.remove(existing);
                panel.setName(viewName);
                contentPanel.add(panel, viewName);
            }
        }

        // Also try direct approach - just ensure panel is in cardLayout
        boolean found = false;
        for (Component comp : contentPanel.getComponents()) {
            if (comp == panel) {
                found = true;
                break;
            }
        }
        if (!found) {
            panel.setName(viewName);
            contentPanel.add(panel, viewName);
        }

        cardLayout.show(contentPanel, viewName);
        refreshStatusBar();
    }

    private String findPlaceholderText(Component comp) {
        if (comp instanceof JPanel panel) {
            for (Component child : panel.getComponents()) {
                if (child instanceof JLabel label) {
                    return label.getText();
                }
            }
        }
        return null;
    }

    private JPanel getDashboardPanel() {
        if (dashboardPanel == null) {
            dashboardPanel = new DashboardPanel();
            dashboardPanel.setName("Dashboard");
            replacePlaceholder("Dashboard", dashboardPanel);
        }
        return dashboardPanel;
    }

    private JPanel getPOSPanel() {
        if (posPanel == null) {
            posPanel = new POSPanel();
            posPanel.setName("POS");
            replacePlaceholder("POS", posPanel);
        }
        return posPanel;
    }

    private JPanel getVendasPanel() {
        if (vendasPanel == null) {
            vendasPanel = new VendaListPanel();
            vendasPanel.setName("Vendas");
            replacePlaceholder("Vendas", vendasPanel);
        }
        return vendasPanel;
    }

    private JPanel getProdutosPanel() {
        if (produtosPanel == null) {
            produtosPanel = new ProdutoListPanel();
            produtosPanel.setName("Produtos");
            replacePlaceholder("Produtos", produtosPanel);
        }
        return produtosPanel;
    }

    private JPanel getClientesPanel() {
        if (clientesPanel == null) {
            clientesPanel = new ClienteListPanel();
            clientesPanel.setName("Clientes");
            replacePlaceholder("Clientes", clientesPanel);
        }
        return clientesPanel;
    }

    private JPanel getStockPanel() {
        if (stockPanel == null) {
            stockPanel = new StockPanel();
            stockPanel.setName("Stock");
            replacePlaceholder("Stock", stockPanel);
        }
        return stockPanel;
    }

    private JPanel getComprasPanel() {
        if (comprasPanel == null) {
            comprasPanel = new CompraListPanel();
            comprasPanel.setName("Compras");
            replacePlaceholder("Compras", comprasPanel);
        }
        return comprasPanel;
    }

    private JPanel getFornecedoresPanel() {
        if (fornecedoresPanel == null) {
            fornecedoresPanel = new FornecedorListPanel();
            fornecedoresPanel.setName("Fornecedores");
            replacePlaceholder("Fornecedores", fornecedoresPanel);
        }
        return fornecedoresPanel;
    }

    private JPanel getRelatoriosPanel() {
        if (relatoriosPanel == null) {
            relatoriosPanel = createPlaceholderPanel("Relatorios");
            relatoriosPanel.setName("Relatorios");
            replacePlaceholder("Relatorios", relatoriosPanel);
        }
        return relatoriosPanel;
    }

    private JPanel getConfiguracoesPanel() {
        if (configuracoesPanel == null) {
            configuracoesPanel = createPlaceholderPanel("Configuracoes");
            configuracoesPanel.setName("Configuracoes");
            replacePlaceholder("Configuracoes", configuracoesPanel);
        }
        return configuracoesPanel;
    }

    private void replacePlaceholder(String viewName, JPanel newPanel) {
        // Remove the old placeholder if it exists
        Component toRemove = null;
        for (Component comp : contentPanel.getComponents()) {
            if (comp.getName() != null && comp.getName().equals(viewName)) {
                // Check if it's a placeholder (not yet replaced)
                if (comp != newPanel) {
                    toRemove = comp;
                }
                break;
            }
        }
        if (toRemove != null) {
            contentPanel.remove(toRemove);
        }
        contentPanel.add(newPanel, viewName);
    }

    private void showAboutDialog() {
        JOptionPane.showMessageDialog(this,
                "<html><body style='width: 300px; text-align: center;'>"
                        + "<h2>FactPro</h2>"
                        + "<p><b>Sistema de Faturacao e Vendas</b></p>"
                        + "<p>Versao: 1.0.0</p>"
                        + "<p>Desktop Application</p>"
                        + "<hr>"
                        + "<p>Desenvolvido com Java 17 + Swing + FlatLaf</p>"
                        + "<p>(c) 2026 FactPro Team</p>"
                        + "</body></html>",
                "Sobre o FactPro",
                JOptionPane.INFORMATION_MESSAGE);
    }

    public void refreshStatusBar() {
        if (statusBarPanel != null) {
            statusBarPanel.refresh();
        }
    }

    /**
     * Atualiza permissoes do utilizador em tempo real.
     */
    private void refreshPermissions() {
        SessionManager.getInstance().refreshPermissions();
        
        // Refresh sidebar visibility
        sidebarPanel.refreshButtonVisibility();
        
        JOptionPane.showMessageDialog(this,
            "Permissoes atualizadas com sucesso!",
            "Permissoes Atualizadas",
            JOptionPane.INFORMATION_MESSAGE);
    }

    public SidebarPanel getSidebarPanel() {
        return sidebarPanel;
    }

    public StatusBarPanel getStatusBarPanel() {
        return statusBarPanel;
    }
}
