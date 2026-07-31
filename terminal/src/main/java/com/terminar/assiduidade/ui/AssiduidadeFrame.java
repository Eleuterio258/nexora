package com.terminar.assiduidade.ui;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.dao.ConfiguracaoDao;
import com.terminar.assiduidade.exception.AssiduidadeException;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.model.MetodoAutenticacao;
import com.terminar.assiduidade.service.PontoService;
import com.terminar.assiduidade.ui.admin.AdminLoginDialog;
import com.terminar.assiduidade.ui.admin.EmployeeManagementPanel;
import lombok.extern.slf4j.Slf4j;

import javax.swing.JFrame;
import javax.swing.JOptionPane;
import javax.swing.JPasswordField;
import javax.swing.JScrollPane;
import javax.swing.Timer;
import java.awt.AWTEvent;
import java.awt.CardLayout;
import java.awt.Toolkit;

import static com.terminar.assiduidade.config.AppConfig.ADMIN_PIN_OMISSAO;

@Slf4j
public class AssiduidadeFrame extends JFrame {

    public static final String CARD_HOME = "home";
    public static final String CARD_PIN = "pin";
    public static final String CARD_QR_MENU = "qrMenu";
    public static final String CARD_QR = "qr";
    public static final String CARD_QR_MOSTRAR = "qrMostrar";
    public static final String CARD_FINGERPRINT = "fingerprint";
    public static final String CARD_NFC = "nfc";
    public static final String CARD_RESULT = "result";
    public static final String CARD_ADMIN = "admin";

    private final CardLayout cardLayout = new CardLayout();
    private final java.awt.Container cards;
    private final java.awt.Dimension kioskSize;
    private final PontoService pontoService = new PontoService();

    private final HomeClockPanel homePanel;
    private final PinAuthPanel pinPanel;
    private final QrMenuPanel qrMenuPanel;
    private final QrAuthPanel qrPanel;
    private final QrMostrarPanel qrMostrarPanel;
    private final FingerprintAuthPanel fingerprintPanel;
    private final NfcAuthPanel nfcPanel;
    private final ResultPanel resultPanel;
    private final EmployeeManagementPanel adminPanel;

    private final Timer inactivityTimer;

    public AssiduidadeFrame() {
        super(AppConfig.getAppTitle());
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        cards = new java.awt.Container();
        cards.setLayout(cardLayout);
        setContentPane(cards);

        homePanel = new HomeClockPanel(this);
        pinPanel = new PinAuthPanel(this);
        qrMenuPanel = new QrMenuPanel(this);
        qrPanel = new QrAuthPanel(this);
        qrMostrarPanel = new QrMostrarPanel(this);
        fingerprintPanel = new FingerprintAuthPanel(this);
        nfcPanel = new NfcAuthPanel(this);
        resultPanel = new ResultPanel(this);
        adminPanel = new EmployeeManagementPanel(this);

        cards.add(homePanel, CARD_HOME);
        cards.add(pinPanel, CARD_PIN);
        cards.add(qrMenuPanel, CARD_QR_MENU);
        cards.add(qrPanel, CARD_QR);
        cards.add(qrMostrarPanel, CARD_QR_MOSTRAR);
        cards.add(fingerprintPanel, CARD_FINGERPRINT);
        cards.add(nfcPanel, CARD_NFC);
        cards.add(resultPanel, CARD_RESULT);
        JScrollPane adminScroll = new JScrollPane(adminPanel);
        adminScroll.setBorder(null);
        cards.add(adminScroll, CARD_ADMIN);

        cards.setPreferredSize(new java.awt.Dimension(AppConfig.getScreenWidth(), AppConfig.getScreenHeight()));
        pack();
        setResizable(false);
        setLocationRelativeTo(null);
        kioskSize = getSize();

        inactivityTimer = new Timer(AppConfig.getSessionTimeoutSeconds() * 1000, e -> goHome());
        inactivityTimer.setRepeats(false);

        Toolkit.getDefaultToolkit().addAWTEventListener(this::onGlobalActivity,
            AWTEvent.MOUSE_EVENT_MASK | AWTEvent.KEY_EVENT_MASK);

        goHome();
    }

    private void onGlobalActivity(AWTEvent event) {
        if (!CARD_HOME.equals(currentCard)) {
            resetInactivityTimer();
        }
    }

    private String currentCard = CARD_HOME;

    private void showCard(String name) {
        currentCard = name;
        cardLayout.show(cards, name);
        if (CARD_HOME.equals(name)) {
            inactivityTimer.stop();
        } else {
            resetInactivityTimer();
        }
    }

    private void resetInactivityTimer() {
        inactivityTimer.restart();
    }

    public void goHome() {
        qrPanel.pararCaptura();
        qrMostrarPanel.pararCaptura();
        nfcPanel.pararLeitura();
        if (CARD_ADMIN.equals(currentCard)) {
            restoreKioskSize();
        }
        homePanel.refrescar();
        setTitle(AppConfig.getAppTitle());
        showCard(CARD_HOME);
    }

