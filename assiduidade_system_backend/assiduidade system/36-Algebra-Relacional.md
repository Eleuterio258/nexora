# Álgebra Relacional — Sistema de Gestão de Assiduidade

## 1. Controlo do documento

| Campo | Valor |
| --- | --- |
| Referência | ALG-ASS-001 |
| Versão | 0.2 |
| Data | 25/09/2026 |
| Estado | Rascunho técnico para validação |
| Responsáveis | Equipa técnica, com validação de RH para as expressões de apuramento — nomes a designar |
| Base documental | [Modelo de Dados](09-Modelo-de-Dados.md), [Regras de Negócio](04-Regras-de-Negocio.md), [TDD](08-Documento-de-Design-Tecnico-TDD.md), [Matriz de Permissões](15-Matriz-de-Permissoes-e-Acessos.md) |

| Versão | Data | Alteração |
| --- | --- | --- |
| 0.1 | 25/09/2026 | Esquemas, expressões ALG-01 a ALG-24 e restrições RIA-01 a RIA-14 |
| 0.2 | 25/09/2026 | Acesso e âmbito (§5) reescritos para permissões granulares: permissões efectivas por cargo, directas e tipo de utilizador; âmbito próprio, hierárquico (responsável de unidade), designado e global |

## 2. Objectivo, âmbito e convenções

Este documento especifica, em álgebra relacional, as consultas centrais e as restrições de integridade do sistema sobre o modelo lógico do [documento 09](09-Modelo-de-Dados.md). A notação formal elimina ambiguidades do texto das regras e serve para três fins:

1. **Referência de implementação:** cada expressão tem o equivalente SQL (PostgreSQL) que a implementação deve reproduzir.
2. **Oráculo de testes:** o resultado da expressão sobre um conjunto de dados de teste é o resultado esperado da funcionalidade correspondente.
3. **Verificação de integridade:** cada restrição RI-xx é escrita como uma expressão que tem de dar o conjunto vazio.

Convenções:

- **ALG-xx** identifica expressões; **RIA-xx** restrições de integridade na forma algébrica. Identificadores estáveis.
- Os nomes de relações e atributos são abreviaturas dos nomes do documento 09, que dependem de DT-12. Uma mudança de nomes não altera as expressões.
- `τ` é o tenant do contexto resolvido no servidor (MEC-01); `c` a conta do actor; `t₀` o instante de avaliação.
- Intervalos são semiabertos `[início, fim)`, com `fim` nulo a significar vigência aberta. Duas vigências sobrepõem-se se e só se `início₁ < fim₂ ∧ início₂ < fim₁` (com `fim` nulo tratado como +∞). Esta condição é abreviada por `sobrepõe(x, y)`.
- `vigente(x, t)` abrevia `x.início ≤ t ∧ (x.fim = nulo ∨ t < x.fim)`.

### 2.1. Notação

| Símbolo | Operação | Símbolo | Operação |
| --- | --- | --- | --- |
| σ<sub>θ</sub>(R) | Selecção | R ⋈<sub>θ</sub> S | Junção teta |
| π<sub>A</sub>(R) | Projecção | R ⋉ S | Semijunção (tuplos de R com correspondência em S) |
| ρ<sub>N</sub>(R) | Renomeação | R ▷ S | Antijunção (tuplos de R sem correspondência em S) |
| R ∪ S, R − S, R ∩ S | União, diferença, intersecção | R ⟕ S | Junção externa à esquerda |
| R × S | Produto cartesiano | R ÷ S | Divisão |
| γ<sub>G; f(A)→B</sub>(R) | Agrupamento e agregação (extensão) | τ<sub>A</sub>(R) | Ordenação (extensão; só na apresentação) |
| X ← E | Atribuição de uma expressão a um nome | ∅ | Relação vazia |

## 3. Esquemas relacionais

Atributos abreviados; `*` marca a chave primária. Todas as relações de negócio têm `tid` (tenant). Colunas não usadas nas expressões são omitidas.

