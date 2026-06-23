package com.factpro.core.exception;

public class StockInsuficienteException extends BusinessException {
    private final Long produtoId;
    private final String produtoNome;
    private final int stockAtual;
    private final double quantidadePedida;
    
    public StockInsuficienteException(String produtoNome, int stockAtual, double quantidadePedida) {
        super(String.format("Stock insuficiente para '%s': atual=%d, pedido=%.2f", 
            produtoNome, stockAtual, quantidadePedida), "STOCK_INSUFICIENTE");
        this.produtoNome = produtoNome;
        this.stockAtual = stockAtual;
        this.quantidadePedida = quantidadePedida;
        this.produtoId = null;
    }
    
    public StockInsuficienteException(Long produtoId, String produtoNome, int stockAtual, double quantidadePedida) {
        super(String.format("Stock insuficiente para '%s' (ID:%d): atual=%d, pedido=%.2f", 
            produtoNome, produtoId, stockAtual, quantidadePedida), "STOCK_INSUFICIENTE");
        this.produtoId = produtoId;
        this.produtoNome = produtoNome;
        this.stockAtual = stockAtual;
        this.quantidadePedida = quantidadePedida;
    }
    
    public Long getProdutoId() { return produtoId; }
    public String getProdutoNome() { return produtoNome; }
    public int getStockAtual() { return stockAtual; }
    public double getQuantidadePedida() { return quantidadePedida; }
}
