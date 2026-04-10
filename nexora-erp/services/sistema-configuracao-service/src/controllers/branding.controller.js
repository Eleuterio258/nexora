'use strict';

const db = require('../config/db');

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM tenant_branding WHERE tenant_id = $1`,
      [req.user.tenantId]
    );
    res.json(rows[0] || null);
  } catch (err) {
    next(err);
  }
}

async function upsert(req, res, next) {
  try {
    const {
      logo_url, cor_primaria, cor_secundaria, slogan, website_url, suporte_email, suporte_telefone
    } = req.body;

    const { rows } = await db.query(
      `INSERT INTO tenant_branding
       (tenant_id, logo_url, cor_primaria, cor_secundaria, slogan, website_url, suporte_email, suporte_telefone, updated_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       ON CONFLICT (tenant_id)
       DO UPDATE SET
         logo_url = EXCLUDED.logo_url,
         cor_primaria = EXCLUDED.cor_primaria,
         cor_secundaria = EXCLUDED.cor_secundaria,
         slogan = EXCLUDED.slogan,
         website_url = EXCLUDED.website_url,
         suporte_email = EXCLUDED.suporte_email,
         suporte_telefone = EXCLUDED.suporte_telefone,
         updated_by = EXCLUDED.updated_by,
         updated_at = NOW()
       RETURNING *`,
      [req.user.tenantId, logo_url || null, cor_primaria || null, cor_secundaria || null, slogan || null, website_url || null, suporte_email || null, suporte_telefone || null, req.user.id]
    );

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { obter, upsert };
