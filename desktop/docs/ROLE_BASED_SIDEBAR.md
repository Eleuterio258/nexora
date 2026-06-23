# Sistema de Controle de Acesso por Role

## Visão Geral
A sidebar da aplicação filtra automaticamente os módulos visíveis baseado nas permissões do role do utilizador autenticado. O sistema agora inclui uma **interface gráfica completa** para gerir roles e permissões.

## ✨ Novidades na Versão 2.0

### Interface de Gestão de Roles
- ✅ **RoleListPanel**: Lista todos os roles com contagem de permissões
- ✅ **RoleFormDialog**: Criar/editar roles com campo de responsabilidades
- ✅ **RolePermissionDialog**: Interface gráfica para gerir permissões por recurso
- ✅ **Botão "Permissoes"**: Acesso directo na lista de roles

### Sistema de Permissões Granular
- ✅ Permissões de menu (`menu:*`)
- ✅ Permissões CRUD por módulo (`vendas:create`, `produtos:update`, etc.)
- ✅ Permissões especiais (`configuracoes:backup`, `roles:manage`)

## Como Funciona

### 1. Estrutura de Permissões

#### Tabela `permissions`
```sql
CREATE TABLE permissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT UNIQUE NOT NULL,        -- Ex: 'menu:vendas', 'vendas:create'
    recurso TEXT NOT NULL,            -- Ex: 'menu', 'vendas', 'produtos'
    acao TEXT NOT NULL,               -- Ex: 'view', 'create', 'update', 'delete'
    descricao TEXT
);
```

#### Formato das Permissões
- **Menu**: `menu:<modulo>` - Controla visibilidade na sidebar
  - `menu:dashboard`, `menu:pos`, `menu:vendas`, etc.
  
- **CRUD**: `<modulo>:<acao>` - Controla operações específicas
  - `vendas:create`, `vendas:update`, `vendas:delete`
  - `produtos:create`, `clientes:update`, etc.
  
- **Especiais**: Permissões administrativas
  - `roles:manage`, `configuracoes:backup`, `usuarios:create`

### 2. Filtragem da Sidebar
Cada botão da sidebar tem uma permissão associada:
```java
{"Dashboard", "📊", "menu:dashboard"},
{"POS", "🛒", "menu:pos"},
{"Vendas", "💰", "menu:vendas"},
// ... etc
```

O `SidebarPanel` verifica:
```java
boolean hasAccess = session.hasAnyPermission(requiredPermissions);
button.setVisible(hasAccess);
```

### 3. Roles Padrão

O sistema inclui 3 roles predefinidos:

#### **Administrador** (ID: 1)
- **Acesso**: Todos os módulos (14 menus + 30+ permissões CRUD)
- **Responsabilidades**: Controle total do sistema
- **Permissões**: Todas as permissões disponíveis

#### **Vendedor** (ID: 2)
- **Menus Visíveis**: 6 módulos (Dashboard, POS, Vendas, Clientes, Produtos, Stock)
- **Operações**: 
  - ✅ Criar vendas e gerar recibos
  - ✅ Criar novos clientes
  - ❌ Não pode eliminar ou atualizar vendas
- **Responsabilidades**: Realizar vendas, registrar clientes, consultar produtos

#### **Gerente de Stock** (ID: 3)
- **Menus Visíveis**: 5 módulos (Dashboard, Produtos, Stock, Compras, Fornecedores)
- **Operações**:
  - ✅ CRUD completo em produtos, stock, compras e fornecedores
  - ❌ Sem acesso a vendas, POS, clientes, configurações
- **Responsabilidades**: Gerir inventário e compras

## Como Usar a Interface

### Criar um Novo Role
1. Navegue para **Configurações → Roles** (requer `menu:roles`)
2. Clique em **"Novo"**
3. Preencha:
   - **Nome**: Identificador do role (ex: "Supervisor")
   - **Descrição**: Breve explicação
   - **Responsabilidades**: Detalhe o que o role pode fazer
4. Clique em **"Guardar"**

### Gerir Permissões de um Role
**Método 1 - Da Lista de Roles:**
1. Selecione o role na tabela
2. Clique em **"Permissoes"** (botão roxo)
3. Marque/desmarque as permissões desejadas
4. Clique em **"Guardar"**

**Método 2 - Do Formulário:**
1. Edite o role (duplo clique ou botão "Editar")
2. Clique em **"Gerir Permissoes"** no formulário
3. Configure as permissões
4. O diálogo fecha e volta ao formulário

