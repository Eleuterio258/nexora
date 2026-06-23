package com.factpro.vendas.view;

import com.factpro.auth.SessionManager;
import com.factpro.clientes.dao.ClienteDAO;
import com.factpro.clientes.model.Cliente;
import com.factpro.clientes.service.ClienteService;
import com.factpro.core.event.EventManager;
import com.factpro.core.util.CurrencyFormatter;
import com.factpro.produtos.dao.CategoriaDAO;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Categoria;
import com.factpro.produtos.model.Produto;
import com.factpro.produtos.service.ProdutoService;
import com.factpro.stock.dao.StockMovimentoDAO;
import com.factpro.vendas.dao.PagamentoDAO;
import com.factpro.vendas.dao.VendaDAO;
import com.factpro.vendas.dao.VendaItemDAO;
import com.factpro.vendas.model.Pagamento;
import com.factpro.vendas.model.Venda;
import com.factpro.vendas.model.VendaItem;
import com.factpro.vendas.service.CarrinhoService;
import com.factpro.vendas.service.PagamentoService;
import com.factpro.vendas.service.VendaService;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.CompoundBorder;
import javax.swing.border.EmptyBorder;
import javax.swing.border.TitledBorder;
import javax.swing.table.DefaultTableCellRenderer;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.InputEvent;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.ArrayList;
import java.util.List;

/**
 * Point of Sale panel with product search, cart management, and sale finalization.
 */
public class POSPanel extends JPanel {

    private static final Logger logger = LoggerFactory.getLogger(POSPanel.class);

    // Services & DAOs
    private final ProdutoDAO produtoDAO;
    private final ProdutoService produtoService;
    private final VendaDAO vendaDAO;
    private final VendaItemDAO vendaItemDAO;
    private final StockMovimentoDAO stockMovimentoDAO;
    private final PagamentoDAO pagamentoDAO;
    private final VendaService vendaService;
    private final PagamentoService pagamentoService;
    private final ClienteDAO clienteDAO;
    private final ClienteService clienteService;
    private final CategoriaDAO categoriaDAO;
    private final CarrinhoService carrinhoService;

    // LEFT side components
    private JTextField searchField;
    private JTable productsTable;
    private ProductsTableModel productsTableModel;
    private JPanel categoryButtonsPanel;
    private List<Produto> allProducts;

    // RIGHT side components
    private JTable cartTable;
    private CartTableModel cartTableModel;
    private JTextField descontoField;
    private JLabel totalLabel;
    private JLabel subtotalLabel;
    private String selectedPaymentMethod;
    private JSplitPane splitPane;

    // Payment buttons
    private final List<JToggleButton> paymentButtons = new ArrayList<>();
    private final ButtonGroup paymentGroup = new ButtonGroup();

    // Colors
    private static final Color GREEN    = new Color(22, 163, 74);
    private static final Color RED      = new Color(220, 38,  38);
    private static final Color BLUE     = new Color(37,  99, 235);
    private static final Color INK      = new Color(15,  23,  42);
    private static final Color MUTED    = new Color(100, 116, 139);
    private static final Color BORDER_C = new Color(226, 232, 240);
    private static final Color SURFACE  = new Color(248, 250, 252);

    public POSPanel() {
        produtoDAO = new ProdutoDAO();
        categoriaDAO = new CategoriaDAO();
        stockMovimentoDAO = new StockMovimentoDAO();
        produtoService = new ProdutoService(produtoDAO, categoriaDAO, stockMovimentoDAO);

        vendaDAO = new VendaDAO();
        vendaItemDAO = new VendaItemDAO();
        pagamentoDAO = new PagamentoDAO();
        vendaService = new VendaService(vendaDAO, vendaItemDAO, produtoDAO, stockMovimentoDAO, pagamentoDAO);
        pagamentoService = new PagamentoService(pagamentoDAO);

        clienteDAO = new ClienteDAO();
        clienteService = new ClienteService(clienteDAO);
        carrinhoService = CarrinhoService.getInstance();
        allProducts = new ArrayList<>();

        setLayout(new BorderLayout());
        setBackground(SURFACE);
        setBorder(new EmptyBorder(8, 8, 8, 8));

        initComponents();
        setupLayout();
        setupListeners();
        installKeyboardShortcuts();
        loadProducts();
        loadCategories();
    }

    private void initComponents() {
        searchField = new JTextField();
        searchField.setFont(searchField.getFont().deriveFont(14f));
        searchField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT,
                "Pesquisar produto ou código de barras…");
        searchField.putClientProperty(FlatClientProperties.STYLE,
                "arc:10; innerFocusWidth:2; focusedBorderColor:#2563eb; margin:6,10,6,10");

