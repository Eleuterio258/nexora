'use strict';

const db = require('../config/db');
const { normalizeLines, validateBalanced } = require('../lib/validacao');

async function listar(req, res, next) {
  try {
    const { status, journal_id, data_inicio, data_fim } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['je.tenant_id = $1'];

    if (status) {
      params.push(status);
      conditions.push(`je.status = $${params.length}`);
    }
    if (journal_id) {
      params.push(journal_id);
      conditions.push(`je.accounting_journal_id = $${params.length}`);
    }
    if (data_inicio) {
      params.push(data_inicio);
      conditions.push(`je.entry_date >= $${params.length}`);
    }
    if (data_fim) {
      params.push(data_fim);
      conditions.push(`je.entry_date <= $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT je.*, aj.nome AS diario_nome
         FROM journal_entries je
         JOIN accounting_journals aj ON aj.id = je.accounting_journal_id
        WHERE ${conditions.join(' AND ')}
        ORDER BY je.entry_date DESC, je.created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM journal_entries WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Lancamento nao encontrado' });
    }

    const { rows: lines } = await db.query(
      `SELECT jel.*, coa.codigo AS conta_codigo, coa.nome AS conta_nome
         FROM journal_entry_lines jel
         JOIN chart_of_accounts coa ON coa.id = jel.account_id
        WHERE jel.journal_entry_id = $1
        ORDER BY jel.id ASC`,
      [req.params.id]
    );

    res.json({ ...rows[0], lines });
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const { accounting_period_id, accounting_journal_id, numero, entry_date, descricao, referencia_tipo, referencia_id, moeda, lines } = req.body;
    if (!accounting_period_id || !accounting_journal_id || !numero || !entry_date || !descricao) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'accounting_period_id, accounting_journal_id, numero, entry_date e descricao sao obrigatorios' });
    }

    const normalizedLines = normalizeLines(lines);
    const totals = validateBalanced(normalizedLines);

    const { rows: periods } = await client.query(
      `SELECT * FROM accounting_periods WHERE id = $1 AND tenant_id = $2 FOR UPDATE`,
      [accounting_period_id, req.user.tenantId]
    );
    if (!periods.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Periodo contabilistico nao encontrado' });
    }
    if (periods[0].status !== 'aberto') {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Periodo contabilistico fechado' });
    }

    const { rows: journals } = await client.query(
      `SELECT * FROM accounting_journals WHERE id = $1 AND tenant_id = $2 AND ativo = TRUE`,
      [accounting_journal_id, req.user.tenantId]
    );
    if (!journals.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Diario nao encontrado ou inativo' });
    }

    const accountIds = normalizedLines.map((line) => line.account_id);
    const { rows: accounts } = await client.query(
      `SELECT id, aceita_movimento, ativo FROM chart_of_accounts
        WHERE tenant_id = $1 AND id = ANY($2::bigint[])`,
      [req.user.tenantId, accountIds]
    );
    if (accounts.length !== accountIds.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Uma ou mais contas nao existem' });
    }
    const invalid = accounts.find((account) => !account.ativo || !account.aceita_movimento);
    if (invalid) {
      await client.query('ROLLBACK');
      return res.status(422).json({ error: 'Todas as contas devem estar ativas e aceitar movimento' });
    }

    const { rows } = await client.query(
      `INSERT INTO journal_entries
       (tenant_id, accounting_period_id, accounting_journal_id, numero, entry_date, descricao, referencia_tipo, referencia_id, moeda, total_debito, total_credito, criado_por)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
       RETURNING *`,
      [
        req.user.tenantId,
        accounting_period_id,
        accounting_journal_id,
        numero,
        entry_date,
        descricao,
        referencia_tipo || null,
        referencia_id || null,
        moeda || 'MZN',
        totals.debit,
        totals.credit,
        req.user.id
      ]
    );

    for (const line of normalizedLines) {
      await client.query(
        `INSERT INTO journal_entry_lines
         (journal_entry_id, account_id, descricao, debit, credit, reference_type, reference_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7)`,
        [rows[0].id, line.account_id, line.description, line.debit, line.credit, line.reference_type, line.reference_id]
      );
    }

    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
}

async function publicar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE journal_entries
          SET status = 'publicado',
              publicado_por = $1,
              publicado_em = NOW(),
              updated_at = NOW()
        WHERE id = $2 AND tenant_id = $3 AND status = 'rascunho'
      RETURNING *`,
      [req.user.id, req.params.id, req.user.tenantId]
    );

    if (!rows.length) {
      return res.status(409).json({ error: 'Apenas lancamentos em rascunho podem ser publicados' });
    }

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, obter, criar, publicar };
