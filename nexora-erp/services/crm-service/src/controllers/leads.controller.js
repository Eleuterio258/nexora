'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { estado, owner_user_id } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['l.tenant_id = $1'];

    if (estado) {
      params.push(estado);
      conditions.push(`l.estado = $${params.length}`);
    }
    if (owner_user_id) {
      params.push(owner_user_id);
      conditions.push(`l.owner_user_id = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT l.*, s.nome AS source_nome
         FROM crm_leads l
         LEFT JOIN crm_lead_sources s ON s.id = l.lead_source_id
        WHERE ${conditions.join(' AND ')}
        ORDER BY l.created_at DESC`,
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
      `SELECT * FROM crm_leads WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Lead nao encontrado' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { lead_source_id, codigo, nome, empresa, email, telefone, interesse, observacoes, owner_user_id } = req.body;
    if (!codigo || !nome) {
      return res.status(400).json({ error: 'codigo e nome sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO crm_leads
       (tenant_id, lead_source_id, codigo, nome, empresa, email, telefone, interesse, observacoes, owner_user_id)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
       RETURNING *`,
      [req.user.tenantId, lead_source_id || null, codigo, nome, empresa || null, email || null, telefone || null, interesse || null, observacoes || null, owner_user_id || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { estado, empresa, email, telefone, interesse, observacoes, owner_user_id } = req.body;
    const { rows } = await db.query(
      `UPDATE crm_leads
          SET estado = COALESCE($1, estado),
              empresa = COALESCE($2, empresa),
              email = COALESCE($3, email),
              telefone = COALESCE($4, telefone),
              interesse = COALESCE($5, interesse),
              observacoes = COALESCE($6, observacoes),
              owner_user_id = COALESCE($7, owner_user_id),
              updated_at = NOW()
        WHERE id = $8 AND tenant_id = $9
      RETURNING *`,
      [estado ?? null, empresa ?? null, email ?? null, telefone ?? null, interesse ?? null, observacoes ?? null, owner_user_id ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Lead nao encontrado' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, obter, criar, atualizar };
