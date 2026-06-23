package com.factpro.vendas.view;

import com.factpro.auth.SessionManager;
import com.factpro.clientes.dao.ClienteDAO;
import com.factpro.clientes.model.Cliente;
import com.factpro.core.util.CurrencyFormatter;
import com.factpro.faturacao.printer.ThermalPrinterService;
import com.factpro.faturacao.service.ReciboService;
import com.factpro.vendas.dao.PagamentoDAO;
import com.factpro.vendas.dao.VendaDAO;
import com.factpro.vendas.dao.VendaItemDAO;
import com.factpro.vendas.model.Pagamento;
import com.factpro.vendas.model.Venda;
import com.factpro.vendas.model.VendaItem;
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
import java.io.File;
import java.util.List;

/**
 * Receipt preview dialog with formatted receipt display and action buttons.
 */
public class ReciboPreviewDialog extends JDialog {

    private static final Logger logger = LoggerFactory.getLogger(ReciboPreviewDialog.class);

    private final Venda venda;
    private final JTextArea receiptArea;

    public ReciboPreviewDialog(Frame parent, Venda venda) {
        super(parent, "Recibo - " + venda.getSerieDocumento() + " " + venda.getNumeroDocumento(), true);
        this.venda = venda;

        setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
        setSize(400, 600);
        setLocationRelativeTo(parent);

        receiptArea = new JTextArea();
        receiptArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        receiptArea.setEditable(false);
        receiptArea.setBackground(new Color(255, 253, 240)); // Receipt paper color

        initComponents();
        setupLayout();
        populateReceipt();
    }

    private void initComponents() {
        // No additional initialization needed
    }

    private void setupLayout() {
        setLayout(new MigLayout("fill, wrap 1, ins 10, gap 8", "[grow]"));

        // Receipt preview
        JScrollPane scrollPane = new JScrollPane(receiptArea);
        scrollPane.setBorder(new CompoundBorder(
                new LineBorder(new Color(200, 200, 200), 1, true),
                new EmptyBorder(5, 5, 5, 5)));
        add(scrollPane, "grow, h 400");

        // Buttons
        JPanel btnPanel = new JPanel(new MigLayout("fillx, ins 5, gap 5, wrap 3", "[grow][grow][grow]"));

        JButton btnImprimir = new JButton("Imprimir");
        JButton btnPDF = new JButton("Salvar PDF");
        JButton btnEmail = new JButton("Enviar Email");
        JButton btnWhatsApp = new JButton("WhatsApp");
        JButton btnFechar = new JButton("Fechar");

        styleBtn(btnImprimir, new Color(57, 113, 227));
        styleBtn(btnPDF, new Color(220, 53, 69));
        styleBtn(btnEmail, new Color(100, 100, 100));
        styleBtn(btnWhatsApp, new Color(37, 211, 102));

        btnPanel.add(btnImprimir, "grow, h 35");
        btnPanel.add(btnPDF, "grow, h 35");
        btnPanel.add(btnEmail, "grow, h 35");
        btnPanel.add(btnWhatsApp, "grow, h 35");
        btnPanel.add(btnFechar, "grow, h 35");
        add(btnPanel, "growx");

        btnImprimir.addActionListener(e -> printReceipt());
        btnPDF.addActionListener(e -> savePDF());
        btnEmail.addActionListener(e -> sendEmail());
        btnWhatsApp.addActionListener(e -> sendWhatsApp());
        btnFechar.addActionListener(e -> dispose());

        getRootPane().setDefaultButton(btnFechar);
        KeyStroke escape = KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(escape, "cancel");
        getRootPane().getActionMap().put("cancel", new AbstractAction() {
            @Override public void actionPerformed(ActionEvent e) { dispose(); }
        });
    }