        String[] productCols = {"Código", "Nome", "Preço", "Stock"};
        productsTableModel = new ProductsTableModel(productCols);
        productsTable = new JTable(productsTableModel);
        productsTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        productsTable.setRowHeight(32);
        productsTable.setShowGrid(false);
        productsTable.setIntercellSpacing(new Dimension(0, 0));
        productsTable.getTableHeader().setReorderingAllowed(false);
        productsTable.getColumnModel().getColumn(0).setPreferredWidth(90);
        productsTable.getColumnModel().getColumn(0).setMaxWidth(110);
        productsTable.getColumnModel().getColumn(2).setPreferredWidth(90);
        productsTable.getColumnModel().getColumn(2).setMaxWidth(110);
        productsTable.getColumnModel().getColumn(3).setPreferredWidth(70);
        productsTable.getColumnModel().getColumn(3).setMaxWidth(90);
        productsTable.getColumnModel().getColumn(2).setCellRenderer(new CurrencyRenderer());
        productsTable.getColumnModel().getColumn(3).setCellRenderer(new StockRenderer());

        String[] cartCols = {"Produto", "Qtd", "Preço", "Total", ""};
        cartTableModel = new CartTableModel(cartCols);
        cartTable = new JTable(cartTableModel);
        cartTable.setRowHeight(34);
        cartTable.setShowGrid(false);
        cartTable.setIntercellSpacing(new Dimension(0, 0));
        cartTable.getTableHeader().setReorderingAllowed(false);
        cartTable.getColumnModel().getColumn(1).setPreferredWidth(58);
        cartTable.getColumnModel().getColumn(1).setMaxWidth(70);
        cartTable.getColumnModel().getColumn(2).setPreferredWidth(90);
        cartTable.getColumnModel().getColumn(2).setMaxWidth(110);
        cartTable.getColumnModel().getColumn(3).setPreferredWidth(100);
        cartTable.getColumnModel().getColumn(3).setMaxWidth(120);
        cartTable.getColumnModel().getColumn(4).setPreferredWidth(62);
        cartTable.getColumnModel().getColumn(4).setMaxWidth(62);
        cartTable.getColumnModel().getColumn(1).setCellRenderer(new QtyRenderer());
        cartTable.getColumnModel().getColumn(1).setCellEditor(new QtyEditor());
        cartTable.getColumnModel().getColumn(2).setCellRenderer(new CurrencyRenderer());
        cartTable.getColumnModel().getColumn(3).setCellRenderer(new CurrencyRenderer());
        cartTable.getColumnModel().getColumn(4).setCellRenderer(new ButtonRenderer());
        cartTable.getColumnModel().getColumn(4).setCellEditor(new ButtonEditor());

        subtotalLabel = new JLabel("0,00 MT");
        subtotalLabel.setFont(subtotalLabel.getFont().deriveFont(Font.PLAIN, 14f));
        subtotalLabel.setHorizontalAlignment(SwingConstants.RIGHT);

        descontoField = new JTextField("0.00", 8);
        descontoField.setHorizontalAlignment(SwingConstants.RIGHT);
        descontoField.putClientProperty(FlatClientProperties.STYLE, "arc:8; margin:4,8,4,8");

        totalLabel = new JLabel("0,00 MT");
        totalLabel.setFont(totalLabel.getFont().deriveFont(Font.BOLD, 26f));
        totalLabel.setForeground(BLUE);
        totalLabel.setHorizontalAlignment(SwingConstants.RIGHT);

        categoryButtonsPanel = new JPanel(new MigLayout("ins 0, gap 6, wrap 4",
                "[grow,fill][grow,fill][grow,fill][grow,fill]"));
        categoryButtonsPanel.setOpaque(false);

