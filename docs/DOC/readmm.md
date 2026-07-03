# ERP – Funcionalidades do Super Admin

## Índice

1. [Visão Geral](#1-visão-geral)
2. [Gestão de Tenants](#2-gestão-de-tenants)
3. [Gestão de Utilizadores](#3-gestão-de-utilizadores)
4. [Gestão de Módulos](#4-gestão-de-módulos)
5. [Gestão de Funcionalidades](#5-gestão-de-funcionalidades)
6. [Gestão de Perfis](#6-gestão-de-perfis)
7. [Gestão de Permissões](#7-gestão-de-permissões)
8. [Gestão de Planos](#8-gestão-de-planos)
9. [Auditoria](#9-auditoria)
10. [Segurança](#10-segurança)
11. [Monitorização](#11-monitorização)
12. [Backup e Recuperação](#12-backup-e-recuperação)

---

## 1. Visão Geral

O Super Admin é o utilizador com o nível máximo de acesso na plataforma. É responsável pela gestão global do sistema, dos tenants, dos módulos e das configurações da plataforma.

---

## 2. Gestão de Tenants

| Ação | Descrição |
| ---- | --------- |
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

| Ação | Descrição |
| ---- | --------- |
| Criar utilizador | Adiciona novo utilizador ao sistema |
| Editar utilizador | Atualiza dados e perfil do utilizador |
| Bloquear utilizador | Impede o acesso temporariamente |
| Desbloquear utilizador | Restaura o acesso bloqueado |
| Repor palavra-passe | Envia link de redefinição de credenciais |
| Ativar MFA | Habilita autenticação multifator |
| Desativar MFA | Remove a autenticação multifator |

---

## 4. Gestão de Módulos

| Ação | Descrição |
| ---- | --------- |
| Criar módulo | Define um novo módulo no sistema |
| Editar módulo | Atualiza metadados e configurações |
| Ativar módulo | Torna o módulo disponível para tenants |
| Desativar módulo | Oculta o módulo sem o eliminar |
| Associar módulo a plano | Vincula o módulo a um plano tarifário |
| Definir dependências | Configura pré-requisitos entre módulos |

---

## 5. Gestão de Funcionalidades

| Ação | Descrição |
| ---- | --------- |
| Criar funcionalidade | Regista uma nova feature no sistema |
| Editar funcionalidade | Atualiza nome, código ou módulo pai |
| Eliminar funcionalidade | Remove a feature definitivamente |
| Definir código | Atribui identificador único à funcionalidade |
| Associar a módulo | Vincula a funcionalidade ao módulo correto |

---

## 6. Gestão de Perfis

### Ações disponíveis

| Ação | Descrição |
| ---- | --------- |
| Criar perfil | Define um novo perfil de acesso |
| Editar perfil | Atualiza nome e permissões associadas |
| Eliminar perfil | Remove o perfil do sistema |
| Duplicar perfil | Clona um perfil existente como base |
| Associar permissões | Define as permissões do perfil por módulo |

### Perfis padrão do sistema

| Perfil | Âmbito |
| ------ | ------ |
| Super Admin | Acesso total à plataforma |
| Tenant Admin | Administração completa do tenant |
| Gestor | Gestão operacional e aprovações |
| Operador | Criação e edição de registos |
| Consulta | Apenas leitura |

---

## 7. Gestão de Permissões

### Tipos de permissão

| Permissão | Descrição |
| --------- | --------- |
| Visualizar | Leitura de registos e relatórios |
| Criar | Adição de novos registos |
| Editar | Alteração de registos existentes |
| Eliminar | Remoção de registos |
| Aprovar | Validação de fluxos de trabalho |
| Exportar | Download de dados em ficheiro |
| Importar | Upload e carregamento de dados |
| Administrar | Configurações avançadas do módulo |

### Hierarquia de permissões

```
Tenant → Módulo → Funcionalidade → Permissão
```

---

## 8. Gestão de Planos

| Ação | Descrição |
| ---- | --------- |
| Criar plano | Define um novo plano tarifário |
| Editar plano | Atualiza preço, módulos e limites |
| Desativar plano | Torna o plano indisponível para novos tenants |
| Definir preço | Configura valor mensal/anual |
| Definir módulos incluídos | Seleciona os módulos do plano |
| Definir limites de utilizadores | Define o número máximo de contas por tenant |

---

## 9. Auditoria

| Ação | Descrição |
| ---- | --------- |
| Consultar logs | Visualiza registos de atividade do sistema |
| Histórico de alterações | Rastreia modificações por entidade |
| Histórico de login | Registo de acessos e tentativas falhadas |
| Exportar auditorias | Download de relatórios de auditoria |

---

## 10. Segurança

| Funcionalidade | Descrição |
| -------------- | --------- |
| Gestão de MFA | Configuração global de autenticação multifator |
| Gestão de sessões | Controlo de sessões ativas e expiração |
| Políticas de palavra-passe | Define complexidade, expiração e histórico |
| Bloqueios automáticos | Regras de bloqueio por tentativas falhadas |

---

## 11. Monitorização

| Indicador | Descrição |
| --------- | --------- |
| Total de tenants | Número de tenants ativos e suspensos |
| Total de utilizadores | Contagem global por estado |
| Utilização por módulo | Adoção de módulos entre tenants |
| Estado dos serviços | Disponibilidade de componentes do sistema |
| Consumo de recursos | CPU, memória, armazenamento e requests |
