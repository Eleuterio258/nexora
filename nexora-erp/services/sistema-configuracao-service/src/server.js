'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3015;

let server;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[sistema-configuracao-service] Database conectada');

    server = app.listen(PORT, () => {
      console.log(`[sistema-configuracao-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[sistema-configuracao-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();

// Graceful shutdown
function shutdown(signal) {
  console.log(`[sistema-configuracao-service] ${signal} recebido. A encerrar...`);
  if (server) {
    server.close(() => {
      console.log('[sistema-configuracao-service] Servidor HTTP encerrado');
      db.end()
        .then(() => {
          console.log('[sistema-configuracao-service] Conexoes a base de dados encerradas');
          process.exit(0);
        })
        .catch((err) => {
          console.error('[sistema-configuracao-service] Erro ao encerrar conexoes:', err.message);
          process.exit(1);
        });
    });
  } else {
    process.exit(0);
  }
  
  // Forcar encerramento apos 10 segundos
  setTimeout(() => {
    console.error('[sistema-configuracao-service] Encerramento forcado apos timeout');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