### Interface de Permissões

#### Layout
```
┌─────────────────────────────────────────────┐
│  Configurar Permissoes                      │
│  Role: Vendedor                             │
├─────────────────────────────────────────────┤
│  ┌─ Acesso a Modulos ───────────────────┐  │
│  │ ☑ Dashboard   ☑ POS    ☑ Vendas      │  │
│  │ ☑ Clientes    ☑ Produtos ☐ Compras   │  │
│  │ ☐ Stock       ☐ Relatorios ☐ Config  │  │
│  └──────────────────────────────────────┘  │
│  ┌─ Vendas ─────────────────────────────┐  │
│  │ ☑ Criar vendas  ☐ Atualizar vendas   │  │
│  │ ☐ Eliminar vendas ☐ Cancelar vendas  │  │
│  │ ☑ Gerar recibos                      │  │
│  └──────────────────────────────────────┘  │
│  ┌─ Produtos ───────────────────────────┐  │
│  │ ☐ Criar produtos  ☐ Atualizar       │  │
│  │ ☐ Eliminar                           │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  [Selecionar Tudo] [Limpar Tudo]           │
│  [Guardar] [Cancelar]                      │
└─────────────────────────────────────────────┘
```

#### Funcionalidades
- **Agrupamento por Recurso**: Permissões organizadas por módulo
- **Selecionar Tudo**: Marca todas as permissões de uma vez
- **Limpar Tudo**: Remove todas as permissões
- **Persistência**: Sincronização automática com base de dados

## Gestão Técnica

### Criar Novo Role (SQL)
```sql
-- 1. Criar o role
INSERT INTO roles (tenant_id, nome, descricao, responsabilidades) 
VALUES (1, 'Supervisor', 'Supervisão de operações', 'Supervisionar vendas e equipas');

-- 2. Obter o ID gerado
SELECT LAST_INSERT_ROWID(); -- Ex: 4

-- 3. Associar permissões
INSERT INTO role_permissions (role_id, permission_id)
SELECT 4, id FROM permissions WHERE nome IN (
    'menu:dashboard', 'menu:vendas', 'menu:clientes',
    'vendas:update', 'vendas:cancel'
);
```

### Adicionar Nova Permissão
```sql
-- Inserir permissão
INSERT INTO permissions (nome, recurso, acao, descricao) 
VALUES ('vendas:export', 'vendas', 'export', 'Exportar vendas para Excel');

-- Associar a roles existentes
INSERT INTO role_permissions (role_id, permission_id)
SELECT role_id, (SELECT id FROM permissions WHERE nome = 'vendas:export')
FROM roles 
WHERE nome IN ('Administrador', 'Gerente');
```

### Verificar Permissões de um Utilizador
```sql
-- Listar todas as permissões de um utilizador
SELECT p.nome, p.recurso, p.acao, p.descricao
FROM users u
JOIN roles r ON u.role_id = r.id
JOIN role_permissions rp ON r.id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id
WHERE u.email = 'admin@factpro.local'
ORDER BY p.recurso, p.acao;
```

## Arquivos Modificados/Criados

### Models
- ✅ `Role.java` - Campo `responsabilidades` adicionado
- ✅ `Permission.java` - Model completo (já existia)

### DAOs
- ✅ `RoleDAO.java` - Suporte a responsabilidades + `findPermissionsByRoleId()`
- ✅ `PermissionDAO.java` - CRUD completo + gestão de permissões por role

### Session
- ✅ `SessionManager.java` - Carregamento de permissões no login
  - `getUserPermissions()`: Lista de permissões
  - `hasPermission(String)`: Verifica permissão específica
  - `hasAnyPermission(String...)`: Verifica múltiplas permissões

### UI - Gestão de Roles
- ✅ `RoleListPanel.java` - Botão "Permissoes" + contagem em tempo real
- ✅ `RoleFormDialog.java` - Campo responsabilidades + botão "Gerir Permissoes"
- ✅ `RolePermissionDialog.java` - **NOVO** Interface gráfica completa

### UI - Sidebar
- ✅ `SidebarPanel.java` - Filtragem por permissões
  - `refreshButtonVisibility()`: Atualiza visibilidade
  - Mapeamento de permissões por botão

- ✅ `MainFrame.java` - Refresh automático na inicialização

