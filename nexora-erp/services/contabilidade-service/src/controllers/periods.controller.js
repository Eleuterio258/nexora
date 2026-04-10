'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM accounting_periods
        WHERE tenant_id = $1
        ORDER BY ano DESC, mes DESC NULLS LAST, data_inicio DESC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { ano, mes, data_inicio, data_fim } = req.body;
    if (!ano || !data_inicio || !data_fim) {
      return res.status(400).json({ error: 'ano, data_inicio e data_fim sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO accounting_periods (tenant_id, ano, mes, data_inicio, data_fim)
       VALUES ($1,$2,$3,$4,$5)
       RETURNING *`,
      [req.user.tenantId, ano, mes || null, data_inicio, data_fim]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function fechar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE accounting_periods
          SET status = 'fechado', fechado_em = NOW(), fechado_por = $1
        WHERE id = $2 AND tenant_id = $3 AND status = 'aberto'
      RETURNING *`,
      [req.user.id, req.params.id, req.user.tenantId]
    );

    if (!rows.length) {
      return res.status(409).json({ error: 'Periodo nao encontrado ou ja fechado' });
    }

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, fechar };
