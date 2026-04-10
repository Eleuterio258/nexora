'use strict';

const db = require('../config/db');

// ── helpers ───────────────────────────────────────────────────────────────────

async function assertCustomer(tenantId, customerId) {
  const { rows } = await db.query(
    `SELECT id FROM customers WHERE id = $1 AND tenant_id = $2`,
    [customerId, tenantId]
  );
  return rows[0] || null;
}

// ── Customers ─────────────────────────────────────────────────────────────────

async function listar(req, res, next) {
  try {
    const { estado, customer_group_id, search, page = 1, limit = 20 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];

    if (estado)            { params.push(estado);            cond.push(`estado = $${params.length}`); }
    if (customer_group_id) { params.push(customer_group_id); cond.push(`customer_group_id = $${params.length}`); }
    if (search)            { params.push(`%${search}%`);     cond.push(`(nome ILIKE $${params.length} OR nuit ILIKE $${params.length})`); }

    params.push(Number(limit), offset);
    const { rows } = await db.query(
      `SELECT id, codigo, nome, nuit, telefone, email, estado, customer_group_id, created_at
         FROM customers
        WHERE ${cond.join(' AND ')}
        ORDER BY nome ASC
        LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { nome, nuit, telefone, email, customer_group_id, codigo, observacao } = req.body;
    if (!nome) return res.status(400).json({ error: 'nome é obrigatório' });

    const { rows } = await db.query(
      `INSERT INTO customers (tenant_id, nome, nuit, telefone, email, customer_group_id, codigo, observacao)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [req.user.tenantId, nome, nuit || null, telefone || null, email || null,
       customer_group_id || null, codigo || null, observacao || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const [custRes, contactsRes, addressesRes, creditRes] = await Promise.all([
      db.query(`SELECT * FROM customers WHERE id = $1 AND tenant_id = $2`, [req.params.id, req.user.tenantId]),
      db.query(`SELECT * FROM customer_contacts WHERE customer_id = $1 ORDER BY principal DESC, id`, [req.params.id]),
      db.query(`SELECT * FROM customer_addresses WHERE customer_id = $1 ORDER BY principal DESC, id`, [req.params.id]),
      db.query(`SELECT * FROM customer_credit_limits WHERE customer_id = $1`, [req.params.id]),
    ]);
    if (!custRes.rows.length) return res.status(404).json({ error: 'Cliente não encontrado' });
    res.json({
      ...custRes.rows[0],
      contacts:     contactsRes.rows,
      addresses:    addressesRes.rows,
      credit_limit: creditRes.rows[0] || null,
    });
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { nome, nuit, telefone, email, customer_group_id, codigo, observacao } = req.body;
    const { rows } = await db.query(
      `UPDATE customers
          SET nome              = COALESCE($1, nome),
              nuit              = COALESCE($2, nuit),
              telefone          = COALESCE($3, telefone),
              email             = COALESCE($4, email),
              customer_group_id = COALESCE($5, customer_group_id),
              codigo            = COALESCE($6, codigo),
              observacao        = COALESCE($7, observacao),
              updated_at        = NOW()
        WHERE id = $8 AND tenant_id = $9
        RETURNING *`,
      [nome || null, nuit || null, telefone || null, email || null,
       customer_group_id || null, codigo || null, observacao || null,
       req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Cliente não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function activar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE customers SET estado = 'ativo', updated_at = NOW()
        WHERE id = $1 AND tenant_id = $2 RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Cliente não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function bloquear(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE customers SET estado = 'bloqueado', updated_at = NOW()
        WHERE id = $1 AND tenant_id = $2 RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Cliente não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function desactivar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE customers SET estado = 'inativo', updated_at = NOW()
        WHERE id = $1 AND tenant_id = $2 RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Cliente não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

// ── Contacts ──────────────────────────────────────────────────────────────────

async function listarContacts(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { rows } = await db.query(
      `SELECT * FROM customer_contacts WHERE customer_id = $1 ORDER BY principal DESC, id`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criarContact(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { nome, cargo, telefone, email, principal } = req.body;
    if (!nome) return res.status(400).json({ error: 'nome é obrigatório' });

    const { rows } = await db.query(
      `INSERT INTO customer_contacts (customer_id, nome, cargo, telefone, email, principal)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [req.params.id, nome, cargo || null, telefone || null, email || null, principal || false]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizarContact(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { nome, cargo, telefone, email, principal } = req.body;
    const { rows } = await db.query(
      `UPDATE customer_contacts
          SET nome      = COALESCE($1, nome),
              cargo     = COALESCE($2, cargo),
              telefone  = COALESCE($3, telefone),
              email     = COALESCE($4, email),
              principal = COALESCE($5, principal)
        WHERE id = $6 AND customer_id = $7
        RETURNING *`,
      [nome || null, cargo || null, telefone || null, email || null,
       principal ?? null, req.params.cid, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Contacto não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function eliminarContact(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { rowCount } = await db.query(
      `DELETE FROM customer_contacts WHERE id = $1 AND customer_id = $2`,
      [req.params.cid, req.params.id]
    );
    if (!rowCount) return res.status(404).json({ error: 'Contacto não encontrado' });
    res.status(204).send();
  } catch (err) { next(err); }
}

// ── Addresses ─────────────────────────────────────────────────────────────────

async function listarAddresses(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { rows } = await db.query(
      `SELECT * FROM customer_addresses WHERE customer_id = $1 ORDER BY principal DESC, id`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criarAddress(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { tipo, endereco, cidade, provincia, pais, codigo_postal, principal } = req.body;
    if (!endereco) return res.status(400).json({ error: 'endereco é obrigatório' });

    const { rows } = await db.query(
      `INSERT INTO customer_addresses (customer_id, tipo, endereco, cidade, provincia, pais, codigo_postal, principal)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [req.params.id, tipo || 'principal', endereco, cidade || null, provincia || null,
       pais || 'Mocambique', codigo_postal || null, principal || false]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizarAddress(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { tipo, endereco, cidade, provincia, pais, codigo_postal, principal } = req.body;
    const { rows } = await db.query(
      `UPDATE customer_addresses
          SET tipo          = COALESCE($1, tipo),
              endereco      = COALESCE($2, endereco),
              cidade        = COALESCE($3, cidade),
              provincia     = COALESCE($4, provincia),
              pais          = COALESCE($5, pais),
              codigo_postal = COALESCE($6, codigo_postal),
              principal     = COALESCE($7, principal)
        WHERE id = $8 AND customer_id = $9
        RETURNING *`,
      [tipo || null, endereco || null, cidade || null, provincia || null,
       pais || null, codigo_postal || null, principal ?? null,
       req.params.aid, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Morada não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function eliminarAddress(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { rowCount } = await db.query(
      `DELETE FROM customer_addresses WHERE id = $1 AND customer_id = $2`,
      [req.params.aid, req.params.id]
    );
    if (!rowCount) return res.status(404).json({ error: 'Morada não encontrada' });
    res.status(204).send();
  } catch (err) { next(err); }
}

// ── Documents ─────────────────────────────────────────────────────────────────

async function listarDocuments(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { rows } = await db.query(
      `SELECT * FROM customer_documents WHERE customer_id = $1 ORDER BY created_at DESC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criarDocument(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { tipo, numero, ficheiro_url, emitido_em, expira_em } = req.body;
    if (!tipo) return res.status(400).json({ error: 'tipo é obrigatório' });

    const { rows } = await db.query(
      `INSERT INTO customer_documents (customer_id, tipo, numero, ficheiro_url, emitido_em, expira_em)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [req.params.id, tipo, numero || null, ficheiro_url || null, emitido_em || null, expira_em || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

// ── Credit Limit ──────────────────────────────────────────────────────────────

async function obterCreditLimit(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { rows } = await db.query(
      `SELECT * FROM customer_credit_limits WHERE customer_id = $1`,
      [req.params.id]
    );
    res.json(rows[0] || null);
  } catch (err) { next(err); }
}

async function upsertCreditLimit(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { limite_credito, moeda, inicio_em, fim_em, ativo } = req.body;
    if (limite_credito === undefined) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'limite_credito é obrigatório' });
    }

    const { rows } = await client.query(
      `INSERT INTO customer_credit_limits (customer_id, limite_credito, moeda, inicio_em, fim_em, ativo)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (customer_id) DO UPDATE
          SET limite_credito = EXCLUDED.limite_credito,
              moeda          = COALESCE(EXCLUDED.moeda, customer_credit_limits.moeda),
              inicio_em      = COALESCE(EXCLUDED.inicio_em, customer_credit_limits.inicio_em),
              fim_em         = COALESCE(EXCLUDED.fim_em, customer_credit_limits.fim_em),
              ativo          = COALESCE(EXCLUDED.ativo, customer_credit_limits.ativo),
              updated_at     = NOW()
       RETURNING *`,
      [req.params.id, limite_credito, moeda || 'MZN', inicio_em || null, fim_em || null, ativo ?? true]
    );
    await client.query('COMMIT');
    res.status(200).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

// ── Notes ─────────────────────────────────────────────────────────────────────

async function listarNotes(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { rows } = await db.query(
      `SELECT * FROM customer_notes WHERE customer_id = $1 ORDER BY created_at DESC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criarNote(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { nota } = req.body;
    if (!nota) return res.status(400).json({ error: 'nota é obrigatória' });

    const { rows } = await db.query(
      `INSERT INTO customer_notes (customer_id, nota, created_by)
       VALUES ($1, $2, $3) RETURNING *`,
      [req.params.id, nota, req.user.id]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

// ── Discounts ─────────────────────────────────────────────────────────────────

async function listarDiscounts(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { rows } = await db.query(
      `SELECT * FROM customer_discounts
        WHERE customer_id = $1 AND ativo = TRUE
        ORDER BY created_at DESC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criarDiscount(req, res, next) {
  try {
    if (!await assertCustomer(req.user.tenantId, req.params.id)) {
      return res.status(404).json({ error: 'Cliente não encontrado' });
    }
    const { tipo, valor, motivo, ativo, inicio_em, fim_em } = req.body;
    if (!tipo || valor === undefined) return res.status(400).json({ error: 'tipo e valor são obrigatórios' });

    const { rows } = await db.query(
      `INSERT INTO customer_discounts (customer_id, tipo, valor, motivo, ativo, inicio_em, fim_em)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [req.params.id, tipo, valor, motivo || null, ativo ?? true, inicio_em || null, fim_em || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

module.exports = {
  listar, criar, obter, actualizar,
  activar, bloquear, desactivar,
  listarContacts, criarContact, actualizarContact, eliminarContact,
  listarAddresses, criarAddress, actualizarAddress, eliminarAddress,
  listarDocuments, criarDocument,
  obterCreditLimit, upsertCreditLimit,
  listarNotes, criarNote,
  listarDiscounts, criarDiscount,
};
