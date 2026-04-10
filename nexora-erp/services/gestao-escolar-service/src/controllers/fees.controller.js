'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { enrollment_id, status } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];
    if (enrollment_id) {
      params.push(enrollment_id);
      conditions.push(`enrollment_id = $${params.length}`);
    }
    if (status) {
      params.push(status);
      conditions.push(`status = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT * FROM school_fees WHERE ${conditions.join(' AND ')} ORDER BY data_vencimento ASC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { enrollment_id, numero, descricao, mes_referencia, data_vencimento, valor_total, moeda } = req.body;
    if (!enrollment_id || !numero || !descricao || !data_vencimento) {
      return res.status(400).json({ error: 'enrollment_id, numero, descricao e data_vencimento sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO school_fees
       (tenant_id, enrollment_id, numero, descricao, mes_referencia, data_vencimento, valor_total, moeda)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING *`,
      [req.user.tenantId, enrollment_id, numero, descricao, mes_referencia || null, data_vencimento, valor_total || 0, moeda || 'MZN']
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function pagar(req, res, next) {
  try {
    const { valor_pago } = req.body;
    if (valor_pago === undefined) {
      return res.status(400).json({ error: 'valor_pago e obrigatorio' });
    }

    const { rows } = await db.query(
      `UPDATE school_fees
          SET valor_pago = valor_pago + $1,
              status = CASE
                         WHEN (valor_pago + $1) >= valor_total THEN 'paga'
                         WHEN (valor_pago + $1) > 0 THEN 'parcial'
                         ELSE status
                       END
        WHERE id = $2 AND tenant_id = $3 AND status IN ('pendente','parcial')
      RETURNING *`,
      [valor_pago, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Propina nao encontrada ou nao pode ser paga' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, pagar };
