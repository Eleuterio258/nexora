'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3014;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[multi-moeda-service] Database conectada');

    app.listen(PORT, () => {
      console.log(`[multi-moeda-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[multi-moeda-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();
