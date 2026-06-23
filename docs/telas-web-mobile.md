# Nexora ERP — Especificação de Telas Web e Mobile

No `nexora ERP`, os módulos **core transversais** são:

1. `empresas`  
   Gestão de tenants/empresas, base multiempresa do ERP.

2. `autenticacao`  
   Login, identidade, sessões, credenciais.

3. `autorizacao`  
   Perfis, papéis, permissões e controlo de acesso.

4. `utilizadores`  
   Gestão dos utilizadores ligados ao sistema.

5. `auditoria`  
   Registo de eventos, ações dos usuários e rastreabilidade.

6. `sistema-configuracao`  
   Configurações globais do ERP, parâmetros base e suporte a definições gerais.

O documento também marca `seguranca` como **descontinuado**, substituído por:

- `autenticacao`
- `autorizacao`
- `auditoria`

Para um ERP funcionar de forma mínima e organizada, eu consideraria este núcleo obrigatório:

```text
empresas
autenticacao
autorizacao
utilizadores
auditoria
sistema-configuracao
```

Depois disso entram os módulos de negócio, como `gestao-clientes`, `gestao-produtos`, `modulo-faturacao`, `financeiro`, `tesouraria` e `contabilidade`.

A análise do `nexora ERP` mostra que o sistema tem **3 níveis de core**, não apenas um.

**1. Core Transversal Obrigatório**

Estes módulos são a base técnica do ERP. Sem eles, os outros módulos ficam sem tenant, login, permissões ou rastreabilidade.

```text
empresas
autenticacao
autorizacao
utilizadores
auditoria
sistema-configuracao
```

Função de cada um:

| Módulo | Papel |
|---|---|
| `empresas` | Base multiempresa/multitenant. Tudo depende do `tenant_id`. |
| `autenticacao` | Contas, login, sessões, API keys, recuperação de senha. |
| `autorizacao` | Roles, permissões e controlo de acesso. |
| `utilizadores` | Gestão dos utilizadores ligados às contas do sistema. |
| `auditoria` | Log de ações de todos os módulos. |
| `sistema-configuracao` | Configurações globais, moedas, países, templates, integrações e logs. |

O módulo `seguranca` deve ser tratado como antigo/descontinuado, porque foi dividido corretamente em:

```text
autenticacao
autorizacao
auditoria
```

**2. Core de Negócio Comercial**

Estes não são “core técnico”, mas são obrigatórios para o ERP vender, faturar e controlar produtos/clientes.

```text
gestao-clientes
gestao-produtos
gestao-stock
modulo-faturacao
```

Dependência principal:

```text
gestao-clientes
gestao-produtos -> gestao-stock
gestao-clientes + gestao-produtos + gestao-stock -> modulo-faturacao
```

Ou seja:

- `gestao-clientes` é dono dos dados dos clientes.
- `gestao-produtos` é dono dos produtos, categorias, preços, unidades e marcas.
- `gestao-stock` é dono dos movimentos e saldos de inventário.
- `modulo-faturacao` é dono dos documentos comerciais: orçamento, encomenda, guia, fatura, recibo, nota de crédito e devolução.

Para um ERP de faturação, estes quatro módulos são praticamente o **core funcional**.

**3. Core Financeiro**

Depois da faturação, entram os módulos que fecham o ciclo financeiro e contabilístico.

```text
tesouraria
financeiro
contabilidade
```

Papel de cada um:

| Módulo | Papel |
|---|---|
| `tesouraria` | Caixa, bancos, saldos, reconciliação e extratos. |
| `financeiro` | Contas a receber, contas a pagar, pagamentos, recebimentos e fluxo de caixa. |
| `contabilidade` | Plano de contas, lançamentos, balancetes, demonstrações e encerramento. |

Relação:

```text
modulo-faturacao -> financeiro -> tesouraria
modulo-faturacao -> contabilidade
financeiro -> contabilidade
```

Na prática:

- Ao emitir fatura, cria conta a receber no `financeiro`.
- Ao receber pagamento, movimenta `tesouraria`.
- Ao faturar/pagar/receber, gera lançamentos na `contabilidade`.

**Ordem Recomendada de Implementação**

A ordem mais segura seria:

```text
1. empresas
2. autenticacao
3. autorizacao
4. utilizadores
5. auditoria
6. sistema-configuracao

7. gestao-clientes
8. gestao-produtos
9. gestao-stock
10. modulo-faturacao

11. tesouraria
12. financeiro
13. contabilidade
```

Depois disso vêm módulos complementares:

```text
impostos
multi-moeda
compras
pos
logistica
crm
recursos-humanos
assinaturas
gestao-escolar
centros-custo
```

**Classificação Final**

Para uso core real do Nexora ERP, eu classificaria assim:

```text
CORE PLATAFORMA
- empresas
- autenticacao
- autorizacao
- utilizadores
- auditoria
- sistema-configuracao

CORE COMERCIAL
- gestao-clientes
- gestao-produtos
- gestao-stock
- modulo-faturacao

CORE FINANCEIRO
- tesouraria
- financeiro
- contabilidade
```

Então, o **MVP sólido do ERP** deveria ter estes 13 módulos. Os outros podem entrar por fase, conforme o tipo de cliente: loja, escola, SaaS, RH, logística ou contabilidade avançada.
Segue um **prompt pronto** para criar as telas do Nexora ERP em **mobile e web**, tela por tela:

```text
Crie o desenho funcional e visual completo, tela por tela, para o sistema Nexora ERP.

O sistema deve ter versão WEB e MOBILE, com layout responsivo, moderno, profissional e adequado para uso empresarial em Moçambique.

Objetivo:
Desenhar todas as telas principais do ERP, separando por módulos, fluxos e permissões de usuário.

Módulos core obrigatórios:
1. Empresas
2. Autenticação
3. Autorização
4. Utilizadores
5. Auditoria
6. Sistema e Configuração
7. Gestão de Clientes
8. Gestão de Produtos
9. Gestão de Stock
10. Faturação
11. Tesouraria
12. Financeiro
13. Contabilidade

Para cada módulo, gerar:
- Nome da tela
- Objetivo da tela
- Versão Web
- Versão Mobile
- Componentes visuais
- Campos do formulário
- Botões e ações
- Estados da tela: vazio, carregando, erro, sucesso
- Permissões necessárias
- Navegação para outras telas
- Regras de negócio visíveis na interface

Estrutura esperada:
```

---

## Índice de Módulos

