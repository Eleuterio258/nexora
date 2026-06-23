package com.factpro.faturacao.service;

import com.factpro.core.util.CurrencyFormatter;
import com.factpro.vendas.model.Pagamento;
import com.factpro.vendas.model.Venda;
import com.factpro.vendas.model.VendaItem;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.util.List;

/**
 * Receipt generation service using Apache PDFBox.
 * Supports PDF generation, email sending, and WhatsApp messaging.
 */
public class ReciboService {

    private static final Logger logger = LoggerFactory.getLogger(ReciboService.class);

    private static final float PAGE_WIDTH = 220; // 80mm receipt width in points
    private static final float MARGIN = 10;
    private static final float FONT_SIZE_SMALL = 7;
    private static final float FONT_SIZE_NORMAL = 8;
    private static final float FONT_SIZE_BOLD = 9;
    private static final float FONT_SIZE_LARGE = 12;

    /**
     * Generates a PDF receipt for the given sale.
     *
     * @param venda       The sale record
     * @param items       The sale items
     * @param pagamentos  The payment records
     * @param outputFile  The output PDF file
     */
    public void generatePDF(Venda venda, List<VendaItem> items, List<Pagamento> pagamentos, File outputFile) {
        try (PDDocument document = new PDDocument()) {
            PDPage page = new PDPage(new PDRectangle(PAGE_WIDTH, 400));
            document.addPage(page);

            try (PDPageContentStream content = new PDPageContentStream(document, page)) {
                float y = page.getMediaBox().getHeight() - MARGIN;

                // Header
                y = drawCenteredText(content, "FACTPRO", FONT_SIZE_LARGE, true, y);
                y = drawCenteredText(content, "Sistema de Faturacao", FONT_SIZE_SMALL, false, y);
                y = drawLine(content, y);

                // Document info
                String docNumber = (venda.getSerieDocumento() != null ? venda.getSerieDocumento() : "FT")
                        + " " + (venda.getNumeroDocumento() != null ? venda.getNumeroDocumento() : "N/A");
                y = drawLeftText(content, "Nº Doc: " + docNumber, FONT_SIZE_NORMAL, y);
                y = drawLeftText(content, "Data: " + (venda.getCriadaEm() != null ? venda.getCriadaEm() : "N/A"),
                        FONT_SIZE_SMALL, y);
                y = drawLine(content, y);

                // Items header
                y = drawTextAt(content, "Produto", MARGIN, y, FONT_SIZE_SMALL, true);
                y = drawTextAt(content, "Qtd", PAGE_WIDTH * 0.55f, y + FONT_SIZE_SMALL + 1, FONT_SIZE_SMALL, true);
                y = drawTextAt(content, "Total", PAGE_WIDTH * 0.78f, y + FONT_SIZE_SMALL + 1, FONT_SIZE_SMALL, true);
                y -= FONT_SIZE_SMALL + 2;
                y = drawLine(content, y);

                // Items
                if (items != null) {
                    com.factpro.produtos.dao.ProdutoDAO produtoDAO = new com.factpro.produtos.dao.ProdutoDAO();
                    for (VendaItem item : items) {
                        com.factpro.produtos.model.Produto p = produtoDAO.findById(item.getProdutoId());
                        String nome = p != null ? p.getNome() : "Produto #" + item.getProdutoId();
                        if (nome.length() > 16) nome = nome.substring(0, 16);

                        y = drawTextAt(content, nome, MARGIN, y, FONT_SIZE_SMALL, false);
                        y = drawTextAt(content, String.valueOf(item.getQuantidade().intValue()),
                                PAGE_WIDTH * 0.55f, y, FONT_SIZE_SMALL, false);
                        y = drawTextAt(content, CurrencyFormatter.formatWithoutSymbol(item.getTotal()),
                                PAGE_WIDTH * 0.72f, y, FONT_SIZE_SMALL, false);
                        y -= FONT_SIZE_SMALL + 2;
                    }
                }

                y = drawLine(content, y);

                // Totals
                y = drawRightText(content, "Subtotal: " + CurrencyFormatter.formatWithoutSymbol(venda.getSubtotal()),
                        PAGE_WIDTH - MARGIN, FONT_SIZE_SMALL, false, y);
                if (venda.getDesconto() != null && venda.getDesconto() > 0) {
                    y = drawRightText(content, "Desconto: " + CurrencyFormatter.formatWithoutSymbol(venda.getDesconto()),
                            PAGE_WIDTH - MARGIN, FONT_SIZE_SMALL, false, y);
                }
                y = drawRightText(content, "TOTAL: " + CurrencyFormatter.formatWithoutSymbol(venda.getTotal()),
                        PAGE_WIDTH - MARGIN, FONT_SIZE_BOLD, true, y);

                y = drawLine(content, y);

                // Payment info
                y = drawLeftText(content, "Pagamento: " + (venda.getMetodoPagamento() != null ? venda.getMetodoPagamento() : "-"),
                        FONT_SIZE_SMALL, y);

                if (pagamentos != null) {
                    for (Pagamento pg : pagamentos) {
                        y = drawLeftText(content, "  " + pg.getMetodo() + ": " + CurrencyFormatter.format(pg.getValor()),
                                FONT_SIZE_SMALL, y);
                    }
                }

                y = drawLine(content, y);

                // Footer
                y -= 10;
                y = drawCenteredText(content, "Obrigado pela sua preferencia!", FONT_SIZE_SMALL, false, y);
                y = drawCenteredText(content, "Volte sempre!", FONT_SIZE_SMALL, false, y);
            }

            document.save(outputFile);
            logger.info("PDF receipt generated: {}", outputFile.getAbsolutePath());
        } catch (IOException e) {
            logger.error("Error generating PDF receipt", e);
            throw new RuntimeException("Erro ao gerar recibo PDF: " + e.getMessage(), e);
        }
    }