    public void goToPin() {
        pinPanel.reiniciar();
        setTitle("Entrada de PIN");
        showCard(CARD_PIN);
    }

    /**
     * Menu com os dois cartões — "Ler QR" (Modo 1: câmara lê o QR fixo do funcionário,
     * identifica e regista localmente) e "Ver QR" (Modo 2: o terminal mostra o seu
     * próprio QR dinâmico de 60s, para a app Nexo do funcionário ler e completar a
     * marcação directamente com o servidor).
     */
    public void goToQr() {
        setTitle("QR Code");
        showCard(CARD_QR_MENU);
    }

    public void goToQrLer() {
        qrPanel.iniciarCaptura();
        setTitle("Leitura de QR Code");
        showCard(CARD_QR);
    }

    public void goToQrMostrar() {
        qrMostrarPanel.iniciar();
        setTitle("Ver QR Code");
        showCard(CARD_QR_MOSTRAR);
    }

    public void goToFingerprint() {
        fingerprintPanel.reiniciar();
        setTitle("Leitora Digital");
        showCard(CARD_FINGERPRINT);
    }

    public void goToNfc() {
        nfcPanel.iniciarLeitura();
        setTitle("NFC");
        showCard(CARD_NFC);
    }

    /**
     * Regista a marcação imediatamente após a autenticação (PIN/QR/NFC/Digital) ter
     * sucesso — sem pedir confirmação extra ao funcionário, que já demonstrou a
     * identidade ao autenticar-se.
     */
    public void goToMarcarPonto(Employee employee, MetodoAutenticacao metodo) {
        qrPanel.pararCaptura();
        qrMostrarPanel.pararCaptura();
        nfcPanel.pararLeitura();
        try {
            pontoService.registarMarcacao(employee, metodo);
            goToResult(employee.getNome() + " — presença registada com sucesso", true);
        } catch (AssiduidadeException e) {
            goToResult(e.getMessage(), false);
        }
    }

    public void goToResult(String mensagem, boolean sucesso) {
        resultPanel.exibir(mensagem, sucesso);
        showCard(CARD_RESULT);
    }

    public void goToAdminGated() {
        AdminLoginDialog dialog = new AdminLoginDialog(this);
        dialog.setVisible(true);
        if (!dialog.isAutenticado()) {
            return;
        }
        if (ADMIN_PIN_OMISSAO.equals(AppConfig.getAdminPin()) && !forcarTrocaPinAdmin()) {
            return;
        }
        adminPanel.refrescar();
        resizeForAdmin();
        showCard(CARD_ADMIN);
    }

    /**
     * O PIN de admin de fábrica ({@link AppConfig#ADMIN_PIN_OMISSAO}) é público (está no
     * README/application.properties) — aceitá-lo indefinidamente anula qualquer protecção
     * contra força bruta no {@link com.terminar.assiduidade.ui.admin.AdminLoginDialog}. Devolve
     * false se o utilizador cancelar, negando o acesso a essa entrada no admin.
     */
    private boolean forcarTrocaPinAdmin() {
        while (true) {
            JPasswordField pin1 = new JPasswordField();
            JPasswordField pin2 = new JPasswordField();
            Object[] mensagem = {
                "O PIN de administração ainda é o de fábrica (" + ADMIN_PIN_OMISSAO + ").\n"
                    + "Defina um novo PIN antes de continuar:",
                "Novo PIN (mín. 4 dígitos):", pin1, "Confirmar PIN:", pin2
            };
            int opcao = JOptionPane.showConfirmDialog(this, mensagem, "Trocar PIN de administração",
                JOptionPane.OK_CANCEL_OPTION);
            if (opcao != JOptionPane.OK_OPTION) {
                return false;
            }
            String p1 = new String(pin1.getPassword());
            String p2 = new String(pin2.getPassword());
            if (p1.length() < 4 || !p1.equals(p2) || ADMIN_PIN_OMISSAO.equals(p1)) {
                JOptionPane.showMessageDialog(this,
                    "PIN inválido — tem de ter pelo menos 4 dígitos, coincidir na confirmação e "
                        + "não pode ser " + ADMIN_PIN_OMISSAO + ".",
                    "Erro", JOptionPane.ERROR_MESSAGE);
                continue;
            }
            new ConfiguracaoDao().guardar("admin.pin", p1);
            AppConfig.setAdminPin(p1);
            log.info("PIN de administração trocado (deixou de ser o de fábrica)");
            return true;
        }
    }

    private void resizeForAdmin() {
        setResizable(true);
        setSize(AppConfig.getAdminScreenWidth(), AppConfig.getAdminScreenHeight());
        setLocationRelativeTo(null);
    }

    private void restoreKioskSize() {
        setResizable(false);
        setSize(kioskSize);
        setLocationRelativeTo(null);
    }
}
