'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { ano, financial_category_id } = req.query;

    const params = [tenantId];
    const conditions = ['fb.tenant_id = $1'];

    if (ano) {
      params.push(Number(ano));
      conditions.push(`fb.ano = $${params.length}`);
    }
    if (financial_category_id) {
      params.push(Number(financial_category_id));
      conditions.push(`fb.financial_category_id = $${params.length}`);
    }

    const where = conditions.join(' AND ');

    const { rows } = await db.query(
      `SELECT fb.*, fc.nome AS category_nome, fc.tipo AS category_tipo
       FROM financial_budgets fb
       LEFT JOIN financial_categories fc ON fc.id = fb.financial_category_id
       WHERE ${where}
       ORDER BY fb.ano DESC, fb.mes ASC`,
      params
    );

    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function upsert(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { financial_category_id, ano, mes, valor_orcamentado } = req.body;

    if (!financial_category_id || !ano || valor_orcamentado === undefined) {
      const err = new Error('financial_category_id, ano e valor_orcamentado são obrigatórios');
      err.status = 400;
      return next(err);
    }

    const { rows } = await db.query(
      `INSERT INTO financial_budgets (tenant_id, financial_category_id, ano, mes, valor_orcamentado)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (tenant_id, financial_category_id, ano, mes)
       DO UPDATE SET valor_orcamentado = EXCLUDED.valor_orcamentado
       RETURNING *`,
      [tenantId, financial_category_id, ano, mes || null, valor_orcamentado]
    );

    res.status(200).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function comparativo(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { ano } = req.query;

    if (!ano) {
      const err = new Error('O parâmetro ano é obrigatório');
      err.status = 400;
      return next(err);
    }

    const { rows } = await db.query(
      `SELECT
         fc.id AS financial_category_id,
         fc.nome AS category_nome,
         fc.tipo AS category_tipo,
         COALESCE(SUM(fb.valor_orcamentado), 0) AS valor_orcamentado,
         COALESCE(
           (
             SELECT SUM(p.valor)
             FROM payments p
             WHERE p.tenant_id = $1
               AND p.financial_category_id = fc.id
               AND EXTRACT(YEAR FROM p.data_pagamento) = $2
               AND p.status != 'cancelado'
           ), 0
         ) AS valor_realizado
       FROM financial_categories fc
       LEFT JOIN financial_budgets fb
         ON fb.financial_category_id = fc.id
         AND fb.tenant_id = $1
         AND fb.ano = $2
       WHERE fc.tenant_id = $1
       GROUP BY fc.id, fc.nome, fc.tipo
       ORDER BY fc.tipo, fc.nome`,
      [tenantId, Number(ano)]
    );

    const result = rows.map((r) => ({
      ...r,
      valor_orcamentado: Number(r.valor_orcamentado),
      valor_realizado: Number(r.valor_realizado),
      variacao: Number(r.valor_realizado) - Number(r.valor_orcamentado),
    }));

    res.json({ ano: Number(ano), data: result });
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, upsert, comparativo };