    /**
     * Sends the receipt PDF by email (placeholder implementation).
     *
     * @param email    Recipient email address
     * @param pdfFile  The PDF file to send
     */
    public void sendByEmail(String email, File pdfFile) {
        logger.info("Email sending placeholder - would send {} to {}", pdfFile.getName(), email);
        // TODO: Implement email sending using JavaMail or similar
        // This would require adding javax.mail dependency
    }

    /**
     * Sends a receipt message via WhatsApp (placeholder implementation).
     *
     * @param telefone  Recipient phone number
     * @param mensagem  The message to send
     */
    public void sendByWhatsApp(String telefone, String mensagem) {
        logger.info("WhatsApp sending placeholder - would send message to {}", telefone);
        // TODO: Implement WhatsApp API integration (e.g., using Twilio or WhatsApp Business API)
    }

    /**
     * Generates a formatted WhatsApp message for a sale.
     *
     * @param venda The sale record
     * @return Formatted message string
     */
    public String generateWhatsAppMessage(Venda venda) {
        StringBuilder sb = new StringBuilder();
        sb.append("*FACTPRO - Recibo*\n");
        sb.append("━━━━━━━━━━━━━━━━━━━━\n\n");

        String docNumber = (venda.getSerieDocumento() != null ? venda.getSerieDocumento() : "FT")
                + " " + (venda.getNumeroDocumento() != null ? venda.getNumeroDocumento() : "N/A");
        sb.append("Nº Doc: ").append(docNumber).append("\n");
        sb.append("Data: ").append(venda.getCriadaEm() != null ? venda.getCriadaEm() : "N/A").append("\n\n");

        if (venda.getSubtotal() != null) {
            sb.append("Subtotal: ").append(CurrencyFormatter.format(venda.getSubtotal())).append("\n");
        }
        if (venda.getDesconto() != null && venda.getDesconto() > 0) {
            sb.append("Desconto: ").append(CurrencyFormatter.format(venda.getDesconto())).append("\n");
        }
        sb.append("\n*TOTAL: ").append(CurrencyFormatter.format(venda.getTotal() != null ? venda.getTotal() : 0.0)).append("*\n");
        sb.append("Pagamento: ").append(venda.getMetodoPagamento() != null ? venda.getMetodoPagamento() : "-").append("\n\n");
        sb.append("Obrigado pela sua preferencia!\n");
        sb.append("Volte sempre!");

        return sb.toString();
    }

    // ==================== Helper Methods ====================

    private float drawCenteredText(PDPageContentStream content, String text, float fontSize,
                                   boolean bold, float y) throws IOException {
        content.beginText();
        if (bold) {
            content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), fontSize);
        } else {
            content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), fontSize);
        }
        float textWidth = new PDType1Font(bold ? Standard14Fonts.FontName.HELVETICA_BOLD : Standard14Fonts.FontName.HELVETICA).getStringWidth(text) / 1000 * fontSize;
        float x = (PAGE_WIDTH - textWidth) / 2;
        content.newLineAtOffset(x, y);
        content.showText(text);
        content.endText();
        return y - fontSize - 2;
    }

    private float drawLeftText(PDPageContentStream content, String text, float fontSize, float y) throws IOException {
        return drawTextAt(content, text, MARGIN, y, fontSize, false);
    }

    private float drawTextAt(PDPageContentStream content, String text, float x, float y,
                             float fontSize, boolean bold) throws IOException {
        content.beginText();
        if (bold) {
            content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), fontSize);
        } else {
            content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), fontSize);
        }
        content.newLineAtOffset(x, y);
        content.showText(text);
        content.endText();
        return y - fontSize - 2;
    }

    private float drawRightText(PDPageContentStream content, String text, float x,
                                float fontSize, boolean bold, float y) throws IOException {
        content.beginText();
        if (bold) {
            content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), fontSize);
        } else {
            content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), fontSize);
        }
        float textWidth = new PDType1Font(bold ? Standard14Fonts.FontName.HELVETICA_BOLD : Standard14Fonts.FontName.HELVETICA).getStringWidth(text) / 1000 * fontSize;
        content.newLineAtOffset(x - textWidth, y);
        content.showText(text);
        content.endText();
        return y - fontSize - 2;
    }

    private float drawLine(PDPageContentStream content, float y) throws IOException {
        content.moveTo(MARGIN, y - 2);
        content.lineTo(PAGE_WIDTH - MARGIN, y - 2);
        content.stroke();
        return y - 6;
    }
}