| Relação | Atributos | Entidade |
| --- | --- | --- |
| Tenant | id\*, estado, fuso | ENT-01 |
| Unidade | id\*, tid, pai, responsavel, tipo, estado | ENT-02 |
| Conta | id\*, tid, colab, tipo, estado | ENT-03 |
| Perm | perm\*, módulo | ENT-05 |
| CargoPerm | cargo, perm | ENT-04 |
| Vinc | id\*, tid, conta, cargo, estado | ENT-06 |
| PermDir | conta, tid, perm, início, fim | ENT-06 |
| PermTipo | tipo, perm | ENT-06 |
| ModDesact | tid, módulo | Módulos desactivados por tenant |
| Colab | id\*, tid, ident, estado | ENT-08 |
| AssocOrg | id\*, tid, colab, unidade, início, fim | ENT-09 |
| Design | id\*, tid, colab, conta, início, fim | ENT-10 |
| Dia | tid, data, útil, âmbito | ENT-12 |
| Dispositivo | id\*, tid, unidade, estado | ENT-16 |
| Propag | id\*, tid, objecto, destino, operação, estado | ENT-19 |
| Evento | id\*, tid, uuid, colab, tipo, origem, método, disp, t_orig, t_rec, estado, dup_de, hash | ENT-20 |
| Recepção | id\*, tid, evento, t, resultado | ENT-21 |
| Habil | id\*, tid, colab, modalidade, estado | ENT-23 |
| RefBio | id\*, tid, colab, modalidade, estado | ENT-24 |
| Pedido | id\*, tid, tipo, colab, requerente, início, fim, estado, versão | ENT-27 |
| Decisão | id\*, tid, pedido, versão_pedido, decisor, resultado | ENT-32 |
| Ajuste | id\*, tid, pedido, evento, apuramento | ENT-33 |
| Jornada | id\*, tid, colab, data_ref, prev_ini, prev_fim | ENT-35 |
| Apur | id\*, tid, jornada, versão, hash_ent, estado, t_liq, criado_em | ENT-36 |
| Ocorr | id\*, tid, apur, tipo, observado, elegível, aprovado | ENT-37 |
| Período | id\*, tid, unidade, início, fim, estado, versão | ENT-38 |
| Fecho | id\*, tid, período, versão, hash, criado_em | ENT-39 |
| FechoApur | fecho, apur | Associação Fecho–Apuramento |
| Exec | id\*, tid, fecho, op_uuid, estado | ENT-43 |
| ItemExec | id\*, tid, exec, colab, estado | ENT-44 |
| Audit | id\*, tid, anterior, actor, acção, obj_tipo, obj_id, t, hash_ant, hash | ENT-45 |

## 4. Expressões base

### 4.1. ALG-01 — Restrição ao tenant do contexto

Toda a consulta de negócio começa por restringir cada relação ao tenant do contexto:

R<sub>τ</sub> ← σ<sub>tid = τ</sub>(R)

As expressões seguintes usam sempre R<sub>τ</sub>; o índice é omitido por legibilidade. Junções entre relações de negócio incluem implicitamente a igualdade de `tid` (RI-01). Uma consulta que use R em vez de R<sub>τ</sub> viola TEN-07.

```sql
-- Aplicado pela camada de persistência e, como segunda barreira, por Row-Level Security (DT-04)
SELECT ... FROM evento_assiduidade e WHERE e.tenant_id = :tau;
```

### 4.2. ALG-02 — Eventos efectivos

EvAceite ← σ<sub>estado = 'aceite'</sub>(Evento)

Eventos `duplicado`, `rejeitado`, `pendente_analise` e `recebido` ficam excluídos do apuramento (RN-011, RN-012, [09 §6.1](09-Modelo-de-Dados.md)).

### 4.3. ALG-03 — Detecção de reenvio (idempotência)

Para um evento recebido com identificador `u` e hash `h`:

Existente ← σ<sub>uuid = u</sub>(Evento)

- Existente = ∅ → primeira recepção;
- π<sub>hash</sub>(Existente) = {h} → `reenvio_equivalente` (devolve o resultado existente);
- caso contrário → `conteudo_divergente` (RN-010, MEC-02).

```sql
SELECT e.hash_conteudo = :h AS equivalente
FROM evento_assiduidade e
WHERE e.tenant_id = :tau AND e.evento_uuid = :u;
```

### 4.4. ALG-04 — Associação vigente no instante do evento

EvAssoc ← Evento ⋈<sub>Evento.colab = AssocOrg.colab ∧ vigente(AssocOrg, Evento.t_orig)</sub> AssocOrg

Cada evento obtém a unidade em que o colaborador estava no instante de origem, não a actual (RN-006, RF-010). Um evento sem correspondência (Evento ▷ EvAssoc) indica colaborador sem associação vigente e deve estar em pendência.

