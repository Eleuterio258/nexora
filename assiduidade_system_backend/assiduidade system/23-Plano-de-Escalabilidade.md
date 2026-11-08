# 23. Plano de Escalabilidade

**Referência:** ESC-ASS-001  
**Versão:** 0.1  
**Data:** 25/09/2026  
**Autor:** Manus AI


> **Estado:** Rascunho para validação. Este documento complementa os documentos 7 a 19 da série e deve ser aprovado pelos responsáveis indicados antes do piloto ou da entrada em produção.

## Objectivo
Suportar o crescimento de tenants, colaboradores, terminais, eventos e relatórios sem alterar os contratos de negócio nem degradar os percursos críticos.

## Estratégia
A API e os workers devem escalar horizontalmente. O processamento de eventos e integrações deve usar filas particionadas por tenant ou chave de ordenação. Leituras pesadas usam réplicas, cache com isolamento e modelos de consulta derivados. Eventos históricos podem ser particionados por tenant e período.

## Limites a medir
| Dimensão | Métrica necessária |
|---|---|
| Tenants | quantidade, distribuição e crescimento mensal |
| Eventos | pico por segundo e concentração em mudanças de turno |
| Terminais | conexões, lote offline e reconexões simultâneas |
| Relatórios | linhas, intervalo, concorrência e duração |
| Dados | crescimento da base, anexos, auditoria e backups |

## Protecção contra saturação
Rate limits, quotas por tenant, filas com backpressure e circuit breakers devem impedir que um tenant prejudique os restantes. O sistema deve rejeitar ou atrasar explicitamente cargas excedentes, nunca perder dados silenciosamente.

## Ensaios
Devem ser realizados testes de carga, stress, soak e recuperação, com tenants pequenos e grandes, relatórios concorrentes, reconexão de terminais e períodos de fecho.
## Documentos relacionados

Consultar os documentos 7 a 19 da série e o índice geral para arquitectura, requisitos, dados, APIs, segurança, integrações e fluxos de processos.
