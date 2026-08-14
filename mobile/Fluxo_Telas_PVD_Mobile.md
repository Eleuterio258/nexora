# Fluxo de Telas — PVD Mobile Android (Ponto de Venda)

Para um **PVD Mobile Android (Ponto de Venda)**, o fluxo das telas estrutura-se assim:

## 1. Splash / Inicialização

**Objectivo:** iniciar a aplicação e validar o ambiente.

**Fluxo:**

1. Abrir aplicação.
2. Verificar sessão do operador.
3. Verificar empresa/loja/terminal.
4. Verificar ligação à Internet.
5. Sincronizar dados pendentes, se necessário.
6. Ir para **Login** ou **Dashboard/Ponto de Venda**.

---

## 2. Login

### Modelo de acesso

O Nexora distingue três conceitos, cada um com o seu próprio tipo de login:

| Conceito | Representa | Faz login? | Pode operar POS? |
|---|---|---|---|
| **Usuário** | Conta de acesso à plataforma | Sim | Conforme permissões |
| **Funcionário** | Pessoa que trabalha para o tenant | Pode ter conta | Se tiver permissão |
| **Terminal** | Máquina/app de caixa registadora | Sim, por credencial técnica | Sim, de forma limitada |

Ou seja: o **utilizador** autentica-se com utilizador+senha; o **terminal** autentica-se separadamente, com uma **credencial técnica própria** (não é a senha do utilizador).

**Elementos:**

* Utilizador
* Senha
* Credencial técnica do terminal (apenas no 1º acesso do dispositivo)
* PIN
* Biometria, opcional
* Botão **Entrar**

**Fluxo:**

O login com **utilizador e senha** identifica o **tenant** (empresa) e a **filial/loja** a que o operador pertence.

Em seguida é feito o **login do terminal**, que associa o dispositivo a essa filial através de uma **credencial técnica** própria do terminal (distinta da senha do utilizador). Este login do terminal é feito **uma única vez** — na primeira utilização do dispositivo.

**1º acesso do dispositivo:**

`Utilizador + Senha → identifica tenant/filial → Login do Terminal (credencial técnica) → terminal associado → Ponto de Venda`

**Acessos seguintes (terminal já associado):**

`PIN ou Biometria → Ponto de Venda`

Se o dispositivo já estiver associado, o operador entra directamente através de PIN ou biometria, sem repetir o login de utilizador/senha nem o login do terminal.

---

## 3. Abertura de Caixa

Antes de vender, o operador pode precisar de abrir a caixa.

**Elementos:**

* Terminal
* Caixa
* Operador
* Data/hora
* Fundo de caixa inicial
* Observação
* **Abrir Caixa**

**Fluxo:**

`Login → Abertura de Caixa → Ponto de Venda`

Se a caixa já estiver aberta:

`Login → Ponto de Venda`

---

# 4. Ponto de Venda — Tela Principal

Esta é a tela mais importante do PVD.

### Estrutura

**Topo**

* Nome da loja
* Operador
* Caixa
* Estado online/offline
* Menu

**Pesquisa**

* 🔍 Procurar produto
* 📷 Ler código de barras

**Categorias**

* Bebidas
* Alimentação
* Electrónica
* etc.

**Produtos**
Cada produto apresenta:

* Imagem
* Nome
* Preço
* Stock
* Botão `+`

**Carrinho**

* Quantidade
* Preço
* Desconto
* Subtotal
* Total

### Fluxo

`Ponto de Venda → seleccionar produto → adicionar ao carrinho`

ou

`Ponto de Venda → scanner → código de barras → produto → carrinho`

---

# 5. Pesquisa de Produto

Permite localizar rapidamente um produto.

**Pesquisa por:**

* Nome
* Código
* SKU
* Código de barras

**Fluxo:**

`Pesquisa → resultado → seleccionar produto → adicionar`

Se não encontrar:

`Produto não encontrado → pesquisar novamente / cancelar`

---

# 6. Scanner de Código de Barras

Tela dedicada à leitura.

**Elementos:**

* Câmara
* Área de leitura
* Flash
* Digitação manual do código

**Fluxo:**

`Scanner → ler EAN/UPC → procurar produto → adicionar ao carrinho`

Se o produto já estiver no carrinho:

`Scanner → produto existente → aumentar quantidade`

---

# 7. Carrinho

Apresenta todos os artigos da venda.

