package com.terminar.assiduidade.ui.admin;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.dao.ConfiguracaoDao;
import com.terminar.assiduidade.integration.ErpApiClient;
import com.terminar.assiduidade.integration.FuncionarioErp;
import net.miginfocom.swing.MigLayout;

import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JTextField;
import javax.swing.SwingUtilities;
import java.awt.Font;
import java.util.List;

/** Ecrã de definições editáveis em runtime — hoje só a integração com o Nexora ERP. */
public class ConfiguracaoPanel extends JPanel {

    private final ConfiguracaoDao configuracaoDao = new ConfiguracaoDao();

    private final JTextField urlField = new JTextField();
    private final JTextField chaveField = new JTextField();
    private final JLabel estadoLabel = new JLabel(" ");

    public ConfiguracaoPanel() {
        setLayout(new MigLayout("insets 8, wrap 2", "[]8[grow]", "[]4[]10[]10[]6[]"));

        JLabel titulo = new JLabel("Integração com o Nexora ERP");
        titulo.setFont(titulo.getFont().deriveFont(Font.BOLD, 12f));
        add(titulo, "span 2, wrap");

        JLabel explicacao = new JLabel("<html><body style='width: 320px'>"
            + "Sincroniza nome/número/activo a partir do ERP e envia cada marcação de ponto "
            + "para lá. PIN/QR/NFC/digital continuam geridos só neste terminal. Deixe em "
            + "branco para manter a integração desligada.</body></html>");
        add(explicacao, "span 2, wrap");

        urlField.setText(AppConfig.getApiBaseUrl());
        add(new JLabel("URL do ERP:"));
        add(urlField, "growx, wrap");

        chaveField.setText(AppConfig.getApiDeviceKey());
        add(new JLabel("Chave do dispositivo:"));
        add(chaveField, "growx, wrap");

        JButton guardarButton = new JButton("Guardar");
        guardarButton.addActionListener(e -> guardar());
        JButton testarButton = new JButton("Testar ligação");
        testarButton.addActionListener(e -> testarLigacao());
        JPanel botoes = new JPanel(new MigLayout("insets 0, gap 6", "[][]", "[]"));
        botoes.add(guardarButton);
        botoes.add(testarButton);
        add(botoes, "span 2, wrap");

        add(estadoLabel, "span 2");
    }

    private void guardar() {
        String url = urlField.getText().trim();
        String chave = chaveField.getText().trim();
        configuracaoDao.guardar("api.base.url", url);
        configuracaoDao.guardar("api.device.key", chave);
        AppConfig.setApiBaseUrl(url);
        AppConfig.setApiDeviceKey(chave);
        estadoLabel.setText(AppConfig.isApiSyncAtivo() ? "Guardado — integração activa." : "Guardado — integração desligada.");
        JOptionPane.showMessageDialog(this, "Definições guardadas.", "Configurações", JOptionPane.INFORMATION_MESSAGE);
    }

    private void testarLigacao() {
        String url = urlField.getText().trim();
        String chave = chaveField.getText().trim();
        if (url.isBlank() || chave.isBlank()) {
            estadoLabel.setText("Preencha o URL e a chave antes de testar.");
            return;
        }
        estadoLabel.setText("A testar...");

        new Thread(() -> {
            try {
                List<FuncionarioErp> funcionarios = new ErpApiClient(url, chave).listarFuncionarios();
                SwingUtilities.invokeLater(() ->
                    estadoLabel.setText("Ligação OK — " + funcionarios.size() + " funcionário(s) no ERP."));
            } catch (Exception e) {
                SwingUtilities.invokeLater(() -> estadoLabel.setText("Falhou: " + e.getMessage()));
            }
        }, "erp-testar-ligacao").start();
    }
}
