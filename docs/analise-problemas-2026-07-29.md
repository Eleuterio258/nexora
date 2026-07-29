# Análise: o que está errado (2026-07-29)

Levantamento feito no servidor de produção (209.126.86.55, base `nexora_erp`).
Todos os números vêm de consultas à base real, não de leitura de código — as
consultas estão incluídas para poderem ser repetidas.

Ordenado por risco, não por esforço.

---

## 1. Trabalho em produção fora do controlo de versões

**18 ficheiros por commitar**, incluindo duas migrações e um ficheiro novo
(`backend/internal/modules/auth/handlers/papel.go`).

A base de dados foi alterada (pessoas fundidas, `users.tipo` promovido, ficha de
docente criada) e as imagens Docker foram reconstruídas a partir destas
alterações. Nada disto está registado no git. Um `git checkout` ou uma reposição
do servidor apaga o código mas **não** desfaz as alterações à base — ficaria um
schema com dados que nenhum código do repositório sabe produzir.

Já aconteceu uma vez neste mesmo dia: alterações locais foram descartadas e as
migrações correspondentes ficaram aplicadas na base sem ficheiro que as
descrevesse.

```bash
git status --porcelain | wc -l    # 18
```

**Correcção:** commitar antes de continuar.

---

## 2. Consentimento de dados: o registo não tem valor

As **8 candidaturas** existentes têm `consentimento_dados = false`, e **nenhum
código em Go escreve alguma vez esse campo** — o portal de candidaturas não o
recolhe.

```sql
SELECT count(*) FROM recrutamento.candidaturas WHERE NOT consentimento_dados;  -- 8
```

```bash
grep -rn "consentimento_dados" --include=*.go internal/   # só uma leitura, nenhuma escrita
```

`ContratarCandidato` recusa contratar sem consentimento (422). Como o campo
nunca é preenchido pelo candidato, **toda a contratação bate nessa recusa** e
alguém a destranca à mão na base de dados. Um consentimento que é sempre
inserido por um administrador deixou de ser um consentimento — e é precisamente
esse o campo que serviria de prova.

**Correcção:** recolher o consentimento no acto da candidatura (portal público),
com data e origem. Enquanto isso não existir, a verificação no backend só produz
a ilusão de conformidade.

---

## 3. Assiduidade: dois modelos que não se falam

### 3.1 Os eventos não alimentam as presenças

`rh.eventos_assiduidade` (QR, NFC, facial, hardware, self-service) e
`rh.presencas` (a tabela que a página *Minha Assiduidade* mostra) não estão
ligados por nada. Marcar ponto grava um evento e **não altera a presença do
dia**.

Verificado na prática: dois eventos registados para 27/07/2026 (entrada 08:00,
saída 17:00) deixaram o dia na página do colaborador como *Falta*, com traços
nas horas.

### 3.2 `CriarPresenca` nunca escreve o `tipo`

O `ON CONFLICT DO UPDATE` de `rh.CriarPresenca` actualiza horas e observações,
mas não o `tipo`. Uma presença registada por cima de uma falta automática fica
com horas **e continua marcada como falta**.

```sql
SELECT count(*) FROM rh.presencas
 WHERE hora_entrada IS NOT NULL AND hora_entrada <> '' AND tipo = 'falta';  -- 32
```

As 32 linhas são todas de 2026-06-10, tenant 5, uma por funcionário.

### 3.3 O resumo conta faltas como dias trabalhados

`ResumoAssiduidade` calcula `dias_trabalhados` com `COUNT(DISTINCT data)` sobre
todas as linhas do mês, sem filtrar o tipo. As **337 faltas** da base contam
como dias trabalhados.

```sql
SELECT count(*) FROM rh.presencas WHERE tipo = 'falta';  -- 337
```

É o que produz o resultado contraditório visível na interface: *8 dias
trabalhados, 8 faltas, 0.0h*.

---

## 4. Marcação por geolocalização no hardware falha sempre

`hardware/service/processor.go:252` resolve o método de marcação pelo código
`"geolocalizacao"`. Esse código **não existe** no catálogo:

```sql
SELECT count(*) FROM rh.metodos_marcacao WHERE codigo = 'geolocalizacao';  -- 0
```

Os códigos semeados são `gps` e `geofence`. Todo evento de geolocalização vindo
de hardware falha a resolução do método.

---

## 5. Falhas de login mascaram-se de credenciais inválidas

`loginWithCredentials` (`auth/handlers/auth.go`) faz `found := err == nil`. Um
erro de schema (42703, coluna inexistente) fica indistinguível de "utilizador
não encontrado":

- a resposta é `401 Credenciais inválidas`, com a password certa;
- **não aparece nos logs**;
- o `login_history` também não regista, porque o INSERT de auditoria é
  `go h.db.Exec(r.Context(), ...)` e o contexto do pedido já foi cancelado.

Foi exactamente isto que escondeu, durante horas, a falta da coluna
`auth.memberships.principal` — com **todos** os logins da plataforma em 401.

**Correcção:** distinguir `pgx.ErrNoRows` de qualquer outro erro, e registar o
segundo.

---

## 6. Entidade Pessoa ainda meio adoptada

| | |
|---|---|
| Clientes ligados a uma pessoa | **2 de 64** |
| Contas sem pessoa | 2 |
| Pessoas com documento de identificação | 2 de 157 |

O módulo `clientes` ficou praticamente fora do modelo Pessoa. E como só duas
pessoas têm documento, a deduplicação por `(tipo_documento, numero_documento)` —
a chave que impede o mesmo humano de existir várias vezes — quase nunca tem por
onde pegar. Hoje o documento só é recolhido na contratação.

---

## 7. Menores, mas reais

- **Dois funcionários activos sem horário de trabalho**: Ana Paulo Machava (87)
  e Bento Muianga (86). O job que marca faltas faz
  `JOIN rh.horarios_trabalho ON h.id = f.horario_id`, portanto **a assiduidade
  destes dois nunca é processada**.
- **NUIT de 8 dígitos aceite** (o registado na contratação da Ana). O NUIT
  moçambicano tem 9 dígitos; nada valida.
- **Duas pessoas chamadas "Funcionário"** (ids 150 e 151) são signatárias de dois
  contratos de trabalho do tenant 7 — **um deles assinado**. O gerador de
  contratos não pôs o nome do trabalhador, e não há na base nenhuma ligação que
  permita identificá-los a posteriori: `assinatura_digital.documentos` não guarda
  a origem.
- **`20260712000120`** está registada em `auth.schema_migrations` sem ficheiro
  correspondente (resto de uma migração movida para `archive/`).

---

## Ordem sugerida

1. **Commitar** o que já está em produção (secção 1) — corrigir mais coisas por
   cima de 18 ficheiros não versionados só aumenta o que se pode perder.
2. Secções **2 a 5**, que produzem dados errados todos os dias.
3. Secção **6**, que é estrutural e não urgente.
4. Secção **7**, avulsa.
