# ERP - Funcionalidades do Super Admin

## 1. Visão Geral

O Super Admin é o utilizador com o nível máximo de acesso na plataforma. É responsável pela gestão global do sistema, dos tenants, dos módulos e das configurações da plataforma.

---

## 2. Gestão de Tenants

### Funcionalidades

* Criar tenant
* Editar tenant
* Suspender tenant
* Reativar tenant
* Eliminar tenant
* Configurar domínio personalizado
* Configurar plano de subscrição
* Configurar limites de utilização

### Ações

| Ação | Descrição |
|---|---|
| Criar tenant | Regista um novo tenant na plataforma |
| Editar tenant | Atualiza dados e configurações do tenant |
| Suspender tenant | Bloqueia temporariamente o acesso |
| Reativar tenant | Restaura o acesso suspenso |
| Eliminar tenant | Remove permanentemente o tenant |
| Configurar domínio personalizado | Define o subdomínio ou domínio próprio |
| Configurar plano de subscrição | Associa o tenant a um plano tarifário |
| Configurar limites de utilização | Define quotas de utilizadores e recursos |

---

## 3. Gestão de Utilizadores

### Funcionalidades

* Criar utilizador
* Editar utilizador
* Bloquear utilizador
* Desbloquear utilizador
* Repor palavra-passe
* Ativar MFA
* Desativar MFA

### Ações

| Ação | Descrição |
|---|---|
| Criar utilizador | Adiciona novo utilizador ao sistema |
| Editar utilizador | Atualiza dados e perfil do utilizador |
| Bloquear utilizador | Impede o acesso temporariamente |
| Desbloquear utilizador | Restaura o acesso bloqueado |
| Repor palavra-passe | Envia link de redefinição de credenciais |
| Ativar MFA | Habilita autenticação multifator |
| Desativar MFA | Remove a autenticação multifator |

---

## 4. Gestão de Módulos

### Funcionalidades

* Criar módulo
* Editar módulo
* Ativar módulo
* Desativar módulo
* Associar módulo a plano
* Definir dependências entre módulos

### Ações

| Ação | Descrição |
|---|---|
| Criar módulo | Define um novo módulo no sistema |
| Editar módulo | Atualiza metadados e configurações |
| Ativar módulo | Torna o módulo disponível para tenants |
| Desativar módulo | Oculta o módulo sem o eliminar |
| Associar módulo a plano | Vincula o módulo a um plano tarifário |
| Definir dependências | Configura pré-requisitos entre módulos |

---

## 5. Gestão de Funcionalidades

### Funcionalidades

* Criar funcionalidade
* Editar funcionalidade
* Eliminar funcionalidade
* Definir código da funcionalidade
* Associar funcionalidade a módulo

### Ações

| Ação | Descrição |
|---|---|
| Criar funcionalidade | Regista uma nova feature no sistema |
| Editar funcionalidade | Atualiza nome, código ou módulo pai |
| Eliminar funcionalidade | Remove a feature definitivamente |
| Definir código | Atribui identificador único à funcionalidade |
| Associar a módulo | Vincula a funcionalidade ao módulo correto |

---

## 6. Gestão de Perfis

### Funcionalidades

* Criar perfil
* Editar perfil
* Eliminar perfil
* Duplicar perfil
* Associar permissões ao perfil

### Ações

| Ação | Descrição |
|---|---|
| Criar perfil | Define um novo perfil de acesso |
| Editar perfil | Atualiza nome e permissões associadas |
| Eliminar perfil | Remove o perfil do sistema |
| Duplicar perfil | Clona um perfil existente como base |
| Associar permissões | Define as permissões do perfil por módulo |

### Perfis padrão

| Perfil | Âmbito |
|---|---|
| Super Admin | Acesso total à plataforma |
| Tenant Admin | Administração completa do tenant |
| Gestor | Gestão operacional e aprovações |
| Operador | Criação e edição de registos |
| Consulta | Apenas leitura |

---

## 7. Gestão de Permissões

### Tipos de Permissões

