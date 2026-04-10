'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3015;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[sistema-configuracao-service] Database conectada');

    app.listen(PORT, () => {
      console.log(`[sistema-configuracao-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[sistema-configuracao-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();
