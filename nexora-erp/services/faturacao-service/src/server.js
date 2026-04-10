'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3003;

let server;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[faturacao-service] Database conectada');
    server = app.listen(PORT, () => {
      console.log(`[faturacao-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[faturacao-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();

// Graceful shutdown
function shutdown(signal) {
  console.log(`[faturacao-service] ${signal} recebido. A encerrar...`);
  if (server) {
    server.close(() => {
      console.log('[faturacao-service] Servidor HTTP encerrado');
      db.end()
        .then(() => {
          console.log('[faturacao-service] Conexões à base de dados encerradas');
          process.exit(0);
        })
        .catch((err) => {
          console.error('[faturacao-service] Erro ao encerrar conexões:', err.message);
          process.exit(1);
        });
    });
  } else {
    process.exit(0);
  }
  
  // Forçar encerramento após 10 segundos
  setTimeout(() => {
    console.error('[faturacao-service] Encerramento forçado após timeout');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
