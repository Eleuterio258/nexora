'use strict';

const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3022;

let server;

async function start() {
  try {
    await db.query('SELECT 1');
    console.log('[notifications-service] Database conectada');

    server = app.listen(PORT, () => {
      console.log(`[notifications-service] A correr na porta ${PORT}`);
    });
  } catch (err) {
    console.error('[notifications-service] Falha ao iniciar:', err.message);
    process.exit(1);
  }
}

start();

// Graceful shutdown
function shutdown(signal) {
  console.log(`[notifications-service] ${signal} recebido. A encerrar...`);
  if (server) {
    server.close(() => {
      console.log('[notifications-service] Servidor HTTP encerrado');
      db.end()
        .then(() => {
          console.log('[notifications-service] Conexoes a base de dados encerradas');
          process.exit(0);
        })
        .catch((err) => {
          console.error('[notifications-service] Erro ao encerrar conexoes:', err.message);
          process.exit(1);
        });
    });
  } else {
    process.exit(0);
  }
  
  // Forcar encerramento apos 10 segundos
  setTimeout(() => {
    console.error('[notifications-service] Encerramento forcado apos timeout');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
