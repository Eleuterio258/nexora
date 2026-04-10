'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3007;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[impostos-service] Database conectada');
    app.listen(PORT, () => {
      console.log(`[impostos-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[impostos-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();
