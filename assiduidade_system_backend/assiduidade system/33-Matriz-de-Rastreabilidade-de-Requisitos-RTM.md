# 33. Matriz de Rastreabilidade de Requisitos (RTM)

**Referência:** RTM-ASS-001  
**Versão:** 0.1  
**Data:** 25/09/2026  
**Autor:** Manus AI


> **Estado:** Rascunho para validação. Este documento complementa os documentos 7 a 19 da série e deve ser aprovado pelos responsáveis indicados antes do piloto ou da entrada em produção.

## Objectivo
Demonstrar a ligação entre necessidade de negócio, requisito, regra, caso de uso, componente, API, teste e evidência de aceite.

| Origem | Requisito/caso | Componente/documento | Evidência |
|---|---|---|---|
| BR-01 | RF-002, RN-001/002 | Multi-Tenant, IAM, Modelo de Dados | Testes negativos A-001 a A-010 |
| BR-04 | RF-032 a RF-037, RN-043/045 | Reconhecimento Facial | Ensaio biométrico B-001 a B-008 |
| BR-06 | RF-025/026, RN-013/014 | Dispositivos, APIs, Fluxos | E2E O-001 a O-006 |
| BR-07 | RF-038/039, RN-017/024 | Motor de Apuramento | Cálculo funcional C-001 a C-012 |
| BR-10 | RF-048 a RF-050, RN-037/039 | Fecho e TDD | Concorrência F-001 a F-005 |
| BR-13 | RF-057 a RF-059, RN-040/042 | Integrações | Reconciliação I-001 a I-008 |
| BR-14/15 | RF-060 a RF-062, RNF-020/029 | Auditoria e Segurança | Segurança S-001 a S-015 |

## Gestão da matriz
A RTM deve ser mantida em cada release. Requisitos sem teste, teste sem requisito ou evidência sem responsável são pendências de aceite. A matriz final deve incluir todos os RF-001 a RF-065, RNF e RN aplicáveis.
## Documentos relacionados

Consultar os documentos 7 a 19 da série e o índice geral para arquitectura, requisitos, dados, APIs, segurança, integrações e fluxos de processos.