```sql
SELECT e.*, a.unidade_organizacional_id
FROM evento_assiduidade e
JOIN associacao_organizacional a
  ON a.tenant_id = e.tenant_id AND a.colaborador_id = e.colaborador_id
 AND a.vigencia @> e.instante_origem
WHERE e.tenant_id = :tau;
```

### 4.5. ALG-05 — Eventos de uma jornada

Para a jornada `j`, com margem de associação Δ<sub>ini</sub> e Δ<sub>fim</sub> definida em PN-02:

EvJ(j) ← EvAceite ⋈<sub>EvAceite.colab = J.colab ∧ J.prev_ini − Δ<sub>ini</sub> ≤ EvAceite.t_orig < J.prev_fim + Δ<sub>fim</sub></sub> σ<sub>id = j</sub>(Jornada)

A jornada é definida pelo intervalo previsto, não pelo dia civil, pelo que um turno das 22:00 às 06:00 recolhe os eventos dos dois dias civis (RN-017, EX-01). Enquanto PN-02 não for aprovado, Δ não tem valor e a expressão não é executável (PD-09).

## 5. Acesso e âmbito

O modelo de autorização está nos [Requisitos Funcionais §3.1](02-Requisitos-Funcionais.md): permissões granulares `módulo:acção` vindas do cargo, das permissões directas e do tipo de utilizador, e âmbito próprio, hierárquico ou global. `c` é a conta do utilizador e `p` o código da permissão.

### 5.1. ALG-06 — Permissões efectivas de uma conta

PermCargo(c) ← π<sub>perm</sub>(σ<sub>conta = c ∧ estado = 'activa'</sub>(Vinc) ⋈<sub>Vinc.cargo = CargoPerm.cargo</sub> CargoPerm)

PermDirecta(c) ← π<sub>perm</sub>(σ<sub>conta = c ∧ vigente(PermDir, t₀)</sub>(PermDir))

PermDoTipo(c) ← π<sub>perm</sub>(σ<sub>id = c</sub>(Conta) ⋈<sub>Conta.tipo = PermTipo.tipo</sub> PermTipo)

PermEf(c) ← (PermCargo(c) ∪ PermDirecta(c) ∪ PermDoTipo(c)) − π<sub>perm</sub>(Perm ⋈<sub>Perm.módulo = ModDesact.módulo</sub> ModDesact)

Tem(c, p) é verdadeiro se e só se σ<sub>perm = p</sub>(PermEf(c)) ≠ ∅. Uma permissão com acção `*` num módulo equivale a todas as acções desse módulo; o tipo `superadmin` é tratado fora destas expressões (RF-008).

```sql
SELECT cp.permissao FROM vinculacao v JOIN cargo_permissao cp ON cp.cargo_id = v.cargo_id
 WHERE v.tenant_id = :tau AND v.conta_id = :c AND v.estado = 'activa'
UNION
SELECT pd.permissao FROM permissao_directa pd
 WHERE pd.tenant_id = :tau AND pd.conta_id = :c AND pd.vigencia @> now()
UNION
SELECT pt.permissao FROM conta_utilizador u JOIN permissao_tipo pt ON pt.tipo = u.tipo
 WHERE u.id = :c
EXCEPT
SELECT p.codigo FROM permissao p JOIN modulo_desactivado m ON m.modulo = p.modulo
 WHERE m.tenant_id = :tau;
```

### 5.2. ALG-07 — Âmbito hierárquico

As unidades de que a conta é responsável, e todas as descendentes, formam o âmbito hierárquico. A álgebra relacional clássica não exprime fecho transitivo; define-se como ponto fixo:

Âmbito<sub>0</sub>(c) ← ρ<sub>unidade←id</sub>(π<sub>id</sub>(Unidade ⋈<sub>Unidade.responsavel = Conta.colab</sub> σ<sub>id = c</sub>(Conta)))

Âmbito<sub>k+1</sub> ← Âmbito<sub>k</sub> ∪ ρ<sub>unidade←id</sub>(π<sub>id</sub>(Unidade ⋈<sub>Unidade.pai = Âmbito<sub>k</sub>.unidade</sub> Âmbito<sub>k</sub>))

Âmbito\*(c) = Âmbito<sub>n</sub> tal que Âmbito<sub>n+1</sub> = Âmbito<sub>n</sub>. A ausência de ciclos (RI-04) garante que o ponto fixo é atingido.

