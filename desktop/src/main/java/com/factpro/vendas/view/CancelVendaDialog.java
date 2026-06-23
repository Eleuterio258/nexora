package com.factpro.vendas.view;

import com.factpro.auth.SessionManager;
import com.factpro.core.util.CurrencyFormatter;
import com.factpro.vendas.dao.PagamentoDAO;
import com.factpro.vendas.dao.VendaDAO;
import com.factpro.vendas.dao.VendaItemDAO;
import com.factpro.vendas.model.Venda;
import com.factpro.vendas.service.VendaService;
import com.factpro.stock.dao.StockMovimentoDAO;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.CompoundBorder;
import javax.swing.border.EmptyBorder;
import javax.swing.border.LineBorder;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;

/**
 * Cancel sale dialog with reason input and stock restoration warning.
 */
public class CancelVendaDialog extends JDialog {

    private static final Logger logger = LoggerFactory.getLogger(CancelVendaDialog.class);

    private final Venda venda;
    private boolean cancelled = false;

    private JTextArea motivoArea;
    private JLabel charCountLabel;

    private static final Color RED = new Color(220, 53, 69);
    private static final Color ORANGE = new Color(255, 152, 0);

    public CancelVendaDialog(Frame parent, Venda venda) {
        super(parent, "Cancelar Venda", true);
        this.venda = venda;

        setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
        setSize(500, 420);
        setLocationRelativeTo(parent);

        initComponents();
        setupLayout();
    }

    private void initComponents() {
        motivoArea = new JTextArea(5, 35);
        motivoArea.setLineWrap(true);
        motivoArea.setWrapStyleWord(true);
        motivoArea.setFont(motivoArea.getFont().deriveFont(Font.PLAIN, 13f));

        charCountLabel = new JLabel("0/10 caracteres");
        charCountLabel.setFont(charCountLabel.getFont().deriveFont(Font.PLAIN, 11f));
        charCountLabel.setForeground(ORANGE);
    }

    private void setupLayout() {
        setLayout(new MigLayout("fill, wrap 1, ins 20, gap 10", "[grow]"));

        // Title
        JLabel titleLabel = new JLabel("Cancelar Venda");
        titleLabel.setFont(titleLabel.getFont().deriveFont(Font.BOLD, 18f));
        titleLabel.setForeground(RED);
        add(titleLabel, "center, gapy 0 10");

        // Sale info card
        JPanel infoPanel = new JPanel(new MigLayout("fillx, ins 10, gap 5 8", "[][grow]"));
        infoPanel.setBackground(new Color(255, 245, 245));
        infoPanel.setBorder(new CompoundBorder(
                new LineBorder(RED, 1, true),
                new EmptyBorder(5, 10, 5, 10)));

        String docNumber = (venda.getSerieDocumento() != null ? venda.getSerieDocumento() : "FT")
                + " " + (venda.getNumeroDocumento() != null ? venda.getNumeroDocumento() : "N/A");

        infoPanel.add(createInfoLabel("Nº Documento:"));
        infoPanel.add(new JLabel(docNumber), "growx");
        infoPanel.add(createInfoLabel("Data:"));
        infoPanel.add(new JLabel(venda.getCriadaEm() != null ? venda.getCriadaEm() : "N/A"), "growx");
        infoPanel.add(createInfoLabel("Total:"));
        JLabel totalLabel = new JLabel(CurrencyFormatter.format(venda.getTotal() != null ? venda.getTotal() : 0.0));
        totalLabel.setFont(totalLabel.getFont().deriveFont(Font.BOLD, 14f));
        totalLabel.setForeground(RED);
        infoPanel.add(totalLabel, "growx");

        add(infoPanel, "growx");

        // Warning message
        JPanel warningPanel = new JPanel(new MigLayout("fillx, ins 10", "[grow]"));
        warningPanel.setBackground(new Color(255, 250, 230));
        warningPanel.setBorder(new CompoundBorder(
                new LineBorder(ORANGE, 1, true),
                new EmptyBorder(8, 10, 8, 10)));

        JLabel warningLabel = new JLabel(
                "<html><b>Atencao:</b> Ao cancelar esta venda, o stock dos produtos sera restaurado automaticamente. "
                        + "Esta operacao nao pode ser desfeita.</html>");
        warningLabel.setFont(warningLabel.getFont().deriveFont(Font.PLAIN, 12f));
        warningLabel.setForeground(new Color(120, 80, 0));
        warningPanel.add(warningLabel, "growx");
        add(warningPanel, "growx");

        // Reason input
        add(new JLabel("Motivo do cancelamento (minimo 10 caracteres): *"), "gapy 10 5");

        JScrollPane scrollPane = new JScrollPane(motivoArea);
        scrollPane.setBorder(new CompoundBorder(
                new LineBorder(new Color(200, 200, 200), 1, true),
                new EmptyBorder(2, 2, 2, 2)));
        add(scrollPane, "growx, h 100");

        // Character count
        JPanel countPanel = new JPanel(new MigLayout("fillx, ins 0", "[grow][]"));
        countPanel.add(new JLabel(""), "grow");
        countPanel.add(charCountLabel);
        add(countPanel, "growx");

        motivoArea.getDocument().addDocumentListener(new javax.swing.event.DocumentListener() {
            @Override public void insertUpdate(javax.swing.event.DocumentEvent e) { updateCharCount(); }
            @Override public void removeUpdate(javax.swing.event.DocumentEvent e) { updateCharCount(); }
            @Override public void changedUpdate(javax.swing.event.DocumentEvent e) { updateCharCount(); }

            private void updateCharCount() {
                int len = motivoArea.getText().length();
                charCountLabel.setText(len + "/10 caracteres");
                if (len >= 10) {
                    charCountLabel.setForeground(new Color(34, 139, 34));
                } else {
                    charCountLabel.setForeground(ORANGE);
                }
            }
        });

        // Buttons
        JPanel btnPanel = new JPanel(new MigLayout("ins 0, gap 10"));
        JButton confirmBtn = new JButton("Confirmar Cancelamento");
        JButton cancelBtn = new JButton("Voltar");
        styleBtn(confirmBtn, RED);
        btnPanel.add(confirmBtn, "grow");
        btnPanel.add(cancelBtn);
        add(btnPanel, "center, gapy 15");

        confirmBtn.addActionListener(e -> confirmCancel());
        cancelBtn.addActionListener(e -> dispose());

        getRootPane().setDefaultButton(cancelBtn);
        KeyStroke escape = KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(escape, "cancel");
        getRootPane().getActionMap().put("cancel", new AbstractAction() {
            @Override public void actionPerformed(ActionEvent e) { dispose(); }
        });
    }

