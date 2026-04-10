'use strict';

const db = require('../config/db');

async function balancete(req, res, next) {
  try {
    const { data_inicio, data_fim } = req.query;
    if (!data_inicio || !data_fim) {
      return res.status(400).json({ error: 'data_inicio e data_fim sao obrigatorios' });
    }

    const { rows } = await db.query(
      `SELECT
          coa.id,
          coa.codigo,
          coa.nome,
          coa.tipo,
          coa.natureza,
          COALESCE(SUM(jel.debit), 0) AS total_debito,
          COALESCE(SUM(jel.credit), 0) AS total_credito,
          COALESCE(SUM(jel.debit - jel.credit), 0) AS saldo
         FROM chart_of_accounts coa
         LEFT JOIN journal_entry_lines jel ON jel.account_id = coa.id
         LEFT JOIN journal_entries je ON je.id = jel.journal_entry_id
                                    AND je.status = 'publicado'
                                    AND je.entry_date BETWEEN $2 AND $3
         WHERE coa.tenant_id = $1
         GROUP BY coa.id, coa.codigo, coa.nome, coa.tipo, coa.natureza
         ORDER BY coa.codigo ASC`,
      [req.user.tenantId, data_inicio, data_fim]
    );

    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function razao(req, res, next) {
  try {
    const { account_id, data_inicio, data_fim } = req.query;
    if (!account_id || !data_inicio || !data_fim) {
      return res.status(400).json({ error: 'account_id, data_inicio e data_fim sao obrigatorios' });
    }

    const { rows } = await db.query(
      `SELECT
          je.id AS journal_entry_id,
          je.numero,
          je.entry_date,
          je.descricao AS entry_description,
          jel.descricao AS line_description,
          jel.debit,
          jel.credit,
          jel.reference_type,
          jel.reference_id
         FROM journal_entry_lines jel
         JOIN journal_entries je ON je.id = jel.journal_entry_id
        WHERE je.tenant_id = $1
          AND je.status = 'publicado'
          AND jel.account_id = $2
          AND je.entry_date BETWEEN $3 AND $4
        ORDER BY je.entry_date ASC, jel.id ASC`,
      [req.user.tenantId, account_id, data_inicio, data_fim]
    );

    res.json(rows);
  } catch (err) {
    next(err);
  }
}

module.exports = { balancete, razao };
