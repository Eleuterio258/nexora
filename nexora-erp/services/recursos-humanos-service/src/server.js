'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3013;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[recursos-humanos-service] Database conectada');

    app.listen(PORT, () => {
      console.log(`[recursos-humanos-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[recursos-humanos-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();
