'use strict';

const db = require('../config/db');

async function resumoPipeline(req, res, next) {
  try {
    const { pipeline_id } = req.query;
    const params = [req.user.tenantId];
    let extra = '';
    if (pipeline_id) {
      params.push(pipeline_id);
      extra = ` AND o.pipeline_id = $2`;
    }

    const { rows } = await db.query(
      `SELECT s.nome AS stage_nome,
              COUNT(o.id) AS total_oportunidades,
              COALESCE(SUM(o.valor_estimado), 0) AS valor_total
         FROM crm_pipeline_stages s
         JOIN crm_pipelines p ON p.id = s.pipeline_id
         LEFT JOIN crm_opportunities o ON o.stage_id = s.id AND o.tenant_id = $1${extra}
        WHERE p.tenant_id = $1
        GROUP BY s.id, s.nome, s.ordem
        ORDER BY s.ordem ASC`,
      params
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

module.exports = { resumoPipeline };
