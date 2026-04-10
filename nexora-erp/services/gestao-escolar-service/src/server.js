'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3024;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[gestao-escolar-service] Database conectada');

    app.listen(PORT, () => {
      console.log(`[gestao-escolar-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[gestao-escolar-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();