```sql
WITH RECURSIVE ambito(unidade_id) AS (
  SELECT u.id FROM unidade_organizacional u
    JOIN conta_utilizador c ON c.colaborador_id = u.responsavel_id
   WHERE u.tenant_id = :tau AND c.id = :c
  UNION
  SELECT u.id FROM unidade_organizacional u JOIN ambito x ON u.pai_id = x.unidade_id
   WHERE u.tenant_id = :tau
)
SELECT unidade_id FROM ambito;
```

### 5.3. ALG-08 — Colaboradores visíveis a uma conta para uma permissão

ColabPróprio(c) ← π<sub>colab</sub>(σ<sub>id = c ∧ colab ≠ nulo</sub>(Conta))

ColabHierárquico(c) ← π<sub>colab</sub>(σ<sub>vigente(AssocOrg, t₀)</sub>(AssocOrg) ⋈<sub>AssocOrg.unidade = Âmbito\*.unidade</sub> Âmbito\*(c))

ColabDesignado(c) ← π<sub>colab</sub>(σ<sub>conta = c ∧ vigente(Design, t₀)</sub>(Design))

ColabGlobal(c) ← π<sub>id→colab</sub>(Colab) se Tem(c, 'recursos-humanos:gerir_funcionarios'), ou, para consultas, Tem(c, 'recursos-humanos:ver_funcionarios'); caso contrário ∅

Visíveis(c, p) ← ∅ se ¬Tem(c, p); caso contrário ColabPróprio(c) ∪ ColabHierárquico(c) ∪ ColabDesignado(c) ∪ ColabGlobal(c)

Para permissões de self-service (`assiduidade:marcar_ponto`, `ver_assiduidade`, `justificar`, `corrigir_ponto`, `pedido-ferias:submeter_pedido`), Visíveis limita-se a ColabPróprio(c).

### 5.4. ALG-09 — Autorização sobre um objecto

Para uma operação com permissão `p` sobre um objecto do colaborador `k`, o acesso é permitido se e só se:

σ<sub>colab = k</sub>(Visíveis(c, p)) ≠ ∅

Sem a permissão, a resposta é `SEM_PERMISSAO`; com a permissão mas com o objecto fora do âmbito, é `NAO_ENCONTRADO` (TEN-05). A segregação de funções (RIA-09) é verificada à parte, sobre as pessoas envolvidas.

## 6. Apuramento

### 6.1. ALG-10 — Faltas candidatas

Uma jornada prevista sem eventos aceites não é, por si só, uma falta: exige verificar ausências aprovadas, eventos pendentes e o vínculo (RN-022). A expressão encadeia antijunções:

SemEventos ← Jornada ▷<sub>Jornada.id = EvJ.jornada</sub> EvJ

AusAprov ← σ<sub>tipo = 'ausencia' ∧ estado = 'aprovado'</sub>(Pedido)

SemAusência ← SemEventos ▷<sub>SemEventos.colab = AusAprov.colab ∧ sobrepõe(SemEventos.prev, AusAprov)</sub> AusAprov

EvPend ← σ<sub>estado = 'pendente_analise'</sub>(Evento)

SemPendente ← SemAusência ▷<sub>SemAusência.colab = EvPend.colab ∧ SemAusência.prev_ini − Δ<sub>ini</sub> ≤ EvPend.t_orig < SemAusência.prev_fim + Δ<sub>fim</sub></sub> EvPend

FaltaCandidata ← SemPendente ⋉<sub>SemPendente.colab = Colab.id</sub> σ<sub>estado = 'activo'</sub>(Colab)

Uma jornada com evento pendente não é falta candidata: fica indeterminada até à análise (FP-03). As tentativas de identificação falhadas não entram na expressão, porque uma falha técnica não prova ausência (RN-022, RN-044).