| Permissão | Descrição |
|---|---|
| Visualizar | Leitura de registos e relatórios |
| Criar | Adição de novos registos |
| Editar | Alteração de registos existentes |
| Eliminar | Remoção de registos |
| Aprovar | Validação de fluxos de trabalho |
| Exportar | Download de dados em ficheiro |
| Importar | Upload e carregamento de dados |
| Administrar | Configurações avançadas do módulo |

### Estrutura

```
Tenant → Módulo → Funcionalidade → Permissão
```

---

## 8. Gestão de Planos

### Funcionalidades

* Criar plano
* Editar plano
* Desativar plano
* Definir preço
* Definir módulos incluídos
* Definir limites de utilizadores

### Ações

| Ação | Descrição |
|---|---|
| Criar plano | Define um novo plano tarifário |
| Editar plano | Atualiza preço, módulos e limites |
| Desativar plano | Torna o plano indisponível para novos tenants |
| Definir preço | Configura valor mensal/anual |
| Definir módulos incluídos | Seleciona os módulos do plano |
| Definir limites de utilizadores | Define o número máximo de contas por tenant |

---

## 9. Auditoria

### Funcionalidades

* Consultar logs
* Consultar histórico de alterações
* Consultar histórico de login
* Exportar auditorias

### Ações

| Ação | Descrição |
|---|---|
| Consultar logs | Visualiza registos de atividade do sistema |
| Histórico de alterações | Rastreia modificações por entidade |
| Histórico de login | Registo de acessos e tentativas falhadas |
| Exportar auditorias | Download de relatórios de auditoria |

---

## 10. Segurança

### Funcionalidades

* Gestão de MFA
* Gestão de sessões
* Gestão de políticas de palavra-passe
* Gestão de bloqueios automáticos

---

## 11. Monitorização

### Indicadores

* Total de tenants
* Total de utilizadores
* Utilização por módulo
* Estado dos serviços
* Consumo de recursos

---

## 12. Backup e Recuperação

### Funcionalidades

* Backup manual
* Backup automático
* Restaurar backup
* Agendar backups

---

## 13. Configurações Globais

### Funcionalidades

* Idiomas
* Moedas
* Fusos horários
* SMTP
* SMS Gateway
* Integrações API

---

## 14. Hierarquia de Acesso

1. Super Admin
2. Tenant Admin
3. Gestor
4. Supervisor
5. Operador
6. Consulta

---

## Notas de Implementação (Nexora ERP)

> Esta secção reflete o estado atual do projeto Nexora e deve ser atualizada conforme a implementação avança.

### Estado atual

- O backend Go reconhece apenas dois tipos de utilizador: `superadmin` e `funcionario`.
- O `superadmin` tem bypass total no middleware de permissões.
- Não existe ainda um tipo `tenant_admin` nem `admin` na tabela `auth.users`.
- O schema `autorizacao.*` existe mas não é usado pelo middleware nem pelo frontend.
- Não existe ainda gestão de tenants, planos, funcionalidades ou módulos dinâmicos.

### Gaps a implementar

| Funcionalidade | Estado |
|---|---|
| Gestão de tenants | ❌ Não implementado |
| Gestão de planos | ❌ Não implementado |
| Gestão de módulos dinâmicos | ❌ Não implementado |
| Gestão de funcionalidades | ❌ Não implementado |
| Perfis RBAC avançados | ⚠️ Parcial (cargos + permissões) |
| MFA | ⚠️ A verificar |
| Auditoria global | ⚠️ Parcial (audit-logs existem) |
| Backup/Recuperação | ❌ Não implementado |
| Configurações globais | ⚠️ Parcial |

### Recomendação

Antes de implementar a maioria destas funcionalidades, é necessário:

1. Definir se a Nexora será multi-tenant na mesma base de dados ou por instância.
2. Criar o tipo `tenant_admin` (ou `admin`) com permissões fixas ou via `auth.permissoes_tipo`.
3. Limpar/decidir o destino do schema legado `autorizacao.*`.
4. Criar tabelas de planos, tenants e módulos ativos por tenant.
5. Implementar as APIs de gestão de tenants com proteção de `superadmin`.
