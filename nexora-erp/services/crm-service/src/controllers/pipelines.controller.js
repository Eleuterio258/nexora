'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM crm_pipelines WHERE tenant_id = $1 ORDER BY nome ASC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const { codigo, nome } = req.body;
    if (!codigo || !nome) {
      return res.status(400).json({ error: 'codigo e nome sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO crm_pipelines (tenant_id, codigo, nome)
       VALUES ($1,$2,$3)
       RETURNING *`,
      [req.user.tenantId, codigo, nome]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function listarStages(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT s.*
         FROM crm_pipeline_stages s
         JOIN crm_pipelines p ON p.id = s.pipeline_id
        WHERE s.pipeline_id = $1 AND p.tenant_id = $2
        ORDER BY s.ordem ASC`,
      [req.params.id, req.user.tenantId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function criarStage(req, res, next) {
  try {
    const { codigo, nome, ordem, probabilidade, ganho, perdido } = req.body;
    if (!codigo || !nome || ordem === undefined) {
      return res.status(400).json({ error: 'codigo, nome e ordem sao obrigatorios' });
    }

    const { rows: pipelines } = await db.query(
      `SELECT id FROM crm_pipelines WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!pipelines.length) {
      return res.status(404).json({ error: 'Pipeline nao encontrado' });
    }

    const { rows } = await db.query(
      `INSERT INTO crm_pipeline_stages (pipeline_id, codigo, nome, ordem, probabilidade, ganho, perdido)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       RETURNING *`,
      [req.params.id, codigo, nome, ordem, probabilidade ?? 0, !!ganho, !!perdido]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, criar, listarStages, criarStage };