```sql
SELECT j.*
FROM jornada j
JOIN colaborador c ON c.tenant_id = j.tenant_id AND c.id = j.colaborador_id AND c.estado = 'activo'
WHERE j.tenant_id = :tau
  AND NOT EXISTS (SELECT 1 FROM evento_assiduidade e
                  WHERE e.tenant_id = j.tenant_id AND e.colaborador_id = j.colaborador_id
                    AND e.estado = 'aceite'
                    AND e.instante_origem >= lower(j.intervalo_previsto) - :delta_ini
                    AND e.instante_origem <  upper(j.intervalo_previsto) + :delta_fim)
  AND NOT EXISTS (SELECT 1 FROM pedido p
                  WHERE p.tenant_id = j.tenant_id AND p.colaborador_id = j.colaborador_id
                    AND p.tipo_pedido = 'ausencia' AND p.estado = 'aprovado'
                    AND p.periodo_abrangido && j.intervalo_previsto)
  AND NOT EXISTS (SELECT 1 FROM evento_assiduidade e
                  WHERE e.tenant_id = j.tenant_id AND e.colaborador_id = j.colaborador_id
                    AND e.estado = 'pendente_analise'
                    AND e.instante_origem >= lower(j.intervalo_previsto) - :delta_ini
                    AND e.instante_origem <  upper(j.intervalo_previsto) + :delta_fim);
```

### 6.2. ALG-11 — Versão actual de cada apuramento

Sem agregação, a versão mais recente é a que não é superada por outra da mesma jornada:

Superadas ← π<sub>A1.*</sub>(ρ<sub>A1</sub>(Apur) ⋈<sub>A1.jornada = A2.jornada ∧ A1.versão < A2.versão</sub> ρ<sub>A2</sub>(Apur))

ApurActual ← Apur − Superadas

Com agregação: ApurActual ← Apur ⋈<sub>jornada, versão</sub> γ<sub>jornada; MAX(versão)→versão</sub>(Apur).

As versões anteriores nunca são removidas (RN-024); a expressão selecciona, não apaga.

### 6.3. ALG-12 — Totais por colaborador num período

Para o período `q` com intervalo `[a, b)`:

JornQ ← σ<sub>a ≤ data_ref < b</sub>(Jornada)

TotaisQ ← γ<sub>colab; SUM(t_liq)→tempo, COUNT(*)→jornadas</sub>(ApurActual ⋈<sub>ApurActual.jornada = JornQ.id</sub> JornQ)

Jornadas com `t_liq` nulo (indeterminado) não entram na soma e devem ser contadas à parte:

Indeterminadas ← γ<sub>colab; COUNT(*)→n</sub>(σ<sub>t_liq = nulo</sub>(ApurActual) ⋈ JornQ)

Um total só é apresentado como completo se Indeterminadas = ∅ para o colaborador (RN §5.2).

### 6.4. ALG-13 — Horas extraordinárias candidatas e aprovadas

Extra ← σ<sub>tipo = 'extraordinaria_candidata'</sub>(Ocorr) ⋈<sub>Ocorr.apur = ApurActual.id</sub> ApurActual ⋈ JornQ

ExtraQ ← γ<sub>colab; SUM(observado)→observado, SUM(elegível)→elegível, SUM(aprovado)→aprovado</sub>(Extra)

Só `aprovado` é enviado ao ERP (INT-06, RN-023); `observado` nunca substitui `aprovado`.

### 6.5. ALG-14 — Colaboradores com presença em todos os dias úteis (divisão)

Exemplo de divisão relacional, útil em relatórios de assiduidade completa:

PresençaDia ← π<sub>colab, data_ref</sub>(σ<sub>t_liq > 0</sub>(ApurActual ⋈<sub>ApurActual.jornada = JornQ.id</sub> JornQ))

DiasÚteisQ ← π<sub>data_ref</sub>(ρ<sub>data_ref←data</sub>(σ<sub>útil ∧ a ≤ data < b</sub>(Dia)))

AssiduidadeCompleta ← PresençaDia ÷ DiasÚteisQ

O resultado contém os colaboradores que têm um tuplo em PresençaDia para cada dia útil do período.

```sql
SELECT pd.colaborador_id
FROM presenca_dia pd
WHERE pd.data_referencia IN (SELECT data FROM dias_uteis_q)
GROUP BY pd.colaborador_id
HAVING COUNT(DISTINCT pd.data_referencia) = (SELECT COUNT(*) FROM dias_uteis_q);
```

### 6.6. ALG-15 — Conflito entre ausência aprovada e presença

ConflitoAusPres ← AusAprov ⋈<sub>AusAprov.colab = EvAceite.colab ∧ AusAprov.início ≤ EvAceite.t_orig < AusAprov.fim</sub> EvAceite

Cada tuplo é uma ocorrência `conflito_ausencia` a resolver (RN-028, EX-05).

### 6.7. ALG-16 — Ausências sobrepostas

