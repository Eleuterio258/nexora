'use strict';

function roundMoney(value) {
  return Math.round((Number(value) + Number.EPSILON) * 100) / 100;
}

function normalizeLines(lines) {
  if (!Array.isArray(lines) || !lines.length) {
    throw new Error('lines deve conter pelo menos uma linha');
  }

  return lines.map((line) => {
    const debit = roundMoney(line.debit || 0);
    const credit = roundMoney(line.credit || 0);
    if (!line.account_id) {
      throw new Error('Cada linha requer account_id');
    }
    if ((debit > 0 && credit > 0) || (debit === 0 && credit === 0)) {
      throw new Error('Cada linha deve ter apenas debito ou credito');
    }
    return {
      account_id: Number(line.account_id),
      debit,
      credit,
      description: line.description || null,
      reference_type: line.reference_type || null,
      reference_id: line.reference_id || null
    };
  });
}

function validateBalanced(lines) {
  const totals = lines.reduce((acc, line) => {
    acc.debit = roundMoney(acc.debit + line.debit);
    acc.credit = roundMoney(acc.credit + line.credit);
    return acc;
  }, { debit: 0, credit: 0 });

  if (totals.debit !== totals.credit) {
    throw new Error('Lancamento nao balanceado');
  }

  return totals;
}

module.exports = { roundMoney, normalizeLines, validateBalanced };
