package com.factpro.stock.view;

import com.factpro.auth.SessionManager;
import com.factpro.produtos.dao.ProdutoDAO;
import com.factpro.produtos.model.Produto;
import com.factpro.produtos.service.ProdutoService;
import com.factpro.stock.dao.StockMovimentoDAO;
import com.factpro.stock.service.StockService;
import com.formdev.flatlaf.FlatClientProperties;
import net.miginfocom.swing.MigLayout;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;
import java.util.List;

/**
 * Stock movement form dialog for recording entries, exits, and adjustments.
 */
public class StockMovimentoDialog extends JDialog {

    private static final Logger logger = LoggerFactory.getLogger(StockMovimentoDialog.class);

    private final StockService stockService;
    private final ProdutoDAO produtoDAO;
    private final String initialTipo;
    private boolean saved = false;

    private JComboBox<String> tipoCombo;
    private JTextField produtoSearchField;
    private JList<ProdutoItem> produtoList;
    private DefaultListModel<ProdutoItem> produtoListModel;
    private JScrollPane produtoScroll;
    private JSpinner quantidadeSpinner;
    private JTextField motivoField;
    private JTextField referenciaField;

    private Produto selectedProduto;

    public StockMovimentoDialog(Frame parent, String tipo, StockService stockService, ProdutoDAO produtoDAO) {
        super(parent, "Movimentacao de Stock", true);
        this.stockService = stockService;
        this.produtoDAO = produtoDAO;
        this.initialTipo = tipo != null ? tipo : "entrada";

        setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
        setSize(500, 520);
        setLocationRelativeTo(parent);

        initComponents();
        setupLayout();
        setupListeners();
    }

