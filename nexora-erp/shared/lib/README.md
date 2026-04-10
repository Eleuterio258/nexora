# Shared Libraries

Este diretório contém bibliotecas partilhadas entre todos os microsserviços.

## Bibliotecas Disponíveis

### rabbitmq.js
Wrapper para o RabbitMQ. Para utilizar:

1. Instale o amqplib no serviço desejado:
   ```bash
   npm install amqplib
   ```

2. Importe e utilize:
   ```javascript
   const rabbitmq = require('../../shared/lib/rabbitmq');
   
   // Conectar
   await rabbitmq.connect(process.env.RABBITMQ_URL);
   
   // Publicar mensagem
   await rabbitmq.publish('nome-da-fila', { dados: 'mensagem' });
   
   // Consumir mensagens
   await rabbitmq.consume('nome-da-fila', (msg) => {
     console.log('Mensagem recebida:', msg);
   });
   ```

### Exemplos de Uso

#### Publicar evento após criação de utilizador
```javascript
// auth-service/src/controllers/auth.controller.js
const rabbitmq = require('../../shared/lib/rabbitmq');

await rabbitmq.publish('user-events', {
  event: 'user.created',
  userId: newUser.id,
  email: newUser.email,
  timestamp: new Date().toISOString(),
});
```

#### Enviar email via fila
```javascript
// Qualquer serviço
const rabbitmq = require('../../shared/lib/rabbitmq');

await rabbitmq.publish('notifications', {
  type: 'email',
  to: 'user@example.com',
  subject: 'Bem-vindo!',
  template: 'welcome',
  data: { name: 'Utilizador' },
});
```
