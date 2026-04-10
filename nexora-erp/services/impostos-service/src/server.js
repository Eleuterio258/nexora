'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3007;

let server;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[impostos-service] Database conectada');
    server = app.listen(PORT, () => {
      console.log(`[impostos-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[impostos-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();

// Graceful shutdown
function shutdown(signal) {
  console.log(`[impostos-service] ${signal} recebido. A encerrar...`);
  if (server) {
    server.close(() => {
      console.log('[impostos-service] Servidor HTTP encerrado');
      db.end()
        .then(() => {
          console.log('[impostos-service] Conexões à base de dados encerradas');
          process.exit(0);
        })
        .catch((err) => {
          console.error('[impostos-service] Erro ao encerrar conexões:', err.message);
          process.exit(1);
        });
    });
  } else {
    process.exit(0);
  }
  
  // Forçar encerramento após 10 segundos
  setTimeout(() => {
    console.error('[impostos-service] Encerramento forçado após timeout');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
