'use strict';

function roundMoney(value) {
  return Math.round((Number(value) + Number.EPSILON) * 100) / 100;
}

function normalizeItems(items) {
  if (!Array.isArray(items) || !items.length) {
    throw new Error('items deve conter pelo menos uma linha');
  }

  return items.map((item) => {
    const quantity = Number(item.quantity);
    const unitPrice = Number(item.unit_price);
    const desconto = Number(item.desconto || 0);
    const taxRate = Number(item.tax_rate || 0);

    if (!item.descricao || Number.isNaN(quantity) || quantity <= 0 || Number.isNaN(unitPrice) || unitPrice < 0) {
      throw new Error('Cada item requer descricao, quantity e unit_price validos');
    }

    const bruto = roundMoney(quantity * unitPrice);
    const base = roundMoney(bruto - desconto);
    const taxAmount = roundMoney(base * (taxRate / 100));
    const total = roundMoney(base + taxAmount);

    return {
      product_id: item.product_id || null,
      descricao: item.descricao,
      unidade: item.unidade || 'UN',
      quantity,
      unit_price: unitPrice,
      desconto,
      tax_rate: taxRate,
      tax_amount: taxAmount,
      total
    };
  });
}

function summarizeItems(items) {
  return items.reduce((acc, item) => {
    acc.subtotal = roundMoney(acc.subtotal + (item.quantity * item.unit_price));
    acc.desconto_total = roundMoney(acc.desconto_total + item.desconto);
    acc.imposto_total = roundMoney(acc.imposto_total + item.tax_amount);
    acc.total = roundMoney(acc.total + item.total);
    return acc;
  }, { subtotal: 0, desconto_total: 0, imposto_total: 0, total: 0 });
}

module.exports = { normalizeItems, summarizeItems, roundMoney };
