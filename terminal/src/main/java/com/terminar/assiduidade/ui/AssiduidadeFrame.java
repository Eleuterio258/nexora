package com.terminar.assiduidade.ui;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.model.MetodoAutenticacao;
import com.terminar.assiduidade.ui.admin.AdminLoginDialog;
import com.terminar.assiduidade.ui.admin.EmployeeManagementPanel;
import lombok.extern.slf4j.Slf4j;

import javax.swing.JFrame;
import javax.swing.JScrollPane;
import javax.swing.Timer;
import java.awt.AWTEvent;
import java.awt.CardLayout;
import java.awt.Toolkit;

@Slf4j
public class AssiduidadeFrame extends JFrame {

    public static final String CARD_HOME = "home";
    public static final String CARD_PIN = "pin";
    public static final String CARD_QR = "qr";
    public static final String CARD_FINGERPRINT = "fingerprint";
    public static final String CARD_NFC = "nfc";
    public static final String CARD_MARCAR = "marcar";
    public static final String CARD_RESULT = "result";
    public static final String CARD_ADMIN = "admin";

    private final CardLayout cardLayout = new CardLayout();
    private final java.awt.Container cards;

    private final HomeClockPanel homePanel;
    private final PinAuthPanel pinPanel;
    private final QrAuthPanel qrPanel;
    private final FingerprintAuthPanel fingerprintPanel;
    private final NfcAuthPanel nfcPanel;
    private final MarcarPontoPanel marcarPontoPanel;
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
        qrPanel = new QrAuthPanel(this);
        fingerprintPanel = new FingerprintAuthPanel(this);
        nfcPanel = new NfcAuthPanel(this);
        marcarPontoPanel = new MarcarPontoPanel(this);
        resultPanel = new ResultPanel(this);
        adminPanel = new EmployeeManagementPanel(this);

        cards.add(homePanel, CARD_HOME);
        cards.add(pinPanel, CARD_PIN);
        cards.add(qrPanel, CARD_QR);
        cards.add(fingerprintPanel, CARD_FINGERPRINT);
        cards.add(nfcPanel, CARD_NFC);
        cards.add(marcarPontoPanel, CARD_MARCAR);
        cards.add(resultPanel, CARD_RESULT);
        JScrollPane adminScroll = new JScrollPane(adminPanel);
        adminScroll.setBorder(null);
        cards.add(adminScroll, CARD_ADMIN);

        cards.setPreferredSize(new java.awt.Dimension(AppConfig.getScreenWidth(), AppConfig.getScreenHeight()));
        pack();
        setResizable(false);
        setLocationRelativeTo(null);

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
        nfcPanel.pararLeitura();
        homePanel.refrescar();
        setTitle(AppConfig.getAppTitle());
        showCard(CARD_HOME);
    }

    public void goToPin() {
        pinPanel.reiniciar();
        setTitle("Entrada de PIN");
        showCard(CARD_PIN);
    }

    public void goToQr() {
        qrPanel.iniciarCaptura();
        setTitle("Leitura de QR Code");
        showCard(CARD_QR);
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

    public void goToMarcarPonto(Employee employee, MetodoAutenticacao metodo) {
        qrPanel.pararCaptura();
        nfcPanel.pararLeitura();
        marcarPontoPanel.exibir(employee, metodo);
        showCard(CARD_MARCAR);
    }

    public void goToResult(String mensagem, boolean sucesso) {
        resultPanel.exibir(mensagem, sucesso);
        showCard(CARD_RESULT);
    }

    public void goToAdminGated() {
        AdminLoginDialog dialog = new AdminLoginDialog(this);
        dialog.setVisible(true);
        if (dialog.isAutenticado()) {
            adminPanel.refrescar();
            showCard(CARD_ADMIN);
        }
    }
}