**Cada linha:**

`Produto | Qtd | Preço | Desconto | Total`

Acções:

* `+` aumentar quantidade
* `−` diminuir
* Remover
* Editar preço, se permitido
* Desconto
* Observação

**Resumo:**

* Subtotal
* Desconto
* Imposto/IVA
* Total

Botões:

**Continuar → Pagamento**

**Fluxo:**

`Produtos → Carrinho → Pagamento`

---

# 8. Cliente

Opcionalmente, antes do pagamento pode associar um cliente.

**Opções:**

* Consumidor final
* Procurar cliente
* Criar cliente
* Seleccionar cliente existente

**Dados:**

* Nome
* NUIT
* Telefone
* Email
* Endereço, se necessário

**Fluxo:**

`Carrinho → Cliente → Pagamento`

Ou:

`Carrinho → Consumidor final → Pagamento`

---

# 9. Descontos

Pode existir como tela/modal dentro do carrinho.

**Tipos:**

* Desconto percentual
* Desconto por valor
* Desconto por produto
* Desconto global

Exemplo:

`Total: 10.000 MT`

`Desconto: 10%`

`Total: 9.000 MT`

O sistema deve verificar se o operador possui permissão para aplicar o desconto.

---

# 10. Pagamento

Esta é outra tela crítica.

### Métodos

* 💵 Numerário
* 💳 TPA
* 📱 M-Pesa
* 📱 e-Mola
* 🏦 Transferência
* Cartão
* Crédito, se permitido

### Exemplo

**Total:** 2.500 MT

**Recebido:** 3.000 MT

**Troco:** 500 MT

Botão:

**Confirmar Pagamento**

---

# 11. Pagamento em Numerário

**Fluxo:**

`Pagamento → Numerário`

Mostrar:

* Total
* Valor recebido
* Troco

Exemplo:

```text
Total       1.250 MT
Recebido    2.000 MT
---------------------
Troco         750 MT
```

Depois:

`Confirmar → Venda concluída`

---

# 12. Pagamento M-Pesa / e-Mola

O fluxo pode ser:

`Pagamento → M-Pesa`

→ Introduzir número do cliente

→ Criar pedido de pagamento

→ Aguardar confirmação

→ Confirmar transacção

→ Emitir documento

O estado deve ser claramente apresentado:

`A aguardar pagamento...`

Depois:

`Pagamento confirmado ✓`

---

# 13. Pagamento TPA

Fluxo:

`Pagamento → TPA`

→ enviar valor para o terminal

→ operador/cliente efectua pagamento

→ receber resposta

→ aprovado ou recusado

**Aprovado:**

`Pagamento confirmado → Venda concluída`

**Recusado:**

`Pagamento recusado → tentar novamente / outro método`

---

# 14. Pagamento Misto

Muito útil para retalho.

Exemplo:

**Total:** 10.000 MT

* Numerário: 4.000 MT
* M-Pesa: 6.000 MT

O sistema mostra:

```text
Total              10.000 MT
Pago                4.000 MT
Restante            6.000 MT
```

Depois de completar:

`Pagamento → Venda concluída`

---

# 15. Venda Concluída

Após pagamento bem-sucedido.

**Mostrar:**

```text
✓ Venda concluída

Documento: FT 2026/000123
Total: 2.500 MT
Pagamento: M-Pesa
```

Acções:

* 🖨️ Imprimir
* 📄 Ver documento
* 📱 Enviar por WhatsApp
* ✉️ Enviar por email
* Nova venda

**Fluxo:**

`Venda concluída → Nova venda`

---

# 16. Documento / Recibo

Permite visualizar o documento fiscal.

**Informação:**

* Empresa
* NUIT
* Cliente
* Número do documento
* Data/hora
* Produtos
* IVA
* Total
* Forma de pagamento
* QR Code, se aplicável

Acções:

**Imprimir | PDF | WhatsApp | Email**

---

# 17. Histórico de Vendas

Lista das vendas realizadas pelo terminal.

Filtros:

* Hoje
* Ontem
* Período
* Operador
* Forma de pagamento
* Estado

Cada venda:

`FT 000123 | 2.500 MT | M-Pesa | Concluída`

Ao seleccionar:

`Histórico → Detalhes da venda`

---

# 18. Detalhes da Venda

Mostra:

* Número do documento
* Cliente
* Produtos
* Quantidades
* Preços
* Descontos
* IVA
* Total
* Pagamento
* Operador
* Terminal
* Data/hora

