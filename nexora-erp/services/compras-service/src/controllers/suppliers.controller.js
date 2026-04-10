'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { estado, q } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];

    if (estado) {
      params.push(estado);
      conditions.push(`estado = $${params.length}`);
    }

    if (q) {
      params.push(`%${q}%`);
      conditions.push(`(nome ILIKE $${params.length} OR codigo ILIKE $${params.length} OR nuit ILIKE $${params.length})`);
    }

    const { rows } = await db.query(
      `SELECT id, supplier_group_id, codigo, nome, nuit, telefone, email, moeda_padrao, prazo_pagamento_dias, estado, created_at
         FROM suppliers
        WHERE ${conditions.join(' AND ')}
        ORDER BY nome ASC`,
      params
    );

    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function detalhar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM suppliers WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Fornecedor nao encontrado' });
    }

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const {
      supplier_group_id, codigo, nome, nuit, telefone, email, moeda_padrao, prazo_pagamento_dias, observacao
    } = req.body;

    if (!nome) {
      return res.status(400).json({ error: 'nome e obrigatorio' });
    }

    const { rows } = await db.query(
      `INSERT INTO suppliers
       (tenant_id, supplier_group_id, codigo, nome, nuit, telefone, email, moeda_padrao, prazo_pagamento_dias, observacao)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
       RETURNING *`,
      [
        req.user.tenantId,
        supplier_group_id || null,
        codigo || null,
        nome,
        nuit || null,
        telefone || null,
        email || null,
        moeda_padrao || 'MZN',
        Number(prazo_pagamento_dias || 0),
        observacao || null
      ]
    );

    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const {
      supplier_group_id, codigo, nome, nuit, telefone, email, moeda_padrao, prazo_pagamento_dias, estado, observacao
    } = req.body;

    const { rows } = await db.query(
      `UPDATE suppliers
          SET supplier_group_id = COALESCE($1, supplier_group_id),
              codigo = COALESCE($2, codigo),
              nome = COALESCE($3, nome),
              nuit = COALESCE($4, nuit),
              telefone = COALESCE($5, telefone),
              email = COALESCE($6, email),
              moeda_padrao = COALESCE($7, moeda_padrao),
              prazo_pagamento_dias = COALESCE($8, prazo_pagamento_dias),
              estado = COALESCE($9, estado),
              observacao = COALESCE($10, observacao),
              updated_at = NOW()
        WHERE id = $11 AND tenant_id = $12
      RETURNING *`,
      [
        supplier_group_id ?? null,
        codigo ?? null,
        nome ?? null,
        nuit ?? null,
        telefone ?? null,
        email ?? null,
        moeda_padrao ?? null,
        prazo_pagamento_dias ?? null,
        estado ?? null,
        observacao ?? null,
        req.params.id,
        req.user.tenantId
      ]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Fornecedor nao encontrado' });
    }

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, detalhar, criar, atualizar };