    private void populateReceipt() {
        StringBuilder sb = new StringBuilder();

        // Header
        sb.append("         ").append("*".repeat(30)).append("\n");
        sb.append("              FACTPRO\n");
        sb.append("     Sistema de Faturacao\n");
        sb.append("         ").append("*".repeat(30)).append("\n\n");

        // Document info
        String docNumber = (venda.getSerieDocumento() != null ? venda.getSerieDocumento() : "FT")
                + " " + (venda.getNumeroDocumento() != null ? venda.getNumeroDocumento() : "N/A");
        sb.append("  Nº Doc: ").append(docNumber).append("\n");
        sb.append("  Data:   ").append(venda.getCriadaEm() != null ? venda.getCriadaEm() : "N/A").append("\n");

        // Client info
        if (venda.getClienteId() != null) {
            ClienteDAO clienteDAO = new ClienteDAO();
            Cliente cliente = clienteDAO.findById(venda.getClienteId());
            if (cliente != null) {
                sb.append("  Cliente: ").append(cliente.getNome()).append("\n");
            }
        } else {
            sb.append("  Cliente: Balcao\n");
        }

        sb.append("  Terminal: ").append(venda.getTerminal() != null ? venda.getTerminal() : "N/A").append("\n");
        sb.append("  ").append("-".repeat(30)).append("\n\n");

        // Items
        sb.append("  Produto             Qtd    Total\n");
        sb.append("  ").append("-".repeat(30)).append("\n");

        VendaItemDAO vendaItemDAO = new VendaItemDAO();
        List<VendaItem> items = vendaItemDAO.findByVendaId(venda.getId());
        com.factpro.produtos.dao.ProdutoDAO produtoDAO = new com.factpro.produtos.dao.ProdutoDAO();

        for (VendaItem item : items) {
            com.factpro.produtos.model.Produto p = produtoDAO.findById(item.getProdutoId());
            String nome = p != null ? p.getNome() : "Produto #" + item.getProdutoId();
            if (nome.length() > 18) nome = nome.substring(0, 18);

            sb.append(String.format("  %-18s %4.0f %9s\n",
                    nome,
                    item.getQuantidade(),
                    CurrencyFormatter.formatWithoutSymbol(item.getTotal())));
        }

        sb.append("  ").append("-".repeat(30)).append("\n\n");

        // Totals
        sb.append(String.format("  Subtotal: %16s\n", CurrencyFormatter.formatWithoutSymbol(venda.getSubtotal())));
        if (venda.getDesconto() != null && venda.getDesconto() > 0) {
            sb.append(String.format("  Desconto: %16s\n", CurrencyFormatter.formatWithoutSymbol(venda.getDesconto())));
        }
        sb.append(String.format("  TOTAL:    %16s\n", CurrencyFormatter.formatWithoutSymbol(venda.getTotal())));
        sb.append("  ").append("-".repeat(30)).append("\n\n");

        // Payments
        sb.append("  Pagamento: ").append(venda.getMetodoPagamento() != null ? venda.getMetodoPagamento() : "-").append("\n");

        PagamentoDAO pagamentoDAO = new PagamentoDAO();
        List<Pagamento> pagamentos = pagamentoDAO.findByVendaId(venda.getId());
        if (!pagamentos.isEmpty()) {
            for (Pagamento pg : pagamentos) {
                sb.append(String.format("    %-14s %13s\n", pg.getMetodo(), CurrencyFormatter.formatWithoutSymbol(pg.getValor())));
            }
        }

        sb.append("\n  ").append("-".repeat(30)).append("\n\n");

        // Footer
        sb.append("   Obrigado pela sua\n");
        sb.append("     preferencia!\n");
        sb.append("     Volte sempre!\n\n");
        sb.append("   ").append("*".repeat(24)).append("\n");

        receiptArea.setText(sb.toString());
        receiptArea.setCaretPosition(0);
    }

