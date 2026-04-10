'use strict';

function errorHandler(err, req, res, next) {
  console.error('[recursos-humanos-service]', err);

  if (err && err.code === '23505') {
    return res.status(409).json({ error: 'Registo duplicado' });
  }

  res.status(err.status || 500).json({ error: err.message || 'Erro interno do servidor' });
}

module.exports = errorHandler;
