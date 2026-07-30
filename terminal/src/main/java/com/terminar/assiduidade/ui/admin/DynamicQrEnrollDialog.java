package com.terminar.assiduidade.ui.admin;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.exception.AssiduidadeException;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.security.TotpUtil;
import com.terminar.assiduidade.util.QrCodeUtil;
import net.miginfocom.swing.MigLayout;

import javax.imageio.ImageIO;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JFileChooser;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JTextField;
import java.awt.Frame;
import java.awt.Image;
import java.awt.image.BufferedImage;
import java.io.File;

/**
 * Mostra o QR de provisionamento (otpauth://) e o segredo TOTP de um funcionário, para
 * configurar uma app de autenticação externa (fora deste projecto) que gera o código
 * dinâmico de 60s lido pelo QrAuthPanel.
 */
public class DynamicQrEnrollDialog extends JDialog {

    private final QrCodeUtil qrCodeUtil = new QrCodeUtil();
    private final TotpUtil totpUtil = new TotpUtil();
    private final BufferedImage imagem;

    public DynamicQrEnrollDialog(Frame owner, Employee employee) {
        super(owner, "QR dinâmico — " + employee.getNome(), true);
        String uri = totpUtil.gerarUriProvisionamento(
            employee.getQrTotpSecret(), employee.getNumero(), AppConfig.getCompanyName());
        this.imagem = qrCodeUtil.gerar(uri, AppConfig.getQrCodeSize());

        setLayout(new MigLayout("insets 6, wrap 1", "[grow, center]", "[]4[]6[]4[]6[]"));
        add(new JLabel(employee.getNome() + " (Nº " + employee.getNumero() + ")"));
        add(new JLabel("<html><center>Configure a app de autenticação do funcionário com este QR.<br>"
            + "O código gerado muda a cada 60 segundos.</center></html>"));
        add(new JLabel(new ImageIcon(escalarParaEcrã(imagem))));

        JTextField segredoField = new JTextField(employee.getQrTotpSecret());
        segredoField.setEditable(false);
        segredoField.setHorizontalAlignment(JTextField.CENTER);
        add(new JLabel("Segredo (introdução manual):"));
        add(segredoField, "growx, w 220!");

        JButton guardarButton = new JButton("Guardar QR como imagem (PNG)");
        guardarButton.addActionListener(e -> guardar(employee));
        add(guardarButton, "align center");

        setResizable(false);
        pack();
        setLocationRelativeTo(owner);
    }

    private Image escalarParaEcrã(BufferedImage imagem) {
        int maxLargura = 160;
        int maxAltura = 160;
        double ratio = Math.min((double) maxLargura / imagem.getWidth(),
                                (double) maxAltura / imagem.getHeight());
        int novaLargura = Math.max(1, (int) (imagem.getWidth() * ratio));
        int novaAltura = Math.max(1, (int) (imagem.getHeight() * ratio));
        return imagem.getScaledInstance(novaLargura, novaAltura, Image.SCALE_SMOOTH);
    }

    private void guardar(Employee employee) {
        JFileChooser chooser = new JFileChooser();
        chooser.setSelectedFile(new File("qr-dinamico-" + employee.getNumero() + ".png"));
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
