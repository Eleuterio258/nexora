# Resumo — Integração Recrutamento → RH

Este documento resume as cinco fases de implementação do botão **Contratar** no pipeline de recrutamento, que transforma um candidato aprovado num funcionário RH integrado com os restantes módulos do ERP.

## Fases

| Fase | Foco | Documento |
|---|---|---|
| 1 | Contratação atómica (handler, transação, funcionário, contrato) | [Fase 1](recrutamento_rh_fase1.md) |
| 2 | Cópia de documentos e contactos de emergência | [Fase 2](recrutamento_rh_fase2.md) |
| 3 | Conformidade legal de Moçambique e auditoria | [Fase 3](recrutamento_rh_fase3.md) |
| 4 | Integração com Gestão Escolar (criação de professor) | [Fase 4](recrutamento_rh_fase4.md) |
| 5 | Notificações automáticas e permissão granular | [Fase 5](recrutamento_rh_fase5.md) |

## Endpoint principal

```http
POST /api/recrutamento/candidaturas/{id}/contratar
```

## Permissão necessária

- `recrutamento.contratar` (preferencial)
- `recrutamento.gerir_candidaturas` (compatibilidade retroativa)

## Fluxo simplificado

1. Validar candidatura aprovada e consentimento de dados.
2. Validar requisitos legais (idade, estrangeiro, HIV/SIDA).
3. Resolver/criar conta `auth.users`.
4. Gerar número de funcionário.
5. Criar funcionário em `rh.funcionarios` e contrato em `rh.contratos`.
6. Copiar CV, carta e exame médico para `rh.documentos_funcionario`.
7. Criar contactos de emergência.
8. Criar professor em `gestao_escolar.school_teachers` (opcional).
9. Marcar candidatura como `contratado`.
10. Notificar candidato (email/SMS/push).
11. Registar auditoria.

## Módulos ERP envolvidos

- `recrutamento`
- `rh`
- `auth`
- `auditoria`
- `gestao_escolar` (quando `criar_professor=true`)
- `notifications`

## Build e testes

```bash
go build ./...
go test ./...
```

Ambos os comandos executam com sucesso.
