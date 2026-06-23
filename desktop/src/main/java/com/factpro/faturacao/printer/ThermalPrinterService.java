package com.factpro.faturacao.printer;

import com.factpro.core.util.CurrencyFormatter;
import com.factpro.vendas.model.Pagamento;
import com.factpro.vendas.model.Venda;
import com.factpro.vendas.model.VendaItem;
import com.fazecast.jSerialComm.SerialPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.OutputStream;
import java.util.List;

/**
 * ESC/POS thermal printer service for receipt printing.
 * Supports serial (USB/COM) and network (TCP) printers.
 */
public class ThermalPrinterService {

    private static final Logger logger = LoggerFactory.getLogger(ThermalPrinterService.class);

    // ESC/POS Commands
    private static final byte[] INIT = {0x1B, 0x40};
    private static final byte[] ALIGN_LEFT = {0x1B, 0x61, 0x00};
    private static final byte[] ALIGN_CENTER = {0x1B, 0x61, 0x01};
    private static final byte[] ALIGN_RIGHT = {0x1B, 0x61, 0x02};
    private static final byte[] BOLD_ON = {0x1B, 0x45, 0x01};
    private static final byte[] BOLD_OFF = {0x1B, 0x45, 0x00};
    private static final byte[] CUT_PAPER = {0x1D, 0x56, 0x42, 0x00};
    private static final byte[] FEED_LINES = {0x1B, 0x64, 0x03};
    private static final byte[] OPEN_DRAWER = {0x1B, 0x70, 0x00, 0x32, (byte) 0xFA};

    private static final int PAPER_WIDTH = 48; // characters for 80mm paper

    private String printerAddress;
    private int printerPort;
    private SerialPort serialPort;
    private java.net.Socket socket;

    /**
     * Creates a printer service for serial/USB connection.
     *
     * @param portName Serial port name (e.g., "COM3", "/dev/ttyUSB0")
     */
    public ThermalPrinterService(String portName) {
        this.printerAddress = portName;
        this.printerPort = 0;
    }

    /**
     * Creates a printer service for network (TCP) connection.
     *
     * @param address IP address or hostname
     * @param port    Port number (commonly 9100)
     */
    public ThermalPrinterService(String address, int port) {
        this.printerAddress = address;
        this.printerPort = port;
    }