        String[] paymentMethods = {"Dinheiro", "Cartão", "M-Pesa", "e-Mola", "Transf.", "Fiado"};
        for (String method : paymentMethods) {
            JToggleButton btn = new JToggleButton(method);
            btn.setFont(btn.getFont().deriveFont(Font.BOLD, 13f));
            btn.putClientProperty(FlatClientProperties.STYLE,
                    "arc:10; selectedBackground:#dbeafe; selectedForeground:#1d4ed8; " +
                    "hoverBackground:#f1f5f9");
            paymentGroup.add(btn);
            paymentButtons.add(btn);
        }
    }

    private void setupLayout() {
        JPanel root = new JPanel(new MigLayout("fill, ins 0, gap 8", "[grow 42][grow 58]", "[grow]"));
        root.setOpaque(false);
        root.add(buildLeftCard(),  "grow");
        root.add(buildRightCard(), "grow");
        add(root, BorderLayout.CENTER);
    }

    // ── Left card: products ──────────────────────────────────

    private JPanel buildLeftCard() {
        JPanel card = makeCard();
        card.setLayout(new MigLayout("fill, ins 0, gap 0, wrap 1", "[grow]"));

        card.add(sectionHeader("Produtos", "F2  •  duplo clique para adicionar"), "growx");

        JPanel searchWrap = transparent(new MigLayout("fill, ins 10 10 6 10", "[grow]"));
        searchWrap.add(searchField, "growx, h 46!");
        card.add(searchWrap, "growx");

        JScrollPane catScroll = cleanScroll(categoryButtonsPanel);
        catScroll.setHorizontalScrollBarPolicy(ScrollPaneConstants.HORIZONTAL_SCROLLBAR_NEVER);
        catScroll.setVerticalScrollBarPolicy(ScrollPaneConstants.VERTICAL_SCROLLBAR_AS_NEEDED);
        JPanel catWrap = transparent(new MigLayout("fill, ins 0 10 8 10", "[grow]"));
        catWrap.add(catScroll, "grow, hmax 90");
        card.add(catWrap, "growx");

        JSeparator sep = new JSeparator();
        sep.setForeground(BORDER_C);
        card.add(sep, "growx, h 1!");

        card.add(cleanScroll(productsTable), "grow, push");

        return card;
    }

    // ── Right card: cart + checkout ──────────────────────────

    private JPanel buildRightCard() {
        JPanel card = makeCard();
        card.setLayout(new MigLayout("fill, ins 0, gap 0, wrap 1", "[grow]"));

        card.add(sectionHeader("Carrinho", "Del para remover  •  clique em Qtd para editar"), "growx");
        card.add(cleanScroll(cartTable), "grow, push");
        card.add(buildSummaryPanel(),  "growx");
        card.add(buildPaymentPanel(),  "growx");
        card.add(buildActionPanel(),   "growx, h 58!");

        return card;
    }

    private JPanel buildSummaryPanel() {
        JPanel p = new JPanel(new MigLayout(
                "fillx, ins 12 14 10 14, gap 8", "[grow][grow]", "[][][6px][]"));
        p.setBackground(SURFACE);
        p.setBorder(BorderFactory.createMatteBorder(1, 0, 1, 0, BORDER_C));

        JLabel lblSub = new JLabel("Subtotal");
        lblSub.setForeground(MUTED);
        lblSub.setFont(lblSub.getFont().deriveFont(Font.PLAIN, 13f));
        p.add(lblSub, "left");
        p.add(subtotalLabel, "right, wrap");

        JLabel lblDesc = new JLabel("Desconto (MT)");
        lblDesc.setForeground(MUTED);
        lblDesc.setFont(lblDesc.getFont().deriveFont(Font.PLAIN, 13f));
        p.add(lblDesc, "left");
        descontoField.setPreferredSize(new Dimension(110, 34));
        p.add(descontoField, "right, w 110!, h 34!, wrap");

        JSeparator line = new JSeparator();
        line.setForeground(BORDER_C);
        p.add(line, "span 2, growx, wrap");

        JLabel lblTotal = new JLabel("TOTAL");
        lblTotal.setFont(lblTotal.getFont().deriveFont(Font.BOLD, 15f));
        lblTotal.setForeground(INK);
        p.add(lblTotal, "left");
        p.add(totalLabel, "right");

        return p;
    }

    private JPanel buildPaymentPanel() {
        JPanel outer = new JPanel(new MigLayout("fillx, ins 10 14 10 14, gap 0, wrap 1", "[grow]", "[][8px][]"));
        outer.setBackground(Color.WHITE);
        outer.setBorder(BorderFactory.createMatteBorder(0, 0, 1, 0, BORDER_C));

        JLabel lbl = new JLabel("Forma de Pagamento");
        lbl.setFont(lbl.getFont().deriveFont(Font.BOLD, 12f));
        lbl.setForeground(MUTED);
        outer.add(lbl, "left");

        JPanel grid = new JPanel(new MigLayout("fillx, ins 0, gap 6, wrap 3",
                "[grow,fill][grow,fill][grow,fill]", "[36!][36!]"));
        grid.setOpaque(false);
        for (JToggleButton btn : paymentButtons) {
            grid.add(btn, "grow");
        }
        outer.add(grid, "growx");

        return outer;
    }

    private JPanel buildActionPanel() {
        JPanel p = new JPanel(new MigLayout("fill, ins 10 14 10 14, gap 10", "[grow][160px]", "[grow]"));
        p.setBackground(Color.WHITE);

        JButton btnFinalizar = new JButton("Finalizar Venda  [F4]");
        btnFinalizar.putClientProperty(FlatClientProperties.STYLE,
                "arc:10; background:#16a34a; foreground:#ffffff; font:bold +2; " +
                "hoverBackground:#15803d; pressedBackground:#166534");

        JButton btnCancelar = new JButton("Cancelar  [F8]");
        btnCancelar.putClientProperty(FlatClientProperties.STYLE,
                "arc:10; background:#f1f5f9; foreground:#64748b; font:bold; " +
                "hoverBackground:#e2e8f0; borderColor:#e2e8f0");

        btnFinalizar.addActionListener(e -> finalizeSale());
        btnCancelar.addActionListener(e -> cancelSale());

        p.add(btnFinalizar, "grow");
        p.add(btnCancelar, "grow");
        return p;
    }

    // ── Layout helpers ───────────────────────────────────────

    private JPanel makeCard() {
        JPanel p = new JPanel();
        p.setBackground(Color.WHITE);
        p.setBorder(BorderFactory.createLineBorder(BORDER_C));
        return p;
    }

    private JPanel sectionHeader(String title, String hint) {
        JPanel p = new JPanel(new MigLayout("fillx, ins 12 14 10 14", "[grow][]", "[]"));
        p.setBackground(SURFACE);
        p.setBorder(BorderFactory.createMatteBorder(0, 0, 1, 0, BORDER_C));

        JLabel t = new JLabel(title);
        t.setFont(t.getFont().deriveFont(Font.BOLD, 14f));
        t.setForeground(INK);

        JLabel h = new JLabel(hint);
        h.setFont(h.getFont().deriveFont(Font.PLAIN, 11f));
        h.setForeground(new Color(148, 163, 184));

        p.add(t, "left");
        p.add(h, "right");
        return p;
    }

    private JPanel transparent(MigLayout layout) {
        JPanel p = new JPanel(layout);
        p.setOpaque(false);
        return p;
    }

    private JScrollPane cleanScroll(Component c) {
        JScrollPane sp = new JScrollPane(c);
        sp.setBorder(BorderFactory.createEmptyBorder());
        sp.getViewport().setOpaque(false);
        return sp;
    }

    private void setupListeners() {
        searchField.addKeyListener(new KeyAdapter() {
            @Override
            public void keyPressed(KeyEvent e) {
                if (e.getKeyCode() == KeyEvent.VK_ENTER) {
                    searchProduct();
                }
            }
        });

        productsTable.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                if (e.getClickCount() == 2) {
                    int row = productsTable.rowAtPoint(e.getPoint());
                    if (row >= 0 && row < productsTableModel.getRowCount()) {
                        Produto p = productsTableModel.getProdutoAt(row);
                        if (p != null) addToCart(p);
                        searchField.setText("");
                        searchField.requestFocusInWindow();
                    }
                }
            }
        });

        descontoField.addActionListener(e -> updateDesconto());

        if (!paymentButtons.isEmpty()) {
            paymentButtons.get(0).setSelected(true);
            selectedPaymentMethod = paymentButtons.get(0).getText();
        }

        for (JToggleButton btn : paymentButtons) {
            btn.addActionListener(e -> {
                if (btn.isSelected()) selectedPaymentMethod = btn.getText();
            });
        }
    }

    private void installKeyboardShortcuts() {
        InputMap inputMap = getInputMap(WHEN_IN_FOCUSED_WINDOW);
        ActionMap actionMap = getActionMap();

        // F2 - Focus search field
        KeyStroke f2 = KeyStroke.getKeyStroke(KeyEvent.VK_F2, 0);
        inputMap.put(f2, "focusSearch");
        actionMap.put("focusSearch", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                searchField.requestFocusInWindow();
            }
        });

        // F4 - Finalize sale
        KeyStroke f4 = KeyStroke.getKeyStroke(KeyEvent.VK_F4, 0);
        inputMap.put(f4, "finalizeSale");
        actionMap.put("finalizeSale", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                finalizeSale();
            }
        });

        // F5 - Apply discount
        KeyStroke f5 = KeyStroke.getKeyStroke(KeyEvent.VK_F5, 0);
        inputMap.put(f5, "applyDiscount");
        actionMap.put("applyDiscount", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                openDiscountDialog();
            }
        });

        // F8 - Cancel sale
        KeyStroke f8 = KeyStroke.getKeyStroke(KeyEvent.VK_F8, 0);
        inputMap.put(f8, "cancelSale");
        actionMap.put("cancelSale", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                cancelSale();
            }
        });

        // F9 - Select client
        KeyStroke f9 = KeyStroke.getKeyStroke(KeyEvent.VK_F9, 0);
        inputMap.put(f9, "selectClient");
        actionMap.put("selectClient", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                openClientSelection();
            }
        });

        // F12 - Open cash drawer
        KeyStroke f12 = KeyStroke.getKeyStroke(KeyEvent.VK_F12, 0);
        inputMap.put(f12, "openCashDrawer");
        actionMap.put("openCashDrawer", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                openCashDrawer();
            }
        });

        // ESC - Clear search
        KeyStroke esc = KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0);
        inputMap.put(esc, "clearSearch");
        actionMap.put("clearSearch", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                searchField.setText("");
            }
        });

        // Delete - Remove selected item from cart
        KeyStroke delete = KeyStroke.getKeyStroke(KeyEvent.VK_DELETE, 0);
        inputMap.put(delete, "removeSelectedItem");
        actionMap.put("removeSelectedItem", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                removeSelectedCartItem();
            }
        });

        // Ctrl+S - Save (finalize sale)
        KeyStroke ctrlS = KeyStroke.getKeyStroke(KeyEvent.VK_S, InputEvent.CTRL_DOWN_MASK);
        inputMap.put(ctrlS, "ctrlSave");
        actionMap.put("ctrlSave", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                finalizeSale();
            }
        });

        // Ctrl+P - Print receipt
        KeyStroke ctrlP = KeyStroke.getKeyStroke(KeyEvent.VK_P, InputEvent.CTRL_DOWN_MASK);
        inputMap.put(ctrlP, "ctrlPrint");
        actionMap.put("ctrlPrint", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                printLastReceipt();
            }
        });
    }

    private void openDiscountDialog() {
        String input = JOptionPane.showInputDialog(this,
                "Introduza o valor do desconto (MT):",
                "Aplicar Desconto",
                JOptionPane.QUESTION_MESSAGE);
        if (input != null && !input.isBlank()) {
            try {
                double desconto = Double.parseDouble(input.replace(",", "."));
                if (desconto < 0) {
                    JOptionPane.showMessageDialog(this,
                            "O desconto nao pode ser negativo.",
                            "Erro", JOptionPane.ERROR_MESSAGE);
                    return;
                }
                carrinhoService.setDesconto(desconto);
                descontoField.setText(String.format("%.2f", desconto));
                updateSummary();
                logger.info("Discount applied: {}", desconto);
            } catch (NumberFormatException ex) {
                JOptionPane.showMessageDialog(this,
                        "Valor invalido. Use apenas numeros.",
                        "Erro", JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    private void openClientSelection() {
        String input = JOptionPane.showInputDialog(this,
                "Pesquisar cliente (ID ou nome):",
                "Selecionar Cliente",
                JOptionPane.QUESTION_MESSAGE);
        if (input != null && !input.isBlank()) {
            List<Cliente> clients = clienteService.search(input);
            if (clients.isEmpty()) {
                JOptionPane.showMessageDialog(this,
                        "Nenhum cliente encontrado: " + input,
                        "Cliente Nao Encontrado", JOptionPane.WARNING_MESSAGE);
                return;
            }
            if (clients.size() == 1) {
                Cliente cliente = clients.get(0);
                logger.info("Cliente selecionado: {} (ID: {})", cliente.getNome(), cliente.getId());
                JOptionPane.showMessageDialog(this,
                        "Cliente: " + cliente.getNome() + "\nNIF: " + (cliente.getNif() != null ? cliente.getNif() : "N/A"),
                        "Cliente Selecionado", JOptionPane.INFORMATION_MESSAGE);
            } else {
                StringBuilder sb = new StringBuilder("Clientes encontrados:\n");
                for (int i = 0; i < Math.min(clients.size(), 10); i++) {
                    Cliente c = clients.get(i);
                    sb.append("  ").append(i + 1).append(". ")
                            .append(c.getNome()).append(" (NIF: ")
                            .append(c.getNif() != null ? c.getNif() : "N/A")
                            .append(")\n");
                }
                JOptionPane.showMessageDialog(this, sb.toString(),
                        "Clientes Encontrados", JOptionPane.INFORMATION_MESSAGE);
            }
        }
    }

    private void openCashDrawer() {
        try {
            String printerPort = "COM3";
            com.factpro.faturacao.printer.ThermalPrinterService printer =
                    new com.factpro.faturacao.printer.ThermalPrinterService(printerPort);
            printer.testPrint();
            JOptionPane.showMessageDialog(this,
                    "Gaveta de dinheiro enviada para porta: " + printerPort,
                    "Gaveta Aberta", JOptionPane.INFORMATION_MESSAGE);
            logger.info("Cash drawer opened via {}", printerPort);
        } catch (Exception ex) {
            logger.error("Erro ao abrir gaveta de dinheiro", ex);
            JOptionPane.showMessageDialog(this,
                    "Erro ao abrir gaveta: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
        }
    }

    private void removeSelectedCartItem() {
        int selectedRow = cartTable.getSelectedRow();
        if (selectedRow < 0) {
            JOptionPane.showMessageDialog(this,
                    "Selecione um item no carrinho para remover.",
                    "Nenhum Item Selecionado", JOptionPane.WARNING_MESSAGE);
            return;
        }
        removeFromCart(selectedRow);
    }

    private void printLastReceipt() {
        try {
            com.factpro.faturacao.printer.ThermalPrinterService printer =
                    new com.factpro.faturacao.printer.ThermalPrinterService("COM3");
            printer.testPrint();
            JOptionPane.showMessageDialog(this,
                    "Recibo enviado para impressora.",
                    "Impressao", JOptionPane.INFORMATION_MESSAGE);
            logger.info("Last receipt printed");
        } catch (Exception ex) {
            logger.error("Erro ao imprimir recibo", ex);
            JOptionPane.showMessageDialog(this,
                    "Erro ao imprimir: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
        }
    }

    private void loadProducts() {
        allProducts = produtoService.findAll();
        productsTableModel.setProducts(allProducts);
        updateSummary();
    }

    private void loadCategories() {
        List<Categoria> categories = categoriaDAO.findAll();
        categoryButtonsPanel.removeAll();

        JButton allBtn = new JButton("Todos");
        allBtn.addActionListener(e -> productsTableModel.setProducts(allProducts));
        categoryButtonsPanel.add(allBtn, "growx");

        for (Categoria cat : categories) {
            JButton btn = new JButton(cat.getNome());
            btn.addActionListener(e -> {
                List<Produto> filtered = allProducts.stream()
                        .filter(p -> cat.getId().equals(p.getCategoriaId()))
                        .toList();
                productsTableModel.setProducts(filtered);
            });
            categoryButtonsPanel.add(btn, "growx");
        }
        categoryButtonsPanel.revalidate();
        categoryButtonsPanel.repaint();
    }

    private void searchProduct() {
        String query = searchField.getText().trim();
        if (query.isEmpty()) {
            productsTableModel.setProducts(allProducts);
            return;
        }

        Produto byBarcode = produtoService.findByCodigoBarras(query);
        if (byBarcode != null) {
            addToCart(byBarcode);
            searchField.setText("");
            productsTableModel.setProducts(allProducts);
            return;
        }

        List<Produto> results = produtoService.search(query);
        productsTableModel.setProducts(results);
    }

    private void addToCart(Produto produto) {
        if (produto.getStockAtual() == null || produto.getStockAtual() <= 0) {
            JOptionPane.showMessageDialog(this, "Produto sem stock: " + produto.getNome(),
                    "Stock Insuficiente", JOptionPane.WARNING_MESSAGE);
            return;
        }

        VendaItem item = new VendaItem();
        item.setProdutoId(produto.getId());
        item.setQuantidade(1.0);
        item.setPrecoUnitario(produto.getPrecoVenda() != null ? produto.getPrecoVenda() : 0.0);
        item.setDesconto(0.0);
        item.setTotal(item.getPrecoUnitario());

        carrinhoService.addItem(item);
        cartTableModel.refresh();
        updateSummary();
        logger.info("Added to cart: {} (ID: {})", produto.getNome(), produto.getId());
    }

    void removeFromCart(int rowIndex) {
        List<VendaItem> items = carrinhoService.getItems();
        if (rowIndex >= 0 && rowIndex < items.size()) {
            carrinhoService.removeItem(items.get(rowIndex).getProdutoId());
            cartTableModel.refresh();
            updateSummary();
        }
    }

    private void updateDesconto() {
        try {
            double desconto = Double.parseDouble(descontoField.getText().replace(",", "."));
            carrinhoService.setDesconto(desconto);
            updateSummary();
        } catch (NumberFormatException e) {
            descontoField.setText("0.00");
            carrinhoService.setDesconto(0.0);
            updateSummary();
        }
    }

    private void updateSummary() {
        subtotalLabel.setText(CurrencyFormatter.format(carrinhoService.getSubtotal()));
        totalLabel.setText(CurrencyFormatter.format(carrinhoService.getTotal()));
    }

    private void finalizeSale() {
        List<VendaItem> items = carrinhoService.getItems();
        if (items.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Carrinho vazio. Adicione produtos antes de finalizar.",
                    "Carrinho Vazio", JOptionPane.WARNING_MESSAGE);
            return;
        }

        if (selectedPaymentMethod == null) {
            JOptionPane.showMessageDialog(this, "Selecione um metodo de pagamento.",
                    "Pagamento Nao Selecionado", JOptionPane.WARNING_MESSAGE);
            return;
        }

        Long clienteId = null;
        if ("Fiado".equals(selectedPaymentMethod)) {
            String input = JOptionPane.showInputDialog(this, "Selecione o cliente (ID ou nome):",
                    "Venda a Credito", JOptionPane.QUESTION_MESSAGE);
            if (input == null || input.isBlank()) {
                JOptionPane.showMessageDialog(this, "Venda a credito requer um cliente.",
                        "Erro", JOptionPane.ERROR_MESSAGE);
                return;
            }
            List<Cliente> clients = clienteService.search(input);
            if (clients.isEmpty()) {
                JOptionPane.showMessageDialog(this, "Cliente nao encontrado: " + input,
                        "Erro", JOptionPane.ERROR_MESSAGE);
                return;
            }
            clienteId = clients.get(0).getId();
        }

        Venda venda = new Venda();
        venda.setTenantId(SessionManager.getInstance().getCurrentTenantId());
        venda.setUserId(SessionManager.getInstance().getCurrentUserId());
        venda.setClienteId(clienteId);
        venda.setTerminal("POS-01");
        venda.setMetodoPagamento(selectedPaymentMethod);
        venda.setStatus("finalizada");
        venda.setTipoDocumento("FT");
        venda.setSerieDocumento("FT");

        try {
            List<Pagamento> pagamentos = new ArrayList<>();
            Pagamento pg = new Pagamento();
            pg.setMetodo(selectedPaymentMethod);
            pg.setValor(carrinhoService.getTotal());
            pg.setStatus("processado");
            pagamentos.add(pg);

            Venda savedVenda = vendaService.finalizarVenda(venda, pagamentos);

            if ("Fiado".equals(selectedPaymentMethod) && clienteId != null) {
                clienteService.actualizarCreditoUsado(clienteId, savedVenda.getTotal());
            }

            EventManager.getInstance().emit("venda_finalizada", savedVenda);
            showReceiptDialog(savedVenda);

            carrinhoService.clear();
            cartTableModel.refresh();
            updateSummary();
            descontoField.setText("0.00");
            loadProducts();

            JOptionPane.showMessageDialog(this,
                    "Venda finalizada com sucesso!\nDocumento: "
                            + savedVenda.getSerieDocumento() + " " + savedVenda.getNumeroDocumento(),
                    "Venda Finalizada", JOptionPane.INFORMATION_MESSAGE);
        } catch (Exception ex) {
            logger.error("Erro ao finalizar venda", ex);
            JOptionPane.showMessageDialog(this, "Erro ao finalizar venda: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
        }
    }

    private void cancelSale() {
        if (carrinhoService.getItems().isEmpty()) return;

        int confirm = JOptionPane.showConfirmDialog(this,
                "Deseja realmente cancelar esta venda?\nTodos os itens serao removidos do carrinho.",
                "Cancelar Venda", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);

        if (confirm == JOptionPane.YES_OPTION) {
            carrinhoService.clear();
            cartTableModel.refresh();
            updateSummary();
            descontoField.setText("0.00");
        }
    }

    private void showReceiptDialog(Venda venda) {
        JDialog dialog = new JDialog((Frame) SwingUtilities.getWindowAncestor(this), "Recibo", true);
        dialog.setLayout(new MigLayout("fill, ins 20", "[grow]", "[][][][][][][][][]"));
        dialog.setSize(350, 400);
        dialog.setLocationRelativeTo(this);

        JLabel title = new JLabel("=== FACTURA ===");
        title.setFont(title.getFont().deriveFont(Font.BOLD, 18f));
        title.setHorizontalAlignment(SwingConstants.CENTER);
        dialog.add(title, "center");
        dialog.add(new JLabel("Nº Doc: " + venda.getSerieDocumento() + " " + venda.getNumeroDocumento()), "center");
        dialog.add(new JLabel("Data: " + (venda.getCriadaEm() != null ? venda.getCriadaEm() : "N/A")), "center");
        dialog.add(new JSeparator(), "growx");
        dialog.add(new JLabel("Subtotal: " + CurrencyFormatter.format(venda.getSubtotal())), "right, gapy 5");
        dialog.add(new JLabel("Desconto: " + CurrencyFormatter.format(venda.getDesconto())), "right");
        dialog.add(new JSeparator(), "growx");
        JLabel totalLbl = new JLabel("TOTAL: " + CurrencyFormatter.format(venda.getTotal()));
        totalLbl.setFont(totalLbl.getFont().deriveFont(Font.BOLD, 16f));
        dialog.add(totalLbl, "right, gapy 5");
        dialog.add(new JLabel("Pagamento: " + venda.getMetodoPagamento()), "center");

        JButton printBtn = new JButton("Imprimir Recibo");
        JButton closeBtn = new JButton("Fechar");
        JPanel btnPanel = new JPanel(new FlowLayout());
        btnPanel.add(printBtn);
        btnPanel.add(closeBtn);
        dialog.add(btnPanel, "center");

        printBtn.addActionListener(e -> JOptionPane.showMessageDialog(dialog,
                "Funcionalidade de impressao em desenvolvimento.", "Imprimir", JOptionPane.INFORMATION_MESSAGE));
        closeBtn.addActionListener(e -> dialog.dispose());

        dialog.setVisible(true);
    }

    // ==================== Table Models ====================

    private static class ProductsTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;
        private List<Produto> products = new ArrayList<>();

        ProductsTableModel(String[] columns) { this.columns = columns; }

        void setProducts(List<Produto> products) {
            this.products = products;
            fireTableDataChanged();
        }

        Produto getProdutoAt(int row) {
            return (row >= 0 && row < products.size()) ? products.get(row) : null;
        }

        @Override public int getRowCount() { return products.size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            if (row < 0 || row >= products.size()) return null;
            Produto p = products.get(row);
            return switch (col) {
                case 0 -> p.getCodigoBarras() != null ? p.getCodigoBarras() : p.getSku();
                case 1 -> p.getNome();
                case 2 -> p.getPrecoVenda() != null ? p.getPrecoVenda() : 0.0;
                case 3 -> p.getStockAtual() != null ? p.getStockAtual() : 0;
                default -> null;
            };
        }
    }

    class CartTableModel extends javax.swing.table.AbstractTableModel {
        private final String[] columns;

        CartTableModel(String[] columns) { this.columns = columns; }

        void refresh() { fireTableDataChanged(); }

        @Override public int getRowCount() { return carrinhoService.getItems().size(); }
        @Override public int getColumnCount() { return columns.length; }
        @Override public String getColumnName(int c) { return columns[c]; }

        @Override
        public Object getValueAt(int row, int col) {
            List<VendaItem> items = carrinhoService.getItems();
            if (row >= items.size()) return null;
            VendaItem item = items.get(row);
            Produto produto = produtoDAO.findById(item.getProdutoId());
            String nome = produto != null ? produto.getNome() : "Produto #" + item.getProdutoId();
            return switch (col) {
                case 0 -> nome;
                case 1 -> item.getQuantidade();
                case 2 -> item.getPrecoUnitario();
                case 3 -> item.getTotal();
                case 4 -> "Remover";
                default -> null;
            };
        }

        @Override
        public boolean isCellEditable(int row, int col) { return col == 1 || col == 4; }

        @Override
        public void setValueAt(Object value, int row, int col) {
            if (col == 1) {
                try {
                    double qty = Double.parseDouble(value.toString());
                    List<VendaItem> items = carrinhoService.getItems();
                    if (row < items.size()) {
                        carrinhoService.updateItemQuantity(items.get(row).getProdutoId(), qty);
                        updateSummary();
                        fireTableDataChanged();
                    }
                } catch (NumberFormatException ignored) {}
            }
        }
    }

    // ==================== Cell Renderers ====================

    private static class CurrencyRenderer extends DefaultTableCellRenderer {
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            if (value instanceof Number) setText(CurrencyFormatter.format(((Number) value).doubleValue()));
            setHorizontalAlignment(SwingConstants.RIGHT);
            return this;
        }
    }

    private static class StockRenderer extends DefaultTableCellRenderer {
        private static final Color S_GREEN = new Color(34, 139, 34);

        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            if (value instanceof Number) {
                int stock = ((Number) value).intValue();
                if (stock <= 0) { setForeground(RED); setText("Esgotado"); }
                else if (stock <= 5) setForeground(Color.ORANGE);
                else setForeground(S_GREEN);
            }
            setHorizontalAlignment(SwingConstants.CENTER);
            return this;
        }
    }

    private static class QtyRenderer extends DefaultTableCellRenderer {
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);
            setHorizontalAlignment(SwingConstants.CENTER);
            return this;
        }
    }

    private static class ButtonRenderer extends JPanel implements javax.swing.table.TableCellRenderer {
        private static final Color BTN_RED = new Color(220, 53, 69);
        private final JButton btn = new JButton("X");

        ButtonRenderer() {
            setLayout(new FlowLayout(FlowLayout.CENTER, 0, 0));
            btn.setFont(btn.getFont().deriveFont(Font.BOLD, 11f));
            btn.setBackground(BTN_RED);
            btn.setForeground(Color.WHITE);
            btn.setFocusPainted(false);
            btn.setPreferredSize(new Dimension(50, 22));
            add(btn);
        }

        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                                                       boolean isSelected, boolean hasFocus, int row, int col) {
            setBackground(isSelected ? table.getSelectionBackground() : table.getBackground());
            return this;
        }
    }

    private class ButtonEditor extends AbstractCellEditor implements javax.swing.table.TableCellEditor {
        private static final Color BTN_RED = new Color(220, 53, 69);
        private final JPanel panel = new JPanel(new FlowLayout(FlowLayout.CENTER, 0, 0));
        private final JButton btn = new JButton("X");
        private int currentRow;

        ButtonEditor() {
            btn.setFont(btn.getFont().deriveFont(Font.BOLD, 11f));
            btn.setBackground(BTN_RED);
            btn.setForeground(Color.WHITE);
            btn.setFocusPainted(false);
            btn.setPreferredSize(new Dimension(50, 22));
            btn.addActionListener(e -> { fireEditingStopped(); removeFromCart(currentRow); });
            panel.add(btn);
        }

        @Override
        public Component getTableCellEditorComponent(JTable table, Object value,
                                                     boolean isSelected, int row, int col) {
            currentRow = row;
            panel.setBackground(isSelected ? table.getSelectionBackground() : table.getBackground());
            return panel;
        }

        @Override public Object getCellEditorValue() { return "Remover"; }
    }

    private static class QtyEditor extends AbstractCellEditor implements javax.swing.table.TableCellEditor {
        private final JTextField field = new JTextField();

        QtyEditor() {
            field.setHorizontalAlignment(SwingConstants.CENTER);
            field.addActionListener(e -> fireEditingStopped());
        }

        @Override
        public Component getTableCellEditorComponent(JTable table, Object value,
                                                     boolean isSelected, int row, int col) {
            field.setText(value != null ? value.toString() : "1");
            field.setBackground(isSelected ? table.getSelectionBackground() : table.getBackground());
            return field;
        }

        @Override public Object getCellEditorValue() { return field.getText(); }
    }
}
