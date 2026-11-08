# 32. Gestão de Versões e Change Management

**Referência:** CHG-ASS-001  
**Versão:** 0.1  
**Data:** 25/09/2026  
**Autor:** Manus AI


> **Estado:** Rascunho para validação. Este documento complementa os documentos 7 a 19 da série e deve ser aprovado pelos responsáveis indicados antes do piloto ou da entrada em produção.

## Versionamento
Usar versionamento semântico para APIs e componentes. Cada release deve ter changelog, commit/release identificável, artefactos imutáveis, migrações, compatibilidade, riscos e plano de rollback.

## Tipos de mudança
Mudanças normais passam por pedido, análise de impacto, revisão, testes, aprovação, janela, execução e validação. Mudanças urgentes podem seguir fluxo acelerado, mas exigem retrospectiva. Mudanças de emergência que afectem segurança, dados, permissões ou fecho devem ser registadas imediatamente.

## Impacto a avaliar
Tenant e autorização, API, base de dados, terminais, biometria, integrações ERP, desempenho, privacidade, auditoria, backup e manuais. Toda mudança deve indicar requisitos e testes afectados.

## Rollout
Preferir canário ou activação faseada por tenant. Monitorizar métricas e logs, confirmar reconciliação e manter capacidade de rollback. Alterações de políticas são versionadas com vigência e não alteram períodos fechados silenciosamente.
## Documentos relacionados

Consultar os documentos 7 a 19 da série e o índice geral para arquitectura, requisitos, dados, APIs, segurança, integrações e fluxos de processos.