Acções, dependendo das permissões:

* Imprimir
* Reenviar
* Anular
* Emitir nota de crédito
* Devolver

---

# 19. Devolução

Fluxo:

`Histórico → Venda → Devolver`

Seleccionar produtos:

```text
Produto A     2 unidades
Produto B     1 unidade
```

Indicar motivo.

Depois:

`Confirmar devolução → processar → documento de devolução`

---

# 20. Caixa

Tela para gestão do caixa.

**Informação:**

```text
Saldo inicial       5.000 MT
Vendas              48.500 MT
Numerário           21.000 MT
TPA                 15.000 MT
M-Pesa               8.500 MT
e-Mola               4.000 MT
```

Acções:

* Entrada de dinheiro
* Saída de dinheiro
* Sangria
* Reforço
* Fechar caixa

---

# 21. Fecho de Caixa

No final do turno:

`Menu → Fechar Caixa`

O sistema apresenta o valor esperado.

Exemplo:

```text
Numerário esperado:  25.000 MT
Numerário contado:   24.500 MT

Diferença:             -500 MT
```

Operador confirma.

Depois:

`Fecho → relatório → sincronização`

---

# 22. Produtos / Stock

Dependendo do nível de acesso, o PVD pode permitir consultar stock.

**Produto:**

```text
Coca-Cola 500ml
Preço: 100 MT
Stock: 35
SKU: CC500
```

Pode mostrar:

* Stock disponível
* Stock reservado
* Stock mínimo
* Armazém

Normalmente, **não se recomenda permitir edição completa do catálogo no PVD**. Isso deve ficar no ERP.

---

# 23. Notificações

Centraliza eventos:

* Pagamento confirmado
* Pagamento recusado
* Stock baixo
* Venda sincronizada
* Erro de sincronização
* Caixa por fechar
* Actualização disponível

---

# 24. Menu Principal

Uma estrutura simples:

```text
PVD

├── 🛒 Nova Venda
├── 📋 Histórico
├── 📦 Produtos
├── 💰 Caixa
├── 👤 Clientes
├── 📊 Relatórios
├── 🔄 Sincronização
├── 🔔 Notificações
└── ⚙️ Configurações
```

---

# 25. Modo Offline

Para um PVD em Moçambique, é **muito importante** ter funcionamento offline.

Fluxo:

`Internet disponível`

→ vender normalmente

`Internet perdida`

→ activar **Modo Offline**

→ venda guardada localmente

→ imprimir recibo

→ quando Internet voltar:

`Internet → sincronização → servidor`

Cada operação deve possuir um identificador único para evitar duplicação.

---

# Fluxo geral do PVD

```text
                 ┌──────────────┐
                 │    LOGIN     │
                 └──────┬───────┘
                        ↓
                 ┌──────────────┐
                 │ ABRIR CAIXA  │
                 └──────┬───────┘
                        ↓
              ┌───────────────────┐
              │   PONTO DE VENDA  │
              └─────────┬─────────┘
                        ↓
              ┌───────────────────┐
              │ PRODUTOS / SCANNER│
              └─────────┬─────────┘
                        ↓
                 ┌──────────────┐
                 │   CARRINHO   │
                 └──────┬───────┘
                        ↓
                 ┌──────────────┐
                 │    CLIENTE   │
                 └──────┬───────┘
                        ↓
                 ┌──────────────┐
                 │   PAGAMENTO  │
                 └──────┬───────┘
                        ↓
              ┌───────────────────┐
              │ VENDA CONCLUÍDA  │
              └─────────┬─────────┘
                        ↓
              ┌───────────────────┐
              │ RECIBO / FACTURA │
              └─────────┬─────────┘
                        ↓
              ┌───────────────────┐
              │ NOVA VENDA        │
              └───────────────────┘
```

### Arquitectura recomendada para o PVD Mobile

**Android → PVD Mobile**

`UI → Venda → Pagamento → Impressão → SQLite/Offline → API → Nexora ERP`

E o **Nexora ERP** fica responsável por:

* Produtos
* Preços
* Clientes
* Stock
* Documentos fiscais
* Configuração de impostos
* Utilizadores/permissões
* Relatórios
* Sincronização entre terminais

Assim o PVD fica **rápido e simples para o operador**, enquanto o ERP mantém toda a gestão central.
