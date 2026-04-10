'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT id, banco, numero_conta, nib, moeda, saldo_atual, ativa, created_at
         FROM contas_bancarias
        WHERE tenant_id = $1
        ORDER BY banco ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { banco, numero_conta, nib, moeda } = req.body;
    if (!banco || !numero_conta) {
      return res.status(400).json({ error: 'banco e numero_conta são obrigatórios' });
    }
    const { rows } = await db.query(
      `INSERT INTO contas_bancarias (tenant_id, banco, numero_conta, nib, moeda)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [req.user.tenantId, banco, numero_conta, nib || null, moeda || 'MZN']
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM contas_bancarias WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Conta bancária não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { banco, numero_conta, nib, ativa } = req.body;
    const { rows } = await db.query(
      `UPDATE contas_bancarias SET
         banco        = COALESCE($1, banco),
         numero_conta = COALESCE($2, numero_conta),
         nib          = COALESCE($3, nib),
         ativa        = COALESCE($4, ativa)
       WHERE id = $5 AND tenant_id = $6 RETURNING *`,
      [banco || null, numero_conta || null, nib !== undefined ? nib : null,
       ativa !== undefined ? ativa : null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Conta bancária não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function deposito(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const { valor, referencia, descricao } = req.body;
    if (!valor || Number(valor) <= 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'valor deve ser um número positivo' });
    }

    const { rows: conta } = await client.query(
      `SELECT id, ativa FROM contas_bancarias WHERE id = $1 AND tenant_id = $2 FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!conta.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Conta bancária não encontrada' });
    }
    if (!conta[0].ativa) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Conta bancária inactiva' });
    }

    const { rows: updated } = await client.query(
      `UPDATE contas_bancarias
          SET saldo_atual = saldo_atual + $1
        WHERE id = $2 RETURNING saldo_atual`,
      [valor, req.params.id]
    );

    const { rows: mov } = await client.query(
      `INSERT INTO movimentos_financeiros
         (tenant_id, origem_tipo, conta_bancaria_id, tipo, valor, referencia, descricao)
       VALUES ($1, 'ajuste', $2, 'recebimento', $3, $4, $5) RETURNING *`,
      [req.user.tenantId, req.params.id, valor, referencia || null, descricao || null]
    );

    await client.query('COMMIT');
    res.status(201).json({ saldo_atual: updated[0].saldo_atual, movimento: mov[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function levantamento(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const { valor, referencia, descricao } = req.body;
    if (!valor || Number(valor) <= 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'valor deve ser um número positivo' });
    }

    const { rows: conta } = await client.query(
      `SELECT id, ativa, saldo_atual FROM contas_bancarias WHERE id = $1 AND tenant_id = $2 FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!conta.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Conta bancária não encontrada' });
    }
    if (!conta[0].ativa) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Conta bancária inactiva' });
    }
    if (Number(conta[0].saldo_atual) < Number(valor)) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Saldo insuficiente' });
    }

    const { rows: updated } = await client.query(
      `UPDATE contas_bancarias
          SET saldo_atual = saldo_atual - $1
        WHERE id = $2 RETURNING saldo_atual`,
      [valor, req.params.id]
    );

    const { rows: mov } = await client.query(
      `INSERT INTO movimentos_financeiros
         (tenant_id, origem_tipo, conta_bancaria_id, tipo, valor, referencia, descricao)
       VALUES ($1, 'ajuste', $2, 'pagamento', $3, $4, $5) RETURNING *`,
      [req.user.tenantId, req.params.id, valor, referencia || null, descricao || null]
    );

    await client.query('COMMIT');
    res.status(201).json({ saldo_atual: updated[0].saldo_atual, movimento: mov[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

module.exports = { listar, criar, obter, actualizar, deposito, levantamento };
