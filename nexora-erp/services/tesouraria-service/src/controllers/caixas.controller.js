'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT id, nome, saldo_atual, ativo, created_at
         FROM caixas
        WHERE tenant_id = $1
        ORDER BY nome ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { nome } = req.body;
    if (!nome) return res.status(400).json({ error: 'nome é obrigatório' });

    const { rows } = await db.query(
      `INSERT INTO caixas (tenant_id, nome)
       VALUES ($1, $2) RETURNING *`,
      [req.user.tenantId, nome]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM caixas WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Caixa não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { nome, ativo } = req.body;
    const { rows } = await db.query(
      `UPDATE caixas SET
         nome  = COALESCE($1, nome),
         ativo = COALESCE($2, ativo)
       WHERE id = $3 AND tenant_id = $4 RETURNING *`,
      [nome || null, ativo !== undefined ? ativo : null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Caixa não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function entrada(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const { valor, origem_tipo, origem_id, descricao } = req.body;
    if (!valor || Number(valor) <= 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'valor deve ser um número positivo' });
    }
    if (!origem_tipo) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'origem_tipo é obrigatório' });
    }

    const tiposValidos = ['faturacao', 'compras', 'rh', 'ajuste'];
    if (!tiposValidos.includes(origem_tipo)) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: `origem_tipo inválido. Valores aceites: ${tiposValidos.join(', ')}` });
    }

    const { rows: caixa } = await client.query(
      `SELECT id, ativo FROM caixas WHERE id = $1 AND tenant_id = $2 FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!caixa.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Caixa não encontrada' });
    }
    if (!caixa[0].ativo) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Caixa inactiva' });
    }

    const { rows: updated } = await client.query(
      `UPDATE caixas SET saldo_atual = saldo_atual + $1 WHERE id = $2 RETURNING saldo_atual`,
      [valor, req.params.id]
    );

    const { rows: mov } = await client.query(
      `INSERT INTO movimentos_financeiros
         (tenant_id, origem_tipo, origem_id, caixa_id, tipo, valor, descricao)
       VALUES ($1, $2, $3, $4, 'recebimento', $5, $6) RETURNING *`,
      [req.user.tenantId, origem_tipo, origem_id || null, req.params.id, valor, descricao || null]
    );

    await client.query('COMMIT');
    res.status(201).json({ saldo_atual: updated[0].saldo_atual, movimento: mov[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function saida(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const { valor, origem_tipo, descricao } = req.body;
    if (!valor || Number(valor) <= 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'valor deve ser um número positivo' });
    }
    if (!origem_tipo) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'origem_tipo é obrigatório' });
    }

    const tiposValidos = ['faturacao', 'compras', 'rh', 'ajuste'];
    if (!tiposValidos.includes(origem_tipo)) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: `origem_tipo inválido. Valores aceites: ${tiposValidos.join(', ')}` });
    }

    const { rows: caixa } = await client.query(
      `SELECT id, ativo, saldo_atual FROM caixas WHERE id = $1 AND tenant_id = $2 FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!caixa.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Caixa não encontrada' });
    }
    if (!caixa[0].ativo) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Caixa inactiva' });
    }
    if (Number(caixa[0].saldo_atual) < Number(valor)) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Saldo insuficiente' });
    }

    const { rows: updated } = await client.query(
      `UPDATE caixas SET saldo_atual = saldo_atual - $1 WHERE id = $2 RETURNING saldo_atual`,
      [valor, req.params.id]
    );

    const { rows: mov } = await client.query(
      `INSERT INTO movimentos_financeiros
         (tenant_id, origem_tipo, caixa_id, tipo, valor, descricao)
       VALUES ($1, $2, $3, 'pagamento', $4, $5) RETURNING *`,
      [req.user.tenantId, origem_tipo, req.params.id, valor, descricao || null]
    );

    await client.query('COMMIT');
    res.status(201).json({ saldo_atual: updated[0].saldo_atual, movimento: mov[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

module.exports = { listar, criar, obter, actualizar, entrada, saida };
