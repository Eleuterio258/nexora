'use strict';

/**
 * Calcula os totais de uma linha de documento.
 * Desconto é aplicado ANTES do IVA (base imponível = preço - desconto).
 */
function calcularLinha(item) {
  const qtd = Number(item.quantidade);
  const preco = Number(item.preco_unitario);
  const descPct = Number(item.desconto_percent || 0);
  const imposPct = Number(item.imposto_percent || 0);

  const bruto = qtd * preco;
  const descValor = parseFloat((bruto * descPct / 100).toFixed(2));
  const subtotal = parseFloat((bruto - descValor).toFixed(2));
  const imposValor = parseFloat((subtotal * imposPct / 100).toFixed(2));
  const total = parseFloat((subtotal + imposValor).toFixed(2));

  return { desconto_valor: descValor, subtotal, imposto_valor: imposValor, total };
}

/**
 * Agrega os totais de um array de linhas calculadas.
 * @param {Array} linhas — linhas já com desconto_valor, subtotal, imposto_valor, total
 * @returns {{ subtotal, desconto_total, imposto_total, total }}
 */
function calcularDocumento(linhas) {
  let subtotal = 0;
  let desconto_total = 0;
  let imposto_total = 0;
  let total = 0;

  for (const l of linhas) {
    subtotal       += Number(l.subtotal);
    desconto_total += Number(l.desconto_valor);
    imposto_total  += Number(l.imposto_valor);
    total          += Number(l.total);
  }

  return {
    subtotal:       parseFloat(subtotal.toFixed(2)),
    desconto_total: parseFloat(desconto_total.toFixed(2)),
    imposto_total:  parseFloat(imposto_total.toFixed(2)),
    total:          parseFloat(total.toFixed(2)),
  };
}

module.exports = { calcularLinha, calcularDocumento };
