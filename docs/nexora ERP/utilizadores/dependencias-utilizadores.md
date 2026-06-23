# Dependencias do Modulo de Utilizadores

## Papel no ERP

O modulo `utilizadores` depende do modulo `seguranca`.

## Dependencias funcionais

- `profiles`, `user_preferences`, `user_notifications`, `user_devices`, `user_activity`, `user_tokens`, `user_security_logs`, `user_avatar` e `user_settings` dependem de `users`
- o modulo `seguranca` continua dono de `users`, `sessions`, `roles`, `permissions` e `audit_logs`
- os modulos funcionais podem enviar notificacoes e atividade para `utilizadores`

## Regra recomendada

- nao duplicar tabela `users` dentro de `utilizadores`
- `utilizadores` deve referenciar `user_id`
- autenticacao e autorizacao ficam em `seguranca`
- personalizacao e experiencia do utilizador ficam em `utilizadores`
