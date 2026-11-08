# Análise — suporte a filiais

**Backend analisado:** `mobile/backend`  
**Data:** 6 de setembro de 2026  
**Decisão recomendada:** uma filial é uma `store` dentro do mesmo `tenant` (empresa), e não um tenant separado.

## 1. Conclusão de viabilidade

O sistema pode suportar filiais. O modelo atual já isola os dados por `tenant_id`, o que representa corretamente a empresa. Deve-se acrescentar uma entidade filha `stores` para representar cada filial, loja ou ponto de venda.

Não se deve criar um tenant por filial. Essa decisão separaria artificialmente utilizadores, catálogo, administração e relatórios de uma única empresa.

```text
Tenant / Empresa: Mercado Horizonte
├── Filial Baixa
│   ├── Caixa principal partilhado
│   └── Dispositivos A, B e C
└── Filial Matola
    ├── Caixa principal partilhado
    └── Dispositivos D e E
```

## 2. Estado atual

O backend atual trabalha no escopo de `tenant_id`: catálogo, produtos, vendas e o módulo de caixa MVP pertencem diretamente à empresa. O módulo de caixa possui um caixa principal por tenant e ainda não modela loja ou terminal.

Isto funciona para uma empresa com apenas um ponto de venda. Não é suficiente para filiais, pois duas localizações diferentes partilhariam o mesmo saldo de caixa e o mesmo fechamento.

## 3. Modelo proposto

### `stores`

Tabela ou coleção para a filial.

| Campo | Finalidade |
|---|---|
| `id` | Identificador da filial |
| `tenant_id` | Empresa proprietária |
| `name`, `code` | Nome e código único dentro da empresa |
| `address` | Endereço ou referência do local |
| `timezone` | Fuso horário operacional da filial |
| `active` | Permite desativar sem apagar histórico |
| `created_at`, `updated_at` | Auditoria básica |

### Entidades impactadas

| Entidade | Evolução necessária |
|---|---|
| `cash_registers` | Adicionar `store_id`; cada filial terá um ou mais caixas próprios |
| `cash_sessions` | A sessão pertence ao caixa, que pertence a uma única filial |
| `cash_movements` | A filial é inferida pela sessão; pode ser gravada também para relatórios rápidos |
| `devices` / `terminals` | Criar entidade ligada a `store_id` e, opcionalmente, a um caixa padrão |
| `sales` | Adicionar `store_id`, `cash_session_id` e `device_id` no momento da conclusão |
| `inventory_balances` | Criar saldo de stock por `product_id` e `store_id` |

Categorias e catálogo podem permanecer no nível do tenant. Isto permite que a empresa use os mesmos produtos nas filiais. Preço, disponibilidade e stock devem ser específicos por filial quando a operação exigir.

## 4. Regras de negócio

1. Uma filial pertence a exatamente um tenant.
2. Cada caixa pertence a uma única filial.
3. Pode haver uma sessão de caixa partilhada aberta por caixa; caixas de filiais distintas podem operar simultaneamente.
4. Um dispositivo é registado numa filial e só pode enviar vendas para caixas dessa filial.
5. A venda grava `store_id` como cópia histórica; mover ou desativar a filial depois não altera vendas antigas.
6. O dinheiro, a abertura e o fechamento de uma filial não podem misturar-se com os de outra.
7. Relatórios devem permitir visão por filial, por caixa e consolidada por empresa.
8. A data operacional e o fechamento usam o fuso horário da filial; timestamps técnicos permanecem em UTC.

## 5. Isolamento entre filiais

O isolamento de filial é complementar ao isolamento atual por tenant:

```text
Tenant A / Empresa A
├── Filial A1 ── só pode aceder a dados com tenant_id=A e store_id=A1
└── Filial A2 ── só pode aceder a dados com tenant_id=A e store_id=A2

Tenant B / Empresa B
└── Filial B1 ── nunca pode aceder a dados do Tenant A
```

- **Entre empresas:** o `tenant_id` impede acesso cruzado, como já ocorre no backend.
- **Entre filiais da mesma empresa:** o `store_id` impede que operações de uma filial afetem outra.
- **Consolidação:** um administrador autorizado da empresa pode consultar relatórios agregados de todas as filiais; isto é leitura consolidada, não mistura de dados operacionais.

