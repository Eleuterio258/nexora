package com.terminar.assiduidade.ui;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.exception.AssiduidadeException;
import com.terminar.assiduidade.integration.ErpApiClient;
import com.terminar.assiduidade.util.QrCodeUtil;
import lombok.extern.slf4j.Slf4j;
import net.miginfocom.swing.MigLayout;

import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import javax.swing.SwingUtilities;
import java.awt.Color;
import java.awt.Font;
import java.awt.Image;
import java.awt.image.BufferedImage;

/**
 * "Ver QR" — Modo 2 (QR dinâmico do terminal): o terminal pede ao ERP um código anónimo
 * (sem funcionario_id) de 60s e mostra-o no ecrã, renovando antes de expirar. O funcionário
 * lê este código com a app Nexo (já sabe quem é, pela sua sessão) e é a app + servidor que
 * completam a marcação — este ecrã não identifica ninguém nem regista nada localmente.
 */
@Slf4j
public class QrMostrarPanel extends JPanel {

    private static final long RENOVAR_ANTES_DE_EXPIRAR_MS = 5_000;
    private static final long DURACAO_PADRAO_MS = 60_000;

    private final int qrTamanho = UiScale.px(90);

    private final AssiduidadeFrame frame;
    private final ErpApiClient erpApiClient = new ErpApiClient();
    private final QrCodeUtil qrCodeUtil = new QrCodeUtil();

    private final JLabel qrLabel = new JLabel("", SwingConstants.CENTER);
    private final JLabel statusLabel = new JLabel("", SwingConstants.CENTER);

    private volatile boolean activo = false;
    private Thread renovacaoThread;

    public QrMostrarPanel(AssiduidadeFrame frame) {
        this.frame = frame;
        setLayout(new MigLayout("fill, insets 8, gap 4", "[grow, center]", "[]6[]6[]4[]"));

        JLabel titulo = new JLabel("Ver QR Code", SwingConstants.CENTER);
        titulo.setFont(titulo.getFont().deriveFont(Font.BOLD, UiScale.f(13f)));

        JButton cancelar = new JButton("Cancelar");
        cancelar.setFont(cancelar.getFont().deriveFont(UiScale.f(11f)));
        cancelar.setMargin(new java.awt.Insets(3, 10, 3, 10));
        cancelar.setFocusable(false);
        cancelar.addActionListener(e -> frame.goHome());

        JPanel topo = new JPanel(new MigLayout("fillx, insets 0", "[grow][]", "[]"));
        topo.add(titulo, "growx, align center");
        topo.add(cancelar, "align right, top");
        add(topo, "growx, wrap");

        JLabel instrucao = new JLabel("Leia com a app Nexo para marcar o ponto",
            SwingConstants.CENTER);
        instrucao.setFont(instrucao.getFont().deriveFont(UiScale.f(10f)));
        add(instrucao, "wrap");

        qrLabel.setPreferredSize(new java.awt.Dimension(qrTamanho, qrTamanho));
        add(qrLabel, "align center, wrap");

        statusLabel.setFont(statusLabel.getFont().deriveFont(UiScale.f(11f)));
        statusLabel.setForeground(new Color(160, 160, 165));
        add(statusLabel, "align center");
    }

    /** Chamado pelo AssiduidadeFrame ao entrar neste ecrã — arranca o ciclo de renovação. */
    public void iniciar() {
        qrLabel.setIcon(null);
        if (!AppConfig.isApiSyncAtivo()) {
            statusLabel.setText("Ver QR exige integração com o ERP activa");
            return;
        }
        statusLabel.setText("A gerar QR Code...");
        activo = true;
        renovacaoThread = new Thread(this::loopRenovacao, "qr-terminal-renovar");
        renovacaoThread.setDaemon(true);
        renovacaoThread.start();
    }

    private void loopRenovacao() {
        while (activo) {
            long inicio = System.currentTimeMillis();
            try {
                String qrCode = erpApiClient.gerarQRTerminal();
                BufferedImage imagem = qrCodeUtil.gerar(qrCode, AppConfig.getQrCodeSize());
                Image escalada = imagem.getScaledInstance(qrTamanho, qrTamanho, Image.SCALE_SMOOTH);
                SwingUtilities.invokeLater(() -> {
                    qrLabel.setIcon(new ImageIcon(escalada));
                    statusLabel.setText("Código actualizado — renova automaticamente");
                });
            } catch (AssiduidadeException e) {
                log.warn("Falha ao gerar QR do terminal", e);
                SwingUtilities.invokeLater(() -> statusLabel.setText(e.getMessage()));
            }
            long decorrido = System.currentTimeMillis() - inicio;
            long espera = Math.max(1000, DURACAO_PADRAO_MS - RENOVAR_ANTES_DE_EXPIRAR_MS - decorrido);
            aguardar(espera);
        }
    }

    private void aguardar(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public void pararCaptura() {
        activo = false;
        if (renovacaoThread != null) {
            renovacaoThread.interrupt();
        }
    }
}
