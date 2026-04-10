'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { conta_bancaria_id, caixa_id, tipo, data_inicio, data_fim, page = 1, limit = 20 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];

    if (conta_bancaria_id) {
      params.push(conta_bancaria_id);
      cond.push(`conta_bancaria_id = $${params.length}`);
    }
    if (caixa_id) {
      params.push(caixa_id);
      cond.push(`caixa_id = $${params.length}`);
    }
    if (tipo) {
      params.push(tipo);
      cond.push(`tipo = $${params.length}`);
    }
    if (data_inicio) {
      params.push(data_inicio);
      cond.push(`data_movimento >= $${params.length}`);
    }
    if (data_fim) {
      params.push(data_fim);
      cond.push(`data_movimento <= $${params.length}`);
    }

    params.push(Number(limit), offset);
    const { rows } = await db.query(
      `SELECT id, origem_tipo, origem_id, conta_bancaria_id, caixa_id,
              tipo, valor, referencia, descricao, data_movimento
         FROM movimentos_financeiros
        WHERE ${cond.join(' AND ')}
        ORDER BY data_movimento DESC
        LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

module.exports = { listar };
