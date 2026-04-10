'use strict';

const db = require('../config/db');

async function ultimasTaxas(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT DISTINCT ON (er.base_currency_id, er.quote_currency_id)
              er.id,
              er.effective_date,
              er.rate,
              er.source,
              er.is_official,
              cb.code AS base_code,
              cq.code AS quote_code
         FROM exchange_rates er
         JOIN currencies cb ON cb.id = er.base_currency_id
         JOIN currencies cq ON cq.id = er.quote_currency_id
        WHERE er.tenant_id = $1
        ORDER BY er.base_currency_id, er.quote_currency_id, er.effective_date DESC, er.created_at DESC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

module.exports = { ultimasTaxas };
