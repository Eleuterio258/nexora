'use strict';

const db = require('../config/db');
const { roundAmount } = require('../lib/fx');

async function converter(req, res, next) {
  try {
    const { from_currency_id, to_currency_id, amount, effective_date } = req.body;
    if (!from_currency_id || !to_currency_id || amount === undefined) {
      return res.status(400).json({ error: 'from_currency_id, to_currency_id e amount sao obrigatorios' });
    }

    if (Number(from_currency_id) === Number(to_currency_id)) {
      return res.json({ rate: 1, original_amount: Number(amount), converted_amount: Number(amount) });
    }

    const { rows } = await db.query(
      `SELECT er.rate, cb.code AS from_code, cq.code AS to_code
         FROM exchange_rates er
         JOIN currencies cb ON cb.id = er.base_currency_id
         JOIN currencies cq ON cq.id = er.quote_currency_id
        WHERE er.tenant_id = $1
          AND er.base_currency_id = $2
          AND er.quote_currency_id = $3
          AND er.effective_date <= COALESCE($4, CURRENT_DATE)
        ORDER BY er.effective_date DESC, er.created_at DESC
        LIMIT 1`,
      [req.user.tenantId, from_currency_id, to_currency_id, effective_date || null]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Taxa de cambio nao encontrada para o par informado' });
    }

    const converted = roundAmount(Number(amount) * Number(rows[0].rate));
    res.json({
      from_currency_id: Number(from_currency_id),
      to_currency_id: Number(to_currency_id),
      from_code: rows[0].from_code,
      to_code: rows[0].to_code,
      rate: Number(rows[0].rate),
      original_amount: Number(amount),
      converted_amount: converted
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { converter };
