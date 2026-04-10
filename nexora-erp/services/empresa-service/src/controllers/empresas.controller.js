'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const params = [];
    const conditions = [];

    if (status) { params.push(status); conditions.push(`status = $${params.length}`); }

    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    params.push(Number(limit), offset);

    const [dataRes, countRes] = await Promise.all([
      db.query(
        `SELECT id, codigo, nome, nome_comercial, tipo, status, moeda_base, timezone, created_at
           FROM companies ${where}
          ORDER BY nome ASC
          LIMIT $${params.length - 1} OFFSET $${params.length}`,
        params
      ),
      db.query(`SELECT COUNT(*) FROM companies ${where}`, params.slice(0, -2)),
    ]);

    res.json({
      data: dataRes.rows,
      meta: { total: parseInt(countRes.rows[0].count), page: Number(page), limit: Number(limit) },
    });
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome, nome_comercial, tipo, moeda_base, timezone } = req.body;
    if (!codigo || !nome) return res.status(400).json({ error: 'codigo e nome são obrigatórios' });

    const { rows } = await db.query(
      `INSERT INTO companies (codigo, nome, nome_comercial, tipo, moeda_base, timezone)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [codigo, nome, nome_comercial || null, tipo || 'empresa', moeda_base || 'MZN', timezone || 'Africa/Maputo']
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ error: 'Código já existe' });
    next(err);
  }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT c.*,
              t.nuit, t.regime_iva, t.taxa_iva_padrao, t.reparticao_fiscal
         FROM companies c
         LEFT JOIN company_tax_info t ON t.company_id = c.id
        WHERE c.id = $1`,
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Empresa não encontrada' });
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function actualizar(req, res, next) {
  try {
    const { nome, nome_comercial, tipo, moeda_base, timezone, status } = req.body;
    const { rows } = await db.query(
      `UPDATE companies SET
         nome          = COALESCE($1, nome),
         nome_comercial = COALESCE($2, nome_comercial),
         tipo          = COALESCE($3, tipo),
         moeda_base    = COALESCE($4, moeda_base),
         timezone      = COALESCE($5, timezone),
         status        = COALESCE($6, status),
         updated_at    = NOW()
       WHERE id = $7
       RETURNING *`,
      [nome, nome_comercial, tipo, moeda_base, timezone, status, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Empresa não encontrada' });
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

// Settings
async function getSettings(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT chave, valor, updated_at FROM company_settings WHERE company_id = $1`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function upsertSetting(req, res, next) {
  try {
    const { chave, valor } = req.body;
    if (!chave) return res.status(400).json({ error: 'chave é obrigatória' });
    const { rows } = await db.query(
      `INSERT INTO company_settings (company_id, chave, valor)
       VALUES ($1, $2, $3)
       ON CONFLICT (company_id, chave) DO UPDATE SET valor = $3, updated_at = NOW()
       RETURNING *`,
      [req.params.id, chave, valor]
    );
    res.json(rows[0]);
  } catch (err) { next(err); }
}

// Tax info
async function getTaxInfo(req, res, next) {
  try {
    const { rows } = await db.query(`SELECT * FROM company_tax_info WHERE company_id = $1`, [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Informação fiscal não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function upsertTaxInfo(req, res, next) {
  try {
    const { nuit, regime_iva, taxa_iva_padrao, inicio_atividade, reparticao_fiscal } = req.body;
    if (!nuit) return res.status(400).json({ error: 'nuit é obrigatório' });
    const { rows } = await db.query(
      `INSERT INTO company_tax_info (company_id, nuit, regime_iva, taxa_iva_padrao, inicio_atividade, reparticao_fiscal)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (company_id) DO UPDATE SET
         nuit = $2, regime_iva = $3, taxa_iva_padrao = $4,
         inicio_atividade = $5, reparticao_fiscal = $6, updated_at = NOW()
       RETURNING *`,
      [req.params.id, nuit, regime_iva || null, taxa_iva_padrao || 17.00, inicio_atividade || null, reparticao_fiscal || null]
    );
    res.json(rows[0]);
  } catch (err) { next(err); }
}

// Branches
async function listBranches(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM company_branches WHERE company_id = $1 ORDER BY principal DESC, nome ASC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function createBranch(req, res, next) {
  try {
    const { codigo, nome, principal } = req.body;
    if (!codigo || !nome) return res.status(400).json({ error: 'codigo e nome são obrigatórios' });
    const { rows } = await db.query(
      `INSERT INTO company_branches (company_id, codigo, nome, principal)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.params.id, codigo, nome, !!principal]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ error: 'Código de filial já existe' });
    next(err);
  }
}

// Banks
async function listBanks(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM company_banks WHERE company_id = $1 ORDER BY principal DESC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function createBank(req, res, next) {
  try {
    const { banco, numero_conta, nib, iban, swift, moeda, principal } = req.body;
    if (!banco || !numero_conta) return res.status(400).json({ error: 'banco e numero_conta são obrigatórios' });
    const { rows } = await db.query(
      `INSERT INTO company_banks (company_id, banco, numero_conta, nib, iban, swift, moeda, principal)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
      [req.params.id, banco, numero_conta, nib || null, iban || null, swift || null, moeda || 'MZN', !!principal]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

// Company users
async function listUsers(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM company_users WHERE company_id = $1 ORDER BY created_at DESC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function addUser(req, res, next) {
  try {
    const { user_id, branch_id, perfil_empresa } = req.body;
    if (!user_id) return res.status(400).json({ error: 'user_id é obrigatório' });
    const { rows } = await db.query(
      `INSERT INTO company_users (company_id, user_id, branch_id, perfil_empresa)
       VALUES ($1,$2,$3,$4) RETURNING *`,
      [req.params.id, user_id, branch_id || null, perfil_empresa || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ error: 'Utilizador já associado a esta empresa' });
    next(err);
  }
}

async function removeUser(req, res, next) {
  try {
    const { rowCount } = await db.query(
      `DELETE FROM company_users WHERE company_id = $1 AND user_id = $2`,
      [req.params.id, req.params.userId]
    );
    if (!rowCount) return res.status(404).json({ error: 'Associação não encontrada' });
    res.status(204).send();
  } catch (err) { next(err); }
}

module.exports = {
  listar, criar, obter, actualizar,
  getSettings, upsertSetting,
  getTaxInfo, upsertTaxInfo,
  listBranches, createBranch,
  listBanks, createBank,
  listUsers, addUser, removeUser,
};
