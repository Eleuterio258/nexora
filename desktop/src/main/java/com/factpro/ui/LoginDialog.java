package com.factpro.ui;

import com.factpro.auth.service.AuthService;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.awt.event.*;
import java.awt.geom.*;

/**
 * Dialogo de login da aplicacao FactPro.
 * Design moderno com painel hero gradiente e cartao de formulario flutuante.
 */
public class LoginDialog extends JDialog {

    private static final Logger logger = LoggerFactory.getLogger(LoginDialog.class);

    // Palette
    private static final Color BLUE_950  = new Color(10,  27,  74);
    private static final Color BLUE_800  = new Color(24,  63, 176);
    private static final Color BLUE_600  = new Color(37,  99, 235);
    private static final Color BLUE_500  = new Color(59, 130, 246);
    private static final Color BLUE_100  = new Color(219, 234, 254);
    private static final Color BLUE_50   = new Color(239, 246, 255);
    private static final Color INK       = new Color(15,  23,  42);
    private static final Color INK_600   = new Color(71,  85, 105);
    private static final Color BORDER    = new Color(226, 232, 240);
    private static final Color SURFACE   = new Color(241, 245, 249);
    private static final Color ERROR_FG  = new Color(185,  28,  28);
    private static final Color ERROR_BG  = new Color(254, 242, 242);
    private static final Color ERROR_BD  = new Color(252, 165, 165);

    private final JTextField     emailField;
    private final JPasswordField passwordField;
    private final JPanel         errorBox;
    private final JLabel         errorLabel;
    private final JButton        enterButton;
    private final JButton        cancelButton;

    private boolean loginSuccessful = false;
    private final AuthService authService;

    public LoginDialog() {
        super((Frame) null, "FactPro — Login", true);
        this.authService = new AuthService();

        setDefaultCloseOperation(JDialog.DO_NOTHING_ON_CLOSE);
        setResizable(false);
        setSize(960, 600);
        setMinimumSize(new Dimension(960, 600));
        setLocationRelativeTo(null);

        emailField    = new JTextField();
        passwordField = new JPasswordField();
        errorLabel    = new JLabel();
        errorBox      = buildErrorBox();
        enterButton   = new JButton("Entrar");
        cancelButton  = new JButton("Cancelar");

        initComponents();
        setupLayout();
        setupListeners();
    }

    // =========================================================
    // Init
    // =========================================================

    private void initComponents() {
        emailField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "nome@empresa.co.mz");
        emailField.putClientProperty(FlatClientProperties.STYLE,
                "arc:10; innerFocusWidth:2; focusedBorderColor:#2563eb; margin:6,10,6,10");

