package com.factpro.vendas.service;

import com.factpro.vendas.model.VendaItem;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Singleton service that manages the shopping cart.
 */
public class CarrinhoService {

    private static final Logger logger = LoggerFactory.getLogger(CarrinhoService.class);
    private static volatile CarrinhoService instance;

    private final List<VendaItem> items;
    private double desconto;

    private CarrinhoService() {
        this.items = new ArrayList<>();
        this.desconto = 0.0;
        logger.info("CarrinhoService initialized");
    }

    /**
     * Returns the singleton instance (thread-safe lazy initialization).
     */
    public static CarrinhoService getInstance() {
        if (instance == null) {
            synchronized (CarrinhoService.class) {
                if (instance == null) {
                    instance = new CarrinhoService();
                }
            }
        }
        return instance;
    }

    /**
     * Adds an item to the cart or increments quantity if the product is already present.
     */
    public void addItem(VendaItem item) {
        if (item == null || item.getProdutoId() == null) {
            logger.warn("Attempted to add a null item or item without produtoId");
            return;
        }

        Optional<VendaItem> existing = items.stream()
                .filter(i -> i.getProdutoId().equals(item.getProdutoId()))
                .findFirst();

        if (existing.isPresent()) {
            VendaItem existingItem = existing.get();
            double newQty = existingItem.getQuantidade() + item.getQuantidade();
            existingItem.setQuantidade(newQty);
            existingItem.setTotal(existingItem.getPrecoUnitario() * newQty - existingItem.getDesconto());
            logger.debug("Updated quantity for produtoId {} to {}", item.getProdutoId(), newQty);
        } else {
            items.add(item);
            logger.debug("Added new item produtoId {} to cart", item.getProdutoId());
        }
    }

    /**
     * Removes an item from the cart by product ID.
     */
    public void removeItem(Long produtoId) {
        boolean removed = items.removeIf(i -> i.getProdutoId().equals(produtoId));
        if (removed) {
            logger.debug("Removed produtoId {} from cart", produtoId);
        } else {
            logger.warn("Attempted to remove produtoId {} not found in cart", produtoId);
        }
    }

    /**
     * Updates the quantity of an item in the cart.
     */
    public void updateItemQuantity(Long produtoId, double quantity) {
        Optional<VendaItem> existing = items.stream()
                .filter(i -> i.getProdutoId().equals(produtoId))
                .findFirst();

        if (existing.isPresent()) {
            VendaItem item = existing.get();
            if (quantity <= 0) {
                removeItem(produtoId);
                return;
            }
            item.setQuantidade(quantity);
            item.setTotal(item.getPrecoUnitario() * quantity - item.getDesconto());
            logger.debug("Updated produtoId {} quantity to {}", produtoId, quantity);
        } else {
            logger.warn("Attempted to update quantity for produtoId {} not found in cart", produtoId);
        }
    }

    /**
     * Clears all items and resets the discount.
     */
    public void clear() {
        items.clear();
        desconto = 0.0;
        logger.info("Cart cleared");
    }

    /**
     * Returns the list of cart items.
     */
    public List<VendaItem> getItems() {
        return new ArrayList<>(items);
    }

    /**
     * Returns the subtotal (sum of all item totals).
     */
    public double getSubtotal() {
        return items.stream()
                .mapToDouble(VendaItem::getTotal)
                .sum();
    }

    /**
     * Returns the total after applying the discount.
     */
    public double getTotal() {
        return Math.max(0.0, getSubtotal() - desconto);
    }

    /**
     * Returns the number of distinct items in the cart.
     */
    public int getItemCount() {
        return items.size();
    }

    /**
     * Sets the cart discount amount.
     */
    public void setDesconto(double desconto) {
        this.desconto = Math.max(0.0, desconto);
        logger.debug("Discount set to {}", this.desconto);
    }

    /**
     * Applies an additional discount to the total (adds to existing desconto).
     */
    public void applyDiscount(double discount) {
        if (discount < 0) {
            logger.warn("Negative discount ignored: {}", discount);
            return;
        }
        this.desconto += discount;
        logger.debug("Applied additional discount of {}. Total discount: {}", discount, this.desconto);
    }

    /**
     * Returns the current discount amount.
     */
    public double getDesconto() {
        return desconto;
    }
}