AusSobrep ← σ<sub>P1.id < P2.id ∧ sobrepõe(P1, P2)</sub>(ρ<sub>P1</sub>(AusAprov) ⋈<sub>P1.colab = P2.colab</sub> ρ<sub>P2</sub>(AusAprov))

A condição `P1.id < P2.id` evita pares repetidos e o par de um pedido consigo próprio (RN-028).

## 7. Pedidos, decisões e fecho

### 7.1. ALG-17 — Pedidos à espera de uma conta

PendDecisão(c) ← σ<sub>estado ∈ {'submetido', 'em_aprovacao'}</sub>(Pedido) ⋉<sub>Pedido.colab = D.colab</sub> ColabDesignado(c)

### 7.2. ALG-18 — Pendências impeditivas do fecho

Para o período `q` com unidade `u` e intervalo `[a, b)`, sendo UnidQ o fecho hierárquico de `u` (como em ALG-07) e ColabQ os colaboradores com associação a UnidQ vigente no intervalo:

P₁ ← π<sub>'evento', id</sub>(σ<sub>estado = 'pendente_analise' ∧ a ≤ t_orig < b</sub>(Evento) ⋉ ColabQ)

P₂ ← π<sub>'pedido', id</sub>(σ<sub>estado ∈ {'submetido', 'em_aprovacao'} ∧ sobrepõe(Pedido, [a, b))</sub>(Pedido) ⋉ ColabQ)

P₃ ← π<sub>'apuramento', id</sub>(σ<sub>estado = 'pendente'</sub>(ApurActual) ⋉ (JornQ ⋉ ColabQ))

Pendências(q) ← P₁ ∪ P₂ ∪ P₃

Impeditivas(q) ← Pendências(q) − Justificadas(q)

O fecho (EP-059) só é permitido se Impeditivas(q) = ∅ (RN-037). Justificadas(q) contém as pendências não impeditivas com justificação registada, conforme PN-09.

### 7.3. ALG-19 — Resultados incluídos num fecho

FechadosQ ← ApurActual ⋈ JornQ ⋉ ColabQ

O `hash` do fecho é calculado sobre FechadosQ ordenado de forma canónica. Depois do fecho, FechoApur regista exactamente estes tuplos, e nenhuma escrita posterior os altera (RI-14).

### 7.4. ALG-20 — Versão enviada ao ERP e pendências de reconciliação

ÚltimoFecho(q) ← σ<sub>período = q</sub>(Fecho) − π<sub>F1.*</sub>(ρ<sub>F1</sub>(Fecho) ⋈<sub>F1.período = F2.período ∧ F1.versão < F2.versão</sub> ρ<sub>F2</sub>(Fecho))

ColabEnviar ← π<sub>colab</sub>(σ<sub>fecho = ÚltimoFecho(q).id</sub>(FechoApur) ⋈<sub>FechoApur.apur = Apur.id</sub> Apur ⋈<sub>Apur.jornada = Jornada.id</sub> Jornada)

Usa-se Apur e não ApurActual porque o fecho referencia as versões exactas que foram fechadas.

ColabConfirm ← π<sub>colab</sub>(σ<sub>estado = 'confirmado'</sub>(ItemExec) ⋈<sub>ItemExec.exec = Exec.id</sub> σ<sub>fecho = ÚltimoFecho.id</sub>(Exec))

PorReconciliar(q) ← ColabEnviar − ColabConfirm

Um período só é apresentado como integrado se PorReconciliar(q) = ∅ (INT-13). Confirmações ligadas a versões anteriores não entram em ColabConfirm, pelo que uma reabertura volta a gerar pendências (RN-039).

## 8. Biometria e propagação

### 8.1. ALG-21 — Referências cuja eliminação pode ser concluída

EliPend ← σ<sub>estado = 'eliminacao_pendente'</sub>(RefBio)

DestPend ← σ<sub>operação = 'eliminar' ∧ estado ≠ 'confirmado'</sub>(Propag)

EliConcluível ← EliPend ▷<sub>EliPend.id = DestPend.objecto</sub> DestPend

Só as referências de EliConcluível podem passar a `eliminado` (BIO-22). Qualquer destino não confirmado mantém a referência pendente.

### 8.2. ALG-22 — Terminais com alterações por aplicar

TermPend ← π<sub>Dispositivo.id, operação</sub>(Dispositivo ⋈<sub>Dispositivo.id = Propag.destino</sub> σ<sub>estado = 'pendente'</sub>(Propag))