### Regras técnicas obrigatórias

1. Toda tabela operacional ligada a uma localização deve guardar `tenant_id` e `store_id`: vendas, sessões de caixa, movimentos, dispositivos e saldos de stock.
2. Toda consulta de detalhe deve filtrar os dois campos. Exemplo: `WHERE tenant_id = :tenant_id AND store_id = :store_id`.
3. O servidor valida que a filial informada pertence ao tenant autenticado; um `store_id` de outro tenant deve devolver `404` ou `403`, sem revelar dados.
4. O servidor valida que o utilizador e o dispositivo têm autorização naquela filial antes de criar venda, sangria, suprimento ou fechamento.
5. A sessão de caixa, o caixa e o dispositivo precisam pertencer à mesma filial. Uma venda não pode apontar para combinações cruzadas.
6. O stock é debitado somente no saldo da filial da venda. Transferência entre filiais é uma operação explícita, auditável e com origem/destino.
7. Relatórios por filial aplicam o filtro no servidor, nunca apenas na aplicação mobile.

### Exemplo

O vendedor da Filial Baixa tenta enviar uma venda usando o identificador de caixa da Filial Matola. O backend deve confirmar, nesta ordem:

1. o caixa existe e pertence ao tenant autenticado;
2. o caixa pertence à Filial Matola;
3. o dispositivo e o utilizador pertencem à Filial Baixa;
4. como as filiais são diferentes, a venda é recusada antes de alterar stock ou dinheiro.

Isto evita que uma aplicação alterada ou um identificador adivinhado mova vendas, stock ou saldo de caixa entre filiais.

## 6. Exemplo operacional

No mesmo dia, a Filial Baixa abre com `1.000 MT` e a Filial Matola abre com `500 MT`. Os vendedores de cada ponto usam os seus próprios dispositivos, mas trabalham no caixa partilhado da respetiva filial.

```text
Filial Baixa:  esperado 4.000 MT, contado 4.000 MT
Filial Matola: esperado 2.700 MT, contado 2.650 MT, diferença -50 MT
Empresa:       consolida os dois relatórios, sem misturar os fechamentos
```

## 7. Migração recomendada

1. Criar `stores`.
2. Para cada tenant existente, criar uma filial padrão, por exemplo, `Sede`.
3. Associar o caixa principal atual à filial padrão.
4. Adicionar `store_id` a caixas, sessões e vendas e preencher os dados existentes com a filial padrão.
5. Criar dispositivos/terminais por filial e associá-los ao caixa partilhado da filial.
6. Criar `inventory_balances(product_id, store_id, quantity)` antes de permitir stock independente ou transferências entre filiais.
7. Depois de os dados estarem migrados, tornar `store_id` obrigatório nas novas vendas e operações de caixa.

As alterações devem ser aditivas e retrocompatíveis: editar apenas os schemas de instalação não atualiza bases já existentes; é necessário executar migrações específicas em cada SGBD suportado.

## 8. Permissões

No MVP, um utilizador que pertence ao tenant pode operar em qualquer filial da empresa. Quando necessário, evoluir para permissões com escopo de filial:

- `sale.create` na Filial Baixa;
- `cash.open` e `cash.close` numa filial ou caixa específico;
- `report.sales.view` apenas na filial autorizada;
- `store.manage` para administração das filiais.

## 9. Critérios de aceite

- Uma venda da Filial Baixa não aparece no caixa nem no relatório da Filial Matola.
- Dois caixas de filiais diferentes podem estar abertos ao mesmo tempo.
- Um dispositivo associado à Filial Baixa não consegue concluir venda usando caixa da Filial Matola.
- O relatório consolidado do tenant soma os dados das filiais sem eliminar o detalhe de origem.
- Stock e transferências entre filiais mantêm histórico e não permitem saldo incorreto.
- Um utilizador ou dispositivo de uma filial não consegue criar nem consultar uma operação detalhada de outra filial sem autorização explícita.
