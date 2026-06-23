# API de Utilizadores

## Perfis

### POST /api/utilizadores/perfis
### GET /api/utilizadores/perfis/{userId}
### PUT /api/utilizadores/perfis/{userId}

## Preferencias

### POST /api/utilizadores/{userId}/preferences
### GET /api/utilizadores/{userId}/preferences
### PUT /api/utilizadores/{userId}/preferences/{preferenceId}

## Notificacoes

### GET /api/utilizadores/{userId}/notifications
### POST /api/utilizadores/{userId}/notifications
### POST /api/utilizadores/{userId}/notifications/{notificationId}/read

## Dispositivos

### GET /api/utilizadores/{userId}/devices
### POST /api/utilizadores/{userId}/devices
### DELETE /api/utilizadores/{userId}/devices/{deviceId}

## Atividade

### GET /api/utilizadores/{userId}/activity

## Tokens

### POST /api/utilizadores/{userId}/tokens
### GET /api/utilizadores/{userId}/tokens
### POST /api/utilizadores/{userId}/tokens/{tokenId}/revogar

## Logs de seguranca

### GET /api/utilizadores/{userId}/security-logs

## Avatar

### POST /api/utilizadores/{userId}/avatar
### GET /api/utilizadores/{userId}/avatar
### DELETE /api/utilizadores/{userId}/avatar

## Settings

### POST /api/utilizadores/{userId}/settings
### GET /api/utilizadores/{userId}/settings
### PUT /api/utilizadores/{userId}/settings/{settingId}
