# 27. Manual do Administrador

**Referência:** MADM-ASS-001  
**Versão:** 0.1  
**Data:** 25/09/2026  
**Autor:** Manus AI


> **Estado:** Rascunho para validação. Este documento complementa os documentos 7 a 19 da série e deve ser aprovado pelos responsáveis indicados antes do piloto ou da entrada em produção.

## Responsabilidades
Quem administra o tenant — ou seja, quem tem as permissões de configuração, `autorizacao:gerir_utilizadores` e `autorizacao:gerir_perfis` — configura organização, utilizadores, cargos, colaboradores, horários, dispositivos, métodos de marcação, políticas e integrações autorizadas. Não pode aceder a outro tenant nem conceder a si próprio uma competência não prevista.

## Configuração inicial
1. Confirmar fuso, idioma e identificação do tenant.  
2. Criar unidades, locais, departamentos e equipas.  
3. Compor os cargos a partir do catálogo de permissões ([Requisitos Funcionais §3.2](02-Requisitos-Funcionais.md)), atribuí-los às contas, acrescentar permissões directas quando necessário e definir os responsáveis de unidade (âmbito hierárquico).  
4. Importar e reconciliar colaboradores.  
5. Configurar calendários, horários e políticas versionadas.  
6. Registar terminais e distribuir configuração.  
7. Executar cenários de marcação, offline e apuramento.

## Controlo de alterações
Alterações de permissões, biometria, políticas, terminais e integrações devem possuir motivo, autor, vigência e auditoria. Períodos fechados não são alterados directamente.

## Segurança operacional
Revogar imediatamente contas, dispositivos ou credenciais comprometidos. Não guardar segredos em folhas de cálculo. Rever acessos periodicamente e verificar terminais sem sincronização, filas de integração e pendências de retenção.
## Documentos relacionados

Consultar os documentos 7 a 19 da série e o índice geral para arquitectura, requisitos, dados, APIs, segurança, integrações e fluxos de processos.
