'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3012;

let server;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[contabilidade-service] Database conectada');

    server = app.listen(PORT, () => {
      console.log(`[contabilidade-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[contabilidade-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();

// Graceful shutdown
function shutdown(signal) {
  console.log(`[contabilidade-service] ${signal} recebido. A encerrar...`);
  if (server) {
    server.close(() => {
      console.log('[contabilidade-service] Servidor HTTP encerrado');
      db.end()
        .then(() => {
          console.log('[contabilidade-service] Conexões à base de dados encerradas');
          process.exit(0);
        })
        .catch((err) => {
          console.error('[contabilidade-service] Erro ao encerrar conexões:', err.message);
          process.exit(1);
        });
    });
  } else {
    process.exit(0);
  }
  
  // Forçar encerramento após 10 segundos
  setTimeout(() => {
    console.error('[contabilidade-service] Encerramento forçado após timeout');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
