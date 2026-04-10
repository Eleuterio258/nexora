'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { estado, pipeline_id, stage_id } = req.query;
    const params = [req.user.tenantId];
    const conditions = ['o.tenant_id = $1'];

    if (estado) {
      params.push(estado);
      conditions.push(`o.estado = $${params.length}`);
    }
    if (pipeline_id) {
      params.push(pipeline_id);
      conditions.push(`o.pipeline_id = $${params.length}`);
    }
    if (stage_id) {
      params.push(stage_id);
      conditions.push(`o.stage_id = $${params.length}`);
    }

    const { rows } = await db.query(
      `SELECT o.*, s.nome AS stage_nome, p.nome AS pipeline_nome
         FROM crm_opportunities o
         JOIN crm_pipeline_stages s ON s.id = o.stage_id
         JOIN crm_pipelines p ON p.id = o.pipeline_id
        WHERE ${conditions.join(' AND ')}
        ORDER BY o.created_at DESC`,
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
      `SELECT * FROM crm_opportunities WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Oportunidade nao encontrada' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function criar(req, res, next) {
  try {
    const {
      pipeline_id, stage_id, lead_id, customer_id, codigo, nome, valor_estimado,
      moeda, probabilidade, expected_close_date, owner_user_id, observacoes
    } = req.body;
    if (!pipeline_id || !stage_id || !codigo || !nome) {
      return res.status(400).json({ error: 'pipeline_id, stage_id, codigo e nome sao obrigatorios' });
    }

    const { rows } = await db.query(
      `INSERT INTO crm_opportunities
       (tenant_id, pipeline_id, stage_id, lead_id, customer_id, codigo, nome, valor_estimado, moeda, probabilidade, expected_close_date, owner_user_id, observacoes)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
       RETURNING *`,
      [req.user.tenantId, pipeline_id, stage_id, lead_id || null, customer_id || null, codigo, nome, valor_estimado || 0, moeda || 'MZN', probabilidade ?? 0, expected_close_date || null, owner_user_id || null, observacoes || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function atualizar(req, res, next) {
  try {
    const { nome, valor_estimado, moeda, probabilidade, expected_close_date, estado, owner_user_id, observacoes } = req.body;
    const { rows } = await db.query(
      `UPDATE crm_opportunities
          SET nome = COALESCE($1, nome),
              valor_estimado = COALESCE($2, valor_estimado),
              moeda = COALESCE($3, moeda),
              probabilidade = COALESCE($4, probabilidade),
              expected_close_date = COALESCE($5, expected_close_date),
              estado = COALESCE($6, estado),
              owner_user_id = COALESCE($7, owner_user_id),
              observacoes = COALESCE($8, observacoes),
              updated_at = NOW()
        WHERE id = $9 AND tenant_id = $10
      RETURNING *`,
      [nome ?? null, valor_estimado ?? null, moeda ?? null, probabilidade ?? null, expected_close_date ?? null, estado ?? null, owner_user_id ?? null, observacoes ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Oportunidade nao encontrada' });
    }
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

async function moverStage(req, res, next) {
  try {
    const { stage_id } = req.body;
    if (!stage_id) {
      return res.status(400).json({ error: 'stage_id e obrigatorio' });
    }

    const { rows: stages } = await db.query(
      `SELECT s.id, s.probabilidade, s.ganho, s.perdido
         FROM crm_pipeline_stages s
         JOIN crm_opportunities o ON o.pipeline_id = s.pipeline_id
        WHERE o.id = $1 AND o.tenant_id = $2 AND s.id = $3`,
      [req.params.id, req.user.tenantId, stage_id]
    );
    if (!stages.length) {
      return res.status(404).json({ error: 'Stage nao encontrado para a oportunidade' });
    }

    const nextEstado = stages[0].ganho ? 'ganha' : stages[0].perdido ? 'perdida' : 'aberta';
    const { rows } = await db.query(
      `UPDATE crm_opportunities
          SET stage_id = $1,
              probabilidade = $2,
              estado = $3,
              updated_at = NOW()
        WHERE id = $4 AND tenant_id = $5
      RETURNING *`,
      [stage_id, stages[0].probabilidade, nextEstado, req.params.id, req.user.tenantId]
    );
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
}

module.exports = { listar, obter, criar, atualizar, moverStage };
