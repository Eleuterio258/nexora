'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3017;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[crm-service] Database conectada');

    app.listen(PORT, () => {
      console.log(`[crm-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[crm-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();
