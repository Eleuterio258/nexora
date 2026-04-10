'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3022;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[notifications-service] Database conectada');

    app.listen(PORT, () => {
      console.log(`[notifications-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[notifications-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();