    private void printReceipt() {
        try {
            ThermalPrinterService printer = new ThermalPrinterService("COM3"); // Default port
            VendaItemDAO vendaItemDAO = new VendaItemDAO();
            PagamentoDAO pagamentoDAO = new PagamentoDAO();
            List<VendaItem> items = vendaItemDAO.findByVendaId(venda.getId());
            List<Pagamento> pagamentos = pagamentoDAO.findByVendaId(venda.getId());

            printer.printReceipt(venda, items, pagamentos);
            JOptionPane.showMessageDialog(this, "Recibo enviado para impressao.",
                    "Imprimir", JOptionPane.INFORMATION_MESSAGE);
        } catch (Exception e) {
            logger.error("Erro ao imprimir recibo", e);
            JOptionPane.showMessageDialog(this,
                    "Erro ao imprimir: " + e.getMessage() + "\nVerifique a conexao da impressora.",
                    "Erro de Impressao", JOptionPane.ERROR_MESSAGE);
        }
    }

    private void savePDF() {
        JFileChooser chooser = new JFileChooser();
        String fileName = "recibo_" + venda.getSerieDocumento() + "_" + venda.getNumeroDocumento() + ".pdf";
        chooser.setSelectedFile(new File(fileName));
        chooser.setFileFilter(new javax.swing.filechooser.FileNameExtensionFilter("PDF Files", "pdf"));

        if (chooser.showSaveDialog(this) == JFileChooser.APPROVE_OPTION) {
            File file = chooser.getSelectedFile();
            try {
                ReciboService reciboService = new ReciboService();
                VendaItemDAO vendaItemDAO = new VendaItemDAO();
                PagamentoDAO pagamentoDAO = new PagamentoDAO();
                List<VendaItem> items = vendaItemDAO.findByVendaId(venda.getId());
                List<Pagamento> pagamentos = pagamentoDAO.findByVendaId(venda.getId());

                reciboService.generatePDF(venda, items, pagamentos, file);
                JOptionPane.showMessageDialog(this, "PDF guardado com sucesso em:\n" + file.getAbsolutePath(),
                        "PDF Guardado", JOptionPane.INFORMATION_MESSAGE);
            } catch (Exception e) {
                logger.error("Erro ao gerar PDF", e);
                JOptionPane.showMessageDialog(this, "Erro ao gerar PDF: " + e.getMessage(),
                        "Erro", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    private void sendEmail() {
        String email = JOptionPane.showInputDialog(this, "Informe o email do destinatario:",
                "Enviar por Email", JOptionPane.QUESTION_MESSAGE);

        if (email != null && !email.isBlank()) {
            // Placeholder - would use ReciboService.sendByEmail
            JOptionPane.showMessageDialog(this,
                    "Funcionalidade de envio por email em desenvolvimento.\nEmail: " + email,
                    "Enviar Email", JOptionPane.INFORMATION_MESSAGE);
        }
    }

    private void sendWhatsApp() {
        ReciboService reciboService = new ReciboService();
        String message = reciboService.generateWhatsAppMessage(venda);

        // Copy to clipboard
        Toolkit.getDefaultToolkit().getSystemClipboard().setContents(
                new java.awt.datatransfer.StringSelection(message), null);

        JOptionPane.showMessageDialog(this,
                "Mensagem copiada para a area de transferencia.\nCole no WhatsApp Web ou app.",
                "WhatsApp", JOptionPane.INFORMATION_MESSAGE);

        // Try to open WhatsApp Web
        try {
            Desktop desktop = Desktop.getDesktop();
            desktop.browse(new java.net.URI("https://web.whatsapp.com"));
        } catch (Exception e) {
            logger.debug("Could not open WhatsApp Web", e);
        }
    }

    private void styleBtn(JButton btn, Color bgColor) {
        btn.setFont(btn.getFont().deriveFont(Font.PLAIN, 12f));
        btn.setBackground(bgColor);
        btn.setForeground(Color.WHITE);
        btn.setFocusPainted(false);
    }
}
