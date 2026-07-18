package tech.omnisyserp.desktop;

import com.formdev.flatlaf.FlatLightLaf;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;
import tech.omnisyserp.desktop.auth.TokenStore;
import tech.omnisyserp.desktop.client.BackendApiClient;
import tech.omnisyserp.desktop.ui.LoginDialog;
import tech.omnisyserp.desktop.ui.MainFrame;

import javax.swing.*;

@SpringBootApplication
@Slf4j
public class OmnisysDesktopApp {

    public static void main(String[] args) {
        // Registrar handler global de exceções
        tech.omnisyserp.desktop.config.GlobalExceptionHandler.register();

        setupLookAndFeel();

        ConfigurableApplicationContext context = SpringApplication.run(OmnisysDesktopApp.class, args);

        SwingUtilities.invokeLater(() -> {
            try {
                BackendApiClient apiClient = context.getBean(BackendApiClient.class);
                TokenStore tokenStore = context.getBean(TokenStore.class);

                // 1. Tentar login silencioso via refresh token guardado no keychain do SO
                boolean autenticado = tentarLoginSilencioso(apiClient, tokenStore);

                // 2. Se falhou, mostrar dialogo de login normal
                if (!autenticado) {
                    LoginDialog loginDialog = new LoginDialog(apiClient, tokenStore);
                    loginDialog.setVisible(true);

                    if (!loginDialog.isAutenticado()) {
                        log.info("Login cancelado pelo utilizador. A encerrar.");
                        System.exit(0);
                        return;
                    }
                }

                // 3. Registar dispositivo se necessario
                try {
                    apiClient.registerDeviceIfNeeded();
                } catch (Exception e) {
                    log.warn("Falha ao registar dispositivo, a continuar: {}", e.getMessage());
                }

                // 4. Abrir janela principal
                var backendProperties = context.getBean(tech.omnisyserp.desktop.config.BackendProperties.class);
                MainFrame mainFrame = new MainFrame(
                        context.getBean(tech.omnisyserp.desktop.service.FuncionarioService.class),
                        context.getBean(tech.omnisyserp.desktop.service.AssiduidadeService.class),
                        context.getBean(tech.omnisyserp.desktop.service.CameraService.class),
                        tokenStore,
                        apiClient,
                        backendProperties);
                mainFrame.setVisible(true);
                log.info("OmnisysERP Desktop iniciado. Utilizador: {}",
                        tokenStore.getCurrentUser().getFull_name());

            } catch (Exception e) {
                log.error("Erro ao iniciar a interface grafica", e);
                JOptionPane.showMessageDialog(null,
                        "Erro ao iniciar a interface: " + e.getMessage(),
                        "Erro Critico",
                        JOptionPane.ERROR_MESSAGE);
                System.exit(1);
            }
        });
    }

    /**
     * Tenta restaurar a sessao usando o refresh token guardado no keychain do SO.
     * @return true se a sessao foi restaurada com sucesso
     */
    private static boolean tentarLoginSilencioso(BackendApiClient apiClient, TokenStore tokenStore) {
        String savedRefresh = tokenStore.loadSavedRefreshToken();
        if (savedRefresh == null) {
            return false;
        }



        log.info("Refresh token encontrado no keychain, a tentar login silencioso...");
        tokenStore.storeSilent(savedRefresh, tokenStore.loadSavedUser());

        if (apiClient.refreshToken()) {
            log.info("Login silencioso bem-sucedido. Utilizador: {}",
                    tokenStore.getCurrentUser() != null ? tokenStore.getCurrentUser().getFull_name() : "?");
            return true;
        }

        log.info("Login silencioso falhou (token expirado ou invalido), a mostrar dialogo de login.");
        tokenStore.clear();
        return false;
    }

    private static void setupLookAndFeel() {
        try {
            UIManager.setLookAndFeel(new FlatLightLaf());
            UIManager.put("Component.arrowType", "chevron");
            UIManager.put("Component.focusWidth", 2);
            UIManager.put("Button.arc", 6);
            UIManager.put("Component.arc", 6);
            UIManager.put("TabbedPane.arc", 6);
            log.info("FlatLaf configurado com sucesso");
        } catch (Exception e) {
            log.warn("Erro ao configurar FlatLaf, a usar look and feel padrao", e);
        }
    }
}
