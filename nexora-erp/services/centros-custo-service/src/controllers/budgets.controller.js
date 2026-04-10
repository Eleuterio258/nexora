'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { ano, cost_center_id } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['b.tenant_id = $1'];
    if (ano) {
      params.push(ano);
      conditions.push(`b.ano = $${params.length}`);
    }
    if (cost_center_id) {
      params.push(cost_center_id);
      conditions.push(`b.cost_center_id = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT b.*, c.codigo AS centro_codigo, c.nome AS centro_nome
         FROM cost_center_budgets b
         JOIN cost_centers c ON c.id = b.cost_center_id
        WHERE ${conditions.join(' AND ')}
        ORDER BY b.ano DESC, b.mes DESC NULLS LAST`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function upsert(req, res, next) {
  try {
    const { cost_center_id, ano, mes, valor_orcamentado, moeda } = req.body;
    if (!cost_center_id || !ano || valor_orcamentado === undefined) {
      return res.status(400).json({ error: 'cost_center_id, ano e valor_orcamentado sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO cost_center_budgets
       (tenant_id, cost_center_id, ano, mes, valor_orcamentado, moeda, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       ON CONFLICT (tenant_id, cost_center_id, ano, mes)
       DO UPDATE SET
         valor_orcamentado = EXCLUDED.valor_orcamentado,
         moeda = EXCLUDED.moeda,
         updated_at = NOW()
       RETURNING *`,
      [req.user.tenantId, cost_center_id, ano, mes || null, valor_orcamentado, moeda || 'MZN', req.user.id]
    );
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, upsert };
