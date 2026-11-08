# 34. Glossário Técnico

**Referência:** GLO-ASS-001  
**Versão:** 0.1  
**Data:** 25/09/2026  
**Autor:** Manus AI


> **Estado:** Rascunho para validação. Este documento complementa os documentos 7 a 19 da série e deve ser aprovado pelos responsáveis indicados antes do piloto ou da entrada em produção.

| Termo | Definição |
|---|---|
| Apuramento | Resultado versionado da aplicação de regras a eventos, ajustes e ausências. |
| Auditoria | Evidência protegida de uma operação, actor, objecto e resultado. |
| Biometric template | Representação técnica derivada de características biométricas; não é uma imagem facial. |
| Event sourcing | Preservação de eventos de origem para reconstruir estados e decisões. |
| FAR/FRR | Taxas de falsa aceitação e falsa rejeição biométrica. |
| Idempotência | Propriedade de repetir uma operação sem duplicar o efeito. |
| Liveness | Prova de presença de uma pessoa real perante o sensor. |
| P95 | Percentil abaixo do qual estão 95% das medições. |
| RPO | Perda temporal máxima de dados admissível após recuperação. |
| RTO | Tempo máximo entre interrupção e serviço recuperado e validado. |
| Tenant | Organização isolada em dados, autorização e operação. |
| Vigência | Intervalo temporal em que uma associação ou política é válida. |
| Período fechado | Período cuja versão aprovada está protegida contra alterações directas. |
| Offline | Operação local sem ligação disponível ao serviço central. |
| Reconciliação | Comparação de eventos, totais, versões e estados entre sistemas. |
| RBAC | Controlo de acesso baseado em cargos. No sistema, cada cargo é um conjunto de permissões granulares `módulo:acção` composto pelo tenant. |
| Permissão | Código `módulo:acção` verificado pelo servidor em cada operação (por exemplo `assiduidade:aprovar_correcao`). |
| Cargo | Conjunto de permissões definido por cada tenant e atribuído à vinculação de uma conta; não há cargos obrigatórios. |
| Competência | Ter a permissão exigida e o colaborador no âmbito do utilizador; condição de qualquer decisão. |
| Âmbito | Conjunto de colaboradores sobre os quais uma permissão actua: próprio, hierárquico (unidades de que o utilizador é responsável e descendentes) ou global no tenant. |
| MFA | Autenticação multifactor. |
| ERP | Sistema empresarial externo que recebe ou fornece dados contratados. |
## Documentos relacionados

Consultar os documentos 7 a 19 da série e o índice geral para arquitectura, requisitos, dados, APIs, segurança, integrações e fluxos de processos.
