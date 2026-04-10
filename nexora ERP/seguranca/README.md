# Modulo de Seguranca (DESCONTINUADO)

Este modulo foi separado em tres modulos independentes:

| Novo modulo | Responsabilidade | Entidades |
| --- | --- | --- |
| `autenticacao/` | Contas, sessoes, login, API keys | users, sessions, login_history, password_resets, api_keys |
| `autorizacao/` | RBAC — roles e permissoes | roles, permissions, role_permissions, user_roles |
| `auditoria/` | Registo de accoes | audit_logs |

Os ficheiros deste directorio sao mantidos apenas como referencia historica.
Utilize os novos modulos para qualquer desenvolvimento.
