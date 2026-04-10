'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3006;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[produtos-service] Database conectada');
    app.listen(PORT, () => {
      console.log(`[produtos-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[produtos-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();
