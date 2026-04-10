'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT r.id, r.conta_bancaria_id, cb.banco, cb.numero_conta,
              r.periodo_inicio, r.periodo_fim, r.saldo_extrato,
              r.saldo_sistema, r.diferenca, r.status, r.created_at
         FROM reconciliacoes_bancarias r
         JOIN contas_bancarias cb ON cb.id = r.conta_bancaria_id
        WHERE r.tenant_id = $1
        ORDER BY r.created_at DESC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { conta_bancaria_id, periodo_inicio, periodo_fim, saldo_extrato } = req.body;
    if (!conta_bancaria_id || !periodo_inicio || !periodo_fim || saldo_extrato === undefined) {
      return res.status(400).json({ error: 'conta_bancaria_id, periodo_inicio, periodo_fim e saldo_extrato são obrigatórios' });
    }

    const { rows: conta } = await db.query(
      `SELECT id FROM contas_bancarias WHERE id = $1 AND tenant_id = $2`,
      [conta_bancaria_id, req.user.tenantId]
    );
    if (!conta.length) return res.status(404).json({ error: 'Conta bancária não encontrada' });

    // Calcula saldo_sistema: recebimentos - pagamentos no período
    const { rows: calc } = await db.query(
      `SELECT
         COALESCE(SUM(CASE WHEN tipo IN ('recebimento','transferencia') THEN valor ELSE 0 END), 0)
         - COALESCE(SUM(CASE WHEN tipo IN ('pagamento') THEN valor ELSE 0 END), 0) AS saldo_sistema
       FROM movimentos_financeiros
      WHERE conta_bancaria_id = $1
        AND data_movimento >= $2
        AND data_movimento <= ($3::date + interval '1 day - 1 second')`,
      [conta_bancaria_id, periodo_inicio, periodo_fim]
    );

    const saldo_sistema = Number(calc[0].saldo_sistema);
    const diferenca = Number(saldo_extrato) - saldo_sistema;

    const { rows } = await db.query(
      `INSERT INTO reconciliacoes_bancarias
         (tenant_id, conta_bancaria_id, periodo_inicio, periodo_fim, saldo_extrato, saldo_sistema, diferenca, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'aberta') RETURNING *`,
      [req.user.tenantId, conta_bancaria_id, periodo_inicio, periodo_fim,
       saldo_extrato, saldo_sistema, diferenca]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT r.*, cb.banco, cb.numero_conta
         FROM reconciliacoes_bancarias r
         JOIN contas_bancarias cb ON cb.id = r.conta_bancaria_id
        WHERE r.id = $1 AND r.tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Reconciliação não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function fechar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE reconciliacoes_bancarias
          SET status = 'fechada'
        WHERE id = $1 AND tenant_id = $2 AND status = 'aberta'
        RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Reconciliação não encontrada ou já fechada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

module.exports = { listar, criar, obter, fechar };
