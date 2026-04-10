'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3005;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[clientes-service] Database conectada');
    app.listen(PORT, () => {
      console.log(`[clientes-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[clientes-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();
