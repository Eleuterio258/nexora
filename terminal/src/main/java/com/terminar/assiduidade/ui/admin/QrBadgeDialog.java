package com.terminar.assiduidade.ui.admin;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.exception.AssiduidadeException;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.util.QrCodeUtil;
import net.miginfocom.swing.MigLayout;

import javax.imageio.ImageIO;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JFileChooser;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.SwingConstants;
import java.awt.Frame;
import java.awt.Image;
import java.awt.image.BufferedImage;
import java.io.File;

public class QrBadgeDialog extends JDialog {

    private final QrCodeUtil qrCodeUtil = new QrCodeUtil();
    private final BufferedImage imagem;

    public QrBadgeDialog(Frame owner, Employee employee) {
        super(owner, "Código QR — " + employee.getNome(), true);
        this.imagem = qrCodeUtil.gerar(employee.getQrCodeToken(), AppConfig.getQrCodeSize());

        setLayout(new MigLayout("insets 6, wrap 1", "[grow, center]", "[]6[]6[]"));
        add(new JLabel(employee.getNome() + " (Nº " + employee.getNumero() + ")"));
        add(new JLabel(new ImageIcon(escalarParaEcrã(imagem))));

        JButton guardarButton = new JButton("Guardar como imagem (PNG)");
        guardarButton.addActionListener(e -> guardar(employee));
        add(guardarButton, "align center");

        setResizable(false);
        pack();
        setLocationRelativeTo(owner);
    }

    private Image escalarParaEcrã(BufferedImage imagem) {
        int maxLargura = 160;
        int maxAltura = 120;
        double ratio = Math.min((double) maxLargura / imagem.getWidth(),
                                (double) maxAltura / imagem.getHeight());
        int novaLargura = Math.max(1, (int) (imagem.getWidth() * ratio));
        int novaAltura = Math.max(1, (int) (imagem.getHeight() * ratio));
        return imagem.getScaledInstance(novaLargura, novaAltura, Image.SCALE_SMOOTH);
    }

    private void guardar(Employee employee) {
        JFileChooser chooser = new JFileChooser();
        chooser.setSelectedFile(new File("qr-" + employee.getNumero() + ".png"));
        if (chooser.showSaveDialog(this) == JFileChooser.APPROVE_OPTION) {
            try {
                File destino = chooser.getSelectedFile();
                ImageIO.write(imagem, "PNG", destino);
                JOptionPane.showMessageDialog(this, "Guardado em " + destino.getAbsolutePath());
            } catch (Exception e) {
                throw new AssiduidadeException("Erro ao guardar imagem do QR Code", e);
            }
        }
    }
}
