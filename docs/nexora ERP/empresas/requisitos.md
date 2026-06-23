# Requisitos — Modulo Empresas

## Requisitos Funcionais

### RF01 — Registo de Empresa
O sistema deve permitir criar uma empresa com codigo unico, nome, tipo, moeda base e timezone.

### RF02 — Gestao de Filiais
O sistema deve permitir criar e gerir filiais (branches) associadas a uma empresa, incluindo definir a filial principal.

### RF03 — Informacao Fiscal
O sistema deve armazenar o NUIT, regime de IVA, taxa de IVA padrao e reparticao fiscal de cada empresa.

### RF04 — Contas Bancarias da Empresa
O sistema deve permitir registar multiplas contas bancarias por empresa, identificando a conta principal.

### RF05 — Moradas e Contactos
O sistema deve suportar multiplas moradas (principal, fiscal, entrega) e contactos por empresa e por filial.

### RF06 — Documentos Legais
O sistema deve permitir anexar documentos legais (alvara, certidao, licenca) com datas de emissao e validade.

### RF07 — Licenciamento
O sistema deve controlar o plano de licenca de cada empresa, incluindo limites de utilizadores, filiais e data de expiracao.

### RF08 — Estado da Empresa
O sistema deve suportar os estados: ativa, suspensa e inativa, com impacto no acesso ao sistema.

### RF09 — Associacao Utilizador-Empresa
O sistema deve associar utilizadores a empresas (e opcionalmente a filiais), controlando o perfil por empresa.

### RF10 — Isolamento Multi-Tenant
Todos os dados do sistema devem estar isolados por empresa (tenant_id), impedindo acesso cruzado entre empresas.

---

## Requisitos Nao Funcionais

### RNF01 — Isolamento de Dados
Todas as queries devem incluir o filtro `tenant_id` para garantir isolamento total entre empresas.

### RNF02 — Unicidade de Codigos
O codigo da empresa deve ser globalmente unico no sistema (sem tenant_id).

### RNF03 — Disponibilidade
O modulo de empresas deve estar disponivel antes de qualquer outro modulo, pois e a base do isolamento multi-tenant.

### RNF04 — Auditoria
Qualquer alteracao aos dados da empresa (nome, estado, fiscal) deve gerar um registo de auditoria.

### RNF05 — Validacao Fiscal
O NUIT deve ser unico por empresa no sistema e validado no formato moçambicano.
