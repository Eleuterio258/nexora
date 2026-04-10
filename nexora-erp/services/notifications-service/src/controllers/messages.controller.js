'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { status, canal_tipo } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];
    if (status) {
      params.push(status);
      conditions.push(`status = $${params.length}`);
    }
    if (canal_tipo) {
      params.push(canal_tipo);
      conditions.push(`canal_tipo = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT * FROM notification_messages WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const {
      channel_id, template_id, canal_tipo, destinatario, assunto, corpo, payload,
      referencia_tipo, referencia_id
    } = req.body;

    if (!canal_tipo || !destinatario || !corpo) {
      return res.status(400).json({ error: 'canal_tipo, destinatario e corpo sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO notification_messages
       (tenant_id, channel_id, template_id, canal_tipo, destinatario, assunto, corpo, payload, referencia_tipo, referencia_id, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
       RETURNING *`,
      [req.user.tenantId, channel_id || null, template_id || null, canal_tipo, destinatario, assunto || null, corpo, payload || null, referencia_tipo || null, referencia_id || null, req.user.id]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function enviar(req, res, next) {
  try {
    const { sucesso = true, erro } = req.body;
    const { rows } = await db.query(
      `UPDATE notification_messages
          SET status = CASE WHEN $1 THEN 'enviado' ELSE 'falha' END,
              tentativas = tentativas + 1,
              erro = $2,
              enviado_em = CASE WHEN $1 THEN NOW() ELSE enviado_em END
        WHERE id = $3 AND tenant_id = $4 AND status IN ('pendente','falha')
      RETURNING *`,
      [!!sucesso, erro || null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Mensagem nao encontrada ou nao pode ser enviada' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, enviar };
