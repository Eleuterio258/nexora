'use strict';

/**
 * RabbitMQ Wrapper para Nexora ERP
 * 
 * Este módulo fornece uma interface simples para publicar e consumir mensagens.
 * Atualmente NÃO utilizado pelos serviços, mas disponível para uso futuro.
 * 
 * Para ativar: npm install amqplib
 */

let channel = null;
let connection = null;

async function connect(rabbitmqUrl) {
  if (channel) return channel;

  const amqp = require('amqplib');

  try {
    connection = await amqp.connect(rabbitmqUrl);
    channel = await connection.createChannel();
    console.log('[rabbitmq] Conectado ao RabbitMQ');

    connection.on('error', (err) => {
      console.error('[rabbitmq] Erro de conexão:', err.message);
      channel = null;
    });

    connection.on('close', () => {
      console.warn('[rabbitmq] Conexão fechada');
      channel = null;
    });

    return channel;
  } catch (err) {
    console.warn('[rabbitmq] Falha ao conectar (a funcionar sem message broker):', err.message);
    return null;
  }
}

async function publish(queue, message, options = {}) {
  if (!channel) {
    console.warn(`[rabbitmq] Não conectado. Mensagem não publicada: ${queue}`);
    return false;
  }

  try {
    await channel.assertQueue(queue, { durable: true });
    channel.sendToQueue(queue, Buffer.from(JSON.stringify(message)), {
      persistent: true,
      ...options,
    });
    console.log(`[rabbitmq] Mensagem publicada em ${queue}`);
    return true;
  } catch (err) {
    console.error(`[rabbitmq] Erro ao publicar em ${queue}:`, err.message);
    return false;
  }
}

async function consume(queue, handler) {
  if (!channel) {
    console.warn(`[rabbitmq] Não conectado. Consumidor não registado: ${queue}`);
    return;
  }

  try {
    await channel.assertQueue(queue, { durable: true });
    channel.consume(queue, (msg) => {
      if (msg) {
        try {
          const content = JSON.parse(msg.content.toString());
          handler(content);
          channel.ack(msg);
        } catch (err) {
          console.error(`[rabbitmq] Erro ao processar mensagem de ${queue}:`, err.message);
          channel.nack(msg, false, true); // Rejeita e não requeue
        }
      }
    });
    console.log(`[rabbitmq] Consumidor registado em ${queue}`);
  } catch (err) {
    console.error(`[rabbitmq] Erro ao consumir ${queue}:`, err.message);
  }
}

async function close() {
  if (channel) {
    await channel.close();
    channel = null;
  }
  if (connection) {
    await connection.close();
    connection = null;
  }
  console.log('[rabbitmq] Conexão encerrada');
}

module.exports = {
  connect,
  publish,
  consume,
  close,
};
