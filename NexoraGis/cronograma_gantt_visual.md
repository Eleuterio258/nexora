# Cronograma Visual — Módulo de Cadastro e Ordenamento Territorial

**Início:** 01 de setembro de 2026  
**Fim:** 30 de outubro de 2027  
**Duração total:** ~14 meses (incluindo suporte pós-implantação)

---

## Legenda

```text
[====]  Período de execução da fase
```

Cada símbolo `=` representa aproximadamente 1 semana.

---

## Cronograma por Fase

```text
Fase                                      Set Out Nov Dez Jan Fev Mar Abr Mai Jun Jul Ago Set Out
                                          2026                    2027
Fase 1 — Fundacao e Infraestrutura        [====]
Fase 2 — Estrutura Territorial e Projetos       [==]
Fase 3 — Cadastro Territorial                       [======]
Fase 4 — Campo e Sincronizacao                              [=====]
Fase 5 — Plano, Zoneamento e Analise                                [======]
Fase 6 — Workflow, Auditoria e Versionamento                                  [===]
Fase 7 — Publicacao e WebGIS                                                     [=====]
Fase 8 — Relatorios, Dashboard e Fiscalizacao                                           [=====]
Fase 9 — Integracoes e Performance                                                            [====]
Fase 10 — Testes, Documentacao e Entrega                                                           [=====]
Suporte Pos-Implantacao                                                                                  [===]
```

---

## Cronograma Detalhado por Épico

```text
Épico / Área                              Set Out Nov Dez Jan Fev Mar Abr Mai Jun Jul Ago Set Out
                                          2026                    2027
AMBIENTE
  Repositorio + Docker + CI/CD            [===]
  Logging e monitoramento                 [=]

BASE DE DADOS
  Schema PostGIS                          [===]
  EF Core + Migrations                    [====]
  Seeds Mocambique                        [==]
  Views e funcoes espaciais               [==]

AUTENTICACAO E AUTORIZACAO
  JWT e Identity                          [===]
  RBAC e permissoes                       [===]
  Multi-tenant                            [==]

ESTRUTURA TERRITORIAL
  CRUD divisoes administrativas                 [===]
  Hierarquia recursiva                          [==]
  Importacao de limites                         [===]
  Visualizacao WebGIS                           [==]

GESTAO DE PROJETOS
  CRUD projetos                                 [===]
  Equipa e workflow                             [===]

CADASTRO
  Parcelas                                          [=======]
  Edificacoes e lotes                                   [===]
  Entidades e proprietarios                               [====]
  Infraestruturas e equipamentos                                [======]

CAMPO E SINC
  App Android / Flutter                                       [=========]
  Sincronizacao offline/API                                             [====]
  GNSS/RTK e Drones                                                       [===]

PLANO E ANALISE
  Planos e versoes                                                              [==]
  Zoneamento                                                                      [====]
  Analise espacial                                                                    [====]
  Motor de conflitos                                                                      [===]

WORKFLOW E AUDITORIA
  Aprovacao                                                                                   [===]
  Versionamento e auditoria                                                                     [====]

PUBLICACAO E WEBGIS
  GeoServer                                                                                           [===]
  WebGIS Tecnico                                                                                          [=====]
  WebGIS Publico                                                                                              [===]

RELATORIOS E FISCALIZACAO
  Dashboard e relatorios                                                                                          [=====]
  Fiscalizacao                                                                                                          [====]

INTEGRACOES E PERFORMANCE
  Import/Export                                                                                                               [====]
  APIs externas                                                                                                                   [===]
  Otimizacao                                                                                                                          [===]

TESTES E ENTREGA
  QA e testes                                                                                                                             [=====]
  Documentacao                                                                                                                                [====]
  Producao e treino                                                                                                                               [====]
```

---

## Marcos Principais

| Marco | Data | Descrição |
|-------|------|-----------|
| M1 | 22/09/2026 | Ambiente e base de dados prontos |
| M2 | 15/10/2026 | Estrutura territorial e projetos operacionais |
| M3 | 16/12/2026 | Cadastro territorial funcional |
| M4 | 28/01/2027 | App de campo e sincronização funcionando |
| M5 | 17/03/2027 | Plano, zoneamento e motor de conflitos |
| M6 | 16/04/2027 | Workflow de aprovação e auditoria |
| M7 | 27/05/2027 | WebGIS técnico e público publicados |
| M8 | 20/07/2027 | Dashboard, relatórios e fiscalização |
| M9 | 31/08/2027 | Integrações e otimização |
| M10 | 15/10/2027 | Sistema em produção |
| M11 | 30/10/2027 | Fim do período de suporte pós-implantação |

---

## Ficheiro Excel/Google Sheets

Para uma versão interativa com gráfico de Gantt, abrir o ficheiro **`cronograma_gantt.csv`** no Excel ou Google Sheets:

1. Selecionar as colunas `Inicio` e `Fim`.
2. Inserir gráfico de barras empilhadas ou usar template de Gantt.
3. Ajustar escala temporal por semanas.

---

## Notas

- As datas consideram uma equipa de 5–7 elementos a tempo inteiro.
- Fins de semana e feriados não foram descontados nas durações.
- Tarefas críticas estão sequenciadas; outras podem ser paralelizadas conforme recursos.