    /**
     * Prints a full receipt including header, items, totals, payments, and footer.
     */
    public void printReceipt(Venda venda, List<VendaItem> items, List<Pagamento> pagamentos) {
        try {
            OutputStream os = openConnection();
            if (os == null) {
                logger.error("Cannot open printer connection");
                return;
            }

            write(os, INIT);

            // Header
            write(os, ALIGN_CENTER);
            write(os, BOLD_ON);
            write(os, "FACTPRO\n");
            write(os, BOLD_OFF);
            write(os, "Sistema de Faturacao\n");
            write(os, "--------------------------------\n");

            // Document info
            write(os, ALIGN_LEFT);
            String docNumber = (venda.getSerieDocumento() != null ? venda.getSerieDocumento() : "FT")
                    + " " + (venda.getNumeroDocumento() != null ? venda.getNumeroDocumento() : "N/A");
            write(os, "Nº Doc: " + docNumber + "\n");
            write(os, "Data:   " + (venda.getCriadaEm() != null ? venda.getCriadaEm() : "N/A") + "\n");
            write(os, "--------------------------------\n");

            // Items header
            write(os, BOLD_ON);
            write(os, String.format("%-20s %5s %10s %12s\n", "Produto", "Qtd", "Preco", "Total"));
            write(os, BOLD_OFF);
            write(os, "--------------------------------\n");

            // Items
            if (items != null) {
                com.factpro.produtos.dao.ProdutoDAO produtoDAO = new com.factpro.produtos.dao.ProdutoDAO();
                for (VendaItem item : items) {
                    com.factpro.produtos.model.Produto p = produtoDAO.findById(item.getProdutoId());
                    String nome = p != null ? p.getNome() : "Produto #" + item.getProdutoId();
                    if (nome.length() > 19) nome = nome.substring(0, 19);
                    write(os, String.format("%-20s %5.0f %10s %12s\n",
                            nome,
                            item.getQuantidade(),
                            CurrencyFormatter.formatWithoutSymbol(item.getPrecoUnitario()),
                            CurrencyFormatter.formatWithoutSymbol(item.getTotal())));
                }
            }

            write(os, "--------------------------------\n");

            // Totals
            write(os, ALIGN_RIGHT);
            write(os, String.format("Subtotal: %12s\n", CurrencyFormatter.formatWithoutSymbol(venda.getSubtotal())));
            if (venda.getDesconto() != null && venda.getDesconto() > 0) {
                write(os, String.format("Desconto: %12s\n", CurrencyFormatter.formatWithoutSymbol(venda.getDesconto())));
            }
            write(os, BOLD_ON);
            write(os, String.format("TOTAL:    %12s\n", CurrencyFormatter.formatWithoutSymbol(venda.getTotal())));
            write(os, BOLD_OFF);
            write(os, "--------------------------------\n");

            // Payments
            write(os, ALIGN_LEFT);
            write(os, "Pagamento: " + (venda.getMetodoPagamento() != null ? venda.getMetodoPagamento() : "-") + "\n");
            if (pagamentos != null) {
                for (Pagamento pg : pagamentos) {
                    write(os, String.format("  %-15s %12s\n", pg.getMetodo(), CurrencyFormatter.formatWithoutSymbol(pg.getValor())));
                }
            }
            write(os, "--------------------------------\n");

            // Footer
            write(os, ALIGN_CENTER);
            write(os, "\nObrigado pela sua preferencia!\n");
            write(os, "Volte sempre!\n");
            write(os, FEED_LINES);
            write(os, CUT_PAPER);

            closeConnection();
            logger.info("Receipt printed for venda {}", venda.getId());
        } catch (IOException e) {
            logger.error("Error printing receipt", e);
        }
    }

    /**
     * Prints a test page to verify printer connection.
     */
    public void testPrint() {
        try {
            OutputStream os = openConnection();
            if (os == null) {
                logger.error("Cannot open printer connection for test print");
                return;
            }

            write(os, INIT);
            write(os, ALIGN_CENTER);
            write(os, BOLD_ON);
            write(os, "=== TEST PRINT ===\n");
            write(os, BOLD_OFF);
            write(os, "FactPro Thermal Printer Test\n");
            write(os, "Date: " + java.time.LocalDateTime.now() + "\n");
            write(os, "Printer: " + printerAddress + "\n");
            write(os, FEED_LINES);
            write(os, CUT_PAPER);

            closeConnection();
            logger.info("Test print completed");
        } catch (IOException e) {
            logger.error("Error during test print", e);
        }
    }

    /**
     * Tests the printer connection and returns true if successful.
     */
    public boolean testConnection() {
        try {
            OutputStream os = openConnection();
            if (os != null) {
                closeConnection();
                return true;
            }
        } catch (Exception e) {
            logger.error("Connection test failed", e);
        }
        return false;
    }

    private OutputStream openConnection() throws IOException {
        if (printerPort > 0) {
            // Network connection
            socket = new java.net.Socket(printerAddress, printerPort);
            return socket.getOutputStream();
        } else {
            // Serial connection
            serialPort = SerialPort.getCommPort(printerAddress);
            serialPort.setComPortParameters(9600, 8, 1, SerialPort.NO_PARITY);
            serialPort.setComPortTimeouts(SerialPort.TIMEOUT_WRITE_BLOCKING, 0, 0);
            if (serialPort.openPort()) {
                return serialPort.getOutputStream();
            }
        }
        return null;
    }

    private void closeConnection() throws IOException {
        if (serialPort != null && serialPort.isOpen()) {
            serialPort.closePort();
        }
        if (socket != null && !socket.isClosed()) {
            socket.close();
        }
    }

    private void write(OutputStream os, String text) throws IOException {
        os.write(text.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        os.flush();
    }

    private void write(OutputStream os, byte[] command) throws IOException {
        os.write(command);
        os.flush();
    }
}
