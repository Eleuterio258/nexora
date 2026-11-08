# 31. Gestão de Incidentes

**Referência:** INC-ASS-001  
**Versão:** 0.1  
**Data:** 25/09/2026  
**Autor:** Manus AI


> **Estado:** Rascunho para validação. Este documento complementa os documentos 7 a 19 da série e deve ser aprovado pelos responsáveis indicados antes do piloto ou da entrada em produção.

## Classificação
| Severidade | Exemplo | Resposta |
|---|---|---|
| P1 | Fuga entre tenants, indisponibilidade crítica ou perda de dados | Activação imediata, contenção e comunicação executiva |
| P2 | Falha generalizada de marcações, ERP ou biometria | Mitigação urgente e acompanhamento frequente |
| P3 | Degradação limitada, erro funcional ou terminal isolado | Tratamento no horário operacional |
| P4 | Dúvida, pedido ou melhoria sem impacto imediato | Backlog e suporte normal |

## Processo
Detectar, registar, classificar, conter, investigar, recuperar, validar e encerrar. O registo deve incluir impacto, tenants afectados, início, evidências, comandos executados, decisões, comunicações e causa provável.

## Incidentes de dados e segurança
Preservar logs e auditoria, revogar credenciais comprometidas, isolar componentes e envolver o responsável de protecção de dados. Não apagar evidências para “limpar” o incidente.

## Pós-incidente
Executar análise de causa raiz, definir ações preventivas, actualizar threat model, testes, runbooks e matriz de risco. O encerramento exige validação do proprietário do serviço.
## Documentos relacionados

Consultar os documentos 7 a 19 da série e o índice geral para arquitectura, requisitos, dados, APIs, segurança, integrações e fluxos de processos.
