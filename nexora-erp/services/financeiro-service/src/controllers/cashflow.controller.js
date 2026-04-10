'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { tipo, origem, data_inicio, data_fim, page = 1, limit = 20 } = req.query;

    const params = [tenantId];
    const conditions = ['tenant_id = $1'];

    if (tipo) {
      params.push(tipo);
      conditions.push(`tipo = $${params.length}`);
    }
    if (origem) {
      params.push(origem);
      conditions.push(`origem = $${params.length}`);
    }
    if (data_inicio) {
      params.push(data_inicio);
      conditions.push(`data >= $${params.length}`);
    }
    if (data_fim) {
      params.push(data_fim);
      conditions.push(`data <= $${params.length}`);
    }

    const offset = (Number(page) - 1) * Number(limit);
    const where = conditions.join(' AND ');

    const { rows: countRows } = await db.query(
      `SELECT COUNT(*) AS total FROM cash_flow_entries WHERE ${where}`,
      params
    );

    params.push(Number(limit), offset);
    const { rows } = await db.query(
      `SELECT * FROM cash_flow_entries WHERE ${where}
       ORDER BY data DESC, created_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    res.json({ total: Number(countRows[0].total), page: Number(page), limit: Number(limit), data: rows });
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { tipo, origem, data, valor, descricao, financial_category_id, referencia_tipo, referencia_id } = req.body;

    if (!tipo || !origem || !data || !valor) {
      const err = new Error('tipo, origem, data e valor são obrigatórios');
      err.status = 400;
      return next(err);
    }

    const { rows } = await db.query(
      `INSERT INTO cash_flow_entries
         (tenant_id, financial_category_id, tipo, origem, data, valor, descricao, referencia_tipo, referencia_id)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       RETURNING *`,
      [
        tenantId,
        financial_category_id || null,
        tipo,
        origem,
        data,
        valor,
        descricao || null,
        referencia_tipo || null,
        referencia_id || null,
      ]
    );

    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === '23514') {
      err.status = 400;
      err.message = 'Tipo ou origem inválidos';
    }
    next(err);
  }
}

async function resumo(req, res, next) {
  try {
    const { tenantId } = req.user;
    const { data_inicio, data_fim } = req.query;

    if (!data_inicio || !data_fim) {
      const err = new Error('data_inicio e data_fim são obrigatórios');
      err.status = 400;
      return next(err);
    }

    const { rows } = await db.query(
      `SELECT
         DATE_TRUNC('week', data) AS semana,
         SUM(CASE WHEN tipo = 'entrada' THEN valor ELSE 0 END) AS total_entradas,
         SUM(CASE WHEN tipo = 'saida' THEN valor ELSE 0 END) AS total_saidas,
         SUM(CASE WHEN tipo = 'entrada' THEN valor ELSE -valor END) AS saldo_semana
       FROM cash_flow_entries
       WHERE tenant_id = $1
         AND data BETWEEN $2 AND $3
       GROUP BY DATE_TRUNC('week', data)
       ORDER BY semana ASC`,
      [tenantId, data_inicio, data_fim]
    );

    const totais = rows.reduce(
      (acc, r) => ({
        total_entradas: acc.total_entradas + Number(r.total_entradas),
        total_saidas: acc.total_saidas + Number(r.total_saidas),
      }),
      { total_entradas: 0, total_saidas: 0 }
    );

    res.json({
      data_inicio,
      data_fim,
      totais: {
        ...totais,
        saldo_periodo: totais.total_entradas - totais.total_saidas,
      },
      por_semana: rows.map((r) => ({
        semana: r.semana,
        total_entradas: Number(r.total_entradas),
        total_saidas: Number(r.total_saidas),
        saldo_semana: Number(r.saldo_semana),
      })),
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, resumo };