### Migrações
- ✅ `V18__add_responsabilidades_to_roles.sql` - Adiciona coluna
- ✅ `V19__insert_default_role_permissions.sql` - 44+ permissões + 3 roles

### Documentação
- ✅ `docs/ROLE_BASED_SIDEBAR.md` - Este ficheiro

## Testes

### Testar Roles Diferentes
1. **Criar utilizadores de teste**:
   ```sql
   -- Vendedor
   INSERT INTO users (tenant_id, role_id, nome, email, senha_hash)
   VALUES (1, 2, 'João Vendedor', 'vendedor@factpro.local', '$hash...');
   
   -- Gerente de Stock
   INSERT INTO users (tenant_id, role_id, nome, email, senha_hash)
   VALUES (1, 3, 'Maria Stock', 'stock@factpro.local', '$hash...');
   ```

2. **Fazer login com cada utilizador**
3. **Verificar**:
   - Apenas módulos autorizados aparecem na sidebar
   - Contagem de permissões correta na lista de roles
   - Ações não autorizadas falham silenciosamente

### Checklist de Testes
- [ ] Login como Admin → Todos os 10+ módulos visíveis
- [ ] Login como Vendedor → Apenas 6 módulos visíveis
- [ ] Login como Gerente Stock → Apenas 5 módulos visíveis
- [ ] Criar novo role → Aparece na lista
- [ ] Gerir permissões → Salva corretamente
- [ ] Modificar permissões em tempo real → Sidebar atualiza após re-login

## Notas Importantes

### Segurança
1. **Fallback**: Se o utilizador não tiver permissões configuradas, TODOS os botões serão exibidos
2. **Validação UI vs Backend**: Atualmente apenas a UI filtra - implementar validação backend é recomendado
3. **Performance**: Permissões carregadas uma vez no login (cache em memória)

### Boas Práticas
1. **Princípio do Menor Privilégio**: Comece com zero permissões e adicione conforme necessário
2. **Roles Específicos**: Crie roles para cada função (evite roles genéricos)
3. **Auditoria**: Monitore quais roles acessam quais módulos
4. **Testes**: Sempre teste com diferentes roles antes de deploy

### Limitações Atuais
- ⚠️ Sem validação backend de permissões (apenas UI)
- ⚠️ Sem notificação quando utilizador tenta acessar módulo não autorizado
- ⚠️ Permissões não atualizam em tempo real (requer re-login)

## Próximos Passos (Melhorias Futuras)

### Alta Prioridade 🔴
- [ ] **Validação Backend**: Interceptar ações não autorizadas no DAO/Service
- [ ] **Mensagem de Erro**: Feedback quando acesso é negado
- [ ] **Refresh em Tempo Real**: Atualizar permissões sem re-login
- [ ] **Auditoria de Acesso**: Log de tentativas de acesso não autorizado

### Média Prioridade 🟡
- [ ] **Permissões por Tenant**: Isolar permissões por organização
- [ ] **Templates de Roles**: Roles predefinidos para setores (restauração, retail, etc.)
- [ ] **Importar/Exportar Roles**: Backup de configuração de roles
- [ ] **Hierarquia de Roles**: Roles herdam permissões de outros roles

### Baixa Prioridade 🟢
- [ ] **Permissões Temporárias**: Acesso limitado por tempo
- [ ] **Aprovação de Ações**: Workflow para ações críticas
- [ ] **Dashboard de Permissões**: Visualização gráfica de quem tem acesso ao quê
- [ ] **Roles Dinâmicos**: Permissões baseadas em regras (horário, localização, etc.)

## Troubleshooting

### Sidebar mostra todos os módulos mesmo sem permissões
**Causa**: Utilizador não tem permissões configuradas (fallback).
**Solução**: Configure permissões pelo menos uma permissão para o role.

### Erro ao salvar permissões
**Causa**: Base de dados não atualizada com migrações.
**Solução**: Execute `V19__insert_default_role_permissions.sql`.

### Permissões não aparecem no diálogo
**Causa**: Tabela `permissions` vazia.
**Solução**: A migração V19 insere permissões automaticamente.

### Role não pode ser eliminado
**Causa**: Existem utilizadores associados ao role.
**Solução**: Reatribua os utilizadores para outro role antes de eliminar.

---

**Versão**: 2.0.0  
**Última Atualização**: 2026-04-12  
**Autor**: FactPro Team
