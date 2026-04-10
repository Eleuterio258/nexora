# Dependencias ERP

## Modulos base (core transversal)

- `empresas`
- `autenticacao`
- `autorizacao`
- `auditoria`
- `utilizadores`
- `sistema-configuracao`

## Modulos de dados mestre

- `gestao-clientes`
- `gestao-produtos`
- `gestao-stock`
- `compras`

## Modulos transacionais

- `modulo-faturacao`
- `pos`
- `logistica`
- `assinaturas`

## Modulos financeiros

- `financeiro`
- `tesouraria`
- `contabilidade`
- `centros-custo`
- `impostos`
- `multi-moeda`

## Modulos operacionais

- `recursos-humanos`
- `crm`
- `gestao-escolar`

## Modulos descontinuados

- `seguranca` - substituido por `autenticacao`, `autorizacao` e `auditoria`

---

## Dependencias funcionais

### Core

- `autorizacao` depende de `autenticacao` (user_id em user_roles)
- `auditoria` recebe eventos de todos os modulos
- `utilizadores` depende de `autenticacao` (user_id)
- `sistema-configuracao` e base de `multi-moeda` (currencies, exchange_rates)

### Dados mestre

- `gestao-stock` depende de `gestao-produtos` (product_id, warehouse)
- `compras` depende de `gestao-produtos`, `gestao-stock`, `financeiro`, `contabilidade`

### Transacionais

- `modulo-faturacao` depende de `gestao-clientes`, `gestao-produtos`, `gestao-stock`, `financeiro`, `contabilidade`
- `pos` depende de `gestao-produtos`, `gestao-stock`, `financeiro`, `tesouraria`
- `logistica` depende de `modulo-faturacao`, `gestao-stock`, `utilizadores`
- `assinaturas` depende de `gestao-clientes`; alimenta `modulo-faturacao` (ciclos faturados) e `financeiro` (recebimentos recorrentes)

### Financeiros

- `financeiro` referencia `tesouraria` (conta_bancaria_id, caixa_id); alimenta `contabilidade`
- `tesouraria` recebe movimentos de `financeiro` e `pos` (reconciliacao de caixa)
- `contabilidade` recebe lancamentos de `modulo-faturacao`, `compras`, `financeiro`, `recursos-humanos`, `pos`
- `centros-custo` depende de `contabilidade` (fiscal_period_id, journal_entry_line_id)
- `impostos` depende de `contabilidade` (taxes); e referenciado por `gestao-clientes`, `compras`, `recursos-humanos`, `modulo-faturacao`
- `multi-moeda` e consumido por `modulo-faturacao`, `compras`, `financeiro`, `contabilidade`

### Operacionais

- `crm` depende de `autenticacao`; integra com `gestao-clientes` e `modulo-faturacao`
- `recursos-humanos` depende de `financeiro` e `contabilidade`
- `gestao-escolar` depende de `autenticacao`, `autorizacao`, `utilizadores`, `auditoria`, `financeiro` e `tesouraria`

---

## Ownership

- cada modulo e dono das suas tabelas
- referencias cruzadas devem ser consolidadas no schema final
- evitar duplicacao de entidades entre modulos

---

## Mapa de dependencias (A -> B = A envia dados ou referencia B)

```text
empresas
  -> autenticacao -> autorizacao
  -> auditoria (recebe de todos)
  -> utilizadores
  -> sistema-configuracao -> multi-moeda

gestao-clientes <- crm
gestao-produtos
gestao-stock         <- gestao-produtos

modulo-faturacao     <- gestao-clientes, gestao-produtos, gestao-stock
pos                  <- gestao-produtos, gestao-stock
assinaturas          <- gestao-clientes
                     --> modulo-faturacao (ciclos faturados)
                     --> financeiro (recebimentos de assinatura)
compras              <- gestao-produtos, gestao-stock
logistica            <- modulo-faturacao, gestao-stock

tesouraria
financeiro           <- tesouraria (conta_bancaria_id, caixa_id)
                     <- modulo-faturacao, compras, pos, assinaturas
                     --> tesouraria (movimentos de caixa)
                     --> contabilidade

contabilidade        <- financeiro, modulo-faturacao, compras, pos, recursos-humanos
centros-custo        <- contabilidade
impostos             <- contabilidade, gestao-clientes, compras, recursos-humanos

recursos-humanos     --> financeiro, contabilidade
gestao-escolar       <- autenticacao, autorizacao, utilizadores
                     <- financeiro, tesouraria
                     --> auditoria
```
