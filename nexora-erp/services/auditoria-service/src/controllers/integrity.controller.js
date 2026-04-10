'use strict';

const db = require('../config/db');
const { makeHash } = require('../lib/hash');

async function verificar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM audit_events WHERE tenant_id = $1 ORDER BY id ASC`,
      [req.user.tenantId]
    );

    let previousHash = null;
    for (const row of rows) {
      const payload = JSON.stringify({
        tenant_id: row.tenant_id,
        actor_user_id: row.actor_user_id,
        actor_email: row.actor_email,
        actor_nome: row.actor_nome,
        service_name: row.service_name,
        module_name: row.module_name,
        action: row.action,
        entity_type: row.entity_type,
        entity_id: row.entity_id,
        status: row.status,
        ip_address: row.ip_address,
        user_agent: row.user_agent,
        metadata: row.metadata,
        payload_before: row.payload_before,
        payload_after: row.payload_after,
        previous_hash: previousHash
      });

      const expectedHash = makeHash(payload);
      if (row.previous_hash !== previousHash || row.event_hash !== expectedHash) {
        return res.json({
          valid: false,
          broken_at_id: row.id,
          expected_previous_hash: previousHash,
          stored_previous_hash: row.previous_hash,
          expected_event_hash: expectedHash,
          stored_event_hash: row.event_hash
        });
      }

      previousHash = row.event_hash;
    }

    res.json({ valid: true, total_eventos: rows.length });
  } catch (err) {
    next(err);
  }
}

module.exports = { verificar };
