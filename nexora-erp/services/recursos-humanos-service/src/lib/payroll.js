'use strict';

function roundMoney(value) {
  return Math.round((Number(value) + Number.EPSILON) * 100) / 100;
}

function calcularFolha(baseSalary, additions, deductions) {
  const salarioBase = roundMoney(baseSalary || 0);
  const adicionais = roundMoney(additions || 0);
  const descontos = roundMoney(deductions || 0);
  const bruto = roundMoney(salarioBase + adicionais);
  const liquido = roundMoney(bruto - descontos);

  return {
    salario_base: salarioBase,
    adicionais,
    descontos,
    bruto,
    liquido
  };
}

module.exports = { calcularFolha, roundMoney };
