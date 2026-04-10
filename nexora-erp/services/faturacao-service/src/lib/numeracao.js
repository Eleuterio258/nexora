'use strict';

/**
 * Gera o próximo número de documento de forma atómica.
 * Usa SELECT ... FOR UPDATE para garantir unicidade em ambiente multi-utilizador (RF01 / RNF01).
 *
 * Formato: {prefixo}/{sequencia padded com zeros}
 * Ex: FT2026/000001
 *
 * @param {object} client  — pg client dentro de uma transacção
 * @param {number} tenantId
 * @param {string} tipo    — 'ORC' | 'ENC' | 'GR' | 'FT' | 'NC' | 'RB'
 * @returns {{ numero: string, serie_id: number }}
 */
async function proximoNumero(client, tenantId, tipo) {
  const ano = new Date().getFullYear();

  // Lock da série para este tenant+tipo+ano
  const { rows } = await client.query(
    `SELECT id, prefixo, sequencia
       FROM invoice_series
      WHERE tenant_id = $1 AND tipo = $2 AND ano = $3 AND ativo = TRUE
      FOR UPDATE`,
    [tenantId, tipo, ano]
  );

  if (!rows.length) {
    throw Object.assign(
      new Error(`Série ${tipo}/${ano} não configurada para este tenant. Crie a série em /api/faturacao/series.`),
      { status: 422 }
    );
  }

  const serie = rows[0];
  const novaSeq = serie.sequencia + 1;

  await client.query(
    `UPDATE invoice_series SET sequencia = $1 WHERE id = $2`,
    [novaSeq, serie.id]
  );

  const numero = `${serie.prefixo}${String(novaSeq).padStart(6, '0')}`;

  return { numero, serie_id: serie.id };
}

module.exports = { proximoNumero };