        passwordField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "••••••••");
        passwordField.putClientProperty(FlatClientProperties.STYLE,
                "arc:10; innerFocusWidth:2; focusedBorderColor:#2563eb; margin:6,10,6,10");
        passwordField.putClientProperty("JPasswordField.showRevealButton", true);

        enterButton.putClientProperty(FlatClientProperties.STYLE,
                "arc:10; background:#2563eb; foreground:#ffffff; font:bold +1; " +
                "hoverBackground:#1d4ed8; pressedBackground:#1e40af");
        cancelButton.putClientProperty(FlatClientProperties.STYLE,
                "arc:10; background:null; foreground:#64748b; font:bold; " +
                "hoverBackground:#f1f5f9; borderColor:null");
    }

    // =========================================================
    // Layout
    // =========================================================

    private void setupLayout() {
        JPanel root = new JPanel(new MigLayout("fill, ins 0, gap 0", "[420px][grow]", "[grow]"));
        root.setBackground(Color.WHITE);
        setContentPane(root);

        root.add(buildHeroPanel(), "grow, h :100%:");
        root.add(buildFormPanel(), "grow, h :100%:");
    }

    // =========================================================
    // Hero Panel
    // =========================================================

    private JPanel buildHeroPanel() {
        JPanel hero = new JPanel(new MigLayout(
                "fill, ins 44 38 38 38, wrap 1",
                "[grow]",
                "[]30[]16[]push[]20[]")) {
            @Override
            protected void paintComponent(Graphics g) {
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

                // Deep blue gradient
                GradientPaint bg = new GradientPaint(
                        0, 0, BLUE_950,
                        getWidth(), getHeight(), BLUE_800);
                g2.setPaint(bg);
                g2.fillRect(0, 0, getWidth(), getHeight());

                // Decorative blobs
                drawBlob(g2, -90, -90, 340, 0.07f);
                drawBlob(g2, getWidth() - 170, getHeight() - 220, 300, 0.05f);
                drawBlob(g2, getWidth() / 2 - 50, getHeight() / 2 - 40, 180, 0.04f);

                g2.dispose();
            }

            private void drawBlob(Graphics2D g2, int x, int y, int r, float alpha) {
                g2.setComposite(AlphaComposite.getInstance(AlphaComposite.SRC_OVER, alpha));
                g2.setColor(Color.WHITE);
                g2.fillOval(x, y, r, r);
                g2.setComposite(AlphaComposite.getInstance(AlphaComposite.SRC_OVER, 1f));
            }
        };
        hero.setOpaque(false);

        hero.add(buildLogoBlock(), "left");

        JLabel heading = new JLabel("<html>Controle total<br>do seu negócio.</html>");
        heading.setForeground(Color.WHITE);
        heading.setFont(heading.getFont().deriveFont(Font.BOLD, 34f));
        hero.add(heading, "growx");

        JLabel sub = new JLabel("<html>Facturação, stock, POS e clientes — numa aplicação<br>" +
                "desktop offline, pronta para Moçambique.</html>");
        sub.setForeground(new Color(186, 213, 251));
        sub.setFont(sub.getFont().deriveFont(Font.PLAIN, 14f));
        hero.add(sub, "growx");

        hero.add(buildFeatureList(), "growx, pushy");

        JLabel footer = new JLabel("FactPro v1.0  •  Moçambique Retail Edition");
        footer.setForeground(new Color(148, 181, 233));
        footer.setFont(footer.getFont().deriveFont(Font.PLAIN, 11f));
        hero.add(footer, "left");

        return hero;
    }

    private JPanel buildLogoBlock() {
        JPanel row = new JPanel(new MigLayout("ins 0, gap 12", "[][grow]", "[]"));
        row.setOpaque(false);

        JPanel mark = new JPanel() {
            @Override
            protected void paintComponent(Graphics g) {
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
                // White rounded square
                g2.setColor(new Color(255, 255, 255, 230));
                g2.fill(new RoundRectangle2D.Float(0, 0, 46, 46, 12, 12));
                // "FP" in blue
                g2.setColor(BLUE_800);
                g2.setFont(getFont().deriveFont(Font.BOLD, 17f));
                FontMetrics fm = g2.getFontMetrics();
                String txt = "FP";
                g2.drawString(txt, (46 - fm.stringWidth(txt)) / 2, (46 - fm.getHeight()) / 2 + fm.getAscent());
                g2.dispose();
            }
            @Override public Dimension getPreferredSize() { return new Dimension(46, 46); }
        };
        mark.setOpaque(false);

        JPanel texts = new JPanel(new MigLayout("ins 0, wrap 1, gap 1", "[grow]", "[][]"));
        texts.setOpaque(false);
        JLabel brand = new JLabel("FactPro");
        brand.setForeground(Color.WHITE);
        brand.setFont(brand.getFont().deriveFont(Font.BOLD, 19f));
        JLabel edition = new JLabel("Desktop Edition");
        edition.setForeground(new Color(165, 200, 240));
        edition.setFont(edition.getFont().deriveFont(Font.PLAIN, 12f));
        texts.add(brand);
        texts.add(edition);

        row.add(mark,  "center, w 46!, h 46!");
        row.add(texts, "center");
        return row;
    }

    private JPanel buildFeatureList() {
        JPanel panel = new JPanel(new MigLayout("ins 0, wrap 1, gap 12", "[grow]", "[][][]"));
        panel.setOpaque(false);
        panel.add(buildFeatureItem("Offline-first",
                "Opera com SQLite local, sem dependência de internet"), "growx");
        panel.add(buildFeatureItem("Multi-módulo",
                "POS, stock, fornecedores, crédito e relatórios"), "growx");
        panel.add(buildFeatureItem("Seguro e rápido",
                "Autenticação por papéis, dados protegidos localmente"), "growx");
        return panel;
    }

    private JPanel buildFeatureItem(String title, String desc) {
        JPanel item = new JPanel(new MigLayout("ins 14 16 14 16, gap 0, wrap 1", "[grow]", "[]6[]")) {
            @Override
            protected void paintComponent(Graphics g) {
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
                g2.setColor(new Color(255, 255, 255, 16));
                g2.fill(new RoundRectangle2D.Float(0, 0, getWidth(), getHeight(), 12, 12));
                g2.setColor(new Color(255, 255, 255, 38));
                g2.setStroke(new BasicStroke(1f));
                g2.draw(new RoundRectangle2D.Float(0.5f, 0.5f, getWidth() - 1, getHeight() - 1, 12, 12));
                g2.dispose();
            }
        };
        item.setOpaque(false);

        JLabel t = new JLabel(title);
        t.setForeground(Color.WHITE);
        t.setFont(t.getFont().deriveFont(Font.BOLD, 13f));

        JLabel d = new JLabel("<html>" + desc + "</html>");
        d.setForeground(new Color(186, 213, 251));
        d.setFont(d.getFont().deriveFont(Font.PLAIN, 12f));

        item.add(t);
        item.add(d, "growx");
        return item;
    }

    // =========================================================
    // Form Panel
    // =========================================================

    private JPanel buildFormPanel() {
        JPanel outer = new JPanel(new MigLayout("fill", "[grow]", "[grow]"));
        outer.setBackground(SURFACE);

        JPanel card = buildCard();

        outer.add(card, "center, w 420!, growy, gaptop 40, gapbottom 40");
        return outer;
    }

    private JPanel buildCard() {
        JPanel card = new JPanel(new MigLayout(
                "fillx, wrap 1, ins 36 40 32 40, gap 0",
                "[grow]",
                "[]14[]8[]16[]10[]16[]8[]16[]")) {
            @Override
            protected void paintComponent(Graphics g) {
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

                // Shadow layers
                for (int i = 1; i <= 6; i++) {
                    float alpha = 0.04f * (7 - i);
                    g2.setColor(new Color(15, 23, 42, Math.round(alpha * 255)));
                    g2.fill(new RoundRectangle2D.Float(i, i + 2, getWidth() - i * 2f, getHeight() - i * 2f, 20, 20));
                }

                // Card background
                g2.setColor(Color.WHITE);
                g2.fill(new RoundRectangle2D.Float(0, 0, getWidth(), getHeight(), 20, 20));

                // Card border
                g2.setColor(BORDER);
                g2.setStroke(new BasicStroke(1f));
                g2.draw(new RoundRectangle2D.Float(0.5f, 0.5f, getWidth() - 1, getHeight() - 1, 20, 20));

                g2.dispose();
            }
        };
        card.setOpaque(false);

        // Avatar
        card.add(buildAvatarPanel(), "center, gapbottom 2");

        // Title
        JLabel title = new JLabel("Bem-vindo de volta");
        title.setForeground(INK);
        title.setFont(title.getFont().deriveFont(Font.BOLD, 24f));
        card.add(title, "center");

        // Subtitle
        JLabel subtitle = new JLabel("Insira as suas credenciais para continuar");
        subtitle.setForeground(INK_600);
        subtitle.setFont(subtitle.getFont().deriveFont(Font.PLAIN, 13f));
        card.add(subtitle, "center, gapbottom 4");

        // Separator
        JSeparator sep = new JSeparator();
        sep.setForeground(BORDER);
        card.add(sep, "growx");

        // Fields
        card.add(createFieldBlock("Endereço de Email", emailField), "growx");
        card.add(createFieldBlock("Senha", passwordField), "growx");

        // Error box (hidden by default)
        card.add(errorBox, "growx");

        // Hint box
        card.add(buildHintBox(), "growx");

        // Buttons
        JPanel actions = new JPanel(new MigLayout("ins 0, gap 10", "[grow][114!]", "[46!]"));
        actions.setOpaque(false);
        actions.add(enterButton,  "grow");
        actions.add(cancelButton, "grow");
        card.add(actions, "growx");

        return card;
    }

    private JPanel buildAvatarPanel() {
        JPanel av = new JPanel() {
            @Override
            protected void paintComponent(Graphics g) {
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

                // Outer ring
                g2.setColor(BLUE_50);
                g2.fillOval(0, 0, 58, 58);

                // Gradient inner circle
                g2.setPaint(new GradientPaint(0, 0, BLUE_600, 58, 58, BLUE_800));
                g2.fillOval(5, 5, 48, 48);

                // "FP" monogram
                g2.setColor(Color.WHITE);
                g2.setFont(getFont().deriveFont(Font.BOLD, 18f));
                FontMetrics fm = g2.getFontMetrics();
                String txt = "FP";
                g2.drawString(txt, (58 - fm.stringWidth(txt)) / 2, (58 - fm.getHeight()) / 2 + fm.getAscent());

                g2.dispose();
            }
            @Override public Dimension getPreferredSize() { return new Dimension(58, 58); }
        };
        av.setOpaque(false);
        return av;
    }

    private JPanel buildHintBox() {
        JPanel box = new JPanel(new MigLayout("fillx, ins 12 14 12 14, gap 0, wrap 1", "[grow]", "[]5[]")) {
            @Override
            protected void paintComponent(Graphics g) {
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
                g2.setColor(BLUE_50);
                g2.fill(new RoundRectangle2D.Float(0, 0, getWidth(), getHeight(), 10, 10));
                g2.setColor(BLUE_100);
                g2.setStroke(new BasicStroke(1f));
                g2.draw(new RoundRectangle2D.Float(0.5f, 0.5f, getWidth() - 1, getHeight() - 1, 10, 10));
                g2.dispose();
            }
        };
        box.setOpaque(false);

        JLabel ht = new JLabel("Credenciais de demonstração");
        ht.setForeground(new Color(30, 64, 175));
        ht.setFont(ht.getFont().deriveFont(Font.BOLD, 12f));

        JLabel hb = new JLabel("<html><b>Email:</b> admin@factpro.local &nbsp; <b>Senha:</b> admin123</html>");
        hb.setForeground(new Color(55, 95, 185));
        hb.setFont(hb.getFont().deriveFont(Font.PLAIN, 12f));

        box.add(ht, "left");
        box.add(hb, "left");
        return box;
    }

    private JPanel buildErrorBox() {
        JPanel box = new JPanel(new MigLayout("fillx, ins 10 14 10 14", "[grow]", "[]")) {
            @Override
            protected void paintComponent(Graphics g) {
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
                g2.setColor(ERROR_BG);
                g2.fill(new RoundRectangle2D.Float(0, 0, getWidth(), getHeight(), 10, 10));
                g2.setColor(ERROR_BD);
                g2.setStroke(new BasicStroke(1f));
                g2.draw(new RoundRectangle2D.Float(0.5f, 0.5f, getWidth() - 1, getHeight() - 1, 10, 10));
                g2.dispose();
            }
        };
        box.setOpaque(false);
        errorLabel.setForeground(ERROR_FG);
        errorLabel.setFont(errorLabel.getFont().deriveFont(Font.PLAIN, 13f));
        box.add(errorLabel, "growx");
        box.setVisible(false);
        return box;
    }

    private JPanel createFieldBlock(String labelText, JComponent field) {
        JPanel panel = new JPanel(new MigLayout("fillx, wrap 1, ins 0, gap 6", "[grow]", "[][]"));
        panel.setOpaque(false);

        JLabel label = new JLabel(labelText);
        label.setForeground(INK);
        label.setFont(label.getFont().deriveFont(Font.BOLD, 13f));

        field.setPreferredSize(new Dimension(340, 46));

        panel.add(label);
        panel.add(field, "growx, h 46!");
        return panel;
    }

    // =========================================================
    // Listeners & Auth
    // =========================================================

    private void setupListeners() {
        enterButton.addActionListener(e -> attemptLogin());

        cancelButton.addActionListener(e -> {
            loginSuccessful = false;
            dispose();
        });

        emailField.addActionListener(e -> passwordField.requestFocusInWindow());
        passwordField.addActionListener(e -> attemptLogin());

        addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                loginSuccessful = false;
                dispose();
            }
        });

        getRootPane().setDefaultButton(enterButton);

        KeyStroke esc = KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(esc, "cancel");
        getRootPane().getActionMap().put("cancel", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                cancelButton.doClick();
            }
        });
    }

    private void attemptLogin() {
        String email    = emailField.getText().trim();
        String password = new String(passwordField.getPassword());

        clearError();

        if (email.isEmpty()) {
            showError("Por favor, insira o seu email.");
            emailField.requestFocusInWindow();
            return;
        }
        if (password.isEmpty()) {
            showError("Por favor, insira a sua senha.");
            passwordField.requestFocusInWindow();
            return;
        }

        setFieldsEnabled(false);
        enterButton.setText("A verificar…");

        SwingWorker<Boolean, Void> worker = new SwingWorker<>() {
            @Override
            protected Boolean doInBackground() {
                return authService.authenticate(email, password);
            }

            @Override
            protected void done() {
                try {
                    if (get()) {
                        loginSuccessful = true;
                        dispose();
                    } else {
                        showError("Email ou senha incorretos. Tente novamente.");
                        passwordField.setText("");
                        passwordField.requestFocusInWindow();
                    }
                } catch (Exception ex) {
                    logger.error("Erro durante autenticacao", ex);
                    showError("Erro de ligação à base de dados.");
                } finally {
                    setFieldsEnabled(true);
                    enterButton.setText("Entrar");
                }
            }
        };
        worker.execute();
    }

    private void clearError() {
        errorBox.setVisible(false);
    }

    private void showError(String message) {
        errorLabel.setText(message);
        errorBox.setVisible(true);
        pack();
    }

    private void setFieldsEnabled(boolean enabled) {
        emailField.setEnabled(enabled);
        passwordField.setEnabled(enabled);
        enterButton.setEnabled(enabled);
        cancelButton.setEnabled(enabled);
    }

    public boolean isLoginSuccessful() {
        return loginSuccessful;
    }
}
