# Plano de Ação - OmnisysERP Desktop

Baseado na análise completa, aqui está o plano recomendado para implementar as lacunas críticas e tornar a aplicação pronta para produção.

## 🎯 Plano de Ação Recomendado

### Fase 1: Critical Fixes (1-2 dias)
- [ ] Implementar token refresh automático
- [ ] Adicionar botão de logout
- [ ] Corrigir eliminação de assiduidade (ou remover botão)
- [ ] Registar device ID no backend

### Fase 2: Essential Features (3-5 dias)
- [ ] Criar Dashboard com métricas
- [ ] Criar Settings Panel
- [ ] Implementar role-based UI
- [ ] Adicionar retry automático
- [ ] Handler global de exceções

### Fase 3: Important Features (1 semana)
- [ ] Self-service panel (/clock/me)
- [ ] Reports panel (usar backend export)
- [ ] Audit log viewer
- [ ] Adjustment request workflow
- [ ] Session timer

### Fase 4: Advanced Features (2 semanas)
- [ ] Face recognition (biometric verify)
- [ ] Units management
- [ ] Devices management
- [ ] Biometric enrollment
- [ ] Consent management
- [ ] Modo offline com sync

### Fase 5: Polish (1 semana)
- [ ] Centralizar cores e constantes
- [ ] Remover dependências não usadas
- [ ] Adicionar testes unitários
- [ ] Melhoria de performance
- [ ] Documentação completa

## 📈 Estado Atual vs Estado Desejado

| Aspecto | Agora | Ideal | Gap |
|---------|-------|-------|-----|
| **Autenticação** | Login básico | Login + refresh + logout + MFA | 🔴 Alto |
| **Funcionários** | CRUD completo | CRUD + foto + documentos | 🟡 Médio |
| **Assiduidade** | Registo manual | Manual + auto + biometric | 🔴 Alto |
| **Camera** | Detecção | Reconhecimento | 🔴 Alto |
| **Roles** | Nenhuma | 4 roles com permissões | 🔴 Alto |
| **Offline** | Não funciona | Funciona com sync | 🔴 Alto |
| **Settings** | Editar ficheiro | UI dedicada | 🟡 Médio |
| **Reports** | CSV manual | Dashboard + export | 🟡 Médio |
| **Testes** | 0% cobertura | 80% cobertura | 🔴 Alto |
| **Documentação** | 2 MD files | Completa + Javadoc | 🟡 Médio |

## 💡 Recomendações Imediatas

### O que fazer AGORA:
1. **Token Refresh** - Crítico para uso contínuo
2. **Logout Button** - Básico para usabilidade
3. **Settings Panel** - Para configurar backend URL sem recompilar
4. **Role-based UI** - Para segurança mínima

### O que pode esperar:
1. **Face Recognition** - Funcionalidade avançada
2. **Offline Mode** - Complexo, pode esperar
3. **Audit Viewer** - Importante mas não crítico
4. **Testes** - Importante mas pode esperar Fase 2

**Data da Criação:** 14 de Abril de 2026