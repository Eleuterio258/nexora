package com.factpro.produtos.view;

import com.factpro.produtos.dao.CategoriaDAO;
import com.factpro.produtos.model.Categoria;
import com.factpro.produtos.model.Produto;
import com.factpro.produtos.service.ProdutoService;
import com.factpro.stock.dao.StockMovimentoDAO;
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
 * Product form dialog for creating and editing products.
 */
public class ProdutoFormDialog extends JDialog {

    private static final Logger logger = LoggerFactory.getLogger(ProdutoFormDialog.class);

    private final ProdutoService produtoService;
    private final CategoriaDAO categoriaDAO;
    private final StockMovimentoDAO stockMovimentoDAO;

    private final Produto editingProduto;
    private boolean saved = false;

    // Form fields
    private JTextField nomeField;
    private JTextField codigoBarrasField;
    private JTextField skuField;
    private JComboBox<CategoriaComboItem> categoriaCombo;
    private JTextArea descricaoArea;
    private JTextField precoCompraField;
    private JTextField precoVendaField;
    private JTextField precoPromocaoField;
    private JTextField stockAtualField;
    private JTextField stockMinimoField;
    private JComboBox<String> unidadeMedidaCombo;
    private JTextField validadeField;
    private JCheckBox compostoCheckBox;
    private JCheckBox ativoCheckBox;
    private JButton imageUploadBtn;

    public ProdutoFormDialog(Frame parent, Produto produto) {
        super(parent, produto == null ? "Novo Produto" : "Editar Produto", true);
        this.editingProduto = produto;

        categoriaDAO = new CategoriaDAO();
        stockMovimentoDAO = new StockMovimentoDAO();
        produtoService = new ProdutoService(new com.factpro.produtos.dao.ProdutoDAO(), categoriaDAO, stockMovimentoDAO);

        setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
        setSize(600, 650);
        setLocationRelativeTo(parent);

        initComponents();
        setupLayout();
        setupListeners();

        if (editingProduto != null) populateForm();
    }

    private void initComponents() {
        nomeField = new JTextField(25);
        codigoBarrasField = new JTextField(15);
        skuField = new JTextField(15);

        categoriaCombo = new JComboBox<>();
        categoriaCombo.addItem(new CategoriaComboItem(null, "-- Sem Categoria --"));
        List<Categoria> categories = categoriaDAO.findAll();
        for (Categoria cat : categories) {
            categoriaCombo.addItem(new CategoriaComboItem(cat.getId(), cat.getNome()));
        }

        descricaoArea = new JTextArea(3, 25);
        descricaoArea.setLineWrap(true);
        descricaoArea.setWrapStyleWord(true);

        precoCompraField = new JTextField(10);
        precoVendaField = new JTextField(10);
        precoPromocaoField = new JTextField(10);
        stockAtualField = new JTextField(8);
        stockMinimoField = new JTextField(8);

        unidadeMedidaCombo = new JComboBox<>(new String[]{"un", "kg", "L"});

        validadeField = new JTextField(12);
        validadeField.putClientProperty(FlatClientProperties.PLACEHOLDER_TEXT, "AAAA-MM-DD");

        compostoCheckBox = new JCheckBox("Produto Composto");
        ativoCheckBox = new JCheckBox("Ativo", true);

        imageUploadBtn = new JButton("\uD83D\uDCF7 Upload Imagem");
        imageUploadBtn.setEnabled(false); // Placeholder
    }

