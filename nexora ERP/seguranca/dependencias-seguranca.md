# Dependencias do Modulo de Seguranca

## Papel no ERP

O modulo de seguranca e transversal a todos os outros modulos.

## Dependencias funcionais

- todos os modulos dependem de `users`, `roles`, `permissions` e `audit_logs`
- `audit_logs` recebe eventos de faturacao, compras, stock, tesouraria, contabilidade e rh
- `api_keys` pode ser usado por integracoes externas com qualquer modulo
- `sessions` e `login_history` suportam autenticacao global do sistema

## Regra recomendada

- `seguranca` deve ser um modulo core
- nenhum modulo funcional deve recriar `users` ou `roles`
- cada modulo apenas referencia `user_id` nas suas operacoes