1. [Autenticação](#módulo-autenticacao)
2. [Autorização](#módulo-autorizacao)
3. [Utilizadores](#módulo-utilizadores)
4. [Empresas](#módulo-empresas)
5. [Auditoria](#módulo-auditoria)
6. [Sistema e Configuração](#módulo-sistema-e-configuracao)
7. [Gestão de Clientes](#módulo-gestao-de-clientes)
8. [Gestão de Produtos](#módulo-gestao-de-produtos)
9. [Faturação](#módulo-faturacao)
10. [Financeiro](#módulo-financeiro)
11. [Contabilidade](#módulo-contabilidade)
12. [Impostos](#módulo-impostos)
13. [Multi-Moeda](#módulo-multi-moeda)
14. [Compras](#módulo-compras)
15. [POS](#módulo-pos)
16. [Logística](#módulo-logistica)
17. [CRM](#módulo-crm)
18. [Recursos Humanos](#módulo-recursos-humanos)
19. [Assinaturas](#módulo-assinaturas)
20. [Centros de Custo](#módulo-centros-de-custo)


---

## Módulo: Autenticação

Objetivo: permitir acesso seguro ao Nexora ERP, gestão de sessão, recuperação de senha, bloqueio de conta e autenticação por API Key.

### 1. Tela de Login

Objetivo: permitir que o utilizador entre no sistema.

Web:
- Layout centralizado com formulário à direita ou centro.
- Logo Nexora ERP.
- Campo de email.
- Campo de senha.
- Checkbox “Lembrar sessão”.
- Link “Esqueci minha senha”.
- Botão “Entrar”.
- Link para suporte, se aplicável.

Mobile:
- Formulário em tela cheia.
- Logo no topo.
- Campos empilhados.
- Botão principal fixo abaixo do formulário.
- Link de recuperação abaixo da senha.

Campos:
- Email
- Senha

Ações:
- Entrar
- Mostrar/ocultar senha
- Recuperar senha

Estados:
- Carregando login
- Credenciais inválidas
- Conta bloqueada
- Conta inativa
- Sessão expirada
- Sem internet
- Login bem-sucedido

Permissões:
- Público

Regras:
- Bloquear temporariamente após várias tentativas falhadas.
- Registar tentativa em `login_history`.
- Criar sessão em `sessions` quando o login for válido.

---

### 2. Tela de Seleção de Empresa

Objetivo: permitir ao utilizador escolher a empresa/tenant quando tiver acesso a mais de uma.

Web:
- Lista ou cards de empresas disponíveis.
- Campo de pesquisa.
- Indicação da empresa ativa.
- Botão “Continuar”.
- Opção “Sair”.

Mobile:
- Lista em cards.
- Pesquisa no topo.
- Toque no card seleciona a empresa.

Campos:
- Pesquisa por nome da empresa

Ações:
- Selecionar empresa
- Continuar
- Sair

Estados:
- Nenhuma empresa disponível
- Carregando empresas
- Empresa suspensa
- Sem permissão na empresa

Permissões:
- Utilizador autenticado

Regras:
- Só mostrar empresas onde o utilizador possui vínculo ativo.
- Após selecionar empresa, carregar permissões do tenant.

---

### 3. Tela de Recuperação de Senha

Objetivo: iniciar processo de recuperação de senha.

Web:
- Formulário simples com email.
- Botão “Enviar instruções”.
- Link “Voltar ao login”.

Mobile:
- Tela simples, foco no campo email.
- Botão principal em largura total.

Campos:
- Email

Ações:
- Enviar link/token de recuperação
- Voltar ao login

Estados:
- Email enviado
- Email não encontrado
- Muitas tentativas
- Erro de envio

Permissões:
- Público

Regras:
- Criar token em `password_resets`.
- Token deve ter expiração.
- Não revelar se o email existe quando a política de segurança exigir privacidade.

---

### 4. Tela de Redefinição de Senha

Objetivo: permitir criar nova senha a partir de token válido.

Web:
- Campo nova senha.
- Campo confirmar senha.
- Indicador de força da senha.
- Botão “Alterar senha”.

Mobile:
- Campos empilhados.
- Indicador visual simples de força.
- Botão fixo no fim.

Campos:
- Nova senha
- Confirmar nova senha

Ações:
- Mostrar/ocultar senha
- Alterar senha

Estados:
- Token inválido
- Token expirado
- Senhas não coincidem
- Senha fraca
- Senha alterada com sucesso

Permissões:
- Público com token válido

Regras:
- Validar força mínima da senha.
- Invalidar token após uso.
- Revogar sessões antigas, se configurado.

---

### 5. Tela de Primeiro Acesso

Objetivo: permitir que novo utilizador defina senha inicial.

Web:
- Mensagem de boas-vindas.
- Definição de senha.
- Confirmação de senha.
- Aceitação dos termos, se aplicável.

Mobile:
- Fluxo em uma tela simples.
- Campos grandes e legíveis.

Campos:
- Nova senha
- Confirmar senha
- Aceitar termos

Ações:
- Ativar conta
- Voltar ao login

Estados:
- Convite inválido
- Convite expirado
- Senha inválida
- Conta ativada

Permissões:
- Público com convite/token válido

Regras:
- Alterar estado do utilizador de `pendente` para `ativo`.
- Criar primeira sessão após ativação, se desejado.

---

### 6. Tela de Sessão Expirada

Objetivo: informar que a sessão expirou e pedir novo login.

Web:
- Modal ou página dedicada.
- Mensagem clara.
- Botão “Entrar novamente”.

Mobile:
- Tela simples com botão principal.

Campos:
- Nenhum

Ações:
- Entrar novamente

Estados:
- Sessão expirada
- Sessão revogada
- Token inválido

Permissões:
- Público

Regras:
- Limpar tokens locais.
- Redirecionar para login.

---

### 7. Tela de Verificação de Código

Objetivo: validar código enviado por email/SMS, se MFA ou verificação adicional for usado.

Web:
- Campo de código de 6 dígitos.
- Botão “Verificar”.
- Link “Reenviar código”.

Mobile:
- Inputs separados por dígito.
- Suporte a colar código.
- Botão em largura total.

Campos:
- Código de verificação

Ações:
- Verificar código
- Reenviar código
- Voltar

Estados:
- Código inválido
- Código expirado
- Código reenviado
- Muitas tentativas

Permissões:
- Login parcialmente autenticado

Regras:
- Limitar tentativas.
- Expirar código por tempo.
- Registar evento de verificação.

---

### 8. Tela de Gestão de Sessões Ativas

Objetivo: permitir ao utilizador ver e revogar sessões abertas.

Web:
- Tabela com dispositivo, IP, localização aproximada, data de login e último acesso.
- Botão “Revogar sessão”.
- Botão “Revogar todas exceto esta”.

Mobile:
- Lista em cards.
- Ações por menu de contexto.

Campos:
- Nenhum obrigatório

Ações:
- Revogar sessão
- Revogar todas as sessões
- Atualizar lista

Estados:
- Nenhuma sessão ativa
- Sessão atual destacada
- Erro ao revogar
- Sessão revogada

Permissões:
- Utilizador autenticado

Regras:
- Não permitir revogar a sessão atual sem confirmação.
- Atualizar tabela `sessions`.
- Registar evento em auditoria.

---

### 9. Tela de Histórico de Login

Objetivo: permitir consultar tentativas de login do utilizador ou da empresa.

Web:
- Tabela com data, email, IP, dispositivo, resultado e motivo da falha.
- Filtros por período, estado e utilizador.
- Exportação para CSV/PDF.

Mobile:
- Lista cronológica.
- Filtros compactos.

Campos/Filtros:
- Período
- Estado: sucesso/falha
- Utilizador
- IP

Ações:
- Filtrar
- Exportar
- Ver detalhe

Estados:
- Sem registos
- Carregando
- Erro de consulta

Permissões:
- Próprio utilizador vê o próprio histórico.
- Administrador vê histórico da empresa.

Regras:
- Dados vêm de `login_history`.
- Histórico deve ser imutável.

---

### 10. Tela de Chaves de API

Objetivo: permitir criar e gerir API Keys para integrações externas.

Web:
- Tabela de chaves com nome, estado, permissões, data de criação, último uso e expiração.
- Botão “Nova API Key”.
- Modal de criação.
- Ação para revogar.

Mobile:
- Lista em cards.
- Botão flutuante para nova chave.
- Detalhes em tela separada.

Campos:
- Nome da chave
- Escopo/permissões
- Data de expiração
- Estado

Ações:
- Criar chave
- Copiar chave
- Revogar chave
- Regenerar chave
- Ver último uso

Estados:
- Nenhuma chave criada
- Chave criada com sucesso
- Chave revogada
- Chave expirada
- Sem permissão

Permissões:
- Administrador técnico
- Utilizador com permissão `api_keys.manage`

Regras:
- Mostrar o segredo da API Key apenas uma vez.
- Guardar apenas hash da chave.
- Registar uso e revogação.

---

### 11. Tela de Conta Bloqueada

Objetivo: informar que a conta foi bloqueada.

Web:
- Mensagem explicando o estado.
- Botão “Contactar administrador”.
- Link “Voltar ao login”.

Mobile:
- Mensagem curta.
- Botão de contacto.

Campos:
- Nenhum

Ações:
- Contactar suporte/admin
- Voltar ao login

Estados:
- Conta bloqueada
- Conta inativa
- Conta pendente

Permissões:
- Público

Regras:
- Não permitir login enquanto estado for `bloqueado` ou `inativo`.

---

### 12. Tela de Logout

Objetivo: encerrar sessão atual com segurança.

Web:
- Pode ser ação direta no menu do utilizador.
- Confirmação opcional.

Mobile:
- Ação no perfil/menu.
- Confirmação simples.

Campos:
- Nenhum

Ações:
- Terminar sessão
- Cancelar

Estados:
- Encerrando sessão
- Sessão encerrada
- Erro ao terminar sessão

Permissões:
- Utilizador autenticado

Regras:
- Revogar sessão atual.
- Limpar tokens locais.
- Redirecionar para login.

---

## Módulo: Autorização

Objetivo: gerir permissões, perfis, papéis de acesso e regras RBAC do Nexora ERP.

### 1. Tela de Perfis/Roles

Objetivo: listar e gerir perfis de acesso da empresa.

Web:
- Sidebar do ERP.
- Topbar com empresa ativa e utilizador.
- Tabela de roles.
- Filtros por estado e tipo.
- Botão “Novo perfil”.
- Ações por linha: ver, editar, duplicar, desativar.

Mobile:
- Lista em cards.
- Pesquisa no topo.
- Botão flutuante para novo perfil.
- Ações no menu de cada card.

Campos:
- Nome do perfil
- Código
- Descrição
- Estado
- Tipo: sistema/customizado

Ações:
- Criar perfil
- Editar perfil
- Duplicar perfil
- Desativar perfil
- Ver permissões

Estados:
- Nenhum perfil criado
- Carregando
- Sem permissão
- Erro ao carregar
- Perfil desativado

Permissões:
- `roles.view`
- `roles.create`
- `roles.update`
- `roles.delete`

Regras:
- Perfis de sistema não devem ser eliminados.
- Perfis customizados podem ser editados conforme permissão.
- Cada perfil pertence a um tenant.

---

### 2. Tela de Criar/Editar Perfil

Objetivo: criar ou alterar um perfil de acesso.

Web:
- Formulário em painel lateral ou página dedicada.
- Campos principais no topo.
- Área de permissões agrupadas por módulo.
- Botões “Guardar” e “Cancelar”.

Mobile:
- Formulário em etapas:
  1. Dados do perfil
  2. Permissões
  3. Revisão
- Botão principal fixo no rodapé.

Campos:
- Nome do perfil
- Código
- Descrição
- Estado
- Permissões atribuídas

Ações:
- Guardar
- Cancelar
- Selecionar todas permissões do módulo
- Remover todas permissões do módulo

Estados:
- Salvando
- Erro de validação
- Código já existente
- Perfil guardado com sucesso

Permissões:
- `roles.create`
- `roles.update`

Regras:
- Código do perfil deve ser único por tenant.
- Não permitir remover permissões críticas do próprio perfil sem confirmação.
- Alterações devem refletir nos utilizadores associados.

---

### 3. Tela de Matriz de Permissões

Objetivo: configurar permissões por módulo, recurso e ação.

Web:
- Tabela matricial:
  - Linhas: recursos/módulos
  - Colunas: visualizar, criar, editar, eliminar, aprovar, exportar
- Pesquisa por módulo/recurso.
- Filtro por perfil.
- Checkboxes por permissão.
- Botão “Guardar alterações”.

Mobile:
- Lista por módulo em acordeões.
- Permissões como checkboxes/toggles.
- Ações agrupadas por recurso.

Campos:
- Perfil
- Módulo
- Recurso
- Ação
- Estado da permissão

Ações:
- Marcar permissão
- Desmarcar permissão
- Selecionar módulo inteiro
- Guardar alterações

Estados:
- Nenhuma permissão encontrada
- Alterações pendentes
- Salvando
- Sem permissão
- Alterações guardadas

Permissões:
- `permissions.view`
- `permissions.assign`

Regras:
- Uma role pode ter várias permissões.
- Permissões devem seguir padrão:
  - `modulo.recurso.acao`
  - exemplo: `faturacao.invoices.create`
- Alterações devem ser auditadas.

---

### 4. Tela de Permissões do Sistema

Objetivo: listar todas as permissões disponíveis no ERP.

Web:
- Tabela com código, módulo, recurso, ação e descrição.
- Filtros por módulo e ação.
- Botão de sincronização/geração de permissões, se aplicável.

Mobile:
- Lista pesquisável.
- Filtros em bottom sheet.

Campos:
- Código da permissão
- Módulo
- Recurso
- Ação
- Descrição
- Estado

Ações:
- Pesquisar
- Filtrar
- Ver detalhe
- Sincronizar permissões

Estados:
- Nenhuma permissão registada
- Carregando
- Erro
- Sem permissão

Permissões:
- `permissions.view`
- `permissions.sync`

Regras:
- Permissões de sistema não devem ser apagadas manualmente.
- Novos módulos devem registar suas permissões base.

---

### 5. Tela de Atribuição de Perfil ao Utilizador

Objetivo: associar roles/perfis aos utilizadores.

Web:
- Seleção de utilizador.
- Lista de perfis disponíveis.
- Lista de perfis atribuídos.
- Tabela com utilizadores e perfis atuais.
- Botão “Guardar atribuições”.

Mobile:
- Pesquisa de utilizador.
- Cards de perfis com checkbox.
- Resumo antes de guardar.

Campos:
- Utilizador
- Perfil
- Empresa/tenant
- Estado da atribuição

Ações:
- Atribuir perfil
- Remover perfil
- Guardar alterações
- Ver permissões efetivas

Estados:
- Utilizador sem perfil
- Sem utilizadores disponíveis
- Alterações pendentes
- Perfil atribuído
- Erro ao guardar

Permissões:
- `user_roles.view`
- `user_roles.assign`
- `user_roles.remove`

Regras:
- Um utilizador pode ter múltiplos perfis.
- Perfis só valem dentro da empresa/tenant selecionada.
- Não permitir remover o último administrador sem confirmação/regra de proteção.

---

### 6. Tela de Permissões Efetivas do Utilizador

Objetivo: mostrar o resultado final das permissões de um utilizador.

Web:
- Cabeçalho com utilizador, email e empresa.
- Lista de perfis atribuídos.
- Tabela de permissões efetivas agrupadas por módulo.
- Indicação da origem da permissão: perfil X, perfil Y.
- Filtros por módulo e ação.

Mobile:
- Dados do utilizador no topo.
- Acordeões por módulo.
- Permissões listadas em cards compactos.

Campos:
- Utilizador
- Perfis
- Permissões efetivas
- Origem da permissão

Ações:
- Filtrar permissões
- Exportar relatório
- Ir para edição de perfis

Estados:
- Utilizador sem permissões
- Carregando permissões
- Sem acesso para visualizar
- Erro

Permissões:
- `permissions.effective.view`

Regras:
- Permissões efetivas resultam da união das roles atribuídas.
- Se existir política de negação explícita no futuro, ela deve sobrepor permissões concedidas.

---

### 7. Tela de Comparação de Perfis

Objetivo: comparar permissões entre dois ou mais perfis.

Web:
- Seletores de perfis.
- Matriz comparativa.
- Diferenças destacadas.
- Exportação.

Mobile:
- Seleção de dois perfis.
- Lista de diferenças por módulo.

Campos:
- Perfil A
- Perfil B
- Módulo
- Permissões diferentes

Ações:
- Comparar
- Exportar
- Copiar permissões de um perfil para outro

Estados:
- Nenhum perfil selecionado
- Sem diferenças
- Diferenças encontradas
- Erro ao comparar

Permissões:
- `roles.compare`
- `permissions.view`

Regras:
- Comparação não altera dados.
- Cópia de permissões deve exigir confirmação.

---

### 8. Tela de Logs de Alterações de Permissões

Objetivo: consultar alterações feitas em roles e permissões.

Web:
- Tabela cronológica.
- Filtros por utilizador, perfil, ação e período.
- Detalhe do antes/depois.

Mobile:
- Timeline de eventos.
- Filtros compactos.

Campos/Filtros:
- Período
- Utilizador responsável
- Perfil alterado
- Tipo de alteração
- Módulo

Ações:
- Filtrar
- Ver detalhe
- Exportar

Estados:
- Nenhum evento encontrado
- Carregando
- Erro
- Sem permissão

Permissões:
- `authorization.audit.view`

Regras:
- Alterações em permissões devem ir para auditoria.
- Logs não devem ser editáveis.

---

### 9. Tela de Templates de Perfis

Objetivo: disponibilizar perfis padrão para criação rápida.

Web:
- Lista de templates:
  - Administrador
  - Gestor
  - Vendedor
  - Caixa
  - Financeiro
  - Contabilista
  - Auditor
- Botão “Criar perfil a partir deste template”.
- Pré-visualização das permissões.

Mobile:
- Cards de templates.
- Tela de detalhe com permissões.

Campos:
- Nome do template
- Descrição
- Módulos incluídos
- Permissões incluídas

Ações:
- Ver permissões
- Criar perfil a partir do template
- Personalizar antes de guardar

Estados:
- Nenhum template disponível
- Template carregado
- Perfil criado

Permissões:
- `role_templates.view`
- `roles.create`

Regras:
- Templates não são roles reais até serem aplicados ao tenant.
- O perfil criado pode ser personalizado.

---

### 10. Tela de Acesso Negado

Objetivo: informar que o utilizador não tem permissão para uma ação ou tela.

Web:
- Página ou modal.
- Mensagem objetiva.
- Botão “Voltar”.
- Opcional: “Solicitar acesso”.

Mobile:
- Tela simples.
- Botão principal para voltar.

Campos:
- Nenhum

Ações:
- Voltar
- Solicitar acesso

Estados:
- Sem permissão
- Sessão válida, mas acesso negado

Permissões:
- Público autenticado

Regras:
- Deve aparecer quando o utilizador está autenticado, mas não tem permissão.
- Deve registar tentativa bloqueada em auditoria se for ação crítica.

---

## Módulo: Utilizadores

Objetivo: gerir os utilizadores do Nexora ERP, seus dados, estado da conta, vínculo com empresa, perfis, sessões e histórico básico.

### 1. Tela de Lista de Utilizadores

Objetivo: consultar e gerir todos os utilizadores da empresa.

Web:
- Sidebar do ERP.
- Topbar com empresa ativa.
- Tabela com nome, email, telefone, perfil principal, estado e último login.
- Filtros por estado, perfil, departamento e data de criação.
- Pesquisa por nome/email.
- Botão “Novo utilizador”.

Mobile:
- Lista em cards.
- Pesquisa no topo.
- Filtros em bottom sheet.
- Botão flutuante para criar.

Campos visíveis:
- Nome
- Email
- Telefone
- Perfil
- Estado
- Último login

Ações:
- Criar utilizador
- Ver detalhes
- Editar
- Bloquear/desbloquear
- Reenviar convite
- Desativar

Estados:
- Nenhum utilizador encontrado
- Carregando
- Erro ao carregar
- Sem permissão
- Lista filtrada sem resultados

Permissões:
- `users.view`
- `users.create`
- `users.update`
- `users.block`
- `users.deactivate`

Regras:
- Só listar utilizadores do tenant ativo.
- Não permitir desativar o próprio utilizador se for o último administrador.
- Estado do utilizador deve vir da conta em `autenticacao`.

---

### 2. Tela de Criar Utilizador

Objetivo: cadastrar novo utilizador e enviar convite de primeiro acesso.

Web:
- Formulário em página ou drawer lateral.
- Secção de dados pessoais.
- Secção de acesso.
- Secção de perfis.
- Botões “Guardar e enviar convite” e “Cancelar”.

Mobile:
- Formulário em etapas:
  1. Dados pessoais
  2. Acesso
  3. Perfis
  4. Revisão

Campos:
- Nome completo
- Email
- Telefone
- Cargo/função
- Departamento
- Idioma
- Estado inicial: pendente/ativo
- Perfis de acesso
- Empresa/filial, se aplicável

Ações:
- Guardar
- Enviar convite
- Cancelar

Estados:
- Salvando
- Email já existente
- Dados inválidos
- Convite enviado
- Erro ao criar

Permissões:
- `users.create`
- `user_roles.assign`

Regras:
- Email deve ser único.
- Novo utilizador deve nascer como `pendente` quando exigir primeiro acesso.
- Convite deve gerar token com expiração.
- Atribuição de perfis deve respeitar permissões do administrador atual.

---

### 3. Tela de Editar Utilizador

Objetivo: alterar dados administrativos de um utilizador.

Web:
- Formulário com dados atuais.
- Estado da conta em destaque.
- Secção de perfis atribuídos.
- Ações críticas separadas: bloquear, desativar, resetar senha.

Mobile:
- Dados em formulário empilhado.
- Ações críticas em menu separado.

Campos:
- Nome completo
- Telefone
- Cargo/função
- Departamento
- Idioma
- Estado
- Perfis
- Filial/unidade

Ações:
- Guardar alterações
- Cancelar
- Bloquear conta
- Desbloquear conta
- Desativar utilizador
- Reenviar convite
- Resetar senha

Estados:
- Salvando
- Alterações guardadas
- Erro de validação
- Sem permissão
- Utilizador bloqueado
- Utilizador desativado

Permissões:
- `users.update`
- `users.block`
- `users.deactivate`
- `user_roles.assign`

Regras:
- Email pode ser bloqueado para edição, dependendo da política.
- Alterações de perfis devem ser auditadas.
- Não permitir remover permissões administrativas críticas de si próprio sem proteção.

---

### 4. Tela de Detalhes do Utilizador

Objetivo: visualizar o perfil administrativo completo do utilizador.

Web:
- Cabeçalho com nome, email, estado e último login.
- Tabs:
  - Dados gerais
  - Perfis e permissões
  - Sessões
  - Histórico de login
  - Auditoria
- Botões de ação no topo.

Mobile:
- Cabeçalho compacto.
- Tabs horizontais ou secções expansíveis.
- Ações no menu superior.

Campos:
- Nome
- Email
- Telefone
- Estado
- Departamento
- Cargo
- Perfis
- Último login
- Data de criação

Ações:
- Editar
- Bloquear/desbloquear
- Resetar senha
- Revogar sessões
- Reenviar convite

Estados:
- Utilizador não encontrado
- Carregando
- Sem permissão
- Dados carregados

Permissões:
- `users.view`
- `permissions.effective.view`
- `sessions.view`
- `login_history.view`

Regras:
- Mostrar apenas informação compatível com a permissão do operador.
- Sessões e histórico vêm do módulo `autenticacao`.

---

### 5. Tela de Perfis do Utilizador

Objetivo: gerir os perfis atribuídos a um utilizador específico.

Web:
- Lista de perfis atribuídos.
- Lista de perfis disponíveis.
- Botões para adicionar/remover.
- Área de permissões efetivas.

Mobile:
- Cards com perfis.
- Checkbox para seleção.
- Resumo de permissões por módulo.

Campos:
- Utilizador
- Perfil
- Empresa
- Estado da atribuição

Ações:
- Adicionar perfil
- Remover perfil
- Ver permissões efetivas
- Guardar

Estados:
- Sem perfis atribuídos
- Alterações pendentes
- Perfil atribuído
- Perfil removido
- Erro ao guardar

Permissões:
- `user_roles.view`
- `user_roles.assign`
- `user_roles.remove`

Regras:
- Um utilizador pode ter múltiplos perfis.
- Perfis são válidos apenas no tenant atual.
- Não permitir deixar a empresa sem administrador.

---

### 6. Tela de Convites Pendentes

Objetivo: acompanhar utilizadores convidados que ainda não ativaram a conta.

Web:
- Tabela com nome, email, data do convite, expiração e estado.
- Filtros por expirado/pendente.
- Ações: reenviar, cancelar convite.

Mobile:
- Lista em cards.
- Indicador de expiração.

Campos:
- Nome
- Email
- Data de envio
- Data de expiração
- Estado

Ações:
- Reenviar convite
- Cancelar convite
- Criar novo convite

Estados:
- Nenhum convite pendente
- Convite expirado
- Convite reenviado
- Convite cancelado

Permissões:
- `users.invites.view`
- `users.invites.resend`
- `users.invites.cancel`

Regras:
- Convites expirados não podem ativar conta.
- Reenvio deve gerar novo token.
- Cancelamento invalida o token anterior.

---

### 7. Tela de Reset de Senha do Utilizador

Objetivo: permitir que administrador inicie reset de senha de um utilizador.

Web:
- Modal de confirmação.
- Opções:
  - Enviar link por email
  - Forçar alteração no próximo login
  - Revogar sessões existentes

Mobile:
- Bottom sheet de confirmação.

Campos:
- Método de reset
- Revogar sessões: sim/não
- Observação opcional

Ações:
- Enviar reset
- Cancelar

Estados:
- Reset enviado
- Erro ao enviar
- Sem permissão

Permissões:
- `users.password.reset`

Regras:
- Administrador não deve ver a nova senha.
- Reset cria token em `password_resets`.
- Evento deve ir para auditoria.

---

### 8. Tela de Bloqueio/Desbloqueio de Utilizador

Objetivo: alterar estado de acesso do utilizador.

Web:
- Modal com motivo obrigatório.
- Estado atual e novo estado em destaque.
- Confirmação.

Mobile:
- Tela/bottom sheet com motivo.

Campos:
- Motivo
- Revogar sessões ativas: sim/não

Ações:
- Bloquear
- Desbloquear
- Cancelar

Estados:
- Utilizador bloqueado
- Utilizador desbloqueado
- Motivo obrigatório
- Erro

Permissões:
- `users.block`
- `users.unblock`

Regras:
- Bloqueio impede novo login.
- Sessões podem ser revogadas no bloqueio.
- Motivo deve ser auditado.

---

### 9. Tela de Preferências do Meu Perfil

Objetivo: permitir que o próprio utilizador atualize preferências pessoais.

Web:
- Página “Meu perfil”.
- Dados básicos.
- Preferências de idioma, tema e notificações.
- Ação para alterar senha.

Mobile:
- Tela no menu de perfil.
- Secções simples.

Campos:
- Nome
- Telefone
- Idioma
- Tema: claro/escuro/sistema
- Notificações

Ações:
- Guardar preferências
- Alterar senha
- Ver sessões

Estados:
- Preferências guardadas
- Erro de validação
- Carregando

Permissões:
- Utilizador autenticado

Regras:
- Utilizador pode editar apenas seus próprios dados permitidos.
- Email pode exigir fluxo separado para alteração.

---

### 10. Tela de Alterar Minha Senha

Objetivo: permitir que utilizador autenticado altere sua senha.

Web:
- Formulário com senha atual, nova senha e confirmação.
- Indicador de força.
- Botão “Alterar senha”.

Mobile:
- Formulário empilhado.
- Mostrar/ocultar senha.

Campos:
- Senha atual
- Nova senha
- Confirmar nova senha

Ações:
- Alterar senha
- Cancelar
- Mostrar/ocultar senha

Estados:
- Senha atual incorreta
- Senhas não coincidem
- Senha fraca
- Senha alterada
- Sessões revogadas, se aplicável

Permissões:
- Utilizador autenticado

Regras:
- Exigir senha atual.
- Validar força da nova senha.
- Opcionalmente revogar outras sessões após alteração.

---

### 11. Tela de Importação de Utilizadores

Objetivo: criar vários utilizadores por ficheiro.

Web:
- Upload de CSV/XLSX.
- Download de modelo.
- Pré-visualização dos dados.
- Validação por linha.
- Botão “Importar”.

Mobile:
- Pode ser apenas consulta do estado da importação.
- Upload pode ser limitado ou simplificado.

Campos:
- Ficheiro
- Perfil padrão
- Departamento padrão
- Enviar convite: sim/não

Ações:
- Baixar modelo
- Carregar ficheiro
- Validar
- Importar
- Cancelar

Estados:
- Sem ficheiro
- Validando
- Erros encontrados
- Importação parcial
- Importação concluída

Permissões:
- `users.import`

Regras:
- Não importar emails duplicados.
- Linhas inválidas devem ser reportadas.
- Convites podem ser enviados em lote.

---

### 12. Tela de Auditoria do Utilizador

Objetivo: ver ações administrativas feitas sobre um utilizador.

Web:
- Timeline ou tabela.
- Filtros por período, tipo de ação e operador.
- Detalhe antes/depois.

Mobile:
- Timeline compacta.

Campos/Filtros:
- Período
- Tipo de ação
- Operador
- Entidade afetada

Ações:
- Filtrar
- Ver detalhe
- Exportar

Estados:
- Nenhum evento
- Carregando
- Erro
- Sem permissão

Permissões:
- `users.audit.view`
- `audit_logs.view`

Regras:
- Eventos vêm do módulo `auditoria`.
- Logs não podem ser editados ou apagados.

---

## Módulo: Empresas

Objetivo: gerir empresas/tenants, dados legais, filiais, licenciamento, preferências e estado operacional dentro do Nexora ERP.

### 1. Tela de Lista de Empresas

Objetivo: consultar e administrar empresas registadas no ERP.

Web:
- Sidebar administrativa.
- Topbar com pesquisa global.
- Tabela com nome comercial, NUIT, plano, estado, cidade, data de criação e utilizadores ativos.
- Filtros por estado, plano, cidade e data de criação.
- Botão “Nova empresa”.

Mobile:
- Lista em cards.
- Pesquisa no topo.
- Filtros em bottom sheet.
- Botão flutuante para criar empresa.

Campos visíveis:
- Nome comercial
- Razão social
- NUIT
- Estado
- Plano
- Cidade
- Utilizadores ativos

Ações:
- Criar empresa
- Ver detalhes
- Editar
- Suspender
- Reativar
- Entrar como empresa ativa, se permitido

Estados:
- Nenhuma empresa encontrada
- Carregando
- Sem permissão
- Erro ao carregar
- Lista filtrada sem resultados

Permissões:
- `companies.view`
- `companies.create`
- `companies.update`
- `companies.suspend`

Regras:
- Apenas super admin ou administrador SaaS vê todas as empresas.
- Utilizador comum só vê empresas às quais pertence.
- Cada empresa deve ser isolada por `tenant_id`.

---

### 2. Tela de Criar Empresa

Objetivo: cadastrar nova empresa/tenant.

Web:
- Formulário em etapas ou página dedicada.
- Secções:
  - Dados legais
  - Contactos
  - Endereço
  - Configuração inicial
  - Plano/licença
- Botões “Guardar” e “Cancelar”.

Mobile:
- Wizard em etapas curtas.
- Botão principal fixo no rodapé.

Campos:
- Nome comercial
- Razão social
- NUIT
- Email
- Telefone
- País
- Província
- Cidade
- Endereço
- Moeda padrão
- Idioma padrão
- Fuso horário
- Plano inicial
- Estado inicial

Ações:
- Guardar empresa
- Cancelar
- Validar NUIT
- Criar administrador inicial

Estados:
- Salvando
- NUIT inválido
- NUIT já existente
- Email inválido
- Empresa criada
- Erro ao criar

Permissões:
- `companies.create`

Regras:
- NUIT deve ser único por empresa.
- Criar `tenant_id` automaticamente.
- Definir moeda padrão, normalmente MZN.
- Criar configurações iniciais do tenant.
- Opcionalmente criar utilizador administrador da empresa.

---

### 3. Tela de Editar Empresa

Objetivo: alterar dados legais e operacionais da empresa.

Web:
- Formulário dividido por tabs:
  - Dados gerais
  - Fiscal
  - Contactos
  - Endereço
  - Configurações
- Ações críticas separadas: suspender, reativar, arquivar.

Mobile:
- Secções expansíveis.
- Ações críticas em menu separado.

Campos:
- Nome comercial
- Razão social
- NUIT
- Email
- Telefone
- Website
- Endereço
- Cidade
- País
- Moeda
- Idioma
- Estado

Ações:
- Guardar alterações
- Cancelar
- Suspender empresa
- Reativar empresa

Estados:
- Salvando
- Alterações guardadas
- Erro de validação
- Sem permissão
- Empresa suspensa

Permissões:
- `companies.update`
- `companies.suspend`
- `companies.reactivate`

Regras:
- Alteração de NUIT pode exigir permissão especial.
- Suspensão deve bloquear novos logins no tenant.
- Alterações legais devem ser auditadas.

---

### 4. Tela de Detalhes da Empresa

Objetivo: visualizar visão completa da empresa.

Web:
- Cabeçalho com nome, NUIT, estado e plano.
- Cards com indicadores:
  - Utilizadores ativos
  - Filiais
  - Documentos emitidos no mês
  - Plano atual
  - Estado da licença
- Tabs:
  - Dados gerais
  - Filiais
  - Utilizadores
  - Licença/plano
  - Configurações
  - Auditoria

Mobile:
- Cabeçalho compacto.
- Indicadores em cards.
- Tabs horizontais ou secções.

Campos visíveis:
- Nome comercial
- Razão social
- NUIT
- Estado
- Plano
- Moeda
- Cidade
- Data de criação

Ações:
- Editar
- Suspender
- Reativar
- Ver utilizadores
- Ver filiais
- Alterar plano

Estados:
- Empresa não encontrada
- Carregando
- Sem permissão
- Dados carregados

Permissões:
- `companies.view`
- `companies.metrics.view`

Regras:
- Indicadores devem respeitar permissões.
- Dados sensíveis só para administradores.

---

### 5. Tela de Filiais/Unidades

Objetivo: gerir filiais, lojas, armazéns ou unidades operacionais da empresa.

Web:
- Tabela de filiais com nome, código, cidade, responsável, estado.
- Botão “Nova filial”.
- Filtros por cidade e estado.

Mobile:
- Lista em cards.
- Botão flutuante.

Campos:
- Nome da filial
- Código
- Tipo: loja, sede, armazém, escritório
- Responsável
- Telefone
- Email
- Endereço
- Cidade
- Estado

Ações:
- Criar filial
- Editar filial
- Desativar filial
- Ver detalhes

Estados:
- Nenhuma filial criada
- Carregando
- Filial criada
- Erro de validação

Permissões:
- `branches.view`
- `branches.create`
- `branches.update`
- `branches.deactivate`

Regras:
- Toda empresa deve ter pelo menos uma unidade principal.
- Código da filial deve ser único por tenant.
- Filiais podem ser usadas por faturação, stock, POS e tesouraria.

---

### 6. Tela de Criar/Editar Filial

Objetivo: cadastrar ou atualizar uma unidade da empresa.

Web:
- Formulário com dados da unidade.
- Secção de endereço.
- Secção de responsável.

Mobile:
- Formulário em etapas simples.

Campos:
- Nome
- Código
- Tipo
- Responsável
- Telefone
- Email
- País
- Província
- Cidade
- Endereço
- Estado

Ações:
- Guardar
- Cancelar

Estados:
- Salvando
- Código duplicado
- Dados inválidos
- Guardado com sucesso

Permissões:
- `branches.create`
- `branches.update`

Regras:
- Não permitir eliminar filial com documentos, stock ou caixa associado.
- Desativar em vez de apagar quando houver histórico.

---

### 7. Tela de Configurações da Empresa

Objetivo: definir preferências gerais do tenant.

Web:
- Tabs:
  - Geral
  - Localização
  - Fiscal
  - Numeração
  - Notificações
  - Segurança
- Botão “Guardar alterações”.

Mobile:
- Lista de secções.
- Cada secção abre formulário próprio.

Campos:
- Moeda padrão
- Idioma padrão
- Fuso horário
- País fiscal
- Formato de data
- Formato de número
- Email remetente
- Logo da empresa
- Tema visual
- Política de sessão
- Política de senha

Ações:
- Guardar
- Restaurar padrão
- Carregar logo

Estados:
- Salvando
- Configurações guardadas
- Erro de validação
- Sem permissão

Permissões:
- `company_settings.view`
- `company_settings.update`

Regras:
- Alterações fiscais e de numeração devem ser auditadas.
- Mudança de moeda padrão pode ser bloqueada após existir movimento financeiro.

---

### 8. Tela de Dados Fiscais da Empresa

Objetivo: gerir dados usados em faturas, recibos e documentos fiscais.

Web:
- Formulário fiscal.
- Pré-visualização de cabeçalho de documento.
- Campos de autoridade tributária, regime e NUIT.

Mobile:
- Formulário simples.
- Pré-visualização compacta.

Campos:
- NUIT
- Regime fiscal
- Nome fiscal
- Endereço fiscal
- Número de licença/alvará
- Atividade económica
- Código da atividade, se aplicável
- Isenção fiscal, se aplicável
- Texto fiscal padrão

Ações:
- Guardar dados fiscais
- Validar NUIT
- Pré-visualizar documento

Estados:
- Dados incompletos
- NUIT inválido
- Guardado com sucesso
- Sem permissão

Permissões:
- `company_tax.view`
- `company_tax.update`

Regras:
- Dados fiscais aparecem nos documentos comerciais.
- Alterações devem ser registradas em auditoria.
- NUIT deve seguir validação de formato local.

---

### 9. Tela de Logotipo e Identidade Visual

Objetivo: configurar imagem da empresa em documentos e interface.

Web:
- Upload de logotipo.
- Pré-visualização em fatura.
- Cores institucionais.
- Remover imagem.

Mobile:
- Upload simples.
- Pré-visualização reduzida.

Campos:
- Logotipo
- Cor principal
- Cor secundária
- Texto de rodapé documental

Ações:
- Carregar imagem
- Remover imagem
- Guardar
- Pré-visualizar

Estados:
- Imagem inválida
- Tamanho excedido
- Upload concluído
- Erro de upload

Permissões:
- `company_branding.view`
- `company_branding.update`

Regras:
- Aceitar PNG/JPG/SVG conforme política.
- Limitar tamanho do ficheiro.
- Usar logotipo em faturas, recibos e relatórios.

---

### 10. Tela de Plano/Licença da Empresa

Objetivo: visualizar plano contratado, limites e estado da licença.

Web:
- Cards:
  - Plano atual
  - Estado
  - Data de renovação
  - Utilizadores permitidos
  - Documentos/mês
  - Módulos ativos
- Histórico de pagamentos/renovações.
- Botão “Alterar plano”.

Mobile:
- Cards empilhados.
- Lista de módulos ativos.

Campos:
- Plano
- Estado da licença
- Data de início
- Data de renovação
- Limite de utilizadores
- Limite de filiais
- Limite de produtos
- Limite de documentos mensais
- Módulos incluídos

Ações:
- Alterar plano
- Renovar licença
- Ver histórico
- Baixar recibo

Estados:
- Trial
- Ativa
- Suspensa
- Expirada
- Cancelada

Permissões:
- `subscriptions.view`
- `subscriptions.manage`

Regras:
- Limites vêm do módulo `assinaturas`.
- Se licença estiver suspensa, bloquear módulos não permitidos.
- Trial deve indicar dias restantes.

---

### 11. Tela de Suspensão/Reativação da Empresa

Objetivo: controlar estado operacional do tenant.

Web:
- Modal de confirmação.
- Motivo obrigatório.
- Opção de notificar administradores.
- Indicação de impacto.

Mobile:
- Bottom sheet ou página de confirmação.

Campos:
- Motivo
- Notificar administradores: sim/não
- Data de reativação prevista, opcional

Ações:
- Suspender
- Reativar
- Cancelar

Estados:
- Empresa suspensa
- Empresa reativada
- Motivo obrigatório
- Erro

Permissões:
- `companies.suspend`
- `companies.reactivate`

Regras:
- Empresa suspensa não deve permitir uso operacional.
- Super admin pode reativar.
- Evento deve ser auditado.

---

### 12. Tela de Auditoria da Empresa

Objetivo: ver alterações feitas nos dados e configurações da empresa.

Web:
- Tabela com data, utilizador, ação, entidade, antes/depois.
- Filtros por período, utilizador e tipo de ação.

Mobile:
- Timeline compacta.
- Filtros simples.

Campos/Filtros:
- Período
- Utilizador
- Ação
- Entidade
- Módulo

Ações:
- Filtrar
- Ver detalhe
- Exportar

Estados:
- Nenhum evento
- Carregando
- Erro
- Sem permissão

Permissões:
- `companies.audit.view`
- `audit_logs.view`

Regras:
- Logs vêm de `auditoria`.
- Não permitir edição ou eliminação de logs.

---

## Módulo: Auditoria

Objetivo: garantir rastreabilidade das ações realizadas no Nexora ERP, permitindo consultar eventos, alterações de dados, acessos críticos e operações sensíveis.

### 1. Tela de Dashboard de Auditoria

Objetivo: apresentar visão geral dos eventos auditados.

Web:
- Sidebar do ERP.
- Topbar com empresa ativa.
- Cards de resumo:
  - Eventos hoje
  - Eventos críticos
  - Falhas de acesso
  - Alterações administrativas
  - Exportações realizadas
- Gráfico de eventos por módulo.
- Lista dos eventos recentes.
- Filtros rápidos por período e severidade.

Mobile:
- Cards empilhados.
- Gráfico simplificado.
- Lista de eventos recentes em cards.
- Filtros em bottom sheet.

Campos/Filtros:
- Período
- Módulo
- Severidade
- Tipo de ação

Ações:
- Filtrar
- Atualizar
- Ver eventos críticos
- Exportar resumo

Estados:
- Sem eventos
- Carregando
- Erro ao carregar
- Sem permissão

Permissões:
- `audit.dashboard.view`

Regras:
- Mostrar apenas eventos do tenant ativo.
- Super admin pode ver eventos multiempresa.
- Eventos críticos devem ficar destacados.

---

### 2. Tela de Lista de Eventos de Auditoria

Objetivo: consultar todos os eventos registados.

Web:
- Tabela com data/hora, utilizador, módulo, entidade, ação, IP, severidade e resultado.
- Pesquisa por utilizador, entidade ou ID.
- Filtros por período, módulo, ação, severidade e resultado.
- Botão “Exportar”.

Mobile:
- Lista cronológica em cards.
- Filtros em bottom sheet.
- Pesquisa no topo.

Campos visíveis:
- Data/hora
- Utilizador
- Módulo
- Entidade
- Ação
- Resultado
- Severidade

Ações:
- Pesquisar
- Filtrar
- Ver detalhe
- Exportar

Estados:
- Nenhum evento encontrado
- Carregando
- Erro
- Sem permissão
- Lista filtrada sem resultados

Permissões:
- `audit_logs.view`
- `audit_logs.export`

Regras:
- Eventos não podem ser editados nem apagados.
- Consultas devem respeitar tenant.
- Exportação deve ser registrada como evento auditável.

---

### 3. Tela de Detalhe do Evento de Auditoria

Objetivo: visualizar informação completa de um evento.

Web:
- Cabeçalho com ação, módulo, severidade e resultado.
- Secções:
  - Dados do evento
  - Utilizador
  - Entidade afetada
  - Antes/depois
  - Metadados técnicos
- Visualização JSON formatada.

Mobile:
- Secções expansíveis.
- JSON em bloco recolhível.

Campos:
- ID do evento
- Data/hora
- Tenant
- Utilizador
- Módulo
- Entidade
- ID da entidade
- Ação
- Resultado
- IP
- User agent
- Dados antes
- Dados depois
- Metadados

Ações:
- Copiar ID do evento
- Copiar JSON
- Voltar
- Exportar detalhe

Estados:
- Evento não encontrado
- Carregando
- Sem permissão
- Erro ao carregar

Permissões:
- `audit_logs.view_detail`
- `audit_logs.export`

Regras:
- Dados sensíveis devem ser mascarados.
- Logs devem ser imutáveis.
- Campos antes/depois devem vir do JSONB de auditoria.

---

### 4. Tela de Eventos Críticos

Objetivo: listar eventos de alto risco ou sensíveis.

Web:
- Tabela dedicada para eventos críticos.
- Indicadores de severidade.
- Filtros por categoria:
  - Permissões
  - Login falhado
  - Exportação
  - Alteração fiscal
  - Eliminação de dados
  - Suspensão de empresa
- Ação para marcar como revisto.

Mobile:
- Lista em cards com destaque visual.
- Filtros por severidade.

Campos:
- Data/hora
- Utilizador
- Evento
- Módulo
- Severidade
- Estado de revisão

Ações:
- Ver detalhe
- Marcar como revisto
- Filtrar
- Exportar

Estados:
- Nenhum evento crítico
- Carregando
- Evento revisto
- Sem permissão

Permissões:
- `audit_critical.view`
- `audit_critical.review`

Regras:
- Eventos críticos devem exigir permissão específica.
- Marcar como revisto não altera o log original; cria metadado de revisão.

---

### 5. Tela de Histórico por Entidade

Objetivo: consultar alterações feitas numa entidade específica, como cliente, produto, fatura ou utilizador.

Web:
- Campo para selecionar módulo.
- Campo para entidade e ID.
- Timeline de alterações.
- Comparação antes/depois.

Mobile:
- Pesquisa por entidade.
- Timeline vertical.

Campos/Filtros:
- Módulo
- Tipo de entidade
- ID da entidade
- Período

Ações:
- Pesquisar histórico
- Ver evento
- Comparar alterações

Estados:
- Nenhum histórico encontrado
- Entidade não encontrada
- Carregando
- Erro

Permissões:
- `audit_entity_history.view`

Regras:
- Deve filtrar por tenant.
- Histórico deve mostrar criação, edição, eliminação e mudanças de estado.
- Dados sensíveis devem ser mascarados.

---

### 6. Tela de Histórico por Utilizador

Objetivo: consultar ações feitas por um utilizador.

Web:
- Cabeçalho com dados do utilizador.
- Cards de resumo:
  - Total de ações
  - Logins
  - Falhas
  - Alterações feitas
  - Exportações
- Timeline ou tabela de eventos.
- Filtros por módulo, período e ação.

Mobile:
- Resumo em cards.
- Lista cronológica.

Campos/Filtros:
- Utilizador
- Período
- Módulo
- Ação
- Resultado

Ações:
- Filtrar
- Ver detalhe do evento
- Exportar histórico

Estados:
- Nenhuma ação encontrada
- Utilizador não encontrado
- Carregando
- Sem permissão

Permissões:
- `audit_user_history.view`

Regras:
- Administrador vê utilizadores do tenant.
- Utilizador comum pode ver apenas o próprio histórico, se permitido.
- Ações administrativas devem ser destacadas.

---

### 7. Tela de Exportação de Logs

Objetivo: exportar logs de auditoria para análise externa.

Web:
- Formulário de exportação.
- Filtros obrigatórios por período.
- Seleção de formato: CSV, XLSX, PDF, JSON.
- Botão “Gerar exportação”.
- Histórico de exportações.

Mobile:
- Formulário simples.
- Histórico em lista.

Campos:
- Período inicial
- Período final
- Módulo
- Severidade
- Formato
- Incluir detalhes técnicos: sim/não

Ações:
- Gerar exportação
- Baixar ficheiro
- Cancelar exportação
- Ver histórico

Estados:
- Gerando ficheiro
- Exportação pronta
- Sem dados
- Erro ao exportar

Permissões:
- `audit_logs.export`

Regras:
- Exportação deve ser auditada.
- Limitar intervalo máximo para evitar ficheiros muito grandes.
- Dados sensíveis devem respeitar política de mascaramento.

---

### 8. Tela de Configurações de Auditoria

Objetivo: definir políticas de auditoria do tenant.

Web:
- Secções:
  - Eventos obrigatórios
  - Retenção de logs
  - Mascaramento de dados
  - Alertas de eventos críticos
  - Exportação
- Toggles e campos numéricos.

Mobile:
- Lista de configurações por secção.

Campos:
- Retenção em dias
- Auditar leituras sensíveis
- Auditar exportações
- Mascarar dados pessoais
- Notificar eventos críticos
- Email de alerta
- Webhook de alerta

Ações:
- Guardar configurações
- Restaurar padrão
- Testar alerta

Estados:
- Salvando
- Configurações guardadas
- Erro de validação
- Sem permissão

Permissões:
- `audit_settings.view`
- `audit_settings.update`

Regras:
- Não permitir desativar eventos obrigatórios do sistema.
- Retenção mínima deve obedecer requisitos legais/contratuais.
- Alterações de configuração devem ser auditadas.

---

### 9. Tela de Alertas de Auditoria

Objetivo: consultar e gerir alertas gerados por eventos críticos.

Web:
- Tabela de alertas.
- Filtros por estado: aberto, em análise, resolvido.
- Prioridade.
- Responsável.
- Ações de acompanhamento.

Mobile:
- Cards por alerta.
- Alteração rápida de estado.

Campos:
- Título
- Evento relacionado
- Prioridade
- Estado
- Responsável
- Data de criação
- Data de resolução

Ações:
- Ver evento
- Atribuir responsável
- Mudar estado
- Adicionar nota
- Resolver alerta

Estados:
- Nenhum alerta
- Alerta aberto
- Alerta em análise
- Alerta resolvido
- Sem permissão

Permissões:
- `audit_alerts.view`
- `audit_alerts.manage`

Regras:
- Alertas referenciam eventos, mas não alteram o log original.
- Resolução deve guardar responsável, data e observação.

---

### 10. Tela de Tentativas Bloqueadas

Objetivo: listar tentativas de ações negadas por falta de permissão.

Web:
- Tabela com utilizador, permissão exigida, módulo, recurso, data e IP.
- Filtros por utilizador, módulo e permissão.
- Ação para ver permissões efetivas do utilizador.

Mobile:
- Lista em cards.
- Link para detalhe do utilizador.

Campos:
- Utilizador
- Permissão exigida
- Módulo
- Recurso
- Ação
- IP
- Data/hora

Ações:
- Ver detalhe
- Ver permissões do utilizador
- Filtrar

Estados:
- Nenhuma tentativa bloqueada
- Carregando
- Sem permissão

Permissões:
- `audit_access_denied.view`

Regras:
- Tentativas negadas em ações críticas devem ser auditadas.
- Não deve revelar informação sensível ao utilizador sem permissão.

---

### 11. Tela de Retenção e Integridade dos Logs

Objetivo: monitorar retenção, volume e integridade dos logs.

Web:
- Cards:
  - Total de logs
  - Logs do mês
  - Espaço usado
  - Retenção configurada
  - Última verificação de integridade
- Tabela de verificações.
- Botão “Verificar integridade”.

Mobile:
- Cards de resumo.
- Lista de verificações.

Campos:
- Retenção atual
- Volume estimado
- Última verificação
- Estado da integridade

Ações:
- Verificar integridade
- Exportar relatório
- Ver política de retenção

Estados:
- Integridade válida
- Integridade com falha
- Verificação em andamento
- Sem permissão

Permissões:
- `audit_integrity.view`
- `audit_integrity.check`

Regras:
- Logs devem ser imutáveis.
- Se houver hash/cadeia de integridade, falhas devem gerar alerta crítico.
- Limpeza por retenção deve ser controlada e auditada.**

---

## Módulo: Sistema e Configuração

Objetivo: gerir configurações globais do ERP, parâmetros do tenant, moedas, localização, notificações, templates, integrações e logs técnicos.

### 1. Tela de Configurações Gerais

Objetivo: centralizar preferências básicas da empresa no sistema.

Web:
- Sidebar do ERP.
- Topbar com empresa ativa.
- Página com secções em tabs:
  - Geral
  - Localização
  - Formatos
  - Segurança
  - Notificações
- Botão “Guardar alterações”.

Mobile:
- Lista de secções.
- Cada secção abre uma tela própria.
- Botão principal fixo no rodapé.

Campos:
- Nome do sistema exibido
- Idioma padrão
- Moeda padrão
- Fuso horário
- Formato de data
- Formato de hora
- Formato numérico
- Tema padrão: claro, escuro, sistema

Ações:
- Guardar
- Restaurar padrão
- Cancelar

Estados:
- Carregando configurações
- Salvando
- Configurações guardadas
- Erro de validação
- Sem permissão

Permissões:
- `settings.view`
- `settings.update`

Regras:
- Configurações são isoladas por `tenant_id`.
- Mudança de moeda padrão pode ser bloqueada se já existirem movimentos financeiros.
- Alterações devem ser auditadas.

---

### 2. Tela de Países, Províncias e Cidades

Objetivo: gerir dados de localização usados em clientes, empresas, fornecedores, filiais e documentos.

Web:
- Tabela com país, província, cidade, código e estado.
- Filtros por país/província/estado.
- Botão “Nova localização”.
- Importação de localidades, se aplicável.

Mobile:
- Lista hierárquica.
- Pesquisa no topo.
- Filtros em bottom sheet.

Campos:
- País
- Código do país
- Província
- Cidade
- Código postal, se aplicável
- Estado

Ações:
- Criar país/província/cidade
- Editar
- Desativar
- Pesquisar
- Importar lista

Estados:
- Nenhuma localização cadastrada
- Carregando
- Localização criada
- Código duplicado
- Sem permissão

Permissões:
- `locations.view`
- `locations.create`
- `locations.update`
- `locations.deactivate`

Regras:
- Não eliminar localização já usada em documentos ou cadastros.
- Preferir desativar em vez de apagar.
- País padrão para Moçambique pode vir pré-configurado.

---

### 3. Tela de Moedas

Objetivo: gerir moedas usadas pelo ERP.

Web:
- Tabela com moeda, código ISO, símbolo, casas decimais, estado e padrão.
- Botão “Nova moeda”.
- Ação para definir moeda padrão.

Mobile:
- Cards com moeda, símbolo e estado.
- Ações no menu do card.

Campos:
- Nome da moeda
- Código ISO
- Símbolo
- Casas decimais
- Estado
- Moeda padrão

Ações:
- Criar moeda
- Editar
- Ativar/desativar
- Definir como padrão

Estados:
- Nenhuma moeda configurada
- Moeda criada
- Código duplicado
- Sem permissão

Permissões:
- `currencies.view`
- `currencies.create`
- `currencies.update`

Regras:
- Código ISO deve ser único.
- Moeda padrão não deve ser desativada.
- MZN deve estar disponível por padrão para Moçambique.

---

### 4. Tela de Taxas de Câmbio

Objetivo: gerir câmbios entre moedas.

Web:
- Tabela com moeda origem, moeda destino, taxa, data, fonte e estado.
- Filtros por moeda e período.
- Botão “Nova taxa”.
- Ação para importar taxa.

Mobile:
- Lista em cards.
- Filtros compactos.

Campos:
- Moeda origem
- Moeda destino
- Taxa
- Data da taxa
- Fonte
- Observação
- Estado

Ações:
- Criar taxa
- Editar taxa
- Importar câmbio
- Filtrar

Estados:
- Nenhuma taxa registada
- Taxa inválida
- Taxa criada
- Erro ao importar

Permissões:
- `exchange_rates.view`
- `exchange_rates.create`
- `exchange_rates.update`
- `exchange_rates.import`

Regras:
- Taxa deve ser maior que zero.
- Não permitir duas taxas ativas iguais para a mesma data e par de moedas.
- Módulos financeiro, faturação e contabilidade consomem estas taxas.

---

### 5. Tela de Idiomas

Objetivo: configurar idiomas disponíveis na interface.

Web:
- Tabela com idioma, código, direção, estado e padrão.
- Botão “Novo idioma”.

Mobile:
- Lista simples com toggles de ativação.

Campos:
- Nome do idioma
- Código
- Direção: LTR/RTL
- Estado
- Idioma padrão

Ações:
- Ativar/desativar idioma
- Definir padrão
- Editar

Estados:
- Nenhum idioma configurado
- Idioma ativado
- Sem permissão

Permissões:
- `languages.view`
- `languages.update`

Regras:
- Idioma padrão não pode ser desativado.
- Português deve estar ativo por padrão.

---

### 6. Tela de Templates de Email

Objetivo: gerir modelos de email usados pelo sistema.

Web:
- Lista/tabela de templates.
- Filtros por módulo e evento.
- Editor com assunto, corpo e variáveis disponíveis.
- Pré-visualização.

Mobile:
- Lista de templates.
- Editor simplificado.
- Pré-visualização em tela separada.

Campos:
- Nome do template
- Módulo
- Evento
- Assunto
- Corpo HTML/texto
- Idioma
- Estado

Ações:
- Criar template
- Editar
- Pré-visualizar
- Enviar teste
- Restaurar padrão

Estados:
- Nenhum template
- Salvando
- Template guardado
- Variável inválida
- Email de teste enviado

Permissões:
- `email_templates.view`
- `email_templates.create`
- `email_templates.update`
- `email_templates.test`

Regras:
- Variáveis devem ser validadas antes de guardar.
- Templates críticos, como recuperação de senha, não devem ficar vazios.
- Alterações devem ser auditadas.

---

### 7. Tela de Templates de SMS

Objetivo: gerir mensagens SMS usadas para notificações.

Web:
- Tabela de templates.
- Editor de texto curto.
- Contador de caracteres.
- Lista de variáveis disponíveis.

Mobile:
- Editor compacto.
- Contador visível.

Campos:
- Nome
- Módulo
- Evento
- Mensagem
- Idioma
- Estado

Ações:
- Criar
- Editar
- Enviar teste
- Ativar/desativar

Estados:
- Template criado
- Mensagem muito longa
- Variável inválida
- SMS de teste enviado

Permissões:
- `sms_templates.view`
- `sms_templates.update`
- `sms_templates.test`

Regras:
- Validar limite de caracteres.
- Mensagens devem evitar dados sensíveis.
- Envio de teste deve ser registado.

---

### 8. Tela de Notificações

Objetivo: configurar regras de notificação do sistema.

Web:
- Tabela por evento:
  - Login suspeito
  - Fatura emitida
  - Pagamento recebido
  - Stock baixo
  - Licença próxima do fim
  - Evento crítico de auditoria
- Canais: email, SMS, push, interno.
- Toggles por canal.

Mobile:
- Lista por evento.
- Canais como switches.

Campos:
- Evento
- Módulo
- Canal
- Destinatários
- Estado
- Frequência

Ações:
- Ativar/desativar notificação
- Editar destinatários
- Testar notificação

Estados:
- Notificação ativa
- Notificação inativa
- Erro ao testar
- Teste enviado

Permissões:
- `notifications.view`
- `notifications.update`
- `notifications.test`

Regras:
- Eventos críticos não devem permitir desativação total sem permissão especial.
- Destinatários devem pertencer ao tenant.
- Notificações devem respeitar preferências do utilizador.

---

### 9. Tela de Integrações

Objetivo: gerir integrações externas do ERP.

Web:
- Cards por integração:
  - Email SMTP
  - SMS gateway
  - M-Pesa
  - e-Mola
  - Bancos
  - API externa
  - Webhooks
- Estado da integração.
- Botão configurar/testar.

Mobile:
- Lista em cards.
- Detalhe da integração em tela separada.

Campos:
- Nome da integração
- Tipo
- URL/host
- Chave pública
- Segredo/API key
- Estado
- Último teste
- Ambiente: sandbox/produção

Ações:
- Configurar
- Testar conexão
- Ativar/desativar
- Ver logs

Estados:
- Não configurada
- Ativa
- Com erro
- Testando conexão
- Conexão bem-sucedida

Permissões:
- `integrations.view`
- `integrations.configure`
- `integrations.test`

Regras:
- Segredos devem ser mascarados.
- Guardar tokens/chaves com segurança.
- Testes de integração devem gerar logs técnicos.

---

### 10. Tela de Webhooks

Objetivo: configurar chamadas externas quando eventos ocorrem no ERP.

Web:
- Tabela com nome, URL, eventos, estado, último envio.
- Botão “Novo webhook”.
- Tela de detalhe com histórico de tentativas.

Mobile:
- Cards por webhook.
- Histórico em lista.

Campos:
- Nome
- URL
- Eventos
- Método
- Headers
- Segredo de assinatura
- Estado

Ações:
- Criar webhook
- Editar
- Testar envio
- Ativar/desativar
- Ver tentativas

Estados:
- Webhook criado
- URL inválida
- Teste enviado
- Falha no envio
- Desativado

Permissões:
- `webhooks.view`
- `webhooks.create`
- `webhooks.update`
- `webhooks.test`

Regras:
- URL deve ser HTTPS em produção.
- Assinar payload com segredo.
- Registrar tentativas e respostas.

---

### 11. Tela de Logs do Sistema

Objetivo: consultar logs técnicos de sistema, integrações e APIs.

Web:
- Tabela com data, nível, origem, mensagem, tenant, request ID.
- Filtros por nível, origem, período e tenant.
- Botão exportar.

Mobile:
- Lista cronológica.
- Filtros compactos.

Campos/Filtros:
- Período
- Nível: info, warning, error, critical
- Origem
- Request ID
- Tenant

Ações:
- Filtrar
- Ver detalhe
- Exportar

Estados:
- Sem logs
- Carregando
- Erro ao carregar
- Sem permissão

Permissões:
- `system_logs.view`
- `system_logs.export`

Regras:
- Logs técnicos não devem expor senhas, tokens ou dados sensíveis.
- Super admin pode ver logs globais.
- Admin de tenant só vê logs do seu tenant.

---

### 12. Tela de Logs de API

Objetivo: monitorar chamadas feitas à API do ERP.

Web:
- Tabela com endpoint, método, status, duração, utilizador/API key, IP e data.
- Filtros por endpoint, status, método e período.
- Detalhe da requisição/resposta, com mascaramento.

Mobile:
- Lista em cards por chamada.
- Indicadores de status.

Campos:
- Endpoint
- Método
- Status HTTP
- Duração
- Utilizador
- API key
- IP
- Request ID
- Data/hora

Ações:
- Filtrar
- Ver detalhe
- Copiar request ID
- Exportar

Estados:
- Nenhuma chamada encontrada
- Erro 4xx
- Erro 5xx
- Chamada lenta
- Sem permissão

Permissões:
- `api_logs.view`
- `api_logs.export`

Regras:
- Mascarar authorization headers, tokens e passwords.
- Chamadas com erro 5xx devem ser destacadas.
- API keys revogadas ainda podem aparecer no histórico.

---

### 13. Tela de Numeração Global

Objetivo: configurar padrões de numeração usados por documentos.

Web:
- Lista de séries por módulo:
  - Faturas
  - Recibos
  - Notas de crédito
  - Compras
  - Pagamentos
  - POS
- Prefixo, ano, sequência atual e estado.
- Botão criar série.

Mobile:
- Cards por série.
- Edição em tela separada.

Campos:
- Módulo
- Tipo de documento
- Prefixo
- Ano
- Sequência inicial
- Sequência atual
- Estado
- Filial, se aplicável

Ações:
- Criar série
- Editar
- Ativar/desativar
- Pré-visualizar próximo número

Estados:
- Nenhuma série
- Série criada
- Prefixo duplicado
- Sequência inválida

Permissões:
- `numbering.view`
- `numbering.create`
- `numbering.update`

Regras:
- Sequência deve ser atômica.
- Não permitir reduzir sequência abaixo de documentos já emitidos.
- Mudanças devem ser auditadas.

---

### 14. Tela de Backup e Manutenção

Objetivo: consultar estado de backups e tarefas de manutenção.

Web:
- Cards:
  - Último backup
  - Próximo backup
  - Estado
  - Tamanho
- Histórico de backups.
- Ações administrativas.

Mobile:
- Cards de estado.
- Histórico simplificado.

Campos:
- Data do backup
- Tipo: completo/incremental
- Estado
- Tamanho
- Localização
- Observação

Ações:
- Ver histórico
- Solicitar backup
- Baixar backup, se permitido
- Verificar integridade

Estados:
- Backup concluído
- Backup falhou
- Backup em execução
- Sem permissão

Permissões:
- `backups.view`
- `backups.request`
- `backups.download`

Regras:
- Download de backup deve exigir permissão crítica.
- Toda ação de backup deve ser auditada.
- Dados sensíveis devem ser protegidos.**

---

## Módulo: Gestão de Clientes

Objetivo: gerir o cadastro completo de clientes, contactos, endereços, documentos, crédito, saldos, histórico comercial e segmentação.

### 1. Tela de Lista de Clientes

Objetivo: consultar e gerir clientes cadastrados.

Web:
- Sidebar do ERP.
- Topbar com pesquisa global.
- Tabela com nome, NUIT, telefone, email, grupo, saldo, limite de crédito e estado.
- Filtros por estado, grupo, cidade, saldo em aberto e limite de crédito.
- Botão “Novo cliente”.
- Ações rápidas por linha.

Mobile:
- Lista em cards.
- Pesquisa no topo.
- Filtros em bottom sheet.
- Botão flutuante para novo cliente.

Campos visíveis:
- Nome
- NUIT
- Telefone
- Email
- Grupo
- Saldo em aberto
- Estado

Ações:
- Criar cliente
- Ver detalhes
- Editar
- Desativar
- Criar fatura
- Registar pagamento
- Ver conta corrente

Estados:
- Nenhum cliente cadastrado
- Carregando
- Erro ao carregar
- Sem permissão
- Lista filtrada sem resultados

Permissões:
- `customers.view`
- `customers.create`
- `customers.update`
- `customers.deactivate`

Regras:
- Cliente pertence sempre ao tenant ativo.
- NUIT pode ser obrigatório conforme configuração fiscal.
- Cliente com documentos emitidos não deve ser apagado, apenas desativado.

---

### 2. Tela de Criar Cliente

Objetivo: cadastrar novo cliente.

Web:
- Formulário dividido por secções:
  - Dados gerais
  - Dados fiscais
  - Contactos
  - Endereço
  - Condições comerciais
- Botões “Guardar”, “Guardar e criar fatura” e “Cancelar”.

Mobile:
- Wizard em etapas:
  1. Dados gerais
  2. Contacto
  3. Fiscal
  4. Comercial
  5. Revisão

Campos:
- Nome/Razão social
- Tipo: individual/empresa
- NUIT
- Email
- Telefone
- Grupo de cliente
- País
- Província
- Cidade
- Endereço
- Limite de crédito
- Prazo de pagamento
- Desconto padrão
- Estado

Ações:
- Guardar cliente
- Guardar e criar fatura
- Cancelar
- Validar NUIT

Estados:
- Salvando
- NUIT inválido
- NUIT duplicado
- Email inválido
- Cliente criado
- Erro ao criar

Permissões:
- `customers.create`

Regras:
- NUIT deve ser único por tenant quando preenchido.
- Limite de crédito não pode ser negativo.
- Desconto padrão deve respeitar limite máximo configurado.

---

### 3. Tela de Editar Cliente

Objetivo: alterar dados do cliente.

Web:
- Formulário com tabs:
  - Geral
  - Fiscal
  - Contactos
  - Endereços
  - Comercial
- Ações críticas separadas: desativar, bloquear crédito.

Mobile:
- Secções expansíveis.
- Ações críticas em menu.

Campos:
- Nome
- NUIT
- Email
- Telefone
- Grupo
- Endereço
- Limite de crédito
- Prazo de pagamento
- Desconto
- Estado

Ações:
- Guardar alterações
- Cancelar
- Desativar cliente
- Bloquear crédito
- Desbloquear crédito

Estados:
- Salvando
- Alterações guardadas
- Erro de validação
- Cliente bloqueado
- Sem permissão

Permissões:
- `customers.update`
- `customers.credit.update`
- `customers.deactivate`

Regras:
- Alterações fiscais devem ser auditadas.
- Cliente com saldo em aberto não deve ser eliminado.
- Bloqueio de crédito impede novas vendas a crédito.

---

### 4. Tela de Detalhes do Cliente

Objetivo: visualizar a ficha completa do cliente.

Web:
- Cabeçalho com nome, NUIT, estado e saldo.
- Cards:
  - Total comprado
  - Total pago
  - Saldo em aberto
  - Limite disponível
  - Última compra
- Tabs:
  - Resumo
  - Contactos
  - Endereços
  - Documentos
  - Conta corrente
  - Pagamentos
  - Histórico
  - Notas

Mobile:
- Cabeçalho compacto.
- Cards empilhados.
- Tabs horizontais.

Campos visíveis:
- Nome
- NUIT
- Contacto principal
- Grupo
- Estado
- Saldo
- Limite de crédito

Ações:
- Editar
- Criar fatura
- Criar orçamento
- Registar pagamento
- Adicionar nota
- Ver conta corrente

Estados:
- Cliente não encontrado
- Carregando
- Sem permissão
- Dados carregados

Permissões:
- `customers.view`
- `customers.financial_summary.view`
- `customers.history.view`

Regras:
- Indicadores financeiros dependem de faturação e financeiro.
- Dados sensíveis podem exigir permissões específicas.

---

### 5. Tela de Grupos de Clientes

Objetivo: organizar clientes por segmento comercial.

Web:
- Tabela com nome do grupo, desconto padrão, prazo de pagamento e quantidade de clientes.
- Botão “Novo grupo”.

Mobile:
- Lista em cards.
- Botão flutuante.

Campos:
- Nome do grupo
- Descrição
- Desconto padrão
- Prazo de pagamento
- Estado

Ações:
- Criar grupo
- Editar grupo
- Desativar grupo
- Ver clientes do grupo

Estados:
- Nenhum grupo criado
- Grupo criado
- Código/nome duplicado
- Sem permissão

Permissões:
- `customer_groups.view`
- `customer_groups.create`
- `customer_groups.update`

Regras:
- Grupo pode definir condições comerciais padrão.
- Não apagar grupo associado a clientes; desativar.

---

### 6. Tela de Contactos do Cliente

Objetivo: gerir pessoas de contacto ligadas ao cliente.

Web:
- Lista/tabela de contactos.
- Indicação de contacto principal.
- Botão “Novo contacto”.

Mobile:
- Cards por contacto.
- Ações rápidas: ligar, enviar email, WhatsApp.

Campos:
- Nome
- Cargo
- Telefone
- Email
- Principal: sim/não
- Observação

Ações:
- Criar contacto
- Editar
- Remover
- Definir como principal
- Ligar/enviar email

Estados:
- Nenhum contacto
- Contacto criado
- Email inválido
- Sem permissão

Permissões:
- `customer_contacts.view`
- `customer_contacts.create`
- `customer_contacts.update`
- `customer_contacts.delete`

Regras:
- Apenas um contacto principal por cliente.
- Não exigir email se telefone estiver preenchido, conforme política.

---

### 7. Tela de Endereços do Cliente

Objetivo: gerir endereços de cobrança, entrega e sede.

Web:
- Tabela de endereços.
- Tipo de endereço visível.
- Botão “Novo endereço”.

Mobile:
- Cards por endereço.
- Ação para abrir mapa, se aplicável.

Campos:
- Tipo: cobrança, entrega, sede, outro
- País
- Província
- Cidade
- Endereço
- Código postal
- Principal: sim/não

Ações:
- Criar endereço
- Editar
- Remover
- Definir como principal

Estados:
- Nenhum endereço
- Endereço criado
- Dados incompletos
- Sem permissão

Permissões:
- `customer_addresses.view`
- `customer_addresses.create`
- `customer_addresses.update`

Regras:
- Pode haver endereço principal por tipo.
- Endereço de cobrança pode ser usado em faturas.

---

### 8. Tela de Documentos Anexos do Cliente

Objetivo: guardar documentos ligados ao cliente.

Web:
- Lista de anexos com tipo, nome, data, validade e responsável.
- Upload de ficheiro.
- Pré-visualização/download.

Mobile:
- Lista de documentos.
- Upload por câmera/ficheiro.

Campos:
- Tipo de documento
- Nome
- Ficheiro
- Data de validade
- Observação

Ações:
- Carregar documento
- Ver
- Baixar
- Remover
- Substituir

Estados:
- Nenhum documento
- Upload em andamento
- Upload concluído
- Ficheiro inválido
- Sem permissão

Permissões:
- `customer_documents.view`
- `customer_documents.upload`
- `customer_documents.delete`

Regras:
- Validar tipo e tamanho do ficheiro.
- Documentos sensíveis devem respeitar permissões.

---

### 9. Tela de Limite de Crédito

Objetivo: controlar crédito concedido ao cliente.

Web:
- Card com limite atual, saldo usado e crédito disponível.
- Histórico de alterações.
- Formulário para ajustar limite.
- Estado de bloqueio de crédito.

Mobile:
- Resumo em cards.
- Formulário simples de ajuste.

Campos:
- Limite de crédito
- Prazo de pagamento
- Bloqueado: sim/não
- Motivo
- Validade do limite

Ações:
- Atualizar limite
- Bloquear crédito
- Desbloquear crédito
- Ver histórico

Estados:
- Crédito disponível
- Limite excedido
- Crédito bloqueado
- Alteração guardada

Permissões:
- `customers.credit.view`
- `customers.credit.update`
- `customers.credit.block`

Regras:
- Limite não pode ser negativo.
- Vendas a crédito devem validar saldo disponível.
- Alterações devem ser auditadas.

---

### 10. Tela de Conta Corrente do Cliente

Objetivo: mostrar movimentos financeiros do cliente.

Web:
- Tabela com data, documento, débito, crédito, saldo e estado.
- Filtros por período e tipo de documento.
- Cards de total faturado, total pago e saldo.
- Botão exportar.

Mobile:
- Lista cronológica.
- Resumo no topo.

Campos/Filtros:
- Período
- Tipo de documento
- Estado
- Documento

Ações:
- Filtrar
- Exportar
- Ver documento
- Registar pagamento

Estados:
- Sem movimentos
- Carregando
- Erro
- Sem permissão

Permissões:
- `customers.statement.view`
- `customers.statement.export`

Regras:
- Fonte principal vem de faturação e financeiro.
- Saldo deve bater com contas a receber.
- Não editar movimentos diretamente pela conta corrente.

---

### 11. Tela de Pagamentos do Cliente

Objetivo: consultar pagamentos recebidos do cliente.

Web:
- Tabela com data, recibo, meio de pagamento, valor, documento associado e estado.
- Filtros por período e meio de pagamento.
- Botão “Registar pagamento”.

Mobile:
- Cards por pagamento.
- Ação rápida para ver recibo.

Campos:
- Data
- Recibo
- Meio de pagamento
- Valor
- Documento
- Estado

Ações:
- Registar pagamento
- Ver recibo
- Exportar
- Anular, se permitido

Estados:
- Nenhum pagamento
- Pagamento registado
- Pagamento anulado
- Sem permissão

Permissões:
- `customer_payments.view`
- `payments.create`
- `payments.cancel`

Regras:
- Pagamentos devem estar ligados ao financeiro/tesouraria.
- Anulação deve gerar movimento inverso e auditoria.

---

### 12. Tela de Histórico Comercial

Objetivo: ver compras, propostas, faturas e interações comerciais do cliente.

Web:
- Timeline com eventos:
  - Cliente criado
  - Orçamento emitido
  - Fatura emitida
  - Pagamento recebido
  - Nota adicionada
  - Crédito alterado
- Filtros por tipo de evento.

Mobile:
- Timeline vertical.

Campos/Filtros:
- Período
- Tipo de evento
- Utilizador

Ações:
- Ver documento
- Adicionar nota
- Filtrar

Estados:
- Sem histórico
- Carregando
- Erro

Permissões:
- `customers.history.view`

Regras:
- Histórico comercial agrega eventos de vários módulos.
- Eventos críticos devem vir da auditoria.

---

### 13. Tela de Notas Internas do Cliente

Objetivo: registar observações internas sobre o cliente.

Web:
- Lista de notas com autor, data e conteúdo.
- Campo para nova nota.
- Filtros por autor/data.

Mobile:
- Timeline de notas.
- Campo de nova nota no final.

Campos:
- Nota
- Visibilidade: privada/equipa
- Etiquetas

Ações:
- Adicionar nota
- Editar nota própria
- Remover nota
- Filtrar

Estados:
- Nenhuma nota
- Nota adicionada
- Nota removida
- Sem permissão

Permissões:
- `customer_notes.view`
- `customer_notes.create`
- `customer_notes.update`
- `customer_notes.delete`

Regras:
- Notas privadas só aparecem ao autor.
- Notas não substituem auditoria.

---

### 14. Tela de Etiquetas de Clientes

Objetivo: classificar clientes com tags comerciais.

Web:
- Lista de etiquetas.
- Associação de etiquetas a clientes.
- Filtros por etiqueta na lista de clientes.

Mobile:
- Chips/tags selecionáveis.

Campos:
- Nome da etiqueta
- Cor
- Descrição
- Estado

Ações:
- Criar etiqueta
- Editar
- Associar ao cliente
- Remover do cliente

Estados:
- Nenhuma etiqueta
- Etiqueta criada
- Nome duplicado
- Sem permissão

Permissões:
- `customer_tags.view`
- `customer_tags.manage`

Regras:
- Etiquetas são por tenant.
- Não apagar etiqueta em uso sem confirmação.

---

### 15. Tela de Descontos por Cliente

Objetivo: configurar descontos comerciais específicos.

Web:
- Tabela de descontos por cliente, categoria ou produto.
- Validade e prioridade.
- Botão “Novo desconto”.

Mobile:
- Lista de descontos.
- Formulário em tela separada.

Campos:
- Tipo: geral, categoria, produto
- Produto/categoria
- Percentual ou valor fixo
- Data inicial
- Data final
- Estado

Ações:
- Criar desconto
- Editar
- Desativar
- Simular aplicação

Estados:
- Nenhum desconto
- Desconto criado
- Desconto expirado
- Conflito de regra

Permissões:
- `customer_discounts.view`
- `customer_discounts.manage`

Regras:
- Desconto não pode exceder limite máximo configurado.
- Descontos ativos devem ser considerados na faturação.
- Regras com sobreposição devem ter prioridade clara.**

---

## Módulo: Gestão de Produtos

Objetivo: gerir produtos, serviços, categorias, preços, unidades, variantes, códigos de barras, imagens, descontos, kits e classificações fiscais/comerciais.

### 1. Tela de Lista de Produtos

Objetivo: consultar e gerir produtos/serviços cadastrados.

Web:
- Sidebar do ERP.
- Topbar com pesquisa global.
- Tabela com código, nome, categoria, marca, preço, stock, IVA, estado.
- Filtros por categoria, marca, tipo, estado, stock baixo e preço.
- Botão “Novo produto”.
- Ações rápidas por linha.

Mobile:
- Lista em cards.
- Pesquisa no topo.
- Filtros em bottom sheet.
- Botão flutuante para novo produto.
- Indicador visual de stock/preço.

Campos visíveis:
- Código/SKU
- Nome
- Categoria
- Preço
- Stock atual
- Estado

Ações:
- Criar produto
- Ver detalhes
- Editar
- Duplicar
- Desativar
- Ajustar preço
- Ver stock

Estados:
- Nenhum produto cadastrado
- Carregando
- Erro ao carregar
- Sem permissão
- Lista filtrada sem resultados

Permissões:
- `products.view`
- `products.create`
- `products.update`
- `products.deactivate`

Regras:
- Produto pertence ao tenant ativo.
- SKU/código deve ser único por tenant.
- Produto com movimentos não deve ser apagado, apenas desativado.

---

### 2. Tela de Criar Produto

Objetivo: cadastrar novo produto ou serviço.

Web:
- Formulário dividido por secções:
  - Dados gerais
  - Classificação
  - Preço
  - Fiscal
  - Stock
  - Imagens
- Botões “Guardar”, “Guardar e novo” e “Cancelar”.

Mobile:
- Wizard:
  1. Dados gerais
  2. Preço e fiscal
  3. Stock
  4. Imagens
  5. Revisão

Campos:
- Tipo: produto, serviço, kit
- Código/SKU
- Nome
- Descrição
- Categoria
- Subcategoria
- Marca
- Unidade de medida
- Preço de venda
- Preço de custo
- IVA/taxa fiscal
- Controla stock: sim/não
- Armazém inicial
- Stock inicial
- Stock mínimo
- Estado

Ações:
- Guardar produto
- Guardar e criar outro
- Cancelar
- Gerar SKU automático
- Adicionar imagem

Estados:
- Salvando
- SKU duplicado
- Preço inválido
- Stock inicial inválido
- Produto criado
- Erro ao criar

Permissões:
- `products.create`
- `product_prices.create`
- `stock.initial.create`

Regras:
- Serviço não deve controlar stock.
- Produto físico pode controlar stock.
- Preço de venda não deve ser negativo.
- Stock inicial deve gerar movimento inicial no módulo de stock.

---

### 3. Tela de Editar Produto

Objetivo: alterar dados do produto.

Web:
- Formulário com tabs:
  - Geral
  - Preços
  - Fiscal
  - Stock
  - Imagens
  - Códigos de barras
  - Variantes
- Ações críticas em área separada.

Mobile:
- Secções expansíveis.
- Ações críticas no menu.

Campos:
- Nome
- Descrição
- Categoria
- Marca
- Unidade
- Preço
- IVA
- Stock mínimo
- Estado
- Controla stock

Ações:
- Guardar alterações
- Cancelar
- Desativar produto
- Duplicar produto
- Ver histórico

Estados:
- Salvando
- Alterações guardadas
- Erro de validação
- Produto desativado
- Sem permissão

Permissões:
- `products.update`
- `product_prices.update`
- `products.deactivate`

Regras:
- Não permitir alterar tipo de produto se já houver movimentos incompatíveis.
- Alterações de preço devem manter histórico.
- Alterações fiscais devem ser auditadas.

---

### 4. Tela de Detalhes do Produto

Objetivo: visualizar ficha completa do produto.

Web:
- Cabeçalho com nome, SKU, estado e preço.
- Cards:
  - Stock atual
  - Stock mínimo
  - Preço de venda
  - Margem estimada
  - Última venda
- Tabs:
  - Resumo
  - Preços
  - Stock
  - Variantes
  - Imagens
  - Códigos de barras
  - Histórico
  - Kits

Mobile:
- Cabeçalho compacto com imagem.
- Cards empilhados.
- Tabs horizontais.

Campos visíveis:
- SKU
- Nome
- Categoria
- Unidade
- Preço
- Stock
- IVA
- Estado

Ações:
- Editar
- Criar fatura com produto
- Ajustar stock
- Alterar preço
- Ver movimentos

Estados:
- Produto não encontrado
- Carregando
- Sem permissão
- Dados carregados

Permissões:
- `products.view`
- `product_stock.view`
- `product_prices.view`

Regras:
- Stock vem do módulo `gestao-stock`.
- Histórico de vendas vem da faturação/POS.
- Margem depende de preço de custo e venda.

---

### 5. Tela de Categorias de Produtos

Objetivo: organizar produtos por categorias e subcategorias.

Web:
- Estrutura em árvore ou tabela hierárquica.
- Botão “Nova categoria”.
- Ações: editar, desativar, criar subcategoria.

Mobile:
- Lista hierárquica.
- Expansão por toque.

Campos:
- Nome
- Código
- Categoria pai
- Descrição
- Estado
- Ordem

Ações:
- Criar categoria
- Criar subcategoria
- Editar
- Desativar
- Reordenar

Estados:
- Nenhuma categoria
- Categoria criada
- Código duplicado
- Sem permissão

Permissões:
- `product_categories.view`
- `product_categories.create`
- `product_categories.update`

Regras:
- Categoria com produtos não deve ser apagada.
- Subcategorias herdam contexto da categoria pai.
- Código deve ser único por tenant.

---

### 6. Tela de Marcas

Objetivo: gerir marcas dos produtos.

Web:
- Tabela com nome, descrição, estado e quantidade de produtos.
- Botão “Nova marca”.

Mobile:
- Cards por marca.
- Pesquisa no topo.

Campos:
- Nome da marca
- Descrição
- Estado

Ações:
- Criar marca
- Editar
- Desativar
- Ver produtos da marca

Estados:
- Nenhuma marca
- Marca criada
- Nome duplicado

Permissões:
- `product_brands.view`
- `product_brands.manage`

Regras:
- Não apagar marca associada a produtos.
- Marca pode ser opcional no produto.

---

### 7. Tela de Unidades de Medida

Objetivo: gerir unidades usadas em produtos e documentos.

Web:
- Tabela com nome, símbolo, tipo e estado.
- Botão “Nova unidade”.

Mobile:
- Lista simples.

Campos:
- Nome
- Símbolo
- Tipo: unidade, peso, volume, comprimento, tempo
- Casas decimais permitidas
- Estado

Ações:
- Criar unidade
- Editar
- Desativar

Estados:
- Nenhuma unidade
- Unidade criada
- Símbolo duplicado

Permissões:
- `product_units.view`
- `product_units.manage`

Regras:
- Unidade usada em documentos não deve ser apagada.
- Serviços podem usar unidade “serviço” ou “hora”.
- Produtos físicos normalmente usam unidade, kg, litro, caixa.

---

### 8. Tela de Preços do Produto

Objetivo: gerir preços e histórico de preços.

Web:
- Tabela de preços por produto:
  - Preço venda
  - Preço custo
  - Moeda
  - Data inicial
  - Data final
  - Estado
- Botão “Novo preço”.
- Histórico de alterações.

Mobile:
- Lista de preços.
- Formulário simples.

Campos:
- Produto
- Tipo de preço: venda, custo, atacado, promocional
- Valor
- Moeda
- Data inicial
- Data final
- Estado

Ações:
- Criar preço
- Editar preço
- Encerrar preço
- Ver histórico

Estados:
- Nenhum preço
- Preço ativo
- Preço expirado
- Conflito de datas

Permissões:
- `product_prices.view`
- `product_prices.create`
- `product_prices.update`

Regras:
- Não deve haver dois preços ativos iguais para o mesmo tipo e período.
- Preço de venda não pode ser negativo.
- Alterações de preço devem ser auditadas.

---

### 9. Tela de Descontos de Produto

Objetivo: configurar descontos por produto, categoria ou período.

Web:
- Tabela com produto/categoria, tipo de desconto, valor, período e estado.
- Botão “Novo desconto”.
- Simulação de preço final.

Mobile:
- Cards de desconto.
- Simulador simples.

Campos:
- Produto ou categoria
- Tipo: percentual ou valor fixo
- Valor
- Data inicial
- Data final
- Estado
- Prioridade

Ações:
- Criar desconto
- Editar
- Desativar
- Simular

Estados:
- Nenhum desconto
- Desconto ativo
- Desconto expirado
- Conflito de regras

Permissões:
- `product_discounts.view`
- `product_discounts.manage`

Regras:
- Desconto não pode deixar preço final negativo.
- Descontos com sobreposição precisam de prioridade clara.
- Faturação deve aplicar descontos ativos conforme regra.

---

### 10. Tela de Códigos de Barras

Objetivo: gerir códigos de barras associados ao produto.

Web:
- Lista de códigos por produto.
- Campo para leitura por scanner.
- Botão “Novo código”.

Mobile:
- Entrada manual ou leitura por câmera, se suportado.

Campos:
- Produto
- Código de barras
- Tipo: EAN13, QR, interno
- Principal: sim/não
- Estado

Ações:
- Adicionar código
- Remover
- Definir principal
- Ler código

Estados:
- Nenhum código
- Código duplicado
- Código adicionado
- Código inválido

Permissões:
- `product_barcodes.view`
- `product_barcodes.manage`

Regras:
- Código de barras deve ser único por tenant.
- Apenas um código principal por produto.
- POS deve localizar produto por código de barras.

---

### 11. Tela de Imagens do Produto

Objetivo: gerir imagens dos produtos.

Web:
- Galeria de imagens.
- Upload por arrastar e soltar.
- Definir imagem principal.
- Pré-visualização.

Mobile:
- Galeria em grid.
- Upload por câmera ou ficheiro.

Campos:
- Imagem
- Descrição
- Principal: sim/não
- Ordem

Ações:
- Carregar imagem
- Remover imagem
- Definir principal
- Reordenar

Estados:
- Sem imagem
- Upload em andamento
- Imagem carregada
- Tamanho excedido
- Formato inválido

Permissões:
- `product_images.view`
- `product_images.upload`
- `product_images.delete`

Regras:
- Validar tipo e tamanho do ficheiro.
- Apenas uma imagem principal.
- Imagens podem aparecer em POS, catálogo e documentos.

---

### 12. Tela de Atributos e Variantes

Objetivo: configurar variantes de produto, como tamanho, cor, modelo ou capacidade.

Web:
- Editor de atributos.
- Lista de variantes geradas.
- Preço e SKU por variante.
- Stock por variante, quando aplicável.

Mobile:
- Acordeões por atributo.
- Lista de variantes.

Campos:
- Atributo: cor, tamanho, modelo
- Valor do atributo
- SKU da variante
- Preço adicional
- Código de barras
- Estado

Ações:
- Criar atributo
- Adicionar valor
- Gerar variantes
- Editar variante
- Desativar variante

Estados:
- Nenhum atributo
- Variantes geradas
- SKU duplicado
- Combinação existente

Permissões:
- `product_attributes.view`
- `product_attributes.manage`
- `product_variants.manage`

Regras:
- Variante deve ter SKU único.
- Produto com variantes pode exigir stock por variante.
- Não permitir duplicar combinação de atributos.

---

### 13. Tela de Kits de Produtos

Objetivo: montar produtos compostos por outros produtos.

Web:
- Lista de kits.
- Formulário com produto principal e itens do kit.
- Cálculo de custo e preço sugerido.

Mobile:
- Lista de kits.
- Edição em etapas.

Campos:
- Produto kit
- Produto componente
- Quantidade
- Unidade
- Custo estimado
- Preço de venda
- Estado

Ações:
- Criar kit
- Adicionar item ao kit
- Remover item
- Simular custo
- Ativar/desativar kit

Estados:
- Nenhum kit
- Kit criado
- Produto componente inválido
- Stock insuficiente na simulação

Permissões:
- `product_kits.view`
- `product_kits.manage`

Regras:
- Kit não deve conter ele mesmo como componente.
- Venda de kit pode baixar stock dos componentes.
- Custo do kit pode ser calculado pelos componentes.

---

### 14. Tela de Etiquetas de Produto

Objetivo: classificar produtos com tags internas.

Web:
- Lista de etiquetas.
- Associação a produtos.
- Filtros por etiqueta na lista de produtos.

Mobile:
- Chips selecionáveis.

Campos:
- Nome
- Cor
- Descrição
- Estado

Ações:
- Criar etiqueta
- Editar
- Associar
- Remover

Estados:
- Nenhuma etiqueta
- Etiqueta criada
- Nome duplicado

Permissões:
- `product_tags.view`
- `product_tags.manage`

Regras:
- Etiquetas são por tenant.
- Etiquetas ajudam pesquisa e segmentação.

---

### 15. Tela de Importação de Produtos

Objetivo: criar ou atualizar produtos em massa.

Web:
- Upload CSV/XLSX.
- Download de modelo.
- Mapeamento de colunas.
- Pré-visualização.
- Validação por linha.
- Botão “Importar”.

Mobile:
- Consulta de importações e erros.
- Upload pode ser limitado.

Campos:
- Ficheiro
- Categoria padrão
- Unidade padrão
- Atualizar existentes: sim/não
- Criar stock inicial: sim/não

Ações:
- Baixar modelo
- Carregar ficheiro
- Validar
- Importar
- Ver erros

Estados:
- Sem ficheiro
- Validando
- Erros encontrados
- Importação parcial
- Importação concluída

Permissões:
- `products.import`

Regras:
- SKU duplicado deve atualizar ou rejeitar conforme opção.
- Linhas inválidas devem ser reportadas.
- Stock inicial deve gerar movimento no módulo de stock.

---

### 16. Tela de Histórico do Produto

Objetivo: ver alterações e eventos relacionados ao produto.

Web:
- Timeline com alterações de preço, stock, dados fiscais, imagens e vendas.
- Filtros por tipo de evento.

Mobile:
- Timeline vertical.

Campos/Filtros:
- Período
- Tipo de evento
- Utilizador
- Módulo

Ações:
- Filtrar
- Ver detalhe
- Exportar

Estados:
- Sem histórico
- Carregando
- Erro
- Sem permissão

Permissões:
- `products.history.view`

Regras:
- Alterações críticas vêm da auditoria.
- Movimentos de stock vêm de `gestao-stock`.
- Vendas vêm de faturação/POS.**

---

## Módulo: Faturação

Objetivo: gerir o ciclo comercial completo: orçamentos, encomendas, guias de remessa, faturas, recibos, notas de crédito, devoluções, séries documentais e integração com stock, financeiro e contabilidade.

### 1. Tela de Dashboard de Faturação

Objetivo: apresentar visão geral de vendas e documentos.

Web:
- Sidebar do ERP.
- Topbar com empresa ativa.
- Cards:
  - Vendas do mês
  - Faturas emitidas
  - Faturas vencidas
  - Valor por receber
  - Orçamentos pendentes
  - Notas de crédito
- Gráfico de vendas por período.
- Lista de documentos recentes.
- Filtros por período, filial e vendedor.

Mobile:
- Cards empilhados.
- Gráfico simplificado.
- Lista de documentos recentes.

Campos/Filtros:
- Período
- Filial
- Vendedor
- Tipo de documento

Ações:
- Nova fatura
- Novo orçamento
- Novo recibo
- Ver vencidas
- Exportar resumo

Estados:
- Sem documentos
- Carregando
- Erro
- Sem permissão

Permissões:
- `billing.dashboard.view`

Regras:
- Indicadores vêm de faturas, recibos e financeiro.
- Mostrar apenas documentos do tenant ativo.
- Valores devem respeitar moeda padrão ou moeda do documento.

---

### 2. Tela de Séries Documentais

Objetivo: gerir numeração de documentos comerciais.

Web:
- Tabela com tipo, série, ano, prefixo, sequência atual, próxima numeração e estado.
- Botão “Nova série”.
- Pré-visualização do próximo número.

Mobile:
- Cards por série.
- Ação para ativar/desativar.

Campos:
- Tipo de documento: orçamento, encomenda, guia, fatura, recibo, nota de crédito
- Série
- Prefixo
- Ano
- Sequência inicial
- Sequência atual
- Filial
- Estado

Ações:
- Criar série
- Editar
- Ativar/desativar
- Ver próximo número

Estados:
- Nenhuma série
- Série criada
- Prefixo duplicado
- Sequência inválida

Permissões:
- `invoice_series.view`
- `invoice_series.create`
- `invoice_series.update`

Regras:
- Numeração deve ser sequencial e atômica.
- Não permitir reduzir sequência já usada.
- Série ativa deve ser única por tipo/filial/ano, conforme regra fiscal.

---

### 3. Tela de Orçamentos

Objetivo: gerir propostas/orçamentos enviados a clientes.

Web:
- Tabela com número, cliente, data, validade, total, estado e vendedor.
- Filtros por estado, cliente, período e vendedor.
- Botão “Novo orçamento”.

Mobile:
- Lista em cards.
- Estado destacado: rascunho, enviado, aceite, recusado, expirado.

Campos visíveis:
- Número
- Cliente
- Validade
- Total
- Estado

Ações:
- Criar orçamento
- Ver detalhe
- Editar
- Enviar
- Converter em encomenda
- Converter em fatura
- Cancelar

Estados:
- Nenhum orçamento
- Rascunho
- Enviado
- Aceite
- Recusado
- Expirado

Permissões:
- `sales_quotes.view`
- `sales_quotes.create`
- `sales_quotes.update`
- `sales_quotes.convert`

Regras:
- Orçamento não movimenta stock.
- Orçamento aceite pode virar encomenda ou fatura.
- Orçamento expirado deve exigir renovação antes de converter.

---

### 4. Tela de Criar/Editar Orçamento

Objetivo: criar ou alterar orçamento comercial.

Web:
- Cabeçalho com cliente, data, validade e vendedor.
- Tabela de itens com produto, quantidade, preço, desconto, IVA e total.
- Resumo financeiro lateral.
- Botões: guardar, enviar, converter.

Mobile:
- Fluxo em etapas:
  1. Cliente
  2. Itens
  3. Condições
  4. Revisão

Campos:
- Cliente
- Data
- Validade
- Produto/serviço
- Quantidade
- Preço unitário
- Desconto
- IVA
- Observações
- Termos comerciais

Ações:
- Adicionar item
- Remover item
- Aplicar desconto
- Guardar rascunho
- Enviar
- Converter

Estados:
- Produto inválido
- Cliente obrigatório
- Orçamento guardado
- Total recalculado
- Erro de validação

Permissões:
- `sales_quotes.create`
- `sales_quotes.update`

Regras:
- Produto deve vir de `gestao-produtos`.
- Cliente deve vir de `gestao-clientes`.
- Total = subtotal - descontos + impostos.
- Não movimenta stock.

---

### 5. Tela de Encomendas de Venda

Objetivo: gerir pedidos confirmados de clientes.

Web:
- Tabela com número, cliente, data, estado, entrega, total e saldo entregue.
- Filtros por estado e período.
- Botão “Nova encomenda”.

Mobile:
- Cards com progresso de entrega.

Campos visíveis:
- Número
- Cliente
- Total
- Estado
- Entregue/parcial

Ações:
- Criar encomenda
- Ver detalhe
- Gerar guia de remessa
- Gerar fatura
- Cancelar

Estados:
- Rascunho
- Confirmada
- Parcialmente entregue
- Entregue
- Faturada
- Cancelada

Permissões:
- `sales_orders.view`
- `sales_orders.create`
- `sales_orders.update`
- `sales_orders.convert`

Regras:
- Encomenda pode reservar stock.
- Entrega parcial deve ser controlada por linha.
- Cancelamento deve libertar reservas.

---

### 6. Tela de Guias de Remessa

Objetivo: gerir entrega física de produtos ao cliente.

Web:
- Tabela com número, cliente, data, transportador, estado e encomenda/fatura origem.
- Botão “Nova guia”.
- Filtros por estado.

Mobile:
- Cards com estado de entrega.

Campos:
- Cliente
- Documento origem
- Produtos
- Quantidade entregue
- Transportador
- Matrícula
- Endereço de entrega
- Estado

Ações:
- Criar guia
- Confirmar saída
- Imprimir/baixar PDF
- Marcar entregue
- Cancelar

Estados:
- Rascunho
- Emitida
- Em transporte
- Entregue
- Cancelada

Permissões:
- `sales_deliveries.view`
- `sales_deliveries.create`
- `sales_deliveries.update`

Regras:
- Guia pode baixar stock ao ser emitida ou entregue, conforme configuração.
- Quantidade entregue não pode exceder encomendada.
- Guia deve referenciar armazém de saída.

---

### 7. Tela de Faturas

Objetivo: consultar e gerir faturas emitidas.

Web:
- Tabela com número, cliente, data, vencimento, total, saldo, estado e vendedor.
- Filtros por estado, cliente, período, vencidas e pagas.
- Botão “Nova fatura”.

Mobile:
- Cards por fatura.
- Indicadores de paga, parcial, vencida.

Campos visíveis:
- Número
- Cliente
- Data
- Vencimento
- Total
- Saldo pendente
- Estado

Ações:
- Criar fatura
- Ver detalhe
- Emitir
- Enviar por email
- Registar recibo
- Criar nota de crédito
- Baixar PDF
- Anular, se permitido

Estados:
- Rascunho
- Emitida
- Parcialmente paga
- Paga
- Vencida
- Anulada

Permissões:
- `invoices.view`
- `invoices.create`
- `invoices.issue`
- `invoices.cancel`

Regras:
- Fatura emitida cria conta a receber no `financeiro`.
- Fatura emitida pode gerar lançamento na `contabilidade`.
- Fatura com produtos pode baixar/reservar stock conforme regra.
- Fatura anulada exige motivo e auditoria.

---

### 8. Tela de Criar/Editar Fatura

Objetivo: criar documento fiscal de venda.

Web:
- Cabeçalho com cliente, série, data, vencimento, moeda e vendedor.
- Linhas de itens.
- Painel lateral com subtotal, descontos, impostos, total e saldo.
- Alertas de crédito e stock.
- Botões “Guardar rascunho”, “Emitir”, “Cancelar”.

Mobile:
- Fluxo em etapas:
  1. Cliente
  2. Itens
  3. Pagamento/condições
  4. Revisão e emissão

Campos:
- Cliente
- Série
- Data
- Vencimento
- Produto/serviço
- Armazém
- Quantidade
- Preço
- Desconto
- IVA
- Moeda
- Observação
- Condição de pagamento

Ações:
- Adicionar item
- Validar stock
- Aplicar desconto
- Guardar rascunho
- Emitir fatura
- Gerar PDF

Estados:
- Cliente sem crédito
- Stock insuficiente
- Produto sem preço
- Fatura guardada
- Fatura emitida
- Erro fiscal

Permissões:
- `invoices.create`
- `invoices.update`
- `invoices.issue`

Regras:
- Cliente obrigatório.
- Série ativa obrigatória.
- Numeração só deve fechar ao emitir.
- Emitir fatura deve validar stock, crédito, impostos e totais.
- Documento emitido não deve ser editado diretamente.

---

### 9. Tela de Detalhes da Fatura

Objetivo: visualizar fatura completa.

Web:
- Cabeçalho com número, cliente, estado e total.
- Dados fiscais.
- Itens da fatura.
- Resumo de impostos.
- Pagamentos associados.
- Histórico do documento.
- Botões de ação.

Mobile:
- Cabeçalho compacto.
- Secções: itens, pagamentos, histórico.

Campos visíveis:
- Número
- Cliente
- NUIT
- Data
- Vencimento
- Itens
- Impostos
- Total
- Saldo
- Estado

Ações:
- Baixar PDF
- Enviar email
- Registar recibo
- Criar nota de crédito
- Ver lançamento contabilístico
- Ver movimentos de stock

Estados:
- Fatura paga
- Fatura vencida
- Fatura anulada
- Carregando

Permissões:
- `invoices.view`
- `invoice_pdf.download`
- `invoice_email.send`

Regras:
- Documento emitido deve manter histórico.
- Pagamentos reduzem saldo pendente.
- Nota de crédito reduz ou anula saldo.

---

### 10. Tela de Recibos

Objetivo: gerir recibos de pagamento de faturas.

Web:
- Tabela com número, cliente, data, valor, meio de pagamento e fatura associada.
- Filtros por cliente, período e meio.
- Botão “Novo recibo”.

Mobile:
- Cards por recibo.
- Ação rápida para baixar PDF.

Campos:
- Cliente
- Fatura
- Data
- Valor recebido
- Meio de pagamento
- Conta/caixa
- Referência bancária
- Observação

Ações:
- Criar recibo
- Ver detalhe
- Baixar PDF
- Anular recibo

Estados:
- Nenhum recibo
- Recibo emitido
- Recibo anulado
- Valor excede saldo

Permissões:
- `invoice_receipts.view`
- `invoice_receipts.create`
- `invoice_receipts.cancel`

Regras:
- Valor recebido não pode exceder saldo da fatura, salvo adiantamento permitido.
- Recibo movimenta financeiro/tesouraria.
- Anulação gera movimento inverso.

---

### 11. Tela de Criar Recibo

Objetivo: registar pagamento recebido de cliente.

Web:
- Seleção de cliente.
- Lista de faturas em aberto.
- Campo de valor recebido por fatura.
- Meio de pagamento e destino na tesouraria.
- Botão “Emitir recibo”.

Mobile:
- Fluxo:
  1. Cliente
  2. Faturas
  3. Pagamento
  4. Confirmação

Campos:
- Cliente
- Fatura
- Valor a pagar
- Meio de pagamento
- Caixa/conta bancária
- Data
- Referência
- Observação

Ações:
- Selecionar faturas
- Distribuir pagamento
- Emitir recibo
- Cancelar

Estados:
- Cliente sem faturas em aberto
- Valor inválido
- Recibo emitido
- Erro ao movimentar tesouraria

Permissões:
- `invoice_receipts.create`
- `payments.create`

Regras:
- Deve atualizar saldo da fatura.
- Deve criar pagamento no financeiro.
- Deve criar movimento de caixa/banco na tesouraria.
- Deve gerar lançamento contabilístico se configurado.

---

### 12. Tela de Notas de Crédito

Objetivo: gerir anulações parciais ou totais de faturas.

Web:
- Tabela com número, cliente, fatura origem, data, valor e estado.
- Botão “Nova nota de crédito”.

Mobile:
- Cards com fatura origem e valor creditado.

Campos:
- Fatura origem
- Cliente
- Motivo
- Itens creditados
- Valor
- Estado

Ações:
- Criar nota de crédito
- Emitir
- Ver PDF
- Aplicar ao saldo
- Cancelar

Estados:
- Rascunho
- Emitida
- Aplicada
- Cancelada

Permissões:
- `credit_notes.view`
- `credit_notes.create`
- `credit_notes.issue`

Regras:
- Nota de crédito deve referenciar fatura emitida.
- Valor creditado não pode exceder valor disponível da fatura.
- Pode devolver stock conforme motivo/configuração.
- Deve atualizar financeiro e contabilidade.

---

### 13. Tela de Devoluções

Objetivo: controlar devolução física de produtos vendidos.

Web:
- Tabela com cliente, documento origem, data, estado e total de itens.
- Botão “Nova devolução”.

Mobile:
- Cards por devolução.
- Estado de receção destacado.

Campos:
- Documento origem
- Cliente
- Produto
- Quantidade devolvida
- Estado do produto: bom, danificado, defeito
- Armazém de entrada
- Motivo

Ações:
- Criar devolução
- Confirmar receção
- Gerar nota de crédito
- Cancelar

Estados:
- Solicitada
- Recebida
- Parcial
- Rejeitada
- Cancelada

Permissões:
- `sales_returns.view`
- `sales_returns.create`
- `sales_returns.receive`

Regras:
- Quantidade devolvida não pode exceder vendida.
- Produto recebido pode entrar no stock ou ir para bloqueado/danificado.
- Devolução pode gerar nota de crédito.

---

### 14. Tela de Documentos Vencidos

Objetivo: acompanhar faturas vencidas e cobranças pendentes.

Web:
- Tabela com cliente, fatura, vencimento, dias em atraso, saldo e contacto.
- Filtros por dias em atraso, cliente e valor.
- Ações de cobrança.

Mobile:
- Lista de cobrança em cards.
- Botões rápidos: ligar, email, WhatsApp.

Campos:
- Cliente
- Fatura
- Vencimento
- Dias em atraso
- Saldo
- Contacto

Ações:
- Enviar lembrete
- Registar pagamento
- Ver cliente
- Ver fatura
- Exportar lista

Estados:
- Sem vencidos
- Fatura vencida
- Lembrete enviado
- Pagamento registado

Permissões:
- `invoices.overdue.view`
- `collections.manage`

Regras:
- Dias em atraso calculados pela data de vencimento.
- Lembretes devem ser registados no histórico do cliente/documento.

---

### 15. Tela de Relatórios de Faturação

Objetivo: gerar relatórios comerciais e fiscais.

Web:
- Lista de relatórios:
  - Vendas por período
  - Vendas por cliente
  - Vendas por produto
  - Faturas em aberto
  - IVA por período
  - Recibos emitidos
  - Notas de crédito
- Filtros e exportação.

Mobile:
- Seleção de relatório.
- Visualização resumida.
- Exportação por email/download.

Campos/Filtros:
- Período
- Cliente
- Produto
- Vendedor
- Filial
- Estado do documento
- Formato

Ações:
- Gerar relatório
- Exportar PDF/XLSX/CSV
- Agendar envio

Estados:
- Sem dados
- Gerando
- Relatório pronto
- Erro

Permissões:
- `billing_reports.view`
- `billing_reports.export`

Regras:
- Relatórios fiscais devem respeitar documentos emitidos.
- Exportações devem ser auditadas.
- Valores devem considerar notas de crédito e anulações.**

---

## Módulo: Financeiro

Objetivo: gerir contas a receber, contas a pagar, pagamentos, recebimentos, categorias financeiras, fluxo de caixa, orçamentos e relatórios financeiros.

### 1. Tela de Dashboard Financeiro

Objetivo: apresentar visão geral financeira da empresa.

Web:
- Sidebar do ERP.
- Topbar com empresa ativa.
- Cards:
  - Total a receber
  - Total a pagar
  - Recebido no mês
  - Pago no mês
  - Fluxo previsto
  - Contas vencidas
- Gráficos:
  - Receitas vs despesas
  - Fluxo de caixa previsto
  - Aging de clientes
- Lista de contas vencidas e próximos pagamentos.

Mobile:
- Cards empilhados.
- Gráficos simplificados.
- Lista de pendências.

Campos/Filtros:
- Período
- Filial
- Moeda
- Categoria financeira

Ações:
- Nova conta a receber
- Nova conta a pagar
- Registar recebimento
- Registar pagamento
- Ver vencidos
- Gerar relatório

Estados:
- Sem dados financeiros
- Carregando
- Erro
- Sem permissão

Permissões:
- `financial.dashboard.view`

Regras:
- Indicadores devem considerar apenas documentos válidos.
- Valores vencidos dependem da data de vencimento.
- Multi-moeda deve separar ou converter conforme configuração.

---

### 2. Tela de Contas a Receber

Objetivo: gerir valores em dívida de clientes.

Web:
- Tabela com cliente, documento, emissão, vencimento, valor original, valor recebido, saldo, estado.
- Filtros por cliente, estado, período, vencidas e moeda.
- Botão “Nova conta a receber”.

Mobile:
- Cards por título.
- Destaque para vencidos e parcialmente pagos.

Campos visíveis:
- Cliente
- Documento origem
- Vencimento
- Valor
- Saldo
- Estado

Ações:
- Ver detalhe
- Registar recebimento
- Renegociar vencimento
- Baixar por perda
- Exportar

Estados:
- Aberta
- Parcialmente recebida
- Recebida
- Vencida
- Cancelada
- Baixada

Permissões:
- `accounts_receivable.view`
- `accounts_receivable.create`
- `accounts_receivable.update`
- `accounts_receivable.writeoff`

Regras:
- Fatura emitida cria conta a receber automaticamente.
- Saldo = valor original - recebimentos - créditos aplicados.
- Baixa por perda exige motivo e permissão especial.

---

### 3. Tela de Detalhe da Conta a Receber

Objetivo: visualizar título financeiro de cliente.

Web:
- Cabeçalho com cliente, documento, vencimento, saldo e estado.
- Cards:
  - Valor original
  - Recebido
  - Saldo
  - Dias em atraso
- Tabs:
  - Pagamentos
  - Histórico
  - Documento origem
  - Renegociações

Mobile:
- Resumo no topo.
- Secções expansíveis.

Campos:
- Cliente
- Documento origem
- Data de emissão
- Data de vencimento
- Valor original
- Valor recebido
- Saldo
- Estado

Ações:
- Registar recebimento
- Ver fatura
- Alterar vencimento
- Baixar saldo
- Exportar

Estados:
- Aberta
- Vencida
- Recebida
- Cancelada

Permissões:
- `accounts_receivable.view_detail`
- `payments.create`

Regras:
- Não permitir recebimento acima do saldo, salvo adiantamento permitido.
- Alteração de vencimento deve ser auditada.
- Pagamentos devem ir para tesouraria.

---

### 4. Tela de Registar Recebimento

Objetivo: lançar recebimento de cliente.

Web:
- Seleção de cliente.
- Lista de contas a receber abertas.
- Distribuição do valor por títulos.
- Método de pagamento.
- Destino: caixa ou conta bancária.
- Botão “Confirmar recebimento”.

Mobile:
- Fluxo:
  1. Cliente
  2. Títulos
  3. Pagamento
  4. Confirmação

Campos:
- Cliente
- Contas a receber
- Valor recebido
- Data
- Meio de pagamento
- Caixa/conta bancária
- Referência
- Observação

Ações:
- Selecionar títulos
- Distribuir automaticamente
- Confirmar recebimento
- Cancelar

Estados:
- Cliente sem contas abertas
- Valor inválido
- Recebimento registado
- Erro de tesouraria

Permissões:
- `receivables_payments.create`
- `payments.create`

Regras:
- Recebimento atualiza saldo da conta a receber.
- Deve criar movimento na tesouraria.
- Pode gerar lançamento contabilístico.

---

### 5. Tela de Contas a Pagar

Objetivo: gerir obrigações com fornecedores, impostos, salários e despesas.

Web:
- Tabela com fornecedor/beneficiário, documento, emissão, vencimento, valor, pago, saldo e estado.
- Filtros por fornecedor, estado, vencimento, categoria e moeda.
- Botão “Nova conta a pagar”.

Mobile:
- Cards por obrigação.
- Destaque para vencidas/próximas do vencimento.

Campos visíveis:
- Fornecedor/beneficiário
- Documento
- Vencimento
- Valor
- Saldo
- Estado

Ações:
- Criar conta a pagar
- Ver detalhe
- Registar pagamento
- Reagendar
- Cancelar
- Exportar

Estados:
- Aberta
- Parcialmente paga
- Paga
- Vencida
- Cancelada

Permissões:
- `accounts_payable.view`
- `accounts_payable.create`
- `accounts_payable.update`
- `accounts_payable.cancel`

Regras:
- Compras podem criar contas a pagar automaticamente.
- Saldo = valor original - pagamentos.
- Pagamento deve movimentar tesouraria.

---

### 6. Tela de Criar Conta a Pagar

Objetivo: registar uma obrigação financeira manual.

Web:
- Formulário com beneficiário, categoria, valor, vencimento e documento.
- Anexo opcional.
- Botão “Guardar”.

Mobile:
- Formulário em etapas curtas.

Campos:
- Tipo de beneficiário: fornecedor, funcionário, imposto, outro
- Beneficiário
- Categoria financeira
- Documento/referência
- Data de emissão
- Data de vencimento
- Valor
- Moeda
- Observação
- Anexo

Ações:
- Guardar
- Guardar e pagar
- Cancelar

Estados:
- Valor inválido
- Vencimento obrigatório
- Conta criada
- Erro

Permissões:
- `accounts_payable.create`

Regras:
- Valor deve ser maior que zero.
- Categoria financeira obrigatória.
- Documento duplicado para o mesmo fornecedor pode exigir alerta.

---

### 7. Tela de Registar Pagamento

Objetivo: lançar pagamento de conta a pagar.

Web:
- Seleção de beneficiário.
- Lista de contas abertas.
- Distribuição do pagamento.
- Origem: caixa ou conta bancária.
- Botão “Confirmar pagamento”.

Mobile:
- Fluxo:
  1. Beneficiário
  2. Contas
  3. Origem do pagamento
  4. Confirmação

Campos:
- Beneficiário
- Conta a pagar
- Valor pago
- Data
- Meio de pagamento
- Caixa/conta bancária
- Referência
- Observação

Ações:
- Selecionar contas
- Confirmar pagamento
- Cancelar

Estados:
- Saldo insuficiente
- Valor inválido
- Pagamento registado
- Erro de tesouraria

Permissões:
- `payables_payments.create`
- `payments.create`

Regras:
- Pagamento reduz saldo da conta a pagar.
- Deve criar saída na tesouraria.
- Pode gerar lançamento contabilístico.

---

### 8. Tela de Pagamentos e Recebimentos

Objetivo: consultar todos os pagamentos/recebimentos financeiros.

Web:
- Tabela com tipo, data, entidade, valor, método, origem, destino e estado.
- Filtros por tipo, período, entidade, meio e estado.
- Exportação.

Mobile:
- Timeline/lista cronológica.
- Indicadores de entrada/saída.

Campos:
- Tipo: recebimento/pagamento
- Entidade
- Valor
- Meio de pagamento
- Caixa/conta
- Documento origem
- Estado

Ações:
- Filtrar
- Ver detalhe
- Anular
- Exportar

Estados:
- Confirmado
- Anulado
- Pendente
- Erro

Permissões:
- `payments.view`
- `payments.cancel`
- `payments.export`

Regras:
- Pagamento confirmado não deve ser editado.
- Anulação deve gerar movimento inverso.
- Origem deve apontar para faturação, compras, RH ou lançamento manual.

---

### 9. Tela de Métodos de Pagamento

Objetivo: configurar meios usados em recebimentos e pagamentos.

Web:
- Tabela com nome, tipo, requer referência, estado e integração.
- Botão “Novo método”.

Mobile:
- Lista com toggles de ativação.

Campos:
- Nome
- Tipo: numerário, TPA, transferência, M-Pesa, e-Mola, cheque, cartão, outro
- Requer referência: sim/não
- Integração associada
- Estado

Ações:
- Criar método
- Editar
- Ativar/desativar

Estados:
- Método criado
- Nome duplicado
- Sem permissão

Permissões:
- `payment_methods.view`
- `payment_methods.manage`

Regras:
- Métodos usados em movimentos não devem ser apagados.
- Alguns métodos podem exigir referência obrigatória.
- Integrações digitais devem validar transação, se configurado.

---

### 10. Tela de Categorias Financeiras

Objetivo: organizar receitas e despesas.

Web:
- Árvore de categorias.
- Tipo: receita, despesa, ambos.
- Associação opcional a conta contabilística.
- Botão “Nova categoria”.

Mobile:
- Lista hierárquica.

Campos:
- Nome
- Código
- Tipo
- Categoria pai
- Conta contabilística
- Estado

Ações:
- Criar categoria
- Editar
- Desativar
- Reordenar

Estados:
- Nenhuma categoria
- Categoria criada
- Código duplicado

Permissões:
- `financial_categories.view`
- `financial_categories.manage`

Regras:
- Categoria usada em lançamentos não deve ser apagada.
- Associação contabilística facilita lançamentos automáticos.

---

### 11. Tela de Fluxo de Caixa

Objetivo: visualizar entradas e saídas realizadas e previstas.

Web:
- Gráfico de fluxo por período.
- Tabela com data, tipo, origem, valor, realizado/previsto.
- Filtros por categoria, conta e período.
- Visão diária, semanal, mensal.

Mobile:
- Resumo por período.
- Lista de próximos fluxos.

Campos/Filtros:
- Período
- Categoria
- Tipo
- Estado: previsto/realizado
- Moeda

Ações:
- Filtrar
- Exportar
- Ver origem
- Criar previsão manual

Estados:
- Sem fluxo
- Fluxo positivo
- Fluxo negativo
- Carregando

Permissões:
- `cash_flow.view`
- `cash_flow.forecast.create`

Regras:
- Contas a receber/pagar geram fluxo previsto.
- Pagamentos/recebimentos confirmados geram realizado.
- Fluxo deve separar realizado de previsto.

---

### 12. Tela de Orçamentos Financeiros

Objetivo: planear receitas e despesas por categoria, ano e mês.

Web:
- Tabela tipo planilha por mês e categoria.
- Comparação orçado vs realizado.
- Botão “Novo orçamento”.

Mobile:
- Lista por categoria/mês.
- Gráfico simples de execução.

Campos:
- Ano
- Mês
- Categoria
- Valor orçado
- Moeda
- Observação

Ações:
- Criar orçamento
- Editar valores
- Importar orçamento
- Ver comparação

Estados:
- Sem orçamento
- Orçamento criado
- Valor inválido
- Realizado acima do orçado

Permissões:
- `financial_budgets.view`
- `financial_budgets.manage`

Regras:
- Valor orçado não pode ser negativo.
- Realizado vem dos pagamentos/recebimentos categorizados.
- Alterações devem manter histórico.

---

### 13. Tela de Aging de Clientes

Objetivo: analisar contas a receber por antiguidade da dívida.

Web:
- Tabela por cliente com colunas:
  - A vencer
  - 0-30 dias
  - 31-60 dias
  - 61-90 dias
  - Mais de 90 dias
  - Total
- Filtros por cliente, vendedor e grupo.
- Exportação.

Mobile:
- Cards por cliente.
- Barras por faixa de atraso.

Campos/Filtros:
- Cliente
- Grupo
- Vendedor
- Data base

Ações:
- Ver cliente
- Ver faturas
- Exportar
- Enviar cobrança

Estados:
- Sem dívidas
- Dívidas vencidas
- Carregando

Permissões:
- `aging_receivables.view`
- `aging_receivables.export`

Regras:
- Baseado em contas a receber abertas.
- Faixas calculadas pela data de vencimento.
- Notas de crédito e pagamentos reduzem saldo.

---

### 14. Tela de Relatórios Financeiros

Objetivo: gerar relatórios financeiros.

Web:
- Lista:
  - Contas a receber
  - Contas a pagar
  - Fluxo de caixa
  - Receitas por categoria
  - Despesas por categoria
  - Aging de clientes
  - Orçamento vs realizado
- Filtros e exportação.

Mobile:
- Seleção do relatório.
- Resumo e exportação.

Campos/Filtros:
- Período
- Categoria
- Cliente
- Fornecedor
- Estado
- Moeda
- Formato

Ações:
- Gerar relatório
- Exportar PDF/XLSX/CSV
- Agendar envio

Estados:
- Sem dados
- Gerando
- Relatório pronto
- Erro

Permissões:
- `financial_reports.view`
- `financial_reports.export`

Regras:
- Exportações devem ser auditadas.
- Relatórios devem respeitar permissões por módulo e tenant.**

---

## Módulo: Contabilidade

Objetivo: gerir contabilidade de dupla entrada, plano de contas, exercícios fiscais, períodos, lançamentos, impostos contabilísticos, ativos fixos, amortizações, balancetes, demonstrações financeiras e encerramento.

### 1. Tela de Dashboard Contabilístico

Objetivo: apresentar visão geral da situação contabilística.

Web:
- Sidebar do ERP.
- Topbar com empresa ativa.
- Cards:
  - Período atual
  - Lançamentos pendentes
  - Total débito do mês
  - Total crédito do mês
  - Diferenças encontradas
  - Períodos por encerrar
- Gráfico de receitas vs despesas.
- Lista de lançamentos recentes.
- Alertas de inconsistência.

Mobile:
- Cards empilhados.
- Lista de alertas e lançamentos recentes.

Campos/Filtros:
- Ano fiscal
- Período
- Filial
- Moeda

Ações:
- Novo lançamento
- Ver balancete
- Encerrar período
- Ver inconsistências

Estados:
- Sem lançamentos
- Carregando
- Período encerrado
- Diferença contábil
- Sem permissão

Permissões:
- `accounting.dashboard.view`

Regras:
- Débito e crédito devem fechar.
- Períodos encerrados não devem aceitar lançamentos sem reabertura.
- Dados vêm apenas do tenant ativo.

---

### 2. Tela de Plano de Contas

Objetivo: gerir contas contabilísticas da empresa.

Web:
- Árvore hierárquica do plano de contas.
- Colunas: código, nome, tipo, natureza, aceita lançamento, estado.
- Botão “Nova conta”.
- Filtros por tipo e estado.

Mobile:
- Lista hierárquica expansível.
- Pesquisa por código/nome.

Campos:
- Código da conta
- Nome
- Tipo de conta
- Conta pai
- Natureza: débito/crédito
- Aceita lançamento: sim/não
- Estado

Ações:
- Criar conta
- Editar conta
- Desativar conta
- Ver razão
- Importar plano

Estados:
- Nenhuma conta
- Conta criada
- Código duplicado
- Conta com movimentos
- Sem permissão

Permissões:
- `chart_accounts.view`
- `chart_accounts.create`
- `chart_accounts.update`
- `chart_accounts.deactivate`

Regras:
- Código deve ser único por tenant.
- Conta sintética não deve aceitar lançamento.
- Conta com lançamentos não deve ser apagada.
- Natureza deve respeitar tipo da conta.

---

### 3. Tela de Tipos de Conta

Objetivo: configurar os tipos base do plano de contas.

Web:
- Tabela com tipo, natureza, grupo e estado.
- Tipos comuns: ativo, passivo, capital próprio, receita, despesa, custo.
- Botão “Novo tipo”, se permitido.

Mobile:
- Lista simples.

Campos:
- Nome do tipo
- Código
- Natureza padrão: débito/crédito
- Grupo
- Estado

Ações:
- Criar tipo
- Editar
- Ativar/desativar

Estados:
- Nenhum tipo
- Tipo criado
- Tipo de sistema bloqueado

Permissões:
- `account_types.view`
- `account_types.manage`

Regras:
- Tipos de sistema não devem ser removidos.
- Tipos alimentam relatórios contabilísticos.

---

### 4. Tela de Anos Fiscais

Objetivo: gerir exercícios fiscais.

Web:
- Tabela com ano, data inicial, data final, estado e períodos.
- Botão “Novo ano fiscal”.
- Ação para abrir/encerrar ano.

Mobile:
- Cards por ano fiscal.

Campos:
- Ano
- Data inicial
- Data final
- Estado: aberto, encerrado, bloqueado
- Observação

Ações:
- Criar ano fiscal
- Abrir ano
- Encerrar ano
- Gerar períodos
- Reabrir, se permitido

Estados:
- Ano aberto
- Ano encerrado
- Sobreposição de datas
- Sem permissão

Permissões:
- `fiscal_years.view`
- `fiscal_years.create`
- `fiscal_years.close`
- `fiscal_years.reopen`

Regras:
- Datas de anos fiscais não devem sobrepor.
- Encerramento do ano exige todos os períodos encerrados.
- Reabertura exige permissão crítica.

---

### 5. Tela de Períodos Fiscais

Objetivo: controlar períodos mensais/trimestrais do ano fiscal.

Web:
- Tabela com período, início, fim, estado e data de encerramento.
- Filtro por ano fiscal.
- Ações para abrir, bloquear, encerrar ou reabrir.

Mobile:
- Lista por ano.
- Estado destacado.

Campos:
- Ano fiscal
- Nome do período
- Data inicial
- Data final
- Estado
- Responsável pelo encerramento

Ações:
- Criar período
- Encerrar período
- Reabrir período
- Bloquear período

Estados:
- Aberto
- Encerrado
- Bloqueado
- Reaberto

Permissões:
- `fiscal_periods.view`
- `fiscal_periods.manage`
- `fiscal_periods.close`

Regras:
- Lançamentos só podem ser feitos em períodos abertos.
- Encerramento exige verificações pendentes resolvidas.
- Reabertura deve ser auditada.

---

### 6. Tela de Lançamentos Contabilísticos

Objetivo: consultar lançamentos de dupla entrada.

Web:
- Tabela com número, data, período, origem, descrição, débito, crédito, estado.
- Filtros por período, conta, origem, estado e utilizador.
- Botão “Novo lançamento”.

Mobile:
- Cards por lançamento.
- Indicador de balanceado/não balanceado.

Campos visíveis:
- Número
- Data
- Descrição
- Origem
- Total débito
- Total crédito
- Estado

Ações:
- Criar lançamento
- Ver detalhe
- Estornar
- Aprovar
- Exportar

Estados:
- Rascunho
- Lançado
- Aprovado
- Estornado
- Não balanceado

Permissões:
- `journal_entries.view`
- `journal_entries.create`
- `journal_entries.approve`
- `journal_entries.reverse`

Regras:
- Total débito deve ser igual ao total crédito.
- Período deve estar aberto.
- Lançamentos automáticos devem referenciar documento de origem.

---

### 7. Tela de Criar Lançamento Manual

Objetivo: registar lançamento contabilístico manual.

Web:
- Cabeçalho com data, período, descrição e referência.
- Grelha de linhas:
  - Conta
  - Centro de custo
  - Débito
  - Crédito
  - Descrição
- Totais em tempo real.
- Botão “Guardar” e “Lançar”.

Mobile:
- Fluxo:
  1. Cabeçalho
  2. Linhas
  3. Revisão
- Total débito/crédito visível.

Campos:
- Data
- Período fiscal
- Descrição
- Referência
- Conta
- Débito
- Crédito
- Centro de custo
- Observação

Ações:
- Adicionar linha
- Remover linha
- Guardar rascunho
- Lançar
- Cancelar

Estados:
- Débito diferente de crédito
- Conta inválida
- Período fechado
- Lançamento criado
- Erro

Permissões:
- `journal_entries.create`

Regras:
- Cada linha deve ter débito ou crédito, não ambos.
- Débito/crédito devem ser positivos.
- Conta deve aceitar lançamento.
- Período precisa estar aberto.

---

### 8. Tela de Detalhe do Lançamento

Objetivo: visualizar lançamento completo.

Web:
- Cabeçalho com número, data, origem, período e estado.
- Linhas contabilísticas.
- Totais débito/crédito.
- Histórico e anexos.
- Botões de ação.

Mobile:
- Cabeçalho compacto.
- Linhas em cards.

Campos:
- Número
- Data
- Período
- Origem
- Descrição
- Conta
- Débito
- Crédito
- Estado

Ações:
- Aprovar
- Estornar
- Baixar PDF
- Ver documento origem
- Ver histórico

Estados:
- Lançado
- Aprovado
- Estornado
- Período fechado

Permissões:
- `journal_entries.view_detail`
- `journal_entries.approve`
- `journal_entries.reverse`

Regras:
- Lançamento aprovado não deve ser editado.
- Estorno gera lançamento inverso.
- Documento origem não deve ser perdido.

---

### 9. Tela de Razão Geral

Objetivo: consultar movimentos por conta.

Web:
- Seleção de conta e período.
- Tabela com data, lançamento, descrição, débito, crédito e saldo.
- Exportação.

Mobile:
- Lista cronológica com saldo acumulado.

Campos/Filtros:
- Conta
- Período
- Data inicial
- Data final
- Centro de custo

Ações:
- Filtrar
- Exportar
- Ver lançamento

Estados:
- Sem movimentos
- Carregando
- Conta sem lançamentos

Permissões:
- `general_ledger.view`
- `general_ledger.export`

Regras:
- Saldo deve respeitar natureza da conta.
- Apenas lançamentos válidos entram no razão.
- Estornos devem aparecer claramente.

---

### 10. Tela de Balancete

Objetivo: gerar balancete por período.

Web:
- Filtros por ano, período, nível de conta e centro de custo.
- Tabela com conta, saldo inicial, débitos, créditos e saldo final.
- Exportação PDF/XLSX.

Mobile:
- Resumo por grupo de contas.
- Detalhe por conta.

Campos/Filtros:
- Ano fiscal
- Período
- Nível
- Centro de custo
- Moeda

Ações:
- Gerar balancete
- Exportar
- Ver razão da conta

Estados:
- Sem dados
- Gerando
- Diferença encontrada
- Relatório pronto

Permissões:
- `trial_balance.view`
- `trial_balance.export`

Regras:
- Total débito deve igualar total crédito.
- Balancete deve considerar lançamentos até o período selecionado.
- Contas sem movimento podem ser ocultadas conforme opção.

---

### 11. Tela de Demonstração de Resultados

Objetivo: visualizar receitas, custos, despesas e resultado líquido.

Web:
- Filtros por período, centro de custo e filial.
- Estrutura por grupos:
  - Receitas
  - Custos
  - Despesas
  - Resultado operacional
  - Resultado líquido
- Comparação com período anterior/orçamento.

Mobile:
- Cards por grupo.
- Detalhe expandível.

Campos/Filtros:
- Período
- Centro de custo
- Comparar com período anterior
- Moeda

Ações:
- Gerar
- Exportar
- Ver contas relacionadas

Estados:
- Sem dados
- Resultado positivo
- Resultado negativo
- Gerando

Permissões:
- `income_statement.view`
- `income_statement.export`

Regras:
- Baseado em contas de receita, custo e despesa.
- Deve respeitar plano de contas.
- Pode comparar com orçamento financeiro/contabilístico.

---

### 12. Tela de Balanço Patrimonial

Objetivo: apresentar ativos, passivos e capital próprio.

Web:
- Filtros por data/período.
- Secções:
  - Ativo
  - Passivo
  - Capital próprio
- Indicador de equilíbrio.

Mobile:
- Resumo por secção.
- Detalhe expandível.

Campos/Filtros:
- Data base
- Ano fiscal
- Moeda
- Nível de detalhe

Ações:
- Gerar balanço
- Exportar
- Ver contas

Estados:
- Sem dados
- Balanço equilibrado
- Diferença encontrada

Permissões:
- `balance_sheet.view`
- `balance_sheet.export`

Regras:
- Ativo deve igualar passivo + capital próprio.
- Baseado em saldos acumulados.
- Diferenças devem gerar alerta.

---

### 13. Tela de Impostos Contabilísticos

Objetivo: gerir taxas e regras fiscais básicas usadas pela contabilidade.

Web:
- Tabs:
  - Grupos de imposto
  - Taxas
  - Regras
  - Transações fiscais
- Tabela com percentagem, conta contabilística e estado.

Mobile:
- Lista por tipo.
- Edição em tela separada.

Campos:
- Grupo
- Nome do imposto
- Percentagem
- Conta de imposto
- Tipo: IVA, IRPS, IRPC, outro
- Estado

Ações:
- Criar taxa
- Editar
- Ativar/desativar
- Ver transações

Estados:
- Taxa ativa
- Taxa inativa
- Percentagem inválida
- Sem permissão

Permissões:
- `accounting_taxes.view`
- `accounting_taxes.manage`

Regras:
- Taxas usadas em documentos não devem ser apagadas.
- Alterações fiscais devem ser auditadas.
- Impostos avançados ficam no módulo `impostos`.

---

### 14. Tela de Ativos Fixos

Objetivo: gerir bens patrimoniais e sua amortização/depreciação.

Web:
- Tabela com código, nome, categoria, valor de aquisição, valor líquido, estado.
- Botão “Novo ativo”.
- Filtros por categoria e estado.

Mobile:
- Cards por ativo.

Campos:
- Código
- Nome
- Categoria
- Data de aquisição
- Valor de aquisição
- Vida útil
- Método de amortização
- Conta contabilística
- Estado

Ações:
- Criar ativo
- Editar
- Gerar plano de amortização
- Baixar/alienar ativo
- Ver histórico

Estados:
- Ativo
- Totalmente amortizado
- Baixado
- Vendido

Permissões:
- `fixed_assets.view`
- `fixed_assets.create`
- `fixed_assets.update`
- `fixed_assets.dispose`

Regras:
- Ativo deve ter plano de amortização.
- Amortização gera lançamento contabilístico.
- Baixa exige motivo e lançamento.

---

### 15. Tela de Plano de Amortização

Objetivo: consultar e executar amortizações dos ativos fixos.

Web:
- Tabela com ativo, período, valor de amortização, valor acumulado e estado.
- Botão “Gerar lançamentos”.

Mobile:
- Lista por ativo/período.

Campos:
- Ativo
- Período
- Valor
- Estado
- Lançamento associado

Ações:
- Gerar amortização
- Criar lançamento
- Ver lançamento
- Recalcular plano

Estados:
- Pendente
- Lançada
- Recalculada
- Erro

Permissões:
- `depreciation.view`
- `depreciation.generate`
- `depreciation.post`

Regras:
- Não lançar amortização em período fechado.
- Não duplicar amortização do mesmo período.
- Recalcular exige permissão.

---

### 16. Tela de Encerramento de Período

Objetivo: fechar período contabilístico com verificações.

Web:
- Checklist:
  - Lançamentos balanceados
  - Faturas contabilizadas
  - Pagamentos contabilizados
  - Amortizações lançadas
  - Impostos calculados
  - Reconciliações pendentes
- Botão “Encerrar período”.

Mobile:
- Checklist vertical.
- Estado de cada verificação.

Campos:
- Ano fiscal
- Período
- Responsável
- Observação

Ações:
- Executar verificações
- Resolver pendências
- Encerrar período
- Reabrir período, se permitido

Estados:
- Verificações pendentes
- Apto para encerramento
- Encerrado
- Reaberto

Permissões:
- `period_closing.view`
- `period_closing.run_checks`
- `period_closing.close`
- `period_closing.reopen`

Regras:
- Período só encerra sem pendências críticas.
- Encerramento bloqueia novos lançamentos.
- Reabertura deve ser auditada.

---

### 17. Tela de Orçamento Contabilístico

Objetivo: planear valores por conta contabilística e ano fiscal.

Web:
- Grelha por conta e mês.
- Comparação orçado vs realizado.
- Importação/exportação.

Mobile:
- Lista por conta.
- Resumo por mês.

Campos:
- Ano fiscal
- Conta
- Mês
- Valor orçado
- Centro de custo
- Observação

Ações:
- Criar orçamento
- Editar
- Importar
- Exportar
- Comparar realizado

Estados:
- Sem orçamento
- Orçamento criado
- Realizado acima do orçado

Permissões:
- `accounting_budgets.view`
- `accounting_budgets.manage`

Regras:
- Conta deve aceitar orçamento.
- Valores realizados vêm dos lançamentos contabilísticos.
- Alterações devem manter histórico.

---

### 18. Tela de Relatórios Contabilísticos

Objetivo: gerar relatórios oficiais e gerenciais.

Web:
- Lista de relatórios:
  - Razão geral
  - Balancete
  - Demonstração de resultados
  - Balanço patrimonial
  - Fluxo contabilístico
  - Ativos fixos
  - Impostos
  - Orçamento vs realizado
- Filtros e exportação.

Mobile:
- Seleção de relatório.
- Visualização resumida.
- Exportação.

Campos/Filtros:
- Ano fiscal
- Período
- Conta
- Centro de custo
- Moeda
- Formato

Ações:
- Gerar relatório
- Exportar PDF/XLSX/CSV
- Agendar envio

Estados:
- Sem dados
- Gerando
- Relatório pronto
- Erro

Permissões:
- `accounting_reports.view`
- `accounting_reports.export`

Regras:
- Relatórios devem respeitar períodos fiscais.
- Exportações devem ser auditadas.
- Documentos oficiais devem usar dados fechados quando aplicável.**

---

## Módulo: Impostos

Objetivo: gerir regimes fiscais, isenções, retenções, declarações fiscais, certificados e obrigações fiscais complementares à contabilidade.

### 1. Tela de Dashboard Fiscal

Objetivo: apresentar visão geral das obrigações fiscais.

Web:
- Cards:
  - IVA apurado no período
  - Retenções pendentes
  - Declarações por submeter
  - Declarações submetidas
  - Certificados ativos
  - Isenções ativas
- Lista de obrigações próximas do vencimento.
- Gráfico de impostos por período.

Mobile:
- Cards empilhados.
- Lista de obrigações fiscais.
- Filtros por período.

Campos/Filtros:
- Período fiscal
- Tipo de imposto
- Estado
- Regime fiscal

Ações:
- Nova declaração
- Ver retenções
- Ver isenções
- Gerar relatório fiscal

Estados:
- Sem dados fiscais
- Carregando
- Obrigações vencidas
- Sem permissão

Permissões:
- `tax_dashboard.view`

Regras:
- Dados devem vir de documentos fiscais, contabilidade e retenções.
- Apenas dados do tenant ativo.
- Alertas fiscais devem respeitar calendário configurado.

---

### 2. Tela de Regimes Fiscais

Objetivo: configurar regimes fiscais aplicáveis à empresa.

Web:
- Tabela com nome, tipo, descrição, estado e data de início.
- Botão “Novo regime fiscal”.

Mobile:
- Lista em cards.
- Estado destacado.

Campos:
- Nome do regime
- Tipo: normal, simplificado, isento, outro
- Data inicial
- Data final
- Descrição
- Estado

Ações:
- Criar regime
- Editar
- Ativar/desativar
- Definir como padrão

Estados:
- Nenhum regime
- Regime ativo
- Regime expirado
- Regime criado

Permissões:
- `tax_regimes.view`
- `tax_regimes.manage`

Regras:
- Apenas um regime fiscal padrão ativo por empresa.
- Regime fiscal pode influenciar cálculo de IVA e retenções.
- Alterações devem ser auditadas.

---

### 3. Tela de Isenções Fiscais

Objetivo: gerir isenções de IVA ou outros impostos por cliente, fornecedor, produto ou categoria.

Web:
- Tabela com entidade, tipo de isenção, imposto, validade, certificado e estado.
- Filtros por entidade, imposto e validade.
- Botão “Nova isenção”.

Mobile:
- Cards por isenção.
- Destaque para isenções expiradas.

Campos:
- Tipo de entidade: cliente, fornecedor, produto, categoria
- Entidade
- Imposto
- Motivo da isenção
- Percentual isento
- Data inicial
- Data final
- Certificado/anexo
- Estado

Ações:
- Criar isenção
- Editar
- Suspender
- Renovar
- Anexar certificado

Estados:
- Isenção ativa
- Isenção expirada
- Isenção suspensa
- Certificado em falta

Permissões:
- `tax_exemptions.view`
- `tax_exemptions.create`
- `tax_exemptions.update`

Regras:
- Isenção vencida não deve ser aplicada.
- Isenção aplicada em documentos deve ser registada.
- Certificados fiscais podem ser obrigatórios conforme tipo.

---

### 4. Tela de Retenções na Fonte

Objetivo: configurar retenções como IRPS, IRPC ou outras retenções aplicáveis.

Web:
- Tabela com imposto, taxa, entidade aplicável, conta contabilística e estado.
- Botão “Nova retenção”.

Mobile:
- Lista simples com taxa e estado.

Campos:
- Nome da retenção
- Tipo: IRPS, IRPC, outro
- Taxa percentual
- Entidade aplicável: cliente, fornecedor, funcionário
- Conta contabilística
- Valor mínimo aplicável
- Estado

Ações:
- Criar retenção
- Editar
- Ativar/desativar
- Ver transações

Estados:
- Retenção ativa
- Retenção inativa
- Taxa inválida

Permissões:
- `withholding_taxes.view`
- `withholding_taxes.manage`

Regras:
- Taxa deve ser maior ou igual a zero.
- Retenção usada em documentos não deve ser apagada.
- Retenções alimentam contabilidade.

---

### 5. Tela de Transações de Retenção

Objetivo: consultar retenções calculadas em documentos, pagamentos ou salários.

Web:
- Tabela com data, entidade, documento origem, base tributável, taxa, valor retido e estado.
- Filtros por período, entidade, imposto e estado.

Mobile:
- Lista em cards.
- Filtros compactos.

Campos:
- Data
- Entidade
- Documento origem
- Tipo de retenção
- Base tributável
- Taxa
- Valor retido
- Estado

Ações:
- Filtrar
- Ver documento origem
- Exportar
- Gerar lançamento contabilístico

Estados:
- Pendente
- Lançada
- Declarada
- Anulada

Permissões:
- `withholding_transactions.view`
- `withholding_transactions.export`
- `withholding_transactions.post`

Regras:
- Retenção deve referenciar documento origem.
- Não lançar duas vezes a mesma retenção.
- Anulação deve gerar movimento inverso.

---

### 6. Tela de Declarações Fiscais

Objetivo: gerir declarações fiscais periódicas.

Web:
- Tabela com tipo, período, valor apurado, estado, data limite e data de submissão.
- Botão “Nova declaração”.

Mobile:
- Cards por declaração.
- Estado e prazo destacados.

Campos:
- Tipo de declaração: IVA, IRPS, IRPC, retenções
- Período fiscal
- Data limite
- Valor apurado
- Estado
- Observação

Ações:
- Criar declaração
- Calcular valores
- Submeter
- Marcar como paga
- Exportar ficheiro
- Anexar comprovativo

Estados:
- Rascunho
- Calculada
- Submetida
- Paga
- Vencida
- Cancelada

Permissões:
- `tax_returns.view`
- `tax_returns.create`
- `tax_returns.submit`
- `tax_returns.pay`

Regras:
- Período fiscal obrigatório.
- Declaração submetida não deve ser editada diretamente.
- Pagamento deve integrar com financeiro/tesouraria.

---

### 7. Tela de Criar Declaração Fiscal

Objetivo: apurar e preparar uma declaração fiscal.

Web:
- Seleção de tipo e período.
- Botão “Calcular”.
- Linhas da declaração com base, imposto, retenções, créditos e total.
- Área de anexos.
- Botões “Guardar rascunho” e “Submeter”.

Mobile:
- Fluxo:
  1. Tipo e período
  2. Apuramento
  3. Revisão
  4. Submissão

Campos:
- Tipo de declaração
- Período
- Regime fiscal
- Linhas de apuramento
- Observação
- Anexos

Ações:
- Calcular
- Recalcular
- Guardar rascunho
- Submeter
- Exportar

Estados:
- Sem movimentos no período
- Valores calculados
- Diferença encontrada
- Declaração submetida

Permissões:
- `tax_returns.create`
- `tax_returns.calculate`
- `tax_returns.submit`

Regras:
- Cálculo deve usar documentos válidos e lançamentos contabilísticos.
- Recalcular deve atualizar rascunho.
- Submissão deve bloquear edição.

---

### 8. Tela de Linhas da Declaração

Objetivo: detalhar valores que compõem a declaração.

Web:
- Tabela com código da linha, descrição, base tributável, taxa, valor e origem.
- Drill-down para documentos origem.

Mobile:
- Lista por linha.
- Detalhe ao tocar.

Campos:
- Código
- Descrição
- Base tributável
- Taxa
- Valor
- Origem

Ações:
- Ver documentos origem
- Exportar detalhe
- Recalcular linha

Estados:
- Linha calculada
- Sem origem
- Divergência

Permissões:
- `tax_return_lines.view`

Regras:
- Linhas devem manter rastreabilidade dos documentos.
- Ajustes manuais devem exigir motivo e auditoria.

---

### 9. Tela de Certificados Fiscais

Objetivo: gerir certificados de bom contribuinte, isenção ou outros documentos fiscais.

Web:
- Tabela com tipo, número, entidade, validade, ficheiro e estado.
- Botão “Novo certificado”.

Mobile:
- Cards por certificado.
- Alerta de vencimento.

Campos:
- Tipo de certificado
- Número
- Entidade relacionada
- Data de emissão
- Data de validade
- Ficheiro
- Estado

Ações:
- Criar certificado
- Anexar ficheiro
- Renovar
- Desativar
- Baixar documento

Estados:
- Ativo
- Expirado
- Próximo de expirar
- Desativado

Permissões:
- `tax_certificates.view`
- `tax_certificates.manage`

Regras:
- Certificado expirado não deve validar isenção.
- Renovação deve preservar histórico.
- Ficheiros devem respeitar permissões.

---

### 10. Tela de Calendário Fiscal

Objetivo: acompanhar prazos fiscais.

Web:
- Calendário mensal com obrigações fiscais.
- Lista lateral de próximos prazos.
- Filtros por tipo de imposto.

Mobile:
- Lista cronológica.
- Visualização mensal simplificada.

Campos:
- Tipo de obrigação
- Data limite
- Período fiscal
- Estado
- Responsável

Ações:
- Criar obrigação
- Marcar como concluída
- Gerar lembrete
- Ver declaração relacionada

Estados:
- Pendente
- Próxima do vencimento
- Vencida
- Concluída

Permissões:
- `tax_calendar.view`
- `tax_calendar.manage`

Regras:
- Obrigações vencidas devem gerar alerta.
- Declarações submetidas podem concluir obrigações automaticamente.

---

### 11. Tela de Relatórios Fiscais

Objetivo: gerar relatórios fiscais internos e oficiais.

Web:
- Lista de relatórios:
  - IVA por período
  - Retenções na fonte
  - Isenções aplicadas
  - Declarações submetidas
  - Impostos por cliente/fornecedor
  - Obrigações vencidas
- Filtros e exportação.

Mobile:
- Seleção de relatório.
- Resumo e exportação.

Campos/Filtros:
- Período
- Tipo de imposto
- Entidade
- Estado
- Formato

Ações:
- Gerar relatório
- Exportar PDF/XLSX/CSV
- Agendar envio

Estados:
- Sem dados
- Gerando
- Relatório pronto
- Erro

Permissões:
- `tax_reports.view`
- `tax_reports.export`

Regras:
- Exportações devem ser auditadas.
- Relatórios oficiais devem usar declarações fechadas/submetidas quando aplicável.Faltam **10 módulos** da lista completa que analisámos.

Já fizemos:

1. Autenticação
2. Autorização
3. Utilizadores
4. Empresas
5. Auditoria
6. Sistema e Configuração
7. Gestão de Clientes
8. Gestão de Produtos
9. Gestão de Stock
10. Faturação
11. Tesouraria
12. Financeiro
13. Contabilidade
14. Impostos

Ainda faltam:

1. `multi-moeda`
2. `compras`
3. `pos`
4. `logistica`
5. `crm`
6. `recursos-humanos`
7. `assinaturas`
8. `gestao-escolar`
9. `centros-custo`
10. `seguranca`

---

## Módulo: Multi-Moeda

Objetivo: permitir operações em várias moedas, gerir câmbios, conversões, ganhos/perdas cambiais e integração com faturação, compras, financeiro e contabilidade.

### 1. Tela de Dashboard Multi-Moeda

Objetivo: apresentar visão geral das operações em moedas diferentes da moeda padrão.

Web:
- Cards:
  - Moeda padrão
  - Moedas ativas
  - Transações em moeda estrangeira
  - Ganho cambial do período
  - Perda cambial do período
  - Taxas pendentes de atualização
- Gráfico de variação cambial.
- Lista de câmbios recentes.

Mobile:
- Cards empilhados.
- Lista de moedas e taxas recentes.

Campos/Filtros:
- Período
- Moeda
- Tipo de transação
- Módulo origem

Ações:
- Atualizar câmbio
- Nova conversão
- Ver ganhos/perdas
- Gerar relatório

Estados:
- Sem operações multi-moeda
- Taxa desatualizada
- Carregando
- Sem permissão

Permissões:
- `multi_currency.dashboard.view`

Regras:
- Moeda padrão vem de `sistema-configuracao`.
- Transações em moeda estrangeira exigem taxa de câmbio.
- Ganhos/perdas cambiais devem integrar com contabilidade.

---

### 2. Tela de Moedas Ativas

Objetivo: gerir moedas permitidas nas operações da empresa.

Web:
- Tabela com moeda, símbolo, código ISO, casas decimais, estado e padrão.
- Botão “Ativar moeda”.
- Ação para definir uso em vendas/compras/financeiro.

Mobile:
- Lista de moedas com switches de ativação.

Campos:
- Moeda
- Código ISO
- Símbolo
- Casas decimais
- Ativa para vendas
- Ativa para compras
- Ativa para financeiro
- Estado

Ações:
- Ativar moeda
- Desativar moeda
- Configurar uso
- Definir moeda padrão, se permitido

Estados:
- Moeda ativa
- Moeda inativa
- Moeda padrão
- Sem permissão

Permissões:
- `multi_currency.currencies.view`
- `multi_currency.currencies.manage`

Regras:
- Moeda padrão não pode ser desativada.
- Moedas vêm da configuração global de `currencies`.
- Desativar moeda não remove histórico.

---

### 3. Tela de Taxas de Câmbio

Objetivo: gerir taxas usadas em conversões e documentos.

Web:
- Tabela com moeda origem, moeda destino, taxa, data, fonte, estado e utilizador.
- Filtros por moeda, período e fonte.
- Botão “Nova taxa”.
- Botão “Importar taxas”.

Mobile:
- Cards por par de moedas.
- Destaque para taxas vencidas/desatualizadas.

Campos:
- Moeda origem
- Moeda destino
- Taxa
- Data de vigência
- Fonte
- Observação
- Estado

Ações:
- Criar taxa
- Editar taxa
- Importar taxas
- Ativar/desativar
- Ver histórico

Estados:
- Taxa ativa
- Taxa expirada
- Taxa duplicada
- Taxa inválida

Permissões:
- `exchange_rates.view`
- `exchange_rates.create`
- `exchange_rates.update`
- `exchange_rates.import`

Regras:
- Taxa deve ser maior que zero.
- Não permitir duas taxas ativas para o mesmo par e data.
- Alteração de taxa usada em documento emitido não altera documento antigo.

---

### 4. Tela de Conversão de Moeda

Objetivo: simular ou registar conversão entre moedas.

Web:
- Formulário com moeda origem, destino, valor, taxa e resultado.
- Histórico de conversões.
- Botão “Converter”.

Mobile:
- Calculadora simples.
- Resultado destacado.

Campos:
- Moeda origem
- Moeda destino
- Valor origem
- Taxa de câmbio
- Valor convertido
- Data da taxa

Ações:
- Converter
- Usar taxa atual
- Guardar conversão
- Copiar resultado

Estados:
- Taxa não encontrada
- Valor inválido
- Conversão calculada
- Moeda igual

Permissões:
- `currency_conversion.view`
- `currency_conversion.create`

Regras:
- Moeda origem e destino não podem ser iguais.
- Taxa deve vir da data da operação.
- Conversão manual deve guardar taxa usada.

---

### 5. Tela de Documento em Moeda Estrangeira

Objetivo: apoiar faturação, compras ou financeiro quando o documento usa moeda diferente da padrão.

Web:
- Componente reutilizável em documentos:
  - Moeda do documento
  - Taxa de câmbio
  - Total na moeda do documento
  - Total convertido para moeda padrão
- Alerta se taxa estiver desatualizada.

Mobile:
- Secção “Moeda e câmbio” no formulário do documento.
- Total convertido visível na revisão.

Campos:
- Moeda
- Taxa de câmbio
- Data da taxa
- Total original
- Total convertido

Ações:
- Selecionar moeda
- Atualizar taxa
- Bloquear taxa no documento
- Recalcular total

Estados:
- Taxa ausente
- Taxa desatualizada
- Total convertido
- Documento emitido

Permissões:
- Depende do módulo origem:
  - `invoices.create`
  - `purchase_orders.create`
  - `payments.create`

Regras:
- Documento emitido deve guardar a taxa usada.
- Moeda do documento não deve ser alterada após emissão.
- Contabilidade deve receber valor convertido e moeda original.

---

### 6. Tela de Ganhos e Perdas Cambiais

Objetivo: apurar diferenças cambiais entre emissão e liquidação.

Web:
- Tabela com documento, entidade, moeda, valor original, taxa emissão, taxa liquidação, diferença e estado.
- Filtros por período, moeda e entidade.
- Botão “Gerar lançamento”.

Mobile:
- Cards por diferença cambial.
- Valor de ganho/perda destacado.

Campos:
- Documento origem
- Entidade
- Moeda
- Valor original
- Taxa de emissão
- Taxa de liquidação
- Valor convertido emissão
- Valor convertido liquidação
- Diferença
- Tipo: ganho/perda

Ações:
- Calcular diferença
- Gerar lançamento contabilístico
- Ver documento origem
- Exportar

Estados:
- Pendente
- Lançado
- Sem diferença
- Erro de cálculo

Permissões:
- `currency_gain_loss.view`
- `currency_gain_loss.calculate`
- `currency_gain_loss.post`

Regras:
- Diferença cambial surge no pagamento/liquidação.
- Ganhos/perdas devem gerar lançamento contabilístico.
- Não lançar duas vezes a mesma diferença.

---

### 7. Tela de Reavaliação Cambial

Objetivo: reavaliar saldos em moeda estrangeira no fim do período.

Web:
- Seleção de período.
- Lista de contas/documentos em moeda estrangeira.
- Taxa de fecho.
- Cálculo de diferença.
- Botão “Gerar lançamentos”.

Mobile:
- Fluxo:
  1. Período
  2. Saldos
  3. Taxas
  4. Resultado

Campos:
- Período
- Moeda
- Conta/documento
- Saldo estrangeiro
- Taxa anterior
- Taxa de fecho
- Diferença calculada

Ações:
- Calcular reavaliação
- Rever diferenças
- Gerar lançamentos
- Exportar

Estados:
- Sem saldos estrangeiros
- Taxa de fecho em falta
- Reavaliação calculada
- Lançada

Permissões:
- `currency_revaluation.view`
- `currency_revaluation.calculate`
- `currency_revaluation.post`

Regras:
- Reavaliação deve respeitar período contabilístico aberto.
- Lançamentos gerados devem referenciar período e moeda.
- Reavaliação não substitui diferença no pagamento, se aplicável.

---

### 8. Tela de Histórico de Taxas

Objetivo: consultar evolução das taxas de câmbio.

Web:
- Gráfico de evolução por par de moedas.
- Tabela histórica.
- Filtros por período e fonte.

Mobile:
- Gráfico compacto.
- Lista histórica.

Campos/Filtros:
- Moeda origem
- Moeda destino
- Período
- Fonte

Ações:
- Filtrar
- Exportar
- Comparar períodos

Estados:
- Sem histórico
- Carregando
- Taxa encontrada

Permissões:
- `exchange_rate_history.view`
- `exchange_rate_history.export`

Regras:
- Histórico deve preservar taxas usadas em documentos.
- Alterações manuais devem indicar utilizador e motivo.

---

### 9. Tela de Configurações Multi-Moeda

Objetivo: definir regras de uso de moedas e câmbio.

Web:
- Secções:
  - Moeda padrão
  - Atualização de taxas
  - Validade da taxa
  - Ganhos/perdas cambiais
  - Reavaliação
- Toggles e campos.

Mobile:
- Lista de configurações por secção.

Campos:
- Permitir documentos em moeda estrangeira
- Validade da taxa em dias
- Fonte padrão de câmbio
- Conta de ganho cambial
- Conta de perda cambial
- Exigir aprovação para taxa manual
- Reavaliar no fecho do período

Ações:
- Guardar configurações
- Restaurar padrão
- Testar fonte de câmbio

Estados:
- Configurações guardadas
- Conta contabilística obrigatória
- Fonte indisponível
- Sem permissão

Permissões:
- `multi_currency_settings.view`
- `multi_currency_settings.update`

Regras:
- Contas de ganho/perda são obrigatórias se apuração automática estiver ativa.
- Alterar moeda padrão após movimentos deve ser bloqueado.
- Taxas manuais podem exigir aprovação.

---

### 10. Tela de Relatórios Multi-Moeda

Objetivo: gerar relatórios de saldos, documentos e diferenças cambiais.

Web:
- Lista:
  - Documentos por moeda
  - Saldos em moeda estrangeira
  - Ganhos e perdas cambiais
  - Taxas usadas por período
  - Reavaliação cambial
- Filtros e exportação.

Mobile:
- Seleção de relatório.
- Resumo e exportação.

Campos/Filtros:
- Período
- Moeda
- Entidade
- Módulo origem
- Formato

Ações:
- Gerar relatório
- Exportar PDF/XLSX/CSV

Estados:
- Sem dados
- Gerando
- Relatório pronto
- Erro

Permissões:
- `multi_currency_reports.view`
- `multi_currency_reports.export`

Regras:
- Relatórios devem mostrar moeda original e valor convertido.
- Exportações devem ser auditadas.**

---

## Módulo: Compras

Objetivo: gerir fornecedores, requisições, pedidos de compra, receção de mercadorias, faturas de fornecedor, devoluções, pagamentos, saldos e integração com stock, financeiro e contabilidade.

### 1. Tela de Dashboard de Compras

Objetivo: apresentar visão geral do ciclo de compras.

Web:
- Cards:
  - Pedidos em aberto
  - Requisições pendentes
  - Mercadoria por receber
  - Faturas de fornecedor em aberto
  - Total comprado no mês
  - Fornecedores ativos
- Gráficos por fornecedor/categoria.
- Lista de pedidos recentes e entregas pendentes.

Mobile:
- Cards empilhados.
- Lista de pendências.

Campos/Filtros:
- Período
- Fornecedor
- Estado
- Categoria
- Filial

Ações:
- Nova requisição
- Novo pedido de compra
- Nova fatura de fornecedor
- Ver pendências
- Gerar relatório

Estados:
- Sem compras
- Carregando
- Erro
- Sem permissão

Permissões:
- `purchases.dashboard.view`

Regras:
- Indicadores devem considerar documentos válidos.
- Valores devem respeitar moeda e câmbio.
- Dados pertencem ao tenant ativo.

---

### 2. Tela de Fornecedores

Objetivo: gerir cadastro de fornecedores.

Web:
- Tabela com nome, NUIT, telefone, email, saldo, estado e classificação.
- Filtros por estado, cidade, categoria e saldo.
- Botão “Novo fornecedor”.

Mobile:
- Cards por fornecedor.
- Pesquisa no topo.
- Filtros compactos.

Campos visíveis:
- Nome
- NUIT
- Telefone
- Email
- Saldo
- Estado

Ações:
- Criar fornecedor
- Ver detalhes
- Editar
- Desativar
- Criar pedido
- Registar pagamento

Estados:
- Nenhum fornecedor
- Carregando
- Fornecedor desativado
- Sem permissão

Permissões:
- `suppliers.view`
- `suppliers.create`
- `suppliers.update`
- `suppliers.deactivate`

Regras:
- NUIT deve ser único por tenant quando preenchido.
- Fornecedor com documentos não deve ser apagado.
- Fornecedor alimenta contas a pagar.

---

### 3. Tela de Criar/Editar Fornecedor

Objetivo: cadastrar ou atualizar fornecedor.

Web:
- Formulário com secções:
  - Dados gerais
  - Fiscal
  - Contactos
  - Endereços
  - Condições comerciais
  - Produtos fornecidos
- Botões “Guardar” e “Cancelar”.

Mobile:
- Wizard em etapas.

Campos:
- Nome/Razão social
- Tipo
- NUIT
- Email
- Telefone
- País
- Cidade
- Endereço
- Condição de pagamento
- Moeda padrão
- Categoria
- Estado

Ações:
- Guardar
- Cancelar
- Validar NUIT

Estados:
- Salvando
- NUIT duplicado
- Dados inválidos
- Fornecedor criado

Permissões:
- `suppliers.create`
- `suppliers.update`

Regras:
- Dados fiscais devem ser auditados.
- Moeda padrão pode alimentar pedidos e faturas.
- Condições comerciais sugerem vencimentos em contas a pagar.

---

### 4. Tela de Detalhes do Fornecedor

Objetivo: visualizar ficha completa do fornecedor.

Web:
- Cabeçalho com nome, NUIT, estado e saldo.
- Cards:
  - Total comprado
  - Total pago
  - Saldo em aberto
  - Última compra
  - Rating
- Tabs:
  - Resumo
  - Contactos
  - Endereços
  - Produtos
  - Pedidos
  - Faturas
  - Pagamentos
  - Histórico

Mobile:
- Cabeçalho compacto.
- Cards empilhados.
- Tabs horizontais.

Ações:
- Editar
- Criar pedido
- Criar fatura
- Registar pagamento
- Adicionar nota

Estados:
- Fornecedor não encontrado
- Carregando
- Sem permissão

Permissões:
- `suppliers.view`
- `suppliers.financial_summary.view`

Regras:
- Resumo financeiro vem do financeiro/compras.
- Histórico agrega documentos e pagamentos.

---

### 5. Tela de Requisições de Compra

Objetivo: gerir pedidos internos de compra.

Web:
- Tabela com número, solicitante, departamento, data, estado e valor estimado.
- Filtros por estado, solicitante e período.
- Botão “Nova requisição”.

Mobile:
- Cards por requisição.
- Estado destacado.

Campos:
- Solicitante
- Departamento
- Produto/serviço
- Quantidade
- Justificativa
- Data necessária
- Valor estimado

Ações:
- Criar requisição
- Aprovar
- Rejeitar
- Converter em pedido de compra
- Cancelar

Estados:
- Rascunho
- Submetida
- Aprovada
- Rejeitada
- Convertida
- Cancelada

Permissões:
- `purchase_requests.view`
- `purchase_requests.create`
- `purchase_requests.approve`

Regras:
- Requisição aprovada pode gerar pedido de compra.
- Aprovação pode depender de valor/centro de custo.
- Rejeição exige motivo.

---

### 6. Tela de Pedido de Compra

Objetivo: gerir pedidos enviados a fornecedores.

Web:
- Tabela com número, fornecedor, data, entrega prevista, total e estado.
- Botão “Novo pedido”.
- Filtros por fornecedor, estado e período.

Mobile:
- Cards com progresso de receção.

Campos:
- Fornecedor
- Data
- Entrega prevista
- Produto
- Quantidade
- Preço
- Desconto
- Imposto
- Total

Ações:
- Criar pedido
- Enviar ao fornecedor
- Aprovar
- Receber mercadoria
- Gerar fatura de fornecedor
- Cancelar

Estados:
- Rascunho
- Aprovado
- Enviado
- Parcialmente recebido
- Recebido
- Faturado
- Cancelado

Permissões:
- `purchase_orders.view`
- `purchase_orders.create`
- `purchase_orders.approve`
- `purchase_orders.receive`

Regras:
- Pedido aprovado pode gerar compromisso financeiro.
- Receção atualiza stock.
- Fatura de fornecedor cria conta a pagar.

---

### 7. Tela de Criar/Editar Pedido de Compra

Objetivo: criar ou alterar pedido de compra.

Web:
- Cabeçalho com fornecedor, data, moeda, entrega prevista.
- Linhas com produto, quantidade, preço e impostos.
- Resumo financeiro lateral.
- Botões: guardar, aprovar, enviar.

Mobile:
- Fluxo:
  1. Fornecedor
  2. Produtos
  3. Condições
  4. Revisão

Campos:
- Fornecedor
- Moeda
- Produto
- Quantidade
- Preço unitário
- Imposto
- Desconto
- Condição de pagamento
- Observação

Ações:
- Adicionar item
- Remover item
- Guardar
- Aprovar
- Enviar

Estados:
- Fornecedor obrigatório
- Produto inválido
- Pedido guardado
- Total recalculado

Permissões:
- `purchase_orders.create`
- `purchase_orders.update`

Regras:
- Produto deve vir de gestão de produtos.
- Fornecedor pode ter produtos associados.
- Documento em moeda estrangeira deve guardar taxa.

---

### 8. Tela de Receção de Mercadorias

Objetivo: registar entrada de produtos recebidos.

Web:
- Seleção de pedido de compra.
- Linhas pendentes com quantidade pedida, recebida e a receber.
- Armazém de entrada.
- Botão “Confirmar receção”.

Mobile:
- Leitura por código de barras.
- Confirmação por produto.

Campos:
- Pedido de compra
- Armazém
- Produto
- Quantidade recebida
- Lote/validade, se aplicável
- Observação

Ações:
- Confirmar receção
- Receber parcial
- Rejeitar item
- Anexar guia do fornecedor

Estados:
- Receção parcial
- Receção completa
- Quantidade excedida
- Produto rejeitado

Permissões:
- `purchase_receipts.view`
- `purchase_receipts.create`

Regras:
- Receção gera entrada no stock.
- Quantidade recebida não deve exceder quantidade pedida sem permissão.
- Produtos com lote/série exigem dados adicionais.

---

### 9. Tela de Faturas de Fornecedor

Objetivo: gerir faturas recebidas de fornecedores.

Web:
- Tabela com fornecedor, número do fornecedor, data, vencimento, total, saldo e estado.
- Filtros por fornecedor, estado, vencidas e período.
- Botão “Nova fatura”.

Mobile:
- Cards por fatura.
- Saldo e vencimento destacados.

Campos:
- Fornecedor
- Número da fatura
- Data de emissão
- Vencimento
- Pedido/receção origem
- Itens
- Impostos
- Total
- Moeda

Ações:
- Criar fatura
- Validar contra pedido
- Registar conta a pagar
- Registar pagamento
- Anular

Estados:
- Rascunho
- Validada
- Em aberto
- Parcialmente paga
- Paga
- Anulada

Permissões:
- `purchase_invoices.view`
- `purchase_invoices.create`
- `purchase_invoices.validate`
- `purchase_invoices.cancel`

Regras:
- Fatura validada cria conta a pagar.
- Pode gerar lançamento contabilístico.
- Número do fornecedor pode ter alerta de duplicação.

---

### 10. Tela de Devoluções a Fornecedor

Objetivo: controlar devolução de produtos comprados.

Web:
- Tabela com fornecedor, documento origem, data, estado e valor.
- Botão “Nova devolução”.

Mobile:
- Cards por devolução.

Campos:
- Fornecedor
- Documento origem
- Produto
- Quantidade
- Motivo
- Armazém
- Estado do produto

Ações:
- Criar devolução
- Confirmar saída
- Gerar crédito de fornecedor
- Cancelar

Estados:
- Rascunho
- Enviada
- Creditada
- Cancelada

Permissões:
- `purchase_returns.view`
- `purchase_returns.create`
- `purchase_returns.send`

Regras:
- Devolução reduz stock.
- Quantidade devolvida não pode exceder recebida.
- Crédito de fornecedor reduz conta a pagar.

---

### 11. Tela de Pagamentos a Fornecedor

Objetivo: consultar e registar pagamentos feitos a fornecedores.

Web:
- Tabela com fornecedor, fatura, data, valor, meio de pagamento e estado.
- Botão “Registar pagamento”.

Mobile:
- Cards por pagamento.

Campos:
- Fornecedor
- Fatura
- Valor
- Meio de pagamento
- Caixa/conta bancária
- Referência
- Data

Ações:
- Registar pagamento
- Ver recibo/comprovativo
- Anular pagamento
- Exportar

Estados:
- Pagamento registado
- Pagamento anulado
- Valor excede saldo

Permissões:
- `supplier_payments.view`
- `supplier_payments.create`
- `supplier_payments.cancel`

Regras:
- Pagamento reduz conta a pagar.
- Pagamento movimenta tesouraria.
- Anulação gera movimento inverso.

---

### 12. Tela de Produtos por Fornecedor

Objetivo: associar produtos a fornecedores e condições de compra.

Web:
- Tabela com fornecedor, produto, código do fornecedor, preço, prazo e mínimo de compra.
- Botão “Associar produto”.

Mobile:
- Lista por produto/fornecedor.

Campos:
- Fornecedor
- Produto
- Código no fornecedor
- Preço de compra
- Moeda
- Quantidade mínima
- Prazo de entrega
- Estado

Ações:
- Associar produto
- Editar condição
- Desativar associação

Estados:
- Associação criada
- Produto duplicado
- Sem permissão

Permissões:
- `supplier_products.view`
- `supplier_products.manage`

Regras:
- Um produto pode ter vários fornecedores.
- Preço de compra pode sugerir custo no pedido.
- Código do fornecedor facilita importação de documentos.

---

### 13. Tela de Avaliação de Fornecedores

Objetivo: avaliar desempenho de fornecedores.

Web:
- Tabela com fornecedor, pontualidade, qualidade, preço, atendimento e nota geral.
- Botão “Nova avaliação”.

Mobile:
- Cards com nota.

Campos:
- Fornecedor
- Pedido relacionado
- Pontualidade
- Qualidade
- Preço
- Atendimento
- Comentário
- Nota geral

Ações:
- Criar avaliação
- Editar
- Ver histórico

Estados:
- Sem avaliações
- Avaliação criada

Permissões:
- `supplier_ratings.view`
- `supplier_ratings.manage`

Regras:
- Avaliação pode ser feita após receção.
- Nota geral pode ser média ponderada.

---

### 14. Tela de Relatórios de Compras

Objetivo: gerar relatórios de compras e fornecedores.

Web:
- Lista:
  - Compras por fornecedor
  - Compras por produto
  - Pedidos pendentes
  - Mercadoria por receber
  - Faturas em aberto
  - Pagamentos a fornecedor
  - Avaliação de fornecedores
- Filtros e exportação.

Mobile:
- Seleção de relatório.
- Resumo e exportação.

Campos/Filtros:
- Período
- Fornecedor
- Produto
- Estado
- Moeda
- Formato

Ações:
- Gerar relatório
- Exportar PDF/XLSX/CSV

Estados:
- Sem dados
- Gerando
- Relatório pronto

Permissões:
- `purchase_reports.view`
- `purchase_reports.export`

Regras:
- Relatórios devem considerar documentos válidos.
- Exportações devem ser auditadas.**

---

## Módulo: POS

Objetivo: gerir vendas rápidas em balcão, terminais, sessões de caixa, pagamentos, devoluções, fecho de caixa, impressão de recibos e integração com stock, financeiro, tesouraria e contabilidade.

### 1. Tela de Seleção de Terminal POS

Objetivo: permitir ao utilizador escolher o terminal/caixa antes de vender.

Web:
- Lista de terminais disponíveis.
- Estado do terminal: ativo, inativo, ocupado, sem caixa.
- Indicação de armazém e caixa associados.
- Botão “Abrir terminal”.

Mobile/Tablet:
- Cards grandes por terminal.
- Pesquisa simples.
- Estado visível por cor.

Campos:
- Terminal
- Filial
- Armazém
- Caixa
- Estado

Ações:
- Selecionar terminal
- Abrir sessão
- Ver sessão aberta
- Sair

Estados:
- Nenhum terminal disponível
- Terminal ocupado
- Terminal sem caixa associado
- Terminal inativo

Permissões:
- `pos_terminals.view`
- `pos_sessions.open`

Regras:
- Terminal deve estar associado a um armazém e caixa.
- Um terminal pode ter apenas uma sessão aberta por vez, salvo configuração.
- Utilizador deve ter permissão para operar o terminal.

---

### 2. Tela de Abertura de Sessão POS

Objetivo: abrir sessão de caixa para começar vendas.

Web:
- Modal/formulário de abertura.
- Mostra terminal, caixa, armazém e operador.
- Campo para saldo inicial declarado.

Mobile/Tablet:
- Formulário simples.
- Teclado numérico destacado para saldo inicial.

Campos:
- Terminal
- Caixa
- Armazém
- Operador
- Saldo inicial
- Observação

Ações:
- Abrir sessão
- Cancelar

Estados:
- Sessão aberta
- Saldo inicial inválido
- Caixa fechado
- Terminal indisponível

Permissões:
- `pos_sessions.open`

Regras:
- Saldo inicial deve ser registado.
- Abrir sessão cria vínculo entre operador, terminal e caixa.
- Sessão aberta habilita vendas.

---

### 3. Tela Principal de Venda POS

Objetivo: realizar venda rápida de produtos.

Web:
- Layout operacional:
  - Pesquisa/leitor de produto no topo.
  - Grade/lista de produtos à esquerda.
  - Carrinho à direita.
  - Total fixo em destaque.
  - Botões de pagamento, desconto, cliente e cancelar.
- Suporte a teclado e scanner.

Mobile/Tablet:
- Pesquisa no topo.
- Lista/grid de produtos.
- Carrinho em painel inferior ou tela separada.
- Botão “Pagar” fixo.

Campos:
- Produto/código de barras
- Cliente opcional
- Quantidade
- Desconto
- Observação

Ações:
- Adicionar produto
- Alterar quantidade
- Remover item
- Aplicar desconto
- Selecionar cliente
- Suspender venda
- Cancelar venda
- Ir para pagamento

Estados:
- Carrinho vazio
- Produto não encontrado
- Stock insuficiente
- Produto sem preço
- Venda em andamento

Permissões:
- `pos_sales.create`
- `pos_discounts.apply`

Regras:
- Produto deve estar ativo.
- Produto com stock deve validar disponibilidade.
- Preços vêm de gestão de produtos.
- Venda POS deve ser rápida, com poucos cliques.

---

### 4. Tela de Seleção de Cliente no POS

Objetivo: associar cliente à venda.

Web:
- Pesquisa por nome, telefone ou NUIT.
- Lista compacta de clientes.
- Botão “Cliente genérico” e “Novo cliente rápido”.

Mobile/Tablet:
- Busca simples.
- Cards por cliente.
- Cadastro rápido em modal/tela.

Campos:
- Nome
- Telefone
- NUIT
- Email, opcional

Ações:
- Pesquisar cliente
- Selecionar cliente
- Criar cliente rápido
- Usar cliente genérico

Estados:
- Cliente não encontrado
- Cliente selecionado
- Cliente bloqueado
- Cliente sem crédito

Permissões:
- `customers.view`
- `customers.create_quick`

Regras:
- Cliente pode ser opcional conforme configuração.
- Venda a crédito exige cliente identificado.
- Cliente bloqueado não deve comprar a crédito.

---

### 5. Tela de Pagamento POS

Objetivo: receber pagamento da venda.

Web:
- Resumo da venda.
- Seleção de meio de pagamento.
- Suporte a múltiplos meios.
- Campo valor recebido.
- Cálculo de troco.
- Botão “Finalizar venda”.

Mobile/Tablet:
- Botões grandes por meio de pagamento.
- Teclado numérico.
- Troco em destaque.

Campos:
- Meio de pagamento
- Valor recebido
- Referência
- Conta/caixa destino
- Cliente, se venda a crédito

Ações:
- Adicionar pagamento
- Remover pagamento
- Finalizar venda
- Voltar ao carrinho

Estados:
- Valor insuficiente
- Troco calculado
- Referência obrigatória
- Pagamento aprovado
- Falha na integração

Permissões:
- `pos_payments.create`

Regras:
- Soma dos pagamentos deve cobrir total da venda.
- Numerário pode gerar troco.
- Métodos como TPA/M-Pesa podem exigir referência.
- Pagamento movimenta financeiro/tesouraria.

---

### 6. Tela de Venda Finalizada

Objetivo: confirmar venda e disponibilizar recibo.

Web:
- Mensagem de sucesso.
- Número da venda/recibo.
- Total pago e troco.
- Botões: imprimir, enviar por email/WhatsApp, nova venda.

Mobile/Tablet:
- Confirmação simples.
- Botões grandes.

Campos:
- Número da venda
- Cliente
- Total
- Troco
- Meio de pagamento

Ações:
- Imprimir recibo
- Enviar recibo
- Nova venda
- Ver detalhe

Estados:
- Venda concluída
- Erro ao imprimir
- Recibo enviado

Permissões:
- `pos_sales.view`
- `pos_receipts.print`
- `pos_receipts.send`

Regras:
- Venda concluída baixa stock.
- Venda cria recebimento e movimento de caixa.
- Pode gerar lançamento contabilístico por sessão ou por venda.

---

### 7. Tela de Vendas POS

Objetivo: consultar vendas realizadas no POS.

Web:
- Tabela com número, data, terminal, operador, cliente, total, pagamento e estado.
- Filtros por período, operador, terminal e estado.
- Botão exportar.

Mobile:
- Lista em cards.
- Filtros compactos.

Campos visíveis:
- Número
- Data
- Operador
- Cliente
- Total
- Estado

Ações:
- Ver detalhe
- Reimprimir recibo
- Devolver
- Anular, se permitido
- Exportar

Estados:
- Concluída
- Devolvida parcialmente
- Devolvida
- Anulada

Permissões:
- `pos_sales.view`
- `pos_sales.cancel`
- `pos_receipts.reprint`

Regras:
- Venda finalizada não deve ser editada.
- Anulação exige motivo e permissão.
- Devolução deve controlar itens devolvidos.

---

### 8. Tela de Detalhe da Venda POS

Objetivo: visualizar venda completa.

Web:
- Cabeçalho com número, estado, operador e terminal.
- Itens vendidos.
- Pagamentos.
- Movimentos de stock.
- Histórico.

Mobile:
- Secções expansíveis.

Campos:
- Número
- Data
- Cliente
- Itens
- Pagamentos
- Total
- Troco
- Estado

Ações:
- Reimprimir recibo
- Criar devolução
- Enviar recibo
- Ver movimento de caixa
- Ver movimento de stock

Estados:
- Venda concluída
- Venda anulada
- Venda devolvida

Permissões:
- `pos_sales.view_detail`

Regras:
- Deve mostrar rastreabilidade financeira e de stock.
- Pagamentos não devem ser alterados diretamente.

---

### 9. Tela de Devolução POS

Objetivo: registar devolução total ou parcial de venda.

Web:
- Pesquisa da venda original.
- Lista de itens disponíveis para devolução.
- Quantidade a devolver.
- Tipo de reembolso.
- Botão “Confirmar devolução”.

Mobile/Tablet:
- Fluxo:
  1. Buscar venda
  2. Selecionar itens
  3. Reembolso
  4. Confirmar

Campos:
- Venda origem
- Produto
- Quantidade devolvida
- Motivo
- Tipo de reembolso: numerário, mesmo método, crédito loja
- Estado do produto
- Armazém de retorno

Ações:
- Confirmar devolução
- Cancelar
- Imprimir comprovativo

Estados:
- Venda não encontrada
- Item já devolvido
- Quantidade inválida
- Devolução concluída

Permissões:
- `pos_returns.create`
- `pos_refunds.create`

Regras:
- Quantidade devolvida não pode exceder quantidade vendida.
- Devolução pode repor stock ou marcar produto danificado.
- Reembolso movimenta tesouraria.
- Deve gerar auditoria.

---

### 10. Tela de Movimentos de Caixa POS

Objetivo: registar entradas e saídas manuais durante a sessão.

Web:
- Lista de movimentos da sessão.
- Botões “Entrada” e “Saída”.
- Motivo obrigatório.

Mobile/Tablet:
- Botões grandes.
- Histórico curto da sessão.

Campos:
- Tipo: entrada/saída
- Valor
- Motivo
- Observação

Ações:
- Criar entrada
- Criar saída
- Ver movimentos

Estados:
- Movimento registado
- Valor inválido
- Motivo obrigatório

Permissões:
- `pos_cash_movements.create`
- `pos_cash_movements.view`

Regras:
- Movimento manual afeta saldo da sessão.
- Saída não deve exceder saldo, conforme configuração.
- Motivo obrigatório para auditoria.

---

### 11. Tela de Fecho de Sessão POS

Objetivo: fechar sessão e reconciliar valores recebidos.

Web:
- Resumo da sessão:
  - Saldo inicial
  - Total vendas
  - Total devoluções
  - Entradas manuais
  - Saídas manuais
  - Saldo calculado
- Totais por meio de pagamento.
- Campos para valores declarados.
- Diferença calculada.
- Botão “Fechar sessão”.

Mobile/Tablet:
- Formulário operacional por meio de pagamento.
- Diferença em destaque.

Campos:
- Saldo declarado em numerário
- Valores declarados por meio
- Observação
- Diferença
- Anexos, se aplicável

Ações:
- Calcular diferença
- Fechar sessão
- Imprimir relatório
- Cancelar

Estados:
- Sessão aberta
- Diferença encontrada
- Sessão fechada
- Fecho bloqueado

Permissões:
- `pos_sessions.close`

Regras:
- Diferença exige observação.
- Sessão fechada não aceita novas vendas.
- Fecho deve gerar reconciliação na tesouraria.

---

### 12. Tela de Sessões POS

Objetivo: consultar sessões abertas e fechadas.

Web:
- Tabela com terminal, operador, abertura, fecho, total vendido, diferença e estado.
- Filtros por terminal, operador, período e estado.

Mobile:
- Cards por sessão.
- Indicador de diferença.

Campos:
- Terminal
- Operador
- Data abertura
- Data fecho
- Total vendas
- Diferença
- Estado

Ações:
- Ver detalhe
- Fechar sessão
- Exportar
- Reabrir, se permitido

Estados:
- Aberta
- Fechada
- Com diferença
- Cancelada

Permissões:
- `pos_sessions.view`
- `pos_sessions.reopen`

Regras:
- Reabertura exige permissão crítica.
- Diferenças devem ser auditadas.

---

### 13. Tela de Configuração de Terminais POS

Objetivo: gerir terminais de venda.

Web:
- Tabela com terminal, filial, armazém, caixa, impressora e estado.
- Botão “Novo terminal”.

Mobile:
- Lista de terminais.
- Edição simples.

Campos:
- Nome do terminal
- Código
- Filial
- Armazém
- Caixa
- Impressora
- Estado

Ações:
- Criar terminal
- Editar
- Ativar/desativar
- Testar impressora

Estados:
- Terminal ativo
- Terminal inativo
- Sem caixa associado
- Sem armazém associado

Permissões:
- `pos_terminals.view`
- `pos_terminals.manage`

Regras:
- Terminal precisa de caixa e armazém.
- Código deve ser único por tenant.
- Terminal inativo não pode abrir sessão.

---

### 14. Tela de Relatórios POS

Objetivo: gerar relatórios de vendas em balcão.

Web:
- Lista:
  - Vendas por operador
  - Vendas por terminal
  - Vendas por produto
  - Vendas por meio de pagamento
  - Sessões com diferença
  - Devoluções
- Filtros e exportação.

Mobile:
- Seleção de relatório.
- Resumo e exportação.

Campos/Filtros:
- Período
- Terminal
- Operador
- Produto
- Meio de pagamento
- Formato

Ações:
- Gerar relatório
- Exportar PDF/XLSX/CSV

Estados:
- Sem dados
- Gerando
- Relatório pronto

Permissões:
- `pos_reports.view`
- `pos_reports.export`

Regras:
- Relatórios devem considerar vendas concluídas e devoluções.
- Exportações devem ser auditadas.**

---

## Módulo: Logística

Objetivo: gerir expedições, rotas, entregas, motoristas, viaturas, rastreamento, estados de entrega e integração com faturação, stock e utilizadores.

### 1. Tela de Dashboard de Logística

Objetivo: apresentar visão geral das entregas e expedições.

Web:
- Cards:
  - Entregas pendentes
  - Entregas em rota
  - Entregas concluídas hoje
  - Entregas atrasadas
  - Viaturas disponíveis
  - Motoristas disponíveis
- Mapa com entregas/rotas, se disponível.
- Lista de entregas prioritárias.

Mobile:
- Cards empilhados.
- Lista de entregas do dia.
- Mapa simplificado opcional.

Campos/Filtros:
- Período
- Estado
- Motorista
- Viatura
- Rota

Ações:
- Nova expedição
- Criar rota
- Atribuir motorista
- Ver atrasadas
- Gerar relatório

Estados:
- Sem entregas
- Carregando
- Entregas atrasadas
- Sem permissão

Permissões:
- `logistics.dashboard.view`

Regras:
- Dados devem pertencer ao tenant ativo.
- Entregas podem nascer de guias de remessa/faturas.
- Estados devem ser atualizados sem perder histórico.

---

### 2. Tela de Expedições

Objetivo: gerir saídas de mercadoria para entrega.

Web:
- Tabela com número, cliente, documento origem, data, rota, motorista, estado e prioridade.
- Filtros por estado, rota, motorista e período.
- Botão “Nova expedição”.

Mobile:
- Cards por expedição.
- Estado destacado.

Campos visíveis:
- Número
- Cliente
- Documento origem
- Endereço
- Motorista
- Estado

Ações:
- Criar expedição
- Ver detalhe
- Atribuir rota
- Atribuir motorista
- Marcar como despachada
- Cancelar

Estados:
- Rascunho
- Planeada
- Despachada
- Em trânsito
- Entregue
- Parcial
- Falhada
- Cancelada

Permissões:
- `shipments.view`
- `shipments.create`
- `shipments.update`
- `shipments.dispatch`
- `shipments.cancel`

Regras:
- Expedição deve referenciar documento origem, como guia ou fatura.
- Não despachar sem itens válidos.
- Cancelamento exige motivo.

---

### 3. Tela de Criar/Editar Expedição

Objetivo: montar uma expedição com itens e destino.

Web:
- Seleção de cliente/documento origem.
- Itens da entrega.
- Endereço de entrega.
- Atribuição de rota, motorista e viatura.
- Botões guardar/despachar.

Mobile:
- Fluxo:
  1. Documento origem
  2. Itens
  3. Endereço
  4. Motorista/viatura
  5. Confirmação

Campos:
- Documento origem
- Cliente
- Endereço de entrega
- Produto
- Quantidade
- Prioridade
- Rota
- Motorista
- Viatura
- Observação

Ações:
- Adicionar item
- Remover item
- Guardar
- Despachar
- Cancelar

Estados:
- Documento inválido
- Item sem quantidade
- Motorista indisponível
- Viatura indisponível
- Expedição criada

Permissões:
- `shipments.create`
- `shipments.update`

Regras:
- Quantidade entregue não deve exceder quantidade do documento origem.
- Motorista/viatura devem estar disponíveis.
- Expedição despachada pode alterar estado da guia de remessa.

---

### 4. Tela de Detalhe da Expedição

Objetivo: acompanhar uma expedição específica.

Web:
- Cabeçalho com número, cliente, estado e prioridade.
- Dados do documento origem.
- Itens.
- Endereço.
- Motorista/viatura.
- Timeline de estados.
- Prova de entrega.

Mobile:
- Cabeçalho compacto.
- Ações rápidas:
  - Iniciar rota
  - Marcar entregue
  - Registar falha
  - Contactar cliente

Campos:
- Número
- Cliente
- Endereço
- Itens
- Motorista
- Viatura
- Estado
- Histórico

Ações:
- Atualizar estado
- Ver documento origem
- Ver mapa
- Anexar comprovativo
- Contactar cliente

Estados:
- Em trânsito
- Entregue
- Falhada
- Parcial
- Cancelada

Permissões:
- `shipments.view_detail`
- `shipments.update_status`

Regras:
- Alterações de estado devem criar log.
- Entrega finalizada não deve ser editada sem permissão.
- Prova de entrega pode ser obrigatória.

---

### 5. Tela de Rotas de Entrega

Objetivo: planear e gerir rotas.

Web:
- Tabela de rotas com nome, data, motorista, viatura, entregas, estado.
- Mapa com sequência de paragens.
- Botão “Nova rota”.

Mobile:
- Lista de rotas.
- Mapa/itinerário simplificado.

Campos:
- Nome da rota
- Data
- Motorista
- Viatura
- Entregas
- Ordem das paragens
- Estado

Ações:
- Criar rota
- Editar rota
- Atribuir entregas
- Reordenar paragens
- Iniciar rota
- Fechar rota

Estados:
- Planeada
- Em andamento
- Concluída
- Cancelada

Permissões:
- `delivery_routes.view`
- `delivery_routes.create`
- `delivery_routes.update`
- `delivery_routes.start`
- `delivery_routes.close`

Regras:
- Uma entrega pode pertencer a uma rota ativa.
- Reordenar rota deve atualizar sequência.
- Rota concluída bloqueia alterações operacionais.

---

### 6. Tela Mobile do Motorista

Objetivo: permitir que motorista execute entregas no terreno.

Mobile:
- Lista das entregas atribuídas.
- Botões grandes para ações.
- Navegação por rota.
- Estado de cada entrega.
- Captura de assinatura/foto.

Web:
- Opcional apenas para supervisão.

Campos:
- Entrega
- Cliente
- Endereço
- Telefone
- Itens
- Estado
- Observação

Ações:
- Iniciar entrega
- Abrir mapa
- Ligar para cliente
- Marcar entregue
- Marcar falhada
- Capturar assinatura
- Tirar foto
- Registar observação

Estados:
- Pendente
- Em rota
- Entregue
- Falhada
- Sem internet/sincronização pendente

Permissões:
- `driver_app.view`
- `shipments.update_assigned`

Regras:
- Motorista só vê entregas atribuídas.
- Deve funcionar com sincronização posterior, se offline for suportado.
- Entrega concluída exige prova conforme configuração.

---

### 7. Tela de Motoristas

Objetivo: gerir motoristas internos ou externos.

Web:
- Tabela com nome, telefone, licença, estado e entregas atribuídas.
- Botão “Novo motorista”.

Mobile:
- Lista de motoristas.
- Contacto rápido.

Campos:
- Nome
- Telefone
- Documento/licença
- Tipo: interno/terceiro
- Utilizador associado
- Estado

Ações:
- Criar motorista
- Editar
- Ativar/desativar
- Ver entregas

Estados:
- Disponível
- Em rota
- Inativo

Permissões:
- `delivery_drivers.view`
- `delivery_drivers.manage`

Regras:
- Motorista pode estar ligado a `utilizadores`.
- Motorista inativo não pode receber rota.
- Documento de licença pode ter validade.

---

### 8. Tela de Viaturas

Objetivo: gerir veículos usados em entregas.

Web:
- Tabela com matrícula, modelo, capacidade, estado e motorista atual.
- Botão “Nova viatura”.

Mobile:
- Cards por viatura.

Campos:
- Matrícula
- Marca/modelo
- Capacidade
- Tipo
- Estado
- Data de inspeção
- Seguro
- Observação

Ações:
- Criar viatura
- Editar
- Marcar manutenção
- Ativar/desativar
- Ver histórico

Estados:
- Disponível
- Em rota
- Em manutenção
- Inativa

Permissões:
- `delivery_vehicles.view`
- `delivery_vehicles.manage`

Regras:
- Viatura em manutenção não pode ser atribuída.
- Matrícula deve ser única por tenant.
- Alertas podem ser gerados por inspeção/seguro vencido.

---

### 9. Tela de Rastreamento de Entregas

Objetivo: acompanhar localização e estado das entregas.

Web:
- Mapa com entregas em trânsito.
- Lista lateral com estado, motorista e ETA.
- Filtros por rota, motorista e estado.

Mobile:
- Mapa da rota do motorista.
- Lista de paragens.

Campos:
- Rota
- Motorista
- Viatura
- Estado
- Última localização
- ETA

Ações:
- Ver entrega
- Contactar motorista
- Atualizar localização
- Ver histórico

Estados:
- Sem localização
- Em trânsito
- Atrasada
- Entregue

Permissões:
- `delivery_tracking.view`

Regras:
- Localização deve respeitar privacidade e permissões.
- Histórico de localização pode ter retenção limitada.
- ETA pode ser manual ou calculado.

---

### 10. Tela de Estados de Entrega

Objetivo: configurar estados e fluxos de entrega.

Web:
- Tabela com estado, descrição, ordem, cor e se é final.
- Botão “Novo estado”.

Mobile:
- Lista de estados.

Campos:
- Nome do estado
- Código
- Descrição
- Ordem
- Estado final: sim/não
- Cor
- Ativo

Ações:
- Criar estado
- Editar
- Desativar
- Reordenar

Estados:
- Estado criado
- Código duplicado
- Estado em uso

Permissões:
- `delivery_status.manage`

Regras:
- Estados finais bloqueiam alterações normais.
- Estados em uso não devem ser apagados.
- Fluxo deve impedir transições inválidas.

---

### 11. Tela de Prova de Entrega

Objetivo: registar evidências da entrega.

Web:
- Visualização da assinatura, fotos, nome de quem recebeu, documento e observação.
- Download dos anexos.

Mobile:
- Captura de assinatura.
- Tirar foto.
- Campo de nome/documento de receptor.

Campos:
- Nome de quem recebeu
- Documento/BI
- Assinatura
- Foto
- Data/hora
- Localização
- Observação

Ações:
- Capturar assinatura
- Tirar foto
- Guardar prova
- Baixar comprovativo

Estados:
- Prova pendente
- Prova registada
- Anexo inválido

Permissões:
- `delivery_proof.view`
- `delivery_proof.create`

Regras:
- Prova pode ser obrigatória para concluir entrega.
- Anexos devem ser protegidos.
- Data/hora deve ser automática.

---

### 12. Tela de Ocorrências de Entrega

Objetivo: registar problemas durante entrega.

Web:
- Tabela com entrega, tipo de ocorrência, responsável, estado e data.
- Botão “Nova ocorrência”.

Mobile:
- Formulário rápido para motorista.

Campos:
- Entrega
- Tipo: cliente ausente, morada errada, produto danificado, atraso, outro
- Descrição
- Foto/anexo
- Estado
- Responsável

Ações:
- Criar ocorrência
- Resolver
- Reagendar entrega
- Cancelar entrega

Estados:
- Aberta
- Em análise
- Resolvida
- Cancelada

Permissões:
- `delivery_issues.view`
- `delivery_issues.create`
- `delivery_issues.resolve`

Regras:
- Ocorrência pode alterar estado da entrega.
- Reagendamento deve manter histórico.
- Produto danificado pode acionar devolução/stock bloqueado.

---

### 13. Tela de Relatórios de Logística

Objetivo: gerar relatórios de entregas e desempenho.

Web:
- Lista:
  - Entregas por estado
  - Entregas por motorista
  - Entregas atrasadas
  - Rotas concluídas
  - Ocorrências
  - Provas de entrega
- Filtros e exportação.

Mobile:
- Seleção de relatório.
- Resumo simples.

Campos/Filtros:
- Período
- Motorista
- Rota
- Estado
- Cliente
- Formato

Ações:
- Gerar relatório
- Exportar PDF/XLSX/CSV

Estados:
- Sem dados
- Gerando
- Relatório pronto

Permissões:
- `logistics_reports.view`
- `logistics_reports.export`

Regras:
- Relatórios devem considerar histórico de estados.
- Exportações devem ser auditadas.**

---

## Módulo: CRM

Objetivo: gerir relacionamento com clientes, leads, oportunidades, funil de vendas, atividades comerciais, contactos, notas, previsão de receita e integração com clientes e faturação.

### 1. Tela de Dashboard CRM

Objetivo: apresentar visão geral comercial.

Web:
- Cards:
  - Leads novos
  - Oportunidades abertas
  - Valor estimado em pipeline
  - Taxa de conversão
  - Atividades pendentes
  - Oportunidades ganhas no mês
- Funil de vendas por etapa.
- Lista de próximas atividades.
- Ranking de vendedores.

Mobile:
- Cards empilhados.
- Funil simplificado.
- Lista de tarefas comerciais.

Campos/Filtros:
- Período
- Responsável
- Pipeline
- Estado

Ações:
- Novo lead
- Nova oportunidade
- Nova atividade
- Ver pipeline
- Gerar relatório

Estados:
- Sem dados CRM
- Carregando
- Atividades vencidas
- Sem permissão

Permissões:
- `crm.dashboard.view`

Regras:
- Utilizador comercial pode ver apenas seus leads/oportunidades, conforme permissão.
- Gestor pode ver equipa.
- Dados pertencem ao tenant ativo.

---

### 2. Tela de Pipelines de Venda

Objetivo: configurar funis comerciais.

Web:
- Tabela de pipelines.
- Detalhe com etapas em ordem.
- Botão “Novo pipeline”.
- Ação para reordenar etapas.

Mobile:
- Lista de pipelines.
- Etapas em cards ordenáveis.

Campos:
- Nome do pipeline
- Descrição
- Etapas
- Probabilidade padrão por etapa
- Estado

Ações:
- Criar pipeline
- Editar
- Adicionar etapa
- Reordenar etapas
- Desativar

Estados:
- Nenhum pipeline
- Pipeline ativo
- Etapa em uso
- Sem permissão

Permissões:
- `crm_pipelines.view`
- `crm_pipelines.manage`

Regras:
- Pipeline deve ter pelo menos uma etapa inicial e uma final.
- Etapas finais podem ser “ganho” ou “perdido”.
- Pipeline em uso não deve ser apagado.

---

### 3. Tela de Leads

Objetivo: gerir potenciais clientes antes da conversão.

Web:
- Tabela com nome, empresa, telefone, email, origem, responsável, estado e data.
- Filtros por origem, responsável, estado e período.
- Botão “Novo lead”.

Mobile:
- Cards por lead.
- Ações rápidas: ligar, WhatsApp, email.

Campos visíveis:
- Nome
- Empresa
- Telefone
- Origem
- Responsável
- Estado

Ações:
- Criar lead
- Ver detalhe
- Editar
- Qualificar
- Converter em cliente
- Criar oportunidade
- Descartar

Estados:
- Novo
- Contactado
- Qualificado
- Convertido
- Descartado

Permissões:
- `crm_leads.view`
- `crm_leads.create`
- `crm_leads.update`
- `crm_leads.convert`

Regras:
- Lead convertido pode criar cliente em `gestao-clientes`.
- Descarte exige motivo.
- Lead deve ter responsável, conforme configuração.

---

### 4. Tela de Criar/Editar Lead

Objetivo: cadastrar ou atualizar lead.

Web:
- Formulário com dados pessoais, empresa, origem e responsável.
- Secção de notas e próxima atividade.

Mobile:
- Formulário curto.
- Botão para criar atividade após guardar.

Campos:
- Nome
- Empresa
- Telefone
- Email
- Origem
- Interesse
- Responsável
- Estado
- Observação

Ações:
- Guardar
- Guardar e criar atividade
- Converter
- Cancelar

Estados:
- Salvando
- Email inválido
- Lead criado
- Lead duplicado possível

Permissões:
- `crm_leads.create`
- `crm_leads.update`

Regras:
- Duplicados devem ser sugeridos por telefone/email.
- Origem deve ser obrigatória para análise comercial.
- Alterações relevantes vão para histórico.

---

### 5. Tela de Detalhes do Lead

Objetivo: visualizar histórico e ações do lead.

Web:
- Cabeçalho com nome, estado e responsável.
- Timeline de atividades, notas e mudanças de estado.
- Dados de contacto.
- Botões de conversão.

Mobile:
- Cabeçalho compacto.
- Ações rápidas fixas.

Campos:
- Nome
- Contactos
- Origem
- Responsável
- Estado
- Histórico

Ações:
- Ligar
- Enviar email/WhatsApp
- Criar atividade
- Criar oportunidade
- Converter em cliente
- Descartar

Estados:
- Lead novo
- Lead qualificado
- Lead convertido
- Lead descartado

Permissões:
- `crm_leads.view_detail`
- `crm_activities.create`
- `crm_leads.convert`

Regras:
- Lead convertido deve manter histórico.
- Conversão não deve apagar o lead original.

---

### 6. Tela de Oportunidades

Objetivo: gerir oportunidades de venda.

Web:
- Visualização Kanban por etapa do pipeline.
- Alternativa em tabela.
- Cards com cliente/lead, valor, probabilidade, responsável e previsão de fecho.
- Arrastar entre etapas.

Mobile:
- Kanban horizontal ou lista por etapa.
- Cards compactos.

Campos visíveis:
- Título
- Cliente/lead
- Valor estimado
- Etapa
- Probabilidade
- Responsável
- Fecho previsto

Ações:
- Criar oportunidade
- Mover etapa
- Marcar como ganha
- Marcar como perdida
- Criar proposta/orçamento
- Filtrar

Estados:
- Aberta
- Ganha
- Perdida
- Pausada

Permissões:
- `crm_opportunities.view`
- `crm_opportunities.create`
- `crm_opportunities.update`
- `crm_opportunities.close`

Regras:
- Mover etapa pode atualizar probabilidade.
- Oportunidade ganha pode gerar orçamento/fatura.
- Oportunidade perdida exige motivo.

---

### 7. Tela de Criar/Editar Oportunidade

Objetivo: cadastrar oportunidade comercial.

Web:
- Formulário com cliente/lead, valor, etapa, probabilidade e previsão.
- Secção de produtos/serviços de interesse.
- Próxima atividade.

Mobile:
- Formulário em etapas.

Campos:
- Título
- Cliente ou lead
- Pipeline
- Etapa
- Valor estimado
- Probabilidade
- Data prevista de fecho
- Responsável
- Produtos/serviços
- Observação

Ações:
- Guardar
- Guardar e criar atividade
- Criar orçamento
- Cancelar

Estados:
- Valor inválido
- Data inválida
- Oportunidade criada
- Sem permissão

Permissões:
- `crm_opportunities.create`
- `crm_opportunities.update`

Regras:
- Valor estimado deve ser positivo.
- Probabilidade deve estar entre 0 e 100.
- Se associada a lead, manter vínculo.

---

### 8. Tela de Detalhe da Oportunidade

Objetivo: acompanhar evolução da oportunidade.

Web:
- Cabeçalho com título, valor, etapa e responsável.
- Timeline de atividades.
- Produtos de interesse.
- Notas.
- Documentos gerados: orçamento, fatura.
- Botões para ganhar/perder.

Mobile:
- Secções expansíveis.
- Ações principais fixas.

Campos:
- Título
- Cliente/lead
- Valor
- Pipeline
- Etapa
- Responsável
- Histórico
- Documentos associados

Ações:
- Mover etapa
- Criar atividade
- Criar orçamento
- Marcar ganha
- Marcar perdida
- Editar

Estados:
- Aberta
- Ganha
- Perdida
- Sem atividade futura

Permissões:
- `crm_opportunities.view_detail`
- `crm_opportunities.update`
- `crm_opportunities.close`

Regras:
- Oportunidade ganha pode criar cliente se veio de lead.
- Documentos comerciais gerados ficam vinculados à oportunidade.

---

### 9. Tela de Atividades Comerciais

Objetivo: gerir tarefas, chamadas, reuniões, demonstrações e follow-ups.

Web:
- Calendário/lista de atividades.
- Filtros por responsável, tipo, estado e data.
- Botão “Nova atividade”.

Mobile:
- Agenda diária.
- Ações rápidas para concluir.

Campos:
- Tipo: chamada, reunião, email, tarefa, demo
- Assunto
- Lead/oportunidade/cliente
- Responsável
- Data e hora
- Prioridade
- Estado
- Observação

Ações:
- Criar atividade
- Concluir
- Reagendar
- Cancelar
- Adicionar nota

Estados:
- Pendente
- Vencida
- Concluída
- Cancelada

Permissões:
- `crm_activities.view`
- `crm_activities.create`
- `crm_activities.update`
- `crm_activities.complete`

Regras:
- Atividade vencida deve gerar alerta.
- Conclusão pode exigir resultado/nota.
- Atividade deve estar ligada a lead, oportunidade ou cliente.

---

### 10. Tela de Contactos CRM

Objetivo: gerir contactos comerciais ligados a leads, clientes ou oportunidades.

Web:
- Tabela com nome, empresa, telefone, email, cargo e origem.
- Filtros por entidade relacionada e responsável.

Mobile:
- Lista com ações rápidas.

Campos:
- Nome
- Cargo
- Telefone
- Email
- Entidade relacionada
- Principal: sim/não

Ações:
- Criar contacto
- Editar
- Ligar
- Enviar email
- Definir como principal

Estados:
- Nenhum contacto
- Contacto criado
- Email inválido

Permissões:
- `crm_contacts.view`
- `crm_contacts.manage`

Regras:
- Contacto pode estar ligado a cliente ou lead.
- Apenas um contacto principal por entidade, se configurado.

---

### 11. Tela de Notas CRM

Objetivo: registar observações comerciais.

Web:
- Timeline de notas por lead/oportunidade/cliente.
- Campo para nova nota.
- Filtro por autor.

Mobile:
- Timeline simples.

Campos:
- Nota
- Entidade relacionada
- Visibilidade
- Etiquetas

Ações:
- Adicionar nota
- Editar nota própria
- Remover
- Filtrar

Estados:
- Sem notas
- Nota criada
- Sem permissão

Permissões:
- `crm_notes.view`
- `crm_notes.create`
- `crm_notes.update`
- `crm_notes.delete`

Regras:
- Notas privadas só aparecem ao autor.
- Notas não substituem auditoria.

---

### 12. Tela de Etiquetas CRM

Objetivo: classificar leads e oportunidades.

Web:
- Lista de etiquetas.
- Associação a entidades CRM.
- Filtros por etiqueta.

Mobile:
- Chips selecionáveis.

Campos:
- Nome
- Cor
- Descrição
- Estado

Ações:
- Criar etiqueta
- Editar
- Associar
- Remover

Estados:
- Nenhuma etiqueta
- Etiqueta criada
- Nome duplicado

Permissões:
- `crm_tags.view`
- `crm_tags.manage`

Regras:
- Etiquetas são por tenant.
- Etiquetas ajudam segmentação e filtros.

---

### 13. Tela de Previsão de Receita

Objetivo: prever receita com base nas oportunidades.

Web:
- Tabela por oportunidade com valor, probabilidade, valor ponderado e previsão.
- Gráfico por mês/responsável.
- Filtros por pipeline e vendedor.

Mobile:
- Cards por período.
- Resumo de previsão.

Campos:
- Período
- Pipeline
- Responsável
- Etapa
- Probabilidade

Ações:
- Filtrar
- Exportar
- Ver oportunidade

Estados:
- Sem previsão
- Receita prevista
- Dados incompletos

Permissões:
- `crm_forecast.view`
- `crm_forecast.export`

Regras:
- Valor ponderado = valor estimado x probabilidade.
- Oportunidades ganhas/perdidas devem sair da previsão aberta.
- Previsão não substitui faturação real.

---

### 14. Tela de Relatórios CRM

Objetivo: gerar relatórios comerciais.

Web:
- Lista:
  - Leads por origem
  - Conversão de leads
  - Pipeline por etapa
  - Oportunidades ganhas/perdidas
  - Atividades por vendedor
  - Previsão de receita
  - Tempo médio de fecho
- Filtros e exportação.

Mobile:
- Seleção de relatório.
- Resumo visual.

Campos/Filtros:
- Período
- Pipeline
- Responsável
- Origem
- Estado
- Formato

Ações:
- Gerar relatório
- Exportar PDF/XLSX/CSV

Estados:
- Sem dados
- Gerando
- Relatório pronto

Permissões:
- `crm_reports.view`
- `crm_reports.export`

Regras:
- Relatórios respeitam permissões de visibilidade por equipa.
- Exportações devem ser auditadas.**

---

## Módulo: Recursos Humanos

Objetivo: gerir estrutura organizacional, funcionários, contratos, salários, assiduidade, horas extra, férias/licenças, processamento salarial, avaliações, formações e processos disciplinares.

### 1. Tela de Dashboard RH

Objetivo: apresentar visão geral de recursos humanos.

Web:
- Cards:
  - Funcionários ativos
  - Admissões no mês
  - Contratos a expirar
  - Licenças pendentes
  - Massa salarial
  - Faltas do mês
- Gráficos:
  - Headcount por departamento
  - Massa salarial por departamento
  - Assiduidade mensal
- Lista de alertas: contratos, aniversários, licenças, documentos expirados.

Mobile:
- Cards empilhados.
- Lista de alertas.
- Filtros por departamento.

Campos/Filtros:
- Departamento
- Período
- Estado do funcionário
- Filial

Ações:
- Novo funcionário
- Nova licença
- Processar salários
- Ver alertas
- Gerar relatório

Estados:
- Sem dados RH
- Carregando
- Alertas pendentes
- Sem permissão

Permissões:
- `hr.dashboard.view`

Regras:
- Gestor pode ver equipa/departamento conforme permissão.
- Dados salariais exigem permissão específica.
- Dados pertencem ao tenant ativo.

---

### 2. Tela de Estrutura Organizacional

Objetivo: gerir departamentos/unidades internas.

Web:
- Organograma em árvore.
- Lista alternativa em tabela.
- Botão “Nova unidade”.
- Ações para mover unidade na hierarquia.

Mobile:
- Lista hierárquica expansível.

Campos:
- Nome da unidade
- Código
- Unidade pai
- Responsável
- Estado

Ações:
- Criar unidade
- Editar
- Mover
- Desativar
- Ver funcionários

Estados:
- Nenhuma unidade
- Unidade criada
- Movimento inválido
- Sem permissão

Permissões:
- `org_units.view`
- `org_units.manage`

Regras:
- Não permitir mover unidade para dentro da própria subárvore.
- Unidade com funcionários não deve ser apagada.
- Closure table deve manter hierarquia consistente.

---

### 3. Tela de Cargos/Funções

Objetivo: gerir cargos e faixas salariais.

Web:
- Tabela com cargo, departamento, grau salarial, salário mínimo/máximo e estado.
- Botão “Novo cargo”.

Mobile:
- Lista de cargos.

Campos:
- Nome do cargo
- Departamento
- Grau salarial
- Salário mínimo
- Salário máximo
- Descrição
- Estado

Ações:
- Criar cargo
- Editar
- Desativar
- Ver funcionários no cargo

Estados:
- Cargo criado
- Faixa salarial inválida
- Cargo em uso

Permissões:
- `employee_positions.view`
- `employee_positions.manage`

Regras:
- Salário mínimo não pode ser maior que máximo.
- Cargo usado em contratos deve ser desativado em vez de apagado.

---

### 4. Tela de Funcionários

Objetivo: consultar e gerir cadastro de funcionários.

Web:
- Tabela com nome, código, departamento, cargo, contrato, salário, estado e data de admissão.
- Filtros por departamento, cargo, estado, contrato e filial.
- Botão “Novo funcionário”.

Mobile:
- Cards por funcionário.
- Pesquisa no topo.

Campos visíveis:
- Nome
- Código
- Departamento
- Cargo
- Estado
- Contacto

Ações:
- Criar funcionário
- Ver detalhe
- Editar
- Desativar
- Criar contrato
- Ver recibos

Estados:
- Nenhum funcionário
- Ativo
- Suspenso
- Desligado
- Sem permissão

Permissões:
- `employees.view`
- `employees.create`
- `employees.update`
- `employees.deactivate`

Regras:
- Dados salariais podem ficar ocultos sem permissão.
- Funcionário desligado mantém histórico.
- Código deve ser único por tenant.

---

### 5. Tela de Criar/Editar Funcionário

Objetivo: cadastrar ou atualizar ficha do funcionário.

Web:
- Formulário com tabs:
  - Dados pessoais
  - Contactos
  - Endereço
  - Documentos
  - Dados fiscais
  - Contrato
  - Benefícios
- Botões “Guardar” e “Cancelar”.

Mobile:
- Wizard em etapas.

Campos:
- Código
- Nome completo
- Data de nascimento
- Sexo
- Nacionalidade
- Documento/BI
- NUIT
- INSS, se aplicável
- Telefone
- Email
- Endereço
- Departamento
- Cargo
- Data de admissão
- Estado

Ações:
- Guardar
- Adicionar documento
- Criar contrato
- Cancelar

Estados:
- Salvando
- Documento duplicado
- Funcionário criado
- Dados inválidos

Permissões:
- `employees.create`
- `employees.update`

Regras:
- Documento principal deve ser único, se configurado.
- Dados pessoais são sensíveis.
- Alterações críticas devem ser auditadas.

---

### 6. Tela de Detalhe do Funcionário

Objetivo: visualizar ficha completa do funcionário.

Web:
- Cabeçalho com foto, nome, cargo, departamento e estado.
- Cards:
  - Contrato atual
  - Salário atual
  - Saldo de férias
  - Assiduidade do mês
- Tabs:
  - Resumo
  - Contratos
  - Salários
  - Assiduidade
  - Licenças
  - Recibos
  - Avaliações
  - Documentos
  - Histórico

Mobile:
- Cabeçalho compacto.
- Secções horizontais/expansíveis.

Ações:
- Editar
- Criar licença
- Registar assiduidade
- Criar avaliação
- Processar salário
- Desligar funcionário

Estados:
- Funcionário ativo
- Funcionário desligado
- Carregando
- Sem permissão

Permissões:
- `employees.view_detail`
- `employee_salaries.view`
- `employee_documents.view`

Regras:
- Salário e recibos exigem permissão específica.
- Histórico deve preservar alterações contratuais e salariais.

---

### 7. Tela de Contratos

Objetivo: gerir contratos de trabalho.

Web:
- Tabela com funcionário, tipo, início, fim, cargo, salário, estado.
- Filtros por estado e contratos a expirar.
- Botão “Novo contrato”.

Mobile:
- Cards por contrato.

Campos:
- Funcionário
- Tipo de contrato
- Data início
- Data fim
- Cargo
- Regime
- Salário base
- Horário
- Estado

Ações:
- Criar contrato
- Renovar
- Suspender
- Encerrar
- Anexar documento

Estados:
- Ativo
- A expirar
- Expirado
- Encerrado
- Suspenso

Permissões:
- `employee_contracts.view`
- `employee_contracts.create`
- `employee_contracts.update`
- `employee_contracts.close`

Regras:
- Funcionário deve ter no máximo um contrato ativo principal.
- Contrato expirado deve gerar alerta.
- Alterações contratuais devem ser auditadas.

---

### 8. Tela de Salários e Benefícios

Objetivo: gerir histórico salarial e benefícios.

Web:
- Histórico de salários por funcionário.
- Tabela de benefícios ativos.
- Botão “Nova alteração salarial”.

Mobile:
- Lista de salários/benefícios.

Campos:
- Funcionário
- Salário base
- Data efetiva
- Motivo
- Benefício
- Valor
- Periodicidade
- Estado

Ações:
- Alterar salário
- Adicionar benefício
- Encerrar benefício
- Ver histórico

Estados:
- Salário atual
- Alteração agendada
- Benefício ativo

Permissões:
- `employee_salaries.view`
- `employee_salaries.manage`
- `employee_benefits.manage`

Regras:
- Salário atual vem do registro mais recente efetivo.
- Alterações salariais exigem auditoria.
- Benefícios podem entrar no processamento salarial.

---

### 9. Tela de Componentes Salariais

Objetivo: configurar proventos e deduções.

Web:
- Tabela com componente, tipo, fórmula, tributável, estado.
- Botão “Novo componente”.

Mobile:
- Lista de componentes.

Campos:
- Nome
- Tipo: provento, dedução, subsídio, imposto
- Fórmula/valor fixo
- Tributável
- Recorrente
- Estado

Ações:
- Criar componente
- Editar
- Desativar

Estados:
- Componente ativo
- Fórmula inválida
- Componente em uso

Permissões:
- `payroll_components.view`
- `payroll_components.manage`

Regras:
- Componentes em uso não devem ser apagados.
- Fórmulas devem ser validadas.
- Componentes fiscais devem respeitar legislação/configuração.

---

### 10. Tela de Assiduidade

Objetivo: gerir presenças, faltas, atrasos e horas trabalhadas.

Web:
- Tabela por funcionário e dia.
- Filtros por departamento, período e estado.
- Botão “Registar presença”.
- Importação de ponto, se aplicável.

Mobile:
- Lista diária.
- Registo rápido de entrada/saída.

Campos:
- Funcionário
- Data
- Entrada
- Saída
- Intervalo
- Horas trabalhadas
- Estado: presente, falta, atraso, licença
- Observação

Ações:
- Registar
- Editar
- Importar ponto
- Aprovar correção

Estados:
- Presente
- Falta
- Atraso
- Correção pendente

Permissões:
- `employee_attendance.view`
- `employee_attendance.create`
- `employee_attendance.update`
- `employee_attendance.approve`

Regras:
- Horas trabalhadas podem ser calculadas.
- Alterações manuais devem ser auditadas.
- Faltas podem impactar folha salarial.

---

### 11. Tela de Horas Extra

Objetivo: gerir pedidos e aprovação de horas extraordinárias.

Web:
- Tabela com funcionário, data, horas, motivo, aprovador e estado.
- Botão “Novo pedido”.

Mobile:
- Cards por pedido.
- Aprovação rápida.

Campos:
- Funcionário
- Data
- Horas
- Motivo
- Aprovador
- Estado

Ações:
- Criar pedido
- Aprovar
- Rejeitar
- Cancelar

Estados:
- Pendente
- Aprovada
- Rejeitada
- Paga

Permissões:
- `employee_overtime.view`
- `employee_overtime.create`
- `employee_overtime.approve`

Regras:
- Aprovação pode depender do gestor.
- Horas aprovadas podem entrar na folha salarial.
- Rejeição exige motivo.

---

### 12. Tela de Férias e Licenças

Objetivo: gerir tipos de licença, saldos e pedidos.

Web:
- Calendário de ausências.
- Tabela de pedidos.
- Saldos por funcionário.
- Botão “Novo pedido”.

Mobile:
- Lista de pedidos.
- Calendário simples.

Campos:
- Funcionário
- Tipo de licença
- Data inicial
- Data final
- Dias
- Motivo
- Saldo disponível
- Estado

Ações:
- Criar pedido
- Aprovar
- Rejeitar
- Cancelar
- Ver saldo

Estados:
- Pendente
- Aprovada
- Rejeitada
- Cancelada
- Sem saldo

Permissões:
- `employee_leaves.view`
- `employee_leaves.create`
- `employee_leaves.approve`

Regras:
- Dias pedidos não podem exceder saldo, salvo permissão.
- Licença aprovada impacta assiduidade.
- Aprovação deve atualizar saldo.

---

### 13. Tela de Processamento Salarial

Objetivo: calcular e gerar salários mensais.

Web:
- Seleção de período.
- Lista de funcionários incluídos.
- Resumo bruto, deduções, líquido.
- Botões: calcular, rever, aprovar, fechar.
- Estado do processamento.

Mobile:
- Consulta e aprovação resumida.

Campos:
- Período
- Funcionários
- Salário base
- Proventos
- Deduções
- Impostos
- Líquido
- Estado

Ações:
- Criar processamento
- Calcular
- Recalcular
- Aprovar
- Fechar
- Gerar pagamentos
- Gerar lançamentos

Estados:
- Rascunho
- Calculado
- Aprovado
- Fechado
- Pago

Permissões:
- `payroll_runs.view`
- `payroll_runs.create`
- `payroll_runs.calculate`
- `payroll_runs.approve`
- `payroll_runs.close`

Regras:
- Não duplicar processamento fechado para o mesmo período.
- Processamento fechado não deve ser editado.
- Pode gerar contas a pagar/pagamentos e lançamentos contabilísticos.

---

### 14. Tela de Recibo de Vencimento

Objetivo: visualizar recibo salarial de funcionário.

Web:
- Cabeçalho com funcionário, período e cargo.
- Linhas de proventos e deduções.
- Total bruto, total deduções, líquido.
- Botão PDF.

Mobile:
- Recibo resumido.
- Download/partilha.

Campos:
- Funcionário
- Período
- Componentes
- Quantidade
- Valor
- Total líquido

Ações:
- Ver recibo
- Baixar PDF
- Enviar ao funcionário

Estados:
- Recibo gerado
- Recibo pago
- Sem permissão

Permissões:
- `payslips.view`
- `payslips.download`
- `payslips.send`

Regras:
- Funcionário pode ver apenas seus recibos, se permitido.
- RH/financeiro vê conforme permissão.
- Recibo deve refletir processamento fechado.

---

### 15. Tela de Avaliações de Desempenho

Objetivo: gerir avaliações periódicas.

Web:
- Tabela com funcionário, período, avaliador, pontuação e estado.
- Formulário com critérios e comentários.

Mobile:
- Lista e formulário simplificado.

Campos:
- Funcionário
- Avaliador
- Período
- Critérios
- Pontuação
- Comentários
- Plano de melhoria

Ações:
- Criar avaliação
- Preencher
- Submeter
- Aprovar
- Ver histórico

Estados:
- Rascunho
- Submetida
- Aprovada
- Arquivada

Permissões:
- `employee_evaluations.view`
- `employee_evaluations.create`
- `employee_evaluations.approve`

Regras:
- Avaliador deve ter vínculo ou permissão.
- Pontuação final pode ser calculada por critérios.
- Avaliação aprovada não deve ser editada.

---

### 16. Tela de Formação e Desenvolvimento

Objetivo: acompanhar formações dos funcionários.

Web:
- Tabela com funcionário, formação, instituição, data, custo e certificado.
- Botão “Nova formação”.

Mobile:
- Cards por formação.

Campos:
- Funcionário
- Nome da formação
- Instituição
- Data inicial/final
- Carga horária
- Custo
- Certificado
- Resultado

Ações:
- Criar formação
- Anexar certificado
- Editar
- Ver histórico

Estados:
- Planeada
- Concluída
- Cancelada

Permissões:
- `employee_training.view`
- `employee_training.manage`

Regras:
- Certificados são anexos sensíveis.
- Custos podem alimentar relatórios de RH.

---

### 17. Tela de Processos Disciplinares

Objetivo: gerir ocorrências e sanções disciplinares.

Web:
- Tabela com funcionário, tipo, data, estado e sanção.
- Botão “Novo processo”.

Mobile:
- Lista restrita conforme permissão.

Campos:
- Funcionário
- Tipo de ocorrência
- Data
- Descrição
- Sanção
- Responsável
- Anexos
- Estado

Ações:
- Criar processo
- Atualizar estado
- Anexar documento
- Encerrar

Estados:
- Aberto
- Em análise
- Encerrado
- Cancelado

Permissões:
- `employee_disciplinary.view`
- `employee_disciplinary.manage`

Regras:
- Dados altamente sensíveis.
- Acesso deve ser restrito.
- Alterações devem ser auditadas.

---

### 18. Tela de Relatórios RH

Objetivo: gerar relatórios de recursos humanos.

Web:
- Lista:
  - Funcionários ativos
  - Headcount por departamento
  - Massa salarial
  - Assiduidade
  - Férias/licenças
  - Contratos a expirar
  - Folha salarial
  - Avaliações
- Filtros e exportação.

Mobile:
- Seleção de relatório.
- Resumo e exportação.

Campos/Filtros:
- Período
- Departamento
- Cargo
- Estado
- Formato

Ações:
- Gerar relatório
- Exportar PDF/XLSX/CSV

Estados:
- Sem dados
- Gerando
- Relatório pronto

Permissões:
- `hr_reports.view`
- `hr_reports.export`

Regras:
- Relatórios salariais exigem permissão específica.
- Exportações devem ser auditadas.**

---

## Módulo: Assinaturas

Objetivo: gerir planos SaaS, licenças, ciclos de faturação recorrente, pagamentos de assinatura, limites operacionais, uso por tenant, suspensão, cancelamento e reativação.

### 1. Tela de Dashboard de Assinaturas

Objetivo: apresentar visão geral das assinaturas e receitas recorrentes.

Web:
- Cards:
  - Assinaturas ativas
  - Assinaturas em trial
  - Assinaturas suspensas
  - Receita recorrente mensal
  - Pagamentos vencidos
  - Cancelamentos no mês
- Gráfico de MRR/receita recorrente.
- Lista de assinaturas em risco.

Mobile:
- Cards empilhados.
- Lista de assinaturas críticas.

Campos/Filtros:
- Período
- Plano
- Estado
- Cliente/empresa

Ações:
- Nova assinatura
- Ver vencidas
- Ver suspensas
- Gerar relatório
- Criar plano

Estados:
- Sem assinaturas
- Carregando
- Pagamentos vencidos
- Sem permissão

Permissões:
- `subscriptions.dashboard.view`

Regras:
- Dados pertencem ao tenant/plataforma conforme perfil.
- Receita recorrente deve considerar assinaturas ativas e ciclos faturados.
- Suspensões devem destacar impacto operacional.

---

### 2. Tela de Planos de Assinatura

Objetivo: gerir planos SaaS disponíveis.

Web:
- Tabela com nome, preço, ciclo, trial, limites e estado.
- Botão “Novo plano”.
- Ação para duplicar plano.

Mobile:
- Cards por plano.
- Lista de funcionalidades/limites.

Campos:
- Nome do plano
- Código
- Preço
- Moeda
- Ciclo: mensal, trimestral, anual
- Dias de trial
- Limite de utilizadores
- Limite de filiais
- Limite de produtos
- Limite de documentos/mês
- Módulos incluídos
- Estado

Ações:
- Criar plano
- Editar plano
- Duplicar
- Ativar/desativar
- Ver assinaturas do plano

Estados:
- Plano ativo
- Plano inativo
- Plano em uso
- Código duplicado

Permissões:
- `subscription_plans.view`
- `subscription_plans.create`
- `subscription_plans.update`

Regras:
- Plano em uso não deve ser apagado.
- Alterações de preço podem afetar apenas novas assinaturas ou próxima renovação.
- Módulos incluídos definem permissões/licença do tenant.

---

### 3. Tela de Funcionalidades do Plano

Objetivo: definir recursos incluídos em cada plano.

Web:
- Matriz com planos nas colunas e funcionalidades nas linhas.
- Toggles para incluir/excluir funcionalidades.
- Campos para limites numéricos.

Mobile:
- Lista por plano.
- Funcionalidades em switches.

Campos:
- Plano
- Módulo
- Funcionalidade
- Incluído: sim/não
- Limite
- Observação

Ações:
- Adicionar funcionalidade
- Editar limite
- Guardar alterações

Estados:
- Funcionalidade ativa
- Funcionalidade indisponível
- Alterações pendentes

Permissões:
- `subscription_plan_features.view`
- `subscription_plan_features.manage`

Regras:
- Funcionalidades críticas podem depender de módulos ativos.
- Limites do plano são aplicados ao tenant na operação.

---

### 4. Tela de Assinaturas

Objetivo: consultar assinaturas de empresas/clientes.

Web:
- Tabela com empresa, cliente, plano, ciclo, estado, início, renovação e valor.
- Filtros por plano, estado, renovação e cliente.
- Botão “Nova assinatura”.

Mobile:
- Cards por assinatura.
- Estado e próxima renovação destacados.

Campos visíveis:
- Empresa
- Cliente
- Plano
- Estado
- Próxima renovação
- Valor

Ações:
- Criar assinatura
- Ver detalhe
- Alterar plano
- Pausar
- Suspender
- Reativar
- Cancelar

Estados:
- Trial
- Ativa
- Pausada
- Suspensa
- Cancelada
- Expirada

Permissões:
- `subscriptions.view`
- `subscriptions.create`
- `subscriptions.update`
- `subscriptions.cancel`

Regras:
- Cada empresa deve ter assinatura ativa ou estado definido.
- Suspensa bloqueia uso conforme política.
- Alteração de plano deve recalcular limites.

---

### 5. Tela de Criar/Editar Assinatura

Objetivo: criar ou alterar assinatura de uma empresa.

Web:
- Formulário com cliente/empresa, plano, ciclo, datas e forma de pagamento.
- Pré-visualização dos limites do plano.
- Botão “Guardar”.

Mobile:
- Wizard:
  1. Empresa/cliente
  2. Plano
  3. Datas e pagamento
  4. Revisão

Campos:
- Empresa
- Cliente
- Plano
- Ciclo
- Data de início
- Data de renovação
- Trial
- Método de pagamento
- Desconto
- Estado

Ações:
- Guardar assinatura
- Ativar
- Cancelar

Estados:
- Empresa já possui assinatura ativa
- Plano obrigatório
- Assinatura criada
- Datas inválidas

Permissões:
- `subscriptions.create`
- `subscriptions.update`

Regras:
- Não permitir múltiplas assinaturas ativas conflitantes para a mesma empresa.
- Trial deve respeitar dias do plano.
- Cliente vem de `gestao-clientes`.

---

### 6. Tela de Detalhe da Assinatura

Objetivo: visualizar assinatura completa.

Web:
- Cabeçalho com empresa, plano, estado e próxima renovação.
- Cards:
  - Valor recorrente
  - Ciclo atual
  - Dias restantes
  - Utilizadores usados/permitidos
  - Documentos usados/limite
- Tabs:
  - Ciclos
  - Pagamentos
  - Uso
  - Eventos
  - Pausas/cancelamentos

Mobile:
- Cabeçalho compacto.
- Cards de uso.
- Tabs horizontais.

Ações:
- Alterar plano
- Renovar
- Suspender
- Reativar
- Pausar
- Cancelar
- Gerar fatura

Estados:
- Ativa
- Trial
- Suspensa
- Expirada
- Cancelada

Permissões:
- `subscriptions.view_detail`
- `subscriptions.manage`

Regras:
- Uso deve ser comparado aos limites do plano.
- Eventos devem manter histórico completo.
- Faturas recorrentes integram com faturação.

---

### 7. Tela de Ciclos de Faturação

Objetivo: gerir ciclos recorrentes da assinatura.

Web:
- Tabela com período, valor, vencimento, fatura, pagamento e estado.
- Botão “Gerar ciclo”, se manual.

Mobile:
- Cards por ciclo.

Campos:
- Assinatura
- Período inicial
- Período final
- Valor
- Data de vencimento
- Fatura associada
- Estado

Ações:
- Gerar ciclo
- Gerar fatura
- Marcar como faturado
- Reprocessar ciclo

Estados:
- Pendente
- Faturado
- Pago
- Vencido
- Cancelado

Permissões:
- `subscription_billing_cycles.view`
- `subscription_billing_cycles.generate`
- `subscription_billing_cycles.invoice`

Regras:
- Ciclo não deve duplicar período já faturado.
- Ciclo faturado deve gerar documento em `modulo-faturacao`.
- Ciclo vencido pode suspender assinatura conforme política.

---

### 8. Tela de Pagamentos de Assinatura

Objetivo: consultar e registar pagamentos recorrentes.

Web:
- Tabela com empresa, ciclo, valor, gateway, referência, data e estado.
- Filtros por estado, gateway, período.
- Botão “Registar pagamento”.

Mobile:
- Cards por pagamento.

Campos:
- Assinatura
- Ciclo
- Valor
- Gateway
- Referência
- Data
- Estado

Ações:
- Registar pagamento
- Confirmar pagamento
- Reconciliar
- Ver recibo
- Anular

Estados:
- Pendente
- Confirmado
- Falhado
- Reembolsado
- Anulado

Permissões:
- `subscription_payments.view`
- `subscription_payments.create`
- `subscription_payments.confirm`

Regras:
- Pagamento confirmado pode reativar assinatura suspensa.
- Deve alimentar financeiro/tesouraria.
- Gateway deve guardar referência externa.

---

### 9. Tela de Gateways de Pagamento

Objetivo: configurar meios de cobrança recorrente.

Web:
- Cards:
  - M-Pesa
  - e-Mola
  - Transferência
  - Stripe
  - PayPal
  - Outro
- Estado da integração.
- Botão configurar/testar.

Mobile:
- Lista de gateways.

Campos:
- Nome
- Tipo
- Ambiente: sandbox/produção
- Chave/API
- Segredo
- Webhook URL
- Estado

Ações:
- Configurar gateway
- Testar conexão
- Ativar/desativar
- Ver logs

Estados:
- Não configurado
- Ativo
- Com erro
- Teste bem-sucedido

Permissões:
- `payment_gateways.view`
- `payment_gateways.configure`

Regras:
- Segredos devem ser mascarados.
- Webhooks devem validar assinatura.
- Testes devem gerar logs técnicos.

---

### 10. Tela de Uso da Assinatura

Objetivo: acompanhar consumo dos limites contratados.

Web:
- Cards:
  - Utilizadores usados/limite
  - Filiais usadas/limite
  - Produtos usados/limite
  - Documentos emitidos no mês/limite
- Histórico de consumo.
- Alertas de limite.

Mobile:
- Barras de progresso por métrica.

Campos:
- Métrica
- Limite
- Uso atual
- Percentual usado
- Período

Ações:
- Atualizar uso
- Ver detalhes
- Notificar cliente
- Sugerir upgrade

Estados:
- Dentro do limite
- Próximo do limite
- Limite excedido
- Sem limite

Permissões:
- `subscription_usage.view`
- `subscription_usage.manage`

Regras:
- Uso deve ser calculado por tenant.
- Exceder limite pode bloquear ação ou sugerir upgrade.
- Documentos/mês reiniciam por ciclo.

---

### 11. Tela de Pausas de Assinatura

Objetivo: gerir pausas temporárias.

Web:
- Tabela com assinatura, início, fim, motivo e estado.
- Botão “Nova pausa”.

Mobile:
- Cards por pausa.

Campos:
- Assinatura
- Data inicial
- Data final
- Motivo
- Estado

Ações:
- Criar pausa
- Encerrar pausa
- Cancelar pausa

Estados:
- Agendada
- Ativa
- Encerrada
- Cancelada

Permissões:
- `subscription_pauses.view`
- `subscription_pauses.manage`

Regras:
- Pausa pode suspender cobrança ou uso conforme política.
- Período de pausa não deve sobrepor outra pausa ativa.
- Encerramento deve recalcular próxima renovação, se configurado.

---

### 12. Tela de Cancelamentos

Objetivo: gerir cancelamento de assinaturas.

Web:
- Formulário de cancelamento.
- Opções:
  - Cancelar imediatamente
  - Cancelar no fim do ciclo
- Motivo obrigatório.

Mobile:
- Fluxo de confirmação.

Campos:
- Assinatura
- Data efetiva
- Motivo
- Observação
- Manter acesso até fim do ciclo: sim/não

Ações:
- Agendar cancelamento
- Confirmar cancelamento
- Reverter cancelamento

Estados:
- Cancelamento agendado
- Cancelada
- Revertida

Permissões:
- `subscriptions.cancel`
- `subscriptions.cancel_revert`

Regras:
- Cancelamento deve manter histórico.
- Cancelamento no fim do ciclo mantém acesso até expiração.
- Motivo obrigatório para análise de churn.

---

### 13. Tela de Eventos da Assinatura

Objetivo: consultar histórico da licença.

Web:
- Timeline com eventos:
  - Criada
  - Trial iniciado
  - Plano alterado
  - Ciclo faturado
  - Pagamento confirmado
  - Suspensa
  - Reativada
  - Cancelada
- Filtros por tipo.

Mobile:
- Timeline vertical.

Campos:
- Data/hora
- Tipo de evento
- Utilizador/sistema
- Descrição
- Metadados

Ações:
- Filtrar
- Ver detalhe
- Exportar

Estados:
- Sem eventos
- Carregando

Permissões:
- `subscription_events.view`

Regras:
- Eventos não devem ser editáveis.
- Eventos críticos também podem ir para auditoria.

---

### 14. Tela de Relatórios de Assinaturas

Objetivo: gerar relatórios SaaS e recorrência.

Web:
- Lista:
  - Assinaturas por estado
  - Receita recorrente mensal
  - Cancelamentos
  - Trial conversion
  - Pagamentos vencidos
  - Uso por plano
  - Upgrade/downgrade
- Filtros e exportação.

Mobile:
- Seleção de relatório.
- Resumo.

Campos/Filtros:
- Período
- Plano
- Estado
- Empresa
- Formato

Ações:
- Gerar relatório
- Exportar PDF/XLSX/CSV

Estados:
- Sem dados
- Gerando
- Relatório pronto

Permissões:
- `subscription_reports.view`
- `subscription_reports.export`

Regras:
- Relatórios financeiros devem bater com ciclos faturados/pagos.
- Exportações devem ser auditadas.

---

## Módulo: Centros de Custo

Objetivo: gerir centros de custo, rateios, alocação de despesas/receitas, orçamentos por centro, análise de rentabilidade e integração com contabilidade, financeiro, compras, RH e faturação.

### 1. Tela de Dashboard de Centros de Custo

Objetivo: apresentar visão geral de custos, receitas e rentabilidade por centro.

Web:
- Cards:
  - Total de custos do período
  - Total de receitas alocadas
  - Resultado por centro
  - Centros acima do orçamento
  - Despesas sem centro de custo
  - Lançamentos pendentes de alocação
- Gráficos:
  - Custos por centro
  - Orçado vs realizado
  - Receita vs custo
- Lista de alertas.

Mobile:
- Cards empilhados.
- Gráficos resumidos.
- Lista de centros com maior desvio.

Campos/Filtros:
- Período
- Centro de custo
- Departamento
- Projeto
- Filial

Ações:
- Novo centro de custo
- Nova regra de rateio
- Ver despesas sem alocação
- Gerar relatório

Estados:
- Sem centros cadastrados
- Carregando
- Desvio acima do orçamento
- Sem permissão

Permissões:
- `cost_centers.dashboard.view`

Regras:
- Dados vêm da contabilidade e financeiro.
- Centros de custo pertencem ao tenant.
- Valores devem respeitar período fiscal.

---

### 2. Tela de Lista de Centros de Custo

Objetivo: consultar e gerir centros de custo.

Web:
- Tabela com código, nome, tipo, responsável, centro pai, orçamento, realizado e estado.
- Visualização alternativa em árvore.
- Filtros por tipo, responsável e estado.
- Botão “Novo centro”.

Mobile:
- Lista hierárquica em cards.
- Pesquisa por código/nome.

Campos visíveis:
- Código
- Nome
- Tipo
- Responsável
- Orçamento
- Realizado
- Estado

Ações:
- Criar centro
- Editar
- Desativar
- Ver detalhes
- Ver lançamentos
- Ver relatório

Estados:
- Nenhum centro
- Ativo
- Inativo
- Acima do orçamento

Permissões:
- `cost_centers.view`
- `cost_centers.create`
- `cost_centers.update`
- `cost_centers.deactivate`

Regras:
- Código deve ser único por tenant.
- Centro com movimentos não deve ser apagado.
- Pode existir hierarquia de centros.

---

### 3. Tela de Criar/Editar Centro de Custo

Objetivo: cadastrar ou atualizar centro de custo.

Web:
- Formulário com dados gerais, responsável, hierarquia e orçamento inicial.
- Botões “Guardar” e “Cancelar”.

Mobile:
- Formulário em etapas:
  1. Dados gerais
  2. Responsável
  3. Orçamento
  4. Revisão

Campos:
- Código
- Nome
- Descrição
- Tipo: departamento, projeto, filial, produto, serviço, campanha, outro
- Centro pai
- Responsável
- Data inicial
- Data final
- Orçamento inicial
- Estado

Ações:
- Guardar
- Cancelar
- Validar código

Estados:
- Código duplicado
- Data inválida
- Centro criado
- Centro atualizado

Permissões:
- `cost_centers.create`
- `cost_centers.update`

Regras:
- Data final não pode ser anterior à inicial.
- Centro pai não pode ser ele próprio.
- Alterações devem ser auditadas.

---

### 4. Tela de Detalhe do Centro de Custo

Objetivo: visualizar desempenho e movimentos do centro.

Web:
- Cabeçalho com código, nome, responsável e estado.
- Cards:
  - Orçamento
  - Realizado
  - Disponível
  - Receita
  - Custo
  - Resultado
- Tabs:
  - Resumo
  - Lançamentos
  - Orçamento
  - Rateios
  - Documentos
  - Histórico

Mobile:
- Cabeçalho compacto.
- Cards empilhados.
- Tabs horizontais.

Ações:
- Editar
- Ver lançamentos
- Criar orçamento
- Criar regra de rateio
- Exportar relatório

Estados:
- Centro ativo
- Centro inativo
- Acima do orçamento
- Sem movimentos

Permissões:
- `cost_centers.view_detail`
- `cost_center_movements.view`

Regras:
- Valores realizados vêm de lançamentos contabilísticos.
- Disponível = orçamento - realizado.
- Centro inativo não deve receber novos lançamentos.

---

### 5. Tela de Hierarquia de Centros de Custo

Objetivo: organizar centros em níveis.

Web:
- Árvore com drag-and-drop.
- Painel lateral com detalhes do centro selecionado.
- Botão “Mover centro”.

Mobile:
- Lista expansível.
- Ação “Mover para”.

Campos:
- Centro
- Centro pai
- Nível
- Caminho hierárquico

Ações:
- Mover centro
- Expandir/recolher
- Ver subcentros
- Exportar estrutura

Estados:
- Estrutura carregada
- Movimento inválido
- Sem permissão

Permissões:
- `cost_center_hierarchy.view`
- `cost_center_hierarchy.update`

Regras:
- Não permitir ciclos na hierarquia.
- Movimentos devem manter histórico.
- Subcentros podem consolidar valores no centro pai.

---

### 6. Tela de Lançamentos por Centro de Custo

Objetivo: consultar lançamentos contabilísticos associados aos centros.

Web:
- Tabela com data, conta, documento, descrição, débito, crédito, centro de custo e origem.
- Filtros por período, conta, origem e centro.
- Exportação.

Mobile:
- Lista cronológica.
- Filtros compactos.

Campos:
- Data
- Conta contabilística
- Documento
- Centro de custo
- Débito
- Crédito
- Origem
- Descrição

Ações:
- Filtrar
- Ver lançamento
- Ver documento origem
- Exportar

Estados:
- Sem lançamentos
- Carregando
- Sem permissão

Permissões:
- `cost_center_entries.view`
- `cost_center_entries.export`

Regras:
- Lançamentos vêm de `journal_entry_lines`.
- Um lançamento pode ter centro direto ou rateio.
- Períodos encerrados são apenas consulta.

---

### 7. Tela de Alocação Manual

Objetivo: atribuir centro de custo a lançamentos ou despesas sem alocação.

Web:
- Lista de lançamentos sem centro.
- Seleção de centro de custo.
- Aplicação individual ou em lote.
- Justificativa obrigatória.

Mobile:
- Lista de pendências.
- Alocação por item.

Campos:
- Lançamento
- Documento origem
- Valor
- Centro de custo
- Justificativa

Ações:
- Alocar centro
- Alocar em lote
- Ignorar pendência
- Ver origem

Estados:
- Pendente de alocação
- Alocado
- Justificativa obrigatória
- Período encerrado

Permissões:
- `cost_center_allocations.view`
- `cost_center_allocations.create`

Regras:
- Não alterar lançamentos em período encerrado sem reabertura/permissão.
- Alocação deve ser auditada.
- Valor total alocado deve bater com o valor do lançamento.

---

### 8. Tela de Regras de Rateio

Objetivo: configurar distribuição automática de valores entre centros.

Web:
- Tabela com nome da regra, base de rateio, centros envolvidos, percentuais e estado.
- Botão “Nova regra”.

Mobile:
- Cards por regra.
- Detalhe com percentuais.

Campos:
- Nome da regra
- Tipo: percentual, valor fixo, quantidade, headcount, receita
- Centros de custo
- Percentual/valor por centro
- Conta/categoria aplicável
- Estado

Ações:
- Criar regra
- Editar
- Simular rateio
- Ativar/desativar

Estados:
- Regra ativa
- Percentual inválido
- Soma diferente de 100%
- Regra em uso

Permissões:
- `cost_allocation_rules.view`
- `cost_allocation_rules.manage`

Regras:
- Rateio percentual deve somar 100%.
- Regras em uso devem preservar histórico.
- Aplicação automática deve registrar origem.

---

### 9. Tela de Simulação de Rateio

Objetivo: simular distribuição antes de aplicar.

Web:
- Seleção de valor/documento/regra.
- Resultado por centro.
- Diferença de arredondamento.
- Botão “Aplicar rateio”.

Mobile:
- Resumo por centro.
- Confirmação final.

Campos:
- Regra de rateio
- Valor base
- Centros
- Percentual
- Valor calculado
- Diferença

Ações:
- Simular
- Aplicar
- Exportar simulação

Estados:
- Simulação calculada
- Diferença de arredondamento
- Regra inválida
- Rateio aplicado

Permissões:
- `cost_allocation_simulation.view`
- `cost_allocations.apply`

Regras:
- Soma dos valores distribuídos deve igualar valor base.
- Diferenças de arredondamento devem ser tratadas em um centro definido.
- Aplicação deve gerar registros rastreáveis.

---

### 10. Tela de Orçamento por Centro de Custo

Objetivo: planear custos/receitas por centro e período.

Web:
- Grelha por centro, categoria/conta e mês.
- Comparação orçado vs realizado.
- Importação/exportação.
- Alertas de desvio.

Mobile:
- Lista por centro e mês.
- Barras de progresso.

Campos:
- Ano/período
- Centro de custo
- Conta/categoria
- Valor orçado
- Moeda
- Observação

Ações:
- Criar orçamento
- Editar orçamento
- Importar
- Exportar
- Comparar realizado

Estados:
- Sem orçamento
- Orçamento criado
- Realizado acima do orçado
- Valor inválido

Permissões:
- `cost_center_budgets.view`
- `cost_center_budgets.manage`

Regras:
- Valor orçado não pode ser negativo.
- Realizado vem dos lançamentos alocados.
- Alterações devem manter histórico.

---

### 11. Tela de Despesas Sem Centro de Custo

Objetivo: identificar valores que precisam de alocação.

Web:
- Tabela com data, documento, conta, valor, origem e responsável.
- Filtros por período, origem e conta.
- Ação “Alocar”.

Mobile:
- Lista de pendências.

Campos:
- Data
- Documento
- Origem
- Conta
- Valor
- Responsável

Ações:
- Alocar
- Ignorar
- Ver documento
- Exportar

Estados:
- Sem pendências
- Pendente
- Ignorada
- Alocada

Permissões:
- `cost_center_unallocated.view`
- `cost_center_allocations.create`

Regras:
- Pendências devem excluir contas que não exigem centro.
- Ignorar deve exigir motivo.
- Pendências podem alimentar alertas.

---

### 12. Tela de Rentabilidade por Centro

Objetivo: analisar resultado financeiro por centro de custo.

Web:
- Tabela com centro, receitas, custos diretos, custos rateados, resultado e margem.
- Gráfico de comparação.
- Drill-down para documentos e lançamentos.

Mobile:
- Cards por centro.
- Margem destacada.

Campos/Filtros:
- Período
- Centro
- Tipo
- Departamento
- Projeto

Ações:
- Filtrar
- Ver detalhes
- Exportar
- Comparar períodos

Estados:
- Sem dados
- Centro lucrativo
- Centro deficitário

Permissões:
- `cost_center_profitability.view`
- `cost_center_profitability.export`

Regras:
- Receita pode vir de faturação/contabilidade.
- Custos diretos e rateados devem ser separados.
- Margem = resultado / receita, quando receita > 0.

---

### 13. Tela de Configurações de Centros de Custo

Objetivo: definir políticas de uso.

Web:
- Secções:
  - Obrigatoriedade por módulo
  - Contas que exigem centro
  - Aprovação de rateios
  - Orçamentos
  - Alertas de desvio
- Toggles e campos.

Mobile:
- Lista de configurações.

Campos:
- Exigir centro em compras
- Exigir centro em despesas financeiras
- Exigir centro em RH/folha
- Exigir centro em lançamentos manuais
- Percentual de alerta de orçamento
- Permitir alocação após encerramento
- Exigir aprovação de rateio

Ações:
- Guardar configurações
- Restaurar padrão

Estados:
- Configurações guardadas
- Erro de validação
- Sem permissão

Permissões:
- `cost_center_settings.view`
- `cost_center_settings.update`

Regras:
- Alterações devem ser auditadas.
- Exigência de centro deve validar documentos antes de emissão/aprovação.
- Períodos encerrados devem ser protegidos.

---

### 14. Tela de Relatórios de Centros de Custo

Objetivo: gerar relatórios gerenciais.

Web:
- Lista:
  - Custos por centro
  - Orçado vs realizado
  - Rentabilidade por centro
  - Despesas sem centro
  - Rateios aplicados
  - Lançamentos por centro
  - Comparativo por período
- Filtros e exportação.

Mobile:
- Seleção de relatório.
- Resumo e exportação.

Campos/Filtros:
- Período
- Centro de custo
- Conta
- Departamento
- Projeto
- Formato

Ações:
- Gerar relatório
- Exportar PDF/XLSX/CSV
- Agendar envio

Estados:
- Sem dados
- Gerando
- Relatório pronto
- Erro

Permissões:
- `cost_center_reports.view`
- `cost_center_reports.export`

Regras:
- Relatórios devem respeitar permissões financeiras/contabilísticas.
- Exportações devem ser auditadas.
