package com.factpro;

import com.formdev.flatlaf.FlatDarkLaf;
import com.formdev.flatlaf.FlatLightLaf;
import com.formdev.flatlaf.FlatLaf;
import com.factpro.config.AppConfig;
import com.factpro.core.database.DatabaseManager;
import com.factpro.core.database.DatabaseMigration;
import com.factpro.auth.SessionManager;
import com.factpro.notificacoes.service.NotificationEventListener;
import com.factpro.ui.MainFrame;
import com.factpro.ui.LoginDialog;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;

/**
 * Ponto de entrada principal da aplicação FactPro.
 * 
 * @author FactPro Team
 * @version 1.0.0
 */
public class FactProApplication {
    
    private static final Logger logger = LoggerFactory.getLogger(FactProApplication.class);
    private static MainFrame mainFrame;
    private static LoginDialog loginDialog;
    
    public static void main(String[] args) {
        // Set look and feel - FlatLaf
        FlatLightLaf.setup();
        
        logger.info("=== FactPro Desktop v{} ===", "1.0.0");
        logger.info("Inicializando aplicação...");
        
        // Run database migrations
        try {
            DatabaseMigration.runMigrations();
            logger.info("Migrações da base de dados concluídas");
        } catch (Exception e) {
            logger.error("Erro ao executar migrações", e);
            JOptionPane.showMessageDialog(null,
                "Erro ao inicializar base de dados:\n" + e.getMessage(),
                "Erro Crítico - FactPro",
                JOptionPane.ERROR_MESSAGE);
            System.exit(1);
        }
        
        // Start application on EDT (Event Dispatch Thread)
        SwingUtilities.invokeLater(() -> {
            try {
                // Check if user is already authenticated
                if (SessionManager.getInstance().isAuthenticated()) {
                    showMainWindow();
                } else {
                    showLoginWindow();
                }
            } catch (Exception e) {
                logger.error("Erro ao inicializar interface", e);
                JOptionPane.showMessageDialog(null,
                    "Erro ao inicializar aplicação:\n" + e.getMessage(),
                    "Erro Crítico - FactPro",
                    JOptionPane.ERROR_MESSAGE);
                System.exit(1);
            }
        });
        
        // Shutdown hook - cleanup on exit
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            logger.info("Encerrando FactPro...");
            DatabaseManager.getInstance().close();
            AppConfig.getInstance().save();
            logger.info("FactPro encerrado com sucesso");
        }));
    }
    
    /**
     * Exibe a janela de login.
     */
    private static void showLoginWindow() {
        loginDialog = new LoginDialog();
        loginDialog.setVisible(true);
        
        // After successful login, show main window
        if (loginDialog.isLoginSuccessful()) {
            loginDialog.dispose();
            registerNotificationListeners();
            showMainWindow();
        } else {
            // User closed login without success
            System.exit(0);
        }
    }
    
    /**
     * Regista listeners de notificacoes apos login.
     */
    private static void registerNotificationListeners() {
        try {
            NotificationEventListener listener = new NotificationEventListener();
            listener.registerListeners();
            logger.info("Listeners de notificacoes inicializados");
        } catch (Exception e) {
            logger.error("Erro ao registar listeners de notificacoes", e);
        }
    }

    /**
     * Exibe a janela principal da aplicação.
     */
    private static void showMainWindow() {
        mainFrame = new MainFrame();
        mainFrame.setVisible(true);
        mainFrame.setExtendedState(JFrame.MAXIMIZED_BOTH);
        logger.info("Janela principal exibida para utilizador: {}", 
            SessionManager.getInstance().getCurrentUserName());
    }
    
    /**
     * Reinicia a aplicação (volta para login).
     */
    public static void restart() {
        if (mainFrame != null) mainFrame.dispose();
        if (loginDialog != null) loginDialog.dispose();
        
        SessionManager.getInstance().logout();
        showLoginWindow();
    }
    
    /**
     * Alterna entre tema claro e escuro.
     */
    public static void toggleTheme() {
        boolean isDark = AppConfig.getInstance().isDarkTheme();
        
        if (isDark) {
            FlatLightLaf.setup();
            AppConfig.getInstance().setDarkTheme(false);
        } else {
            FlatDarkLaf.setup();
            AppConfig.getInstance().setDarkTheme(true);
        }
        
        FlatLaf.updateUI();
    }
    
    /**
     * Fecha a aplicação.
     */
    public static void exit() {
        int confirm = JOptionPane.showConfirmDialog(null,
            "Deseja realmente sair do FactPro?",
            "Confirmar Saída",
            JOptionPane.YES_NO_OPTION,
            JOptionPane.QUESTION_MESSAGE);
        
        if (confirm == JOptionPane.YES_OPTION) {
            System.exit(0);
        }
    }
    
    public static MainFrame getMainFrame() {
        return mainFrame;
    }
}
