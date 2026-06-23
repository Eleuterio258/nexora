# API de Seguranca

## Auth

### POST /api/auth/login
### POST /api/auth/logout
### POST /api/auth/refresh
### POST /api/auth/forgot-password
### POST /api/auth/reset-password

## Users

### POST /api/users
### GET /api/users
### GET /api/users/{id}
### PUT /api/users/{id}
### POST /api/users/{id}/bloquear
### POST /api/users/{id}/ativar

## Roles

### POST /api/roles
### GET /api/roles
### PUT /api/roles/{id}

## Permissions

### POST /api/permissions
### GET /api/permissions

## Role Permissions

### POST /api/roles/{id}/permissions
### GET /api/roles/{id}/permissions

## User Roles

### POST /api/users/{id}/roles
### GET /api/users/{id}/roles

## Sessions

### GET /api/sessions
### POST /api/sessions/{id}/revogar

## Login History

### GET /api/login-history

## API Keys

### POST /api/api-keys
### GET /api/api-keys
### POST /api/api-keys/{id}/revogar

## Audit Logs

### GET /api/audit-logs