Alimenta EP-028 (para cada terminal) e a monitorização de RF-063.

### 8.3. ALG-23 — Colaboradores habilitados sem referência activa

HabAct ← σ<sub>estado = 'activa'</sub>(Habil)

RefAct ← σ<sub>estado = 'activo'</sub>(RefBio)

SemEnrollment ← π<sub>colab, modalidade</sub>(HabAct) − π<sub>colab, modalidade</sub>(RefAct)

### 8.4. ALG-24 — Referências activas sem habilitação

Utilização sem habilitação viola BIO-01:

RefSemHab ← π<sub>colab, modalidade</sub>(RefAct) − π<sub>colab, modalidade</sub>(HabAct)

RefSemHab tem de ser vazio; quando não o é, as referências devem ser suspensas (RN-043).

## 9. Restrições de integridade na forma algébrica

Cada restrição é uma expressão que tem de produzir ∅. Pode ser executada como verificação periódica ou como teste automático.

| ID | Restrição (09) | Expressão que deve ser vazia |
| --- | --- | --- |
| RIA-01 | RI-01 — mesmo tenant | σ<sub>E.tid ≠ C.tid</sub>(ρ<sub>E</sub>(Evento) ⋈<sub>E.colab = C.id</sub> ρ<sub>C</sub>(Colab)) — e análogas para cada chave estrangeira |
| RIA-02 | RI-02 — `uuid` único por tenant | σ<sub>n > 1</sub>(γ<sub>tid, uuid; COUNT(*)→n</sub>(Evento)) |
| RIA-03 | RI-03 — identificador de colaborador único | σ<sub>n > 1</sub>(γ<sub>tid, ident; COUNT(*)→n</sub>(Colab)) |
| RIA-04 | RI-04 — hierarquia sem ciclos | σ<sub>unidade = origem</sub>(Caminhos), em que Caminhos é o fecho transitivo de (id, pai) com a origem preservada |
| RIA-05 | RI-05 — vigências exclusivas | σ<sub>A1.id < A2.id ∧ sobrepõe(A1, A2)</sub>(ρ<sub>A1</sub>(AssocOrg) ⋈<sub>A1.colab = A2.colab</sub> ρ<sub>A2</sub>(AssocOrg)) |
| RIA-06 | RI-07 — `duplicado` exige referência | σ<sub>estado = 'duplicado' ∧ dup_de = nulo</sub>(Evento) |
| RIA-07 | RI-07 — o evento efectivo existe e está aceite | σ<sub>estado = 'duplicado'</sub>(Evento) ▷<sub>Evento.dup_de = EvAceite.id</sub> EvAceite |
| RIA-08 | RI-09 — uma decisão efectiva por versão | σ<sub>n > 1</sub>(γ<sub>pedido, versão_pedido; COUNT(*)→n</sub>(Decisão)) |
| RIA-09 | SDF-02 — segregação de funções | σ<sub>D.decisor = P.requerente ∨ K.colab = P.colab</sub>(ρ<sub>D</sub>(Decisão) ⋈<sub>D.pedido = P.id</sub> ρ<sub>P</sub>(Pedido) ⋈<sub>D.decisor = K.id</sub> ρ<sub>K</sub>(Conta)), enquanto não houver política de auto-aprovação |
| RIA-10 | RI-11 — ajuste com exactamente um alvo | σ<sub>(evento = nulo) = (apuramento = nulo)</sub>(Ajuste) |
| RIA-11 | RI-10 — sem apuramentos novos em período fechado | σ<sub>Apur.criado_em > F.criado_em</sub>(Apur ⋈<sub>Apur.jornada = JornQ.id</sub> JornQ × ρ<sub>F</sub>(ÚltimoFecho(q))), para cada período q em estado `fechado` |
| RIA-12 | RI-12 — eventos sem colaborador existente | σ<sub>colab ≠ nulo</sub>(Evento) ▷<sub>Evento.colab = Colab.id</sub> Colab |
| RIA-13 | BIO-01 | RefSemHab (ALG-24) |
| RIA-14 | AUD-06 — cadeia de auditoria | σ<sub>A2.hash_ant ≠ A1.hash</sub>(ρ<sub>A1</sub>(Audit) ⋈<sub>A1.tid = A2.tid ∧ A2.anterior = A1.id</sub> ρ<sub>A2</sub>(Audit)) |

