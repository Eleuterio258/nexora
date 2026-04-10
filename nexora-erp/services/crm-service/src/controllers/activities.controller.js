'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { lead_id, opportunity_id, status } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];

    if (lead_id) {
      params.push(lead_id);
      conditions.push(`lead_id = $${params.length}`);
    }
    if (opportunity_id) {
      params.push(opportunity_id);
      conditions.push(`opportunity_id = $${params.length}`);
    }
    if (status) {
      params.push(status);
      conditions.push(`status = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT * FROM crm_activities WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { lead_id, opportunity_id, tipo, assunto, descricao, agendado_para, owner_user_id } = req.body;
    if (!tipo || !assunto) {
      return res.status(400).json({ error: 'tipo e assunto sao obrigatorios' });
    }
    if (!lead_id && !opportunity_id) {
      return res.status(400).json({ error: 'lead_id ou opportunity_id e obrigatorio' });
    }

    const { rows } = await db.query(
      `INSERT INTO crm_activities
       (tenant_id, lead_id, opportunity_id, tipo, assunto, descricao, agendado_para, owner_user_id, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       RETURNING *`,
      [req.user.tenantId, lead_id || null, opportunity_id || null, tipo, assunto, descricao || null, agendado_para || null, owner_user_id || null, req.user.id]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar };
