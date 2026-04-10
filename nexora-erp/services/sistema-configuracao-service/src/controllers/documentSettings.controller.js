'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { modulo } = req.query;
    const params = [req.user.tenantId];
    let sql = `SELECT * FROM tenant_document_settings WHERE tenant_id = $1`;
    if (modulo) {
      params.push(modulo);
      sql += ` AND modulo = $2`;
    }
    sql += ` ORDER BY modulo ASC, tipo_documento ASC`;

    const { rows } = await db.query(sql, params);
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function upsert(req, res, next) {
  try {
    const { modulo, tipo_documento, prefixo, reinicia_anualmente, serie_activa, layout_template } = req.body;
    if (!modulo || !tipo_documento) {
      return res.status(400).json({ error: 'modulo e tipo_documento sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO tenant_document_settings
       (tenant_id, modulo, tipo_documento, prefixo, reinicia_anualmente, serie_activa, layout_template, updated_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       ON CONFLICT (tenant_id, modulo, tipo_documento)
       DO UPDATE SET
         prefixo = EXCLUDED.prefixo,
         reinicia_anualmente = EXCLUDED.reinicia_anualmente,
         serie_activa = EXCLUDED.serie_activa,
         layout_template = EXCLUDED.layout_template,
         updated_by = EXCLUDED.updated_by,
         updated_at = NOW()
       RETURNING *`,
      [req.user.tenantId, modulo, tipo_documento, prefixo || null, reinicia_anualmente ?? true, serie_activa || null, layout_template || null, req.user.id]
    );

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, upsert };
