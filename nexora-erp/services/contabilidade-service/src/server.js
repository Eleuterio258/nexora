'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3012;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[contabilidade-service] Database conectada');

    app.listen(PORT, () => {
      console.log(`[contabilidade-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[contabilidade-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();