RIA-04 e RIA-14 usam, respectivamente, fecho transitivo e a noção de "evento anterior", que a implementação representa com consulta recursiva e com uma referência explícita ao evento precedente.

## 10. Limitações e extensões

| Limitação da álgebra clássica | Extensão ou tratamento adoptado | SQL |
| --- | --- | --- |
| Sem agregação | γ (agrupamento e agregação) | `GROUP BY` |
| Sem ordenação | τ, usado apenas na apresentação; nenhuma regra depende da ordem física | `ORDER BY` |
| Sem fecho transitivo | Definição por ponto fixo (ALG-07, RIA-04) | `WITH RECURSIVE` |
| Semântica de conjuntos | As expressões assumem conjuntos; projecções que possam gerar duplicados em SQL usam `DISTINCT` | `SELECT DISTINCT` |
| Nulos | `fim = nulo` significa +∞; `t_liq = nulo` significa indeterminado e nunca é tratado como zero | Tipos `tstzrange` e `IS NULL` |
| Tempo e intervalos | `sobrepõe` e `vigente` como predicados | Operadores `&&` e `@>` sobre intervalos |

## 11. Utilização nos testes

1. Cada expressão ALG é implementada como consulta de referência, independente do código de produção, e executada sobre o conjunto de dados de teste do [Plano de Testes](21-Plano-de-Testes.md).
2. O resultado da funcionalidade (endpoint ou tarefa) é comparado com o da expressão. Uma divergência é um defeito da implementação ou uma ambiguidade da regra, a resolver na origem.
3. As restrições RIA-01 a RIA-14 são executadas após cada teste de integração e periodicamente em produção. Um resultado não vazio gera alerta (RF-064).
4. Os cenários EX-01 a EX-10 e CA-01 a CA-09 devem ter dados que exercitem pelo menos uma expressão cada.

## 12. Rastreabilidade

| Expressões | Requisitos | Regras | Outros |
| --- | --- | --- | --- |
| ALG-01, RIA-01 | RF-002 | RN-001 | TEN-01 a TEN-07, RI-01 |
| ALG-02, ALG-03, RIA-02, RIA-06, RIA-07 | RF-023, RF-026 | RN-010, RN-011 | MEC-02, EP-031, EP-032 |
| ALG-04, ALG-05, RIA-05 | RF-010, RF-014 | RN-006, RN-017 | MEC-04, PN-02 |
| ALG-06 a ALG-09 | RF-007, RF-051 | RN-002 | PERM, EP-005 |
| ALG-10 | RF-038 | RN-022 | FP-03 |
| ALG-11 a ALG-14 | RF-038 a RF-040, RF-052 | RN-023, RN-024 | MEC-06 |
| ALG-15, ALG-16 | RF-044 | RN-028 | EX-05 |
| ALG-17, RIA-08, RIA-09 | RF-043, RF-047 | RN-031, RN-035 | SDF-02 |
| ALG-18, ALG-19, RIA-11 | RF-048, RF-049 | RN-037, RN-038 | EP-058, EP-059 |
| ALG-20 | RF-058, RF-059 | RN-039, RN-041, RN-042 | INT-12, INT-13 |
| ALG-21 a ALG-24, RIA-13 | RF-036, RF-061 | RN-043, RN-047 | BIO-01, BIO-22 |
| RIA-14 | RF-060 | — | AUD-06 |

## 13. Decisões pendentes

| Decisão | Efeito |
| --- | --- |
| DT-12 | Nomes finais de relações e atributos |
| PN-02 | Margens Δ de associação de eventos a jornadas (ALG-05, ALG-10) |
| PN-09 | Composição de Justificadas(q) e pendências impeditivas (ALG-18) |
| DF-02 | Política de auto-aprovação (RIA-09) |
| DT-07 | Representação do evento anterior na cadeia de auditoria (RIA-14) |

## 14. Aprovação e referências

A equipa técnica valida notação, expressões e SQL equivalente; RH valida ALG-10 a ALG-14 e ALG-18 face aos exemplos de cálculo aprovados. Cada aprovação deve identificar nome, versão e data. Estado de aprovação desta versão: **pendente**.

- [Índice da documentação](README.MD).
- [Modelo de Dados](09-Modelo-de-Dados.md), [Regras de Negócio](04-Regras-de-Negocio.md), [TDD](08-Documento-de-Design-Tecnico-TDD.md), [Matriz de Permissões](15-Matriz-de-Permissoes-e-Acessos.md).
