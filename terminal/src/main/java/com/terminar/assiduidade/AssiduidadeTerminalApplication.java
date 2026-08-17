package com.terminar.assiduidade;

import com.formdev.flatlaf.FlatDarkLaf;
import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.dao.ConfiguracaoDao;
import com.terminar.assiduidade.service.ErpSyncService;
import com.terminar.assiduidade.ui.AssiduidadeFrame;
import com.terminar.assiduidade.util.DatabaseManager;
import lombok.extern.slf4j.Slf4j;

import javax.swing.*;

@Slf4j
public class   AssiduidadeTerminalApplication {

    public static void main(String[] args) {
        System.setProperty("flatlaf.useWindowDecorations", "true");
        FlatDarkLaf.setup();

        SwingUtilities.invokeLater(() -> {
            try {
                AppConfig.load();
                DatabaseManager.initialize();
                aplicarConfiguracaoGuardada();
                new ErpSyncService().iniciarCicloAutomatico();
                Runtime.getRuntime().addShutdownHook(
                    new Thread(DatabaseManager::shutdown, "database-shutdown"));
                UIManager.setLookAndFeel(new FlatDarkLaf());
                JFrame.setDefaultLookAndFeelDecorated(true);
                new AssiduidadeFrame().setVisible(true);
                log.info("Terminar Assiduidade iniciado.");
            } catch (Exception e) {
                log.error("Erro ao iniciar aplicação", e);
                JOptionPane.showMessageDialog(null,
                    "Erro ao iniciar: " + e.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
            }
        });
    }

    /** Definições gravadas via ecrã "Configurações" do admin sobrepõem-se a application.properties. */
    private static void aplicarConfiguracaoGuardada() {
        ConfiguracaoDao configuracaoDao = new ConfiguracaoDao();
        configuracaoDao.obter("api.base.url").ifPresent(AppConfig::setApiBaseUrl);
        configuracaoDao.obter("api.device.key").ifPresent(AppConfig::setApiDeviceKey);
        configuracaoDao.obter("admin.pin").ifPresent(AppConfig::setAdminPin);
    }
}
