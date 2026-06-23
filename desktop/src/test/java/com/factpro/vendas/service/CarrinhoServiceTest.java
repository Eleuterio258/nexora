package com.factpro.vendas.service;

import com.factpro.vendas.model.VendaItem;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class CarrinhoServiceTest {

    @AfterEach
    void tearDown() {
        CarrinhoService.getInstance().clear();
    }

    @Test
    void shouldReturnSameInstance() {
        CarrinhoService s1 = CarrinhoService.getInstance();
        CarrinhoService s2 = CarrinhoService.getInstance();
        assertSame(s1, s2);
    }

    @Test
    void shouldAddNewItem() {
        CarrinhoService cart = CarrinhoService.getInstance();
        VendaItem item = createItem(1L, 100.0, 1.0);

        cart.addItem(item);

        assertEquals(1, cart.getItemCount());
    }

    @Test
    void shouldIncrementQuantityForExistingProduct() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.addItem(createItem(1L, 100.0, 1.0));
        cart.addItem(createItem(1L, 100.0, 2.0));

        assertEquals(1, cart.getItemCount());
        assertEquals(3.0, cart.getItems().get(0).getQuantidade(), 0.01);
    }

    @Test
    void shouldNotAddNullItem() {
        CarrinhoService cart = CarrinhoService.getInstance();

        cart.addItem(null);

        assertEquals(0, cart.getItemCount());
    }

    @Test
    void shouldNotAddItemWithoutProdutoId() {
        CarrinhoService cart = CarrinhoService.getInstance();
        VendaItem item = new VendaItem();
        item.setProdutoId(null);

        cart.addItem(item);

        assertEquals(0, cart.getItemCount());
    }

    @Test
    void shouldRemoveItemByProductId() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.addItem(createItem(1L, 100.0, 1.0));
        cart.addItem(createItem(2L, 50.0, 1.0));

        cart.removeItem(1L);

        assertEquals(1, cart.getItemCount());
        assertEquals(2L, cart.getItems().get(0).getProdutoId());
    }

    @Test
    void shouldUpdateItemQuantity() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.addItem(createItem(1L, 100.0, 1.0));

        cart.updateItemQuantity(1L, 5.0);

        assertEquals(5.0, cart.getItems().get(0).getQuantidade(), 0.01);
    }

    @Test
    void shouldRemoveItemWhenQuantityIsZero() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.addItem(createItem(1L, 100.0, 1.0));

        cart.updateItemQuantity(1L, 0);

        assertEquals(0, cart.getItemCount());
    }

    @Test
    void shouldRemoveItemWhenQuantityIsNegative() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.addItem(createItem(1L, 100.0, 1.0));

        cart.updateItemQuantity(1L, -5.0);

        assertEquals(0, cart.getItemCount());
    }

    @Test
    void shouldClearCart() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.addItem(createItem(1L, 100.0, 1.0));
        cart.addItem(createItem(2L, 50.0, 1.0));

        cart.clear();

        assertEquals(0, cart.getItemCount());
        assertEquals(0.0, cart.getDesconto(), 0.01);
    }

    @Test
    void shouldCalculateSubtotal() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.addItem(createItem(1L, 100.0, 2.0)); // total = 200
        cart.addItem(createItem(2L, 50.0, 1.0));  // total = 50

        assertEquals(250.0, cart.getSubtotal(), 0.01);
    }

    @Test
    void shouldCalculateTotalWithDiscount() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.addItem(createItem(1L, 100.0, 2.0)); // total = 200
        cart.setDesconto(30.0);

        assertEquals(170.0, cart.getTotal(), 0.01);
    }

    @Test
    void shouldNotAllowNegativeTotal() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.addItem(createItem(1L, 10.0, 1.0));
        cart.setDesconto(100.0);

        assertTrue(cart.getTotal() >= 0);
    }

    @Test
    void shouldNotAcceptNegativeDiscount() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.setDesconto(-50.0);

        assertEquals(0.0, cart.getDesconto(), 0.01);
    }

    @Test
    void shouldApplyAdditionalDiscount() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.setDesconto(10.0);
        cart.applyDiscount(20.0);

        assertEquals(30.0, cart.getDesconto(), 0.01);
    }

    @Test
    void shouldIgnoreNegativeAdditionalDiscount() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.setDesconto(10.0);
        cart.applyDiscount(-5.0);

        assertEquals(10.0, cart.getDesconto(), 0.01);
    }

    @Test
    void shouldReturnCopyOfItems() {
        CarrinhoService cart = CarrinhoService.getInstance();
        cart.addItem(createItem(1L, 100.0, 1.0));

        List<VendaItem> items = cart.getItems();
        items.clear(); // modifying the returned list should not affect the cart

        assertEquals(1, cart.getItemCount());
    }

    private VendaItem createItem(Long produtoId, double preco, double qty) {
        VendaItem item = new VendaItem();
        item.setProdutoId(produtoId);
        item.setPrecoUnitario(preco);
        item.setQuantidade(qty);
        item.setTotal(preco * qty);
        item.setDesconto(0.0);
        return item;
    }
}