    private JLabel createInfoLabel(String text) {
        JLabel label = new JLabel(text);
        label.setFont(label.getFont().deriveFont(Font.BOLD, 12f));
        label.setForeground(Color.GRAY);
        return label;
    }

    private void styleBtn(JButton btn, Color bgColor) {
        btn.setFont(btn.getFont().deriveFont(Font.BOLD, 13f));
        btn.setBackground(bgColor);
        btn.setForeground(Color.WHITE);
        btn.setFocusPainted(false);
    }

    private void confirmCancel() {
        String motivo = motivoArea.getText().trim();

        // Validation
        if (motivo.isEmpty()) {
            JOptionPane.showMessageDialog(this,
                    "O motivo do cancelamento e obrigatorio.",
                    "Validacao", JOptionPane.WARNING_MESSAGE);
            motivoArea.requestFocusInWindow();
            return;
        }

        if (motivo.length() < 10) {
            JOptionPane.showMessageDialog(this,
                    "O motivo deve ter pelo menos 10 caracteres.\n"
                            + "Atual: " + motivo.length() + " caracteres",
                    "Motivo Muito Curto", JOptionPane.WARNING_MESSAGE);
            motivoArea.requestFocusInWindow();
            return;
        }

        // Final confirmation
        int confirm = JOptionPane.showConfirmDialog(this,
                "Tem certeza que deseja cancelar esta venda?\n"
                        + "Documento: " + (venda.getSerieDocumento() != null ? venda.getSerieDocumento() : "FT")
                        + " " + (venda.getNumeroDocumento() != null ? venda.getNumeroDocumento() : "N/A") + "\n"
                        + "Total: " + CurrencyFormatter.format(venda.getTotal() != null ? venda.getTotal() : 0.0) + "\n"
                        + "O stock sera restaurado automaticamente.",
                "Confirmar Cancelamento",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.WARNING_MESSAGE);

        if (confirm == JOptionPane.YES_OPTION) {
            try {
                VendaDAO vendaDAO = new VendaDAO();
                VendaItemDAO vendaItemDAO = new VendaItemDAO();
                StockMovimentoDAO stockMovimentoDAO = new StockMovimentoDAO();
                PagamentoDAO pagamentoDAO = new PagamentoDAO();

                VendaService vendaService = new VendaService(
                        vendaDAO, vendaItemDAO, null, stockMovimentoDAO, pagamentoDAO);

                Long userId = SessionManager.getInstance().getCurrentUserId();
                boolean result = vendaService.cancelarVenda(venda.getId(), userId, motivo);

                if (result) {
                    JOptionPane.showMessageDialog(this,
                            "Venda cancelada com sucesso.\nO stock foi restaurado.",
                            "Sucesso", JOptionPane.INFORMATION_MESSAGE);
                    cancelled = true;
                    dispose();
                } else {
                    JOptionPane.showMessageDialog(this,
                            "Erro ao cancelar a venda. Verifique os logs para mais detalhes.",
                            "Erro", JOptionPane.ERROR_MESSAGE);
                }
            } catch (Exception ex) {
                logger.error("Erro ao cancelar venda", ex);
                JOptionPane.showMessageDialog(this,
                        "Erro ao cancelar venda: " + ex.getMessage(),
                        "Erro", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    public boolean isCancelled() {
        return cancelled;
    }
}