    private void initComponents() {
        // Tipo combo
        tipoCombo = new JComboBox<>(new String[]{
                "entrada", "saida", "ajuste_positivo", "ajuste_negativo"
        });
        tipoCombo.setSelectedItem(initialTipo);

        // Product search
        produtoSearchField = new JTextField(20);
        produtoSearchField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Pesquisar produto...");

        produtoListModel = new DefaultListModel<>();
        produtoList = new JList<>(produtoListModel);
        produtoList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        produtoList.setCellRenderer(new ProdutoListCellRenderer());
        produtoScroll = new JScrollPane(produtoList);
        produtoScroll.setPreferredSize(new Dimension(0, 120));
        produtoScroll.setVisible(false);

        // Quantidade
        quantidadeSpinner = new JSpinner(new SpinnerNumberModel(1.0, 0.01, 99999.0, 1.0));
        ((JSpinner.NumberEditor) quantidadeSpinner.getEditor()).getFormat().setMinimumFractionDigits(0);
        ((JSpinner.NumberEditor) quantidadeSpinner.getEditor()).getFormat().setMaximumFractionDigits(2);

        // Motivo
        motivoField = new JTextField(25);

        // Referencia
        referenciaField = new JTextField(20);
        referenciaField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "Opcional");
    }

    private void setupLayout() {
        setLayout(new MigLayout("fill, wrap 2, ins 20, gap 8 12",
                "[right, 130][grow, 250]"));

        add(new JLabel("<html><b>Registar Movimentacao de Stock</b></html>"), "span 2, gapy 0 10");

        add(new JLabel("Tipo:"));
        add(tipoCombo, "growx");

        add(new JLabel("Produto: *"));
        add(produtoSearchField, "growx");

        add(produtoScroll, "span 2, growx, h 120");

        add(new JLabel("Quantidade: *"));
        add(quantidadeSpinner, "growx");

        add(new JLabel("Motivo:"));
        add(motivoField, "growx");

        add(new JLabel("Referencia:"));
        add(referenciaField, "growx");

        // Buttons
        add(new JLabel(), "gapy 15");
        JPanel btnPanel = new JPanel(new MigLayout("ins 0, gap 10"));
        JButton saveBtn = new JButton("Guardar");
        JButton cancelBtn = new JButton("Cancelar");
        saveBtn.setFont(saveBtn.getFont().deriveFont(Font.BOLD, 13f));
        cancelBtn.setFont(cancelBtn.getFont().deriveFont(Font.PLAIN, 13f));
        btnPanel.add(saveBtn);
        btnPanel.add(cancelBtn);
        add(btnPanel, "span 2, center");

        saveBtn.addActionListener(e -> saveMovimento());
        cancelBtn.addActionListener(e -> dispose());

        getRootPane().setDefaultButton(saveBtn);
        KeyStroke escape = KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(escape, "cancel");
        getRootPane().getActionMap().put("cancel", new AbstractAction() {
            @Override public void actionPerformed(ActionEvent e) { dispose(); }
        });
    }

    private void setupListeners() {
        produtoSearchField.addKeyListener(new java.awt.event.KeyAdapter() {
            @Override
            public void keyReleased(java.awt.event.KeyEvent e) {
                String query = produtoSearchField.getText().trim();
                if (query.length() >= 2) {
                    searchProduto(query);
                } else {
                    produtoScroll.setVisible(false);
                    revalidate();
                    repaint();
                }
            }
        });

        produtoList.addMouseListener(new java.awt.event.MouseAdapter() {
            @Override
            public void mouseClicked(java.awt.event.MouseEvent e) {
                if (e.getClickCount() == 2) {
                    selectProduto();
                }
            }
        });
    }

    private void searchProduto(String query) {
        ProdutoService ps = new ProdutoService(produtoDAO, null, null);
        List<Produto> results = ps.search(query);
        produtoListModel.clear();
        for (Produto p : results) {
            produtoListModel.addElement(new ProdutoItem(p));
        }
        produtoScroll.setVisible(!results.isEmpty());
        revalidate();
        repaint();
    }

    private void selectProduto() {
        ProdutoItem item = produtoList.getSelectedValue();
        if (item != null) {
            selectedProduto = item.produto;
            produtoSearchField.setText(selectedProduto.getNome() + " (Stock: " + selectedProduto.getStockAtual() + ")");
            produtoScroll.setVisible(false);
            revalidate();
            repaint();
        }
    }

    private void saveMovimento() {
        // Validation
        if (selectedProduto == null) {
            JOptionPane.showMessageDialog(this, "Selecione um produto.",
                    "Validacao", JOptionPane.WARNING_MESSAGE);
            produtoSearchField.requestFocusInWindow();
            return;
        }

        double quantidade = ((Number) quantidadeSpinner.getValue()).doubleValue();
        if (quantidade <= 0) {
            JOptionPane.showMessageDialog(this, "A quantidade deve ser maior que zero.",
                    "Validacao", JOptionPane.WARNING_MESSAGE);
            return;
        }

        String motivo = motivoField.getText().trim();
        String referencia = referenciaField.getText().trim();
        String tipo = (String) tipoCombo.getSelectedItem();

        try {
            Long userId = SessionManager.getInstance().getCurrentUserId();

            switch (tipo) {
                case "entrada" -> stockService.entrada(selectedProduto.getId(), quantidade, motivo, userId);
                case "saida" -> stockService.saida(selectedProduto.getId(), quantidade, motivo, userId);
                case "ajuste_positivo", "ajuste_negativo" ->
                        stockService.ajuste(selectedProduto.getId(), quantidade, tipo, motivo, userId);
            }

            JOptionPane.showMessageDialog(this, "Movimentacao registada com sucesso.",
                    "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            saved = true;
            dispose();
        } catch (Exception ex) {
            logger.error("Erro ao registar movimentacao", ex);
            JOptionPane.showMessageDialog(this, "Erro ao registar movimentacao: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
        }
    }

    public boolean isSaved() {
        return saved;
    }

    // ==================== Helper Classes ====================

    private record ProdutoItem(Produto produto) {
        @Override
        public String toString() {
            return produto.getNome() + " [Stock: " + produto.getStockAtual() + "]";
        }
    }

    private static class ProdutoListCellRenderer extends DefaultListCellRenderer {
        @Override
        public Component getListCellRendererComponent(JList<?> list, Object value, int index,
                                                      boolean isSelected, boolean cellHasFocus) {
            super.getListCellRendererComponent(list, value, index, isSelected, cellHasFocus);
            if (value instanceof ProdutoItem item) {
                Produto p = item.produto;
                String stockInfo = "Stock: " + p.getStockAtual();
                if (p.getStockAtual() != null && p.getStockAtual() <= 0) {
                    setForeground(new Color(220, 53, 69));
                    stockInfo += " (ESGOTADO)";
                }
                setText(p.getNome() + " - " + stockInfo);
            }
            return this;
        }
    }
}
