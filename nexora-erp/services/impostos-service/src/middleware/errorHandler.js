'use strict';

module.exports = function errorHandler(err, req, res, next) {
  const status = err.status || err.statusCode || 500;
  if (process.env.NODE_ENV !== 'production') console.error(`[ERROR] ${req.method} ${req.path}:`, err.message);
  res.status(status).json({ error: err.message || 'Erro interno' });
};
