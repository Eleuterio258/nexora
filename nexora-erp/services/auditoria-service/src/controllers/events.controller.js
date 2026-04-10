'use strict';

const db = require('../config/db');
const { makeHash } = require('../lib/hash');

async function listar(req, res, next) {
  try {
    const { service_name, module_name, action, entity_type, status, page = 1, limit = 50 } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['tenant_id = $1'];

    if (service_name) {
      params.push(service_name);
      conditions.push(`service_name = $${params.length}`);
    }
    if (module_name) {
      params.push(module_name);
      conditions.push(`module_name = $${params.length}`);
    }
    if (action) {
      params.push(action);
      conditions.push(`action = $${params.length}`);
    }
    if (entity_type) {
      params.push(entity_type);
      conditions.push(`entity_type = $${params.length}`);
    }
    if (status) {
      params.push(status);
      conditions.push(`status = $${params.length}`);
    }

    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);

    const { rows } = await db.query(
      `SELECT id, actor_user_id, actor_email, actor_nome, service_name, module_name, action, entity_type, entity_id, status, ip_address, created_at
         FROM audit_events
        WHERE ${conditions.join(' AND ')}
        ORDER BY created_at DESC, id DESC
        LIMIT $${params.length - 1} OFFSET $${params.length}`,
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
      `SELECT * FROM audit_events WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Evento de auditoria nao encontrado' });
    }

    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const {
      service_name, module_name, action, entity_type, entity_id, status, actor_email, actor_nome,
      metadata, payload_before, payload_after
    } = req.body;

    if (!service_name || !module_name || !action || !entity_type) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'service_name, module_name, action e entity_type sao obrigatorios' });
    }

    const { rows: lastRows } = await client.query(
      `SELECT event_hash FROM audit_events WHERE tenant_id = $1 ORDER BY id DESC LIMIT 1`,
      [req.user.tenantId]
    );
    const previousHash = lastRows[0]?.event_hash || null;

    const payload = JSON.stringify({
      tenant_id: req.user.tenantId,
      actor_user_id: req.user.id,
      actor_email: actor_email || null,
      actor_nome: actor_nome || null,
      service_name,
      module_name,
      action,
      entity_type,
      entity_id: entity_id || null,
      status: status || 'sucesso',
      ip_address: req.ip,
      user_agent: req.headers['user-agent'] || null,
      metadata: metadata || null,
      payload_before: payload_before || null,
      payload_after: payload_after || null,
      previous_hash: previousHash
    });
    const eventHash = makeHash(payload);

    const { rows } = await client.query(
      `INSERT INTO audit_events
       (tenant_id, actor_user_id, actor_email, actor_nome, service_name, module_name, action, entity_type, entity_id, status, ip_address, user_agent, metadata, payload_before, payload_after, previous_hash, event_hash)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)
       RETURNING *`,
      [
        req.user.tenantId,
        req.user.id,
        actor_email || null,
        actor_nome || null,
        service_name,
        module_name,
        action,
        entity_type,
        entity_id || null,
        status || 'sucesso',
        req.ip,
        req.headers['user-agent'] || null,
        metadata || null,
        payload_before || null,
        payload_after || null,
        previousHash,
        eventHash
      ]
    );

    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
}

module.exports = { listar, obter, criar };