    private void setupLayout() {
        setLayout(new MigLayout("fill, wrap 2, ins 20, gap 8 12",
                "[right, 140][grow, 250]"));

        add(new JLabel("<html><b>Dados do Produto</b></html>"), "span 2, gapy 0 10");

        add(new JLabel("Nome: *"));
        add(nomeField, "growx");

        add(new JLabel("Codigo de Barras:"));
        add(codigoBarrasField, "growx");

        add(new JLabel("SKU:"));
        add(skuField, "growx");

        add(new JLabel("Categoria:"));
        add(categoriaCombo, "growx");

        add(new JLabel("Descricao:"));
        add(new JScrollPane(descricaoArea), "growx, h 60");

        add(new JSeparator(), "span 2, gapy 10");
        add(new JLabel("<html><b>Preos</b></html>"), "span 2");

        add(new JLabel("Preco de Compra:"));
        add(precoCompraField);

        add(new JLabel("Preco de Venda: *"));
        add(precoVendaField);

        add(new JLabel("Preco Promocao:"));
        add(precoPromocaoField);

        add(new JSeparator(), "span 2, gapy 10");
        add(new JLabel("<html><b>Stock</b></html>"), "span 2");

        add(new JLabel("Stock Atual:"));
        add(stockAtualField);

        add(new JLabel("Stock Minimo:"));
        add(stockMinimoField);

        add(new JLabel("Unidade de Medida:"));
        add(unidadeMedidaCombo);

        add(new JLabel("Validade:"));
        add(validadeField);

        add(new JSeparator(), "span 2, gapy 10");

        add(compostoCheckBox, "span 2");
        add(ativoCheckBox, "span 2");

        add(new JLabel("Imagem:"));
        add(imageUploadBtn);

        // Buttons
        add(new JLabel(), "gapy 15"); // spacer
        JPanel btnPanel = new JPanel(new MigLayout("ins 0, gap 10"));
        JButton saveBtn = new JButton("Guardar");
        JButton cancelBtn = new JButton("Cancelar");
        saveBtn.setFont(saveBtn.getFont().deriveFont(Font.BOLD, 13f));
        cancelBtn.setFont(cancelBtn.getFont().deriveFont(Font.PLAIN, 13f));
        btnPanel.add(saveBtn);
        btnPanel.add(cancelBtn);
        add(btnPanel, "span 2, center");

        saveBtn.addActionListener(e -> saveProduto());
        cancelBtn.addActionListener(e -> dispose());

        // Enter key triggers save
        getRootPane().setDefaultButton(saveBtn);
        KeyStroke escape = KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(escape, "cancel");
        getRootPane().getActionMap().put("cancel", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) { dispose(); }
        });
    }

    private void setupListeners() {
        // Warning if precoVenda <= precoCompra
        precoVendaField.addFocusListener(new java.awt.event.FocusAdapter() {
            @Override
            public void focusLost(java.awt.event.FocusEvent e) {
                checkPriceWarning();
            }
        });
    }

    private void checkPriceWarning() {
        try {
            Double precoCompra = parseDouble(precoCompraField.getText());
            Double precoVenda = parseDouble(precoVendaField.getText());
            if (precoCompra != null && precoVenda != null && precoVenda <= precoCompra) {
                JOptionPane.showMessageDialog(this,
                        "Atencao: O preco de venda nao e maior que o preco de compra.",
                        "Aviso de Preco",
                        JOptionPane.WARNING_MESSAGE);
            }
        } catch (Exception ignored) {}
    }

    private void populateForm() {
        if (editingProduto == null) return;

        nomeField.setText(editingProduto.getNome());
        codigoBarrasField.setText(editingProduto.getCodigoBarras());
        skuField.setText(editingProduto.getSku());

        if (editingProduto.getCategoriaId() != null) {
            for (int i = 0; i < categoriaCombo.getItemCount(); i++) {
                CategoriaComboItem item = categoriaCombo.getItemAt(i);
                if (item.id != null && item.id.equals(editingProduto.getCategoriaId())) {
                    categoriaCombo.setSelectedIndex(i);
                    break;
                }
            }
        }

        descricaoArea.setText(editingProduto.getDescricao());
        if (editingProduto.getPrecoCompra() != null)
            precoCompraField.setText(String.valueOf(editingProduto.getPrecoCompra()));
        if (editingProduto.getPrecoVenda() != null)
            precoVendaField.setText(String.valueOf(editingProduto.getPrecoVenda()));
        if (editingProduto.getPrecoPromocao() != null)
            precoPromocaoField.setText(String.valueOf(editingProduto.getPrecoPromocao()));
        if (editingProduto.getStockAtual() != null)
            stockAtualField.setText(String.valueOf(editingProduto.getStockAtual()));
        if (editingProduto.getStockMinimo() != null)
            stockMinimoField.setText(String.valueOf(editingProduto.getStockMinimo()));
        if (editingProduto.getUnidadeMedida() != null)
            unidadeMedidaCombo.setSelectedItem(editingProduto.getUnidadeMedida());
        validadeField.setText(editingProduto.getValidade());
        compostoCheckBox.setSelected(editingProduto.getComposto() != null && editingProduto.getComposto());
        ativoCheckBox.setSelected(editingProduto.getAtivo() == null || editingProduto.getAtivo());
    }

    private void saveProduto() {
        // Validation
        String nome = nomeField.getText().trim();
        if (nome.isEmpty()) {
            JOptionPane.showMessageDialog(this, "O campo Nome e obrigatorio.",
                    "Validacao", JOptionPane.WARNING_MESSAGE);
            nomeField.requestFocusInWindow();
            return;
        }

        Double precoVenda = parseDouble(precoVendaField.getText());
        if (precoVenda == null || precoVenda <= 0) {
            JOptionPane.showMessageDialog(this, "O preco de venda deve ser maior que zero.",
                    "Validacao", JOptionPane.WARNING_MESSAGE);
            precoVendaField.requestFocusInWindow();
            return;
        }

        Produto produto = editingProduto != null ? editingProduto : new Produto();
        produto.setNome(nome);
        produto.setCodigoBarras(codigoBarrasField.getText().trim());
        produto.setSku(skuField.getText().trim());

        CategoriaComboItem selectedCat = (CategoriaComboItem) categoriaCombo.getSelectedItem();
        if (selectedCat != null && selectedCat.id != null) {
            produto.setCategoriaId(selectedCat.id);
        }

        produto.setDescricao(descricaoArea.getText().trim());
        produto.setPrecoCompra(parseDouble(precoCompraField.getText()));
        produto.setPrecoVenda(precoVenda);
        produto.setPrecoPromocao(parseDouble(precoPromocaoField.getText()));

        try { produto.setStockAtual(Integer.parseInt(stockAtualField.getText().trim())); }
        catch (Exception e) { produto.setStockAtual(0); }

        try { produto.setStockMinimo(Integer.parseInt(stockMinimoField.getText().trim())); }
        catch (Exception e) { produto.setStockMinimo(0); }

        produto.setUnidadeMedida((String) unidadeMedidaCombo.getSelectedItem());
        produto.setValidade(validadeField.getText().trim());
        produto.setComposto(compostoCheckBox.isSelected());
        produto.setAtivo(ativoCheckBox.isSelected());

        try {
            if (editingProduto == null) {
                produtoService.save(produto);
                JOptionPane.showMessageDialog(this, "Produto criado com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            } else {
                produtoService.update(produto);
                JOptionPane.showMessageDialog(this, "Produto atualizado com sucesso.",
                        "Sucesso", JOptionPane.INFORMATION_MESSAGE);
            }
            saved = true;
            dispose();
        } catch (Exception ex) {
            logger.error("Erro ao guardar produto", ex);
            JOptionPane.showMessageDialog(this, "Erro ao guardar produto: " + ex.getMessage(),
                    "Erro", JOptionPane.ERROR_MESSAGE);
        }
    }

    private Double parseDouble(String text) {
        if (text == null || text.trim().isEmpty()) return null;
        try {
            return Double.parseDouble(text.trim().replace(",", "."));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    public boolean isSaved() {
        return saved;
    }

    private static class CategoriaComboItem {
        final Long id;
        final String nome;

        CategoriaComboItem(Long id, String nome) {
            this.id = id;
            this.nome = nome;
        }

        @Override
        public String toString() {
            return nome;
        }
    }
}
