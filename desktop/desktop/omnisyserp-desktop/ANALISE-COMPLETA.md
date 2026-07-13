# Análise Completa - OmnisysERP Desktop

## 📊 Resumo Executivo

A aplicação desktop tem **26 ficheiros Java** com funcionalidades básicas implementadas, mas existem **lacunas críticas** que impedem o uso em produção.

---

## ✅ O que ESTÁ Implementado

### Funcionalidades Completas
| Módulo | Funcionalidade | Estado |
|--------|---------------|--------|
| **Login** | Autenticação via username/password | ✅ Completo |
| **Funcionários** | CRUD completo | ✅ Completo |
| **Assiduidade** | Listagem, filtros, registo manual | ✅ Completo |
| **Assiduidade** | Exportação CSV | ✅ Completo |
| **Camera** | Captura de vídeo em tempo real | ✅ Completo |
| **Camera** | Detecção de faces (OpenCV) | ✅ Completo |
| **Camera** | Registo entrada/saída com foto | ✅ Completo |
| **UI** | Design moderno com FlatLaf | ✅ Completo |
| **Backend** | Integração via REST API | ✅ Parcial |

---

## 🚨 Bugs Críticos (PRIORIDADE 1)

### 1. **Token Refresh Não Implementado** ❌
**Problema:** Access token expira em 60 minutos e não há renovação automática.
**Impacto:** Utilizador tem que reiniciar a aplicação a cada hora.
**Solução:** Implementar interceptor que detecta 401 e chama `POST /auth/refresh`.

### 2. **Logout Não Existe** ❌
**Problema:** Não há botão de logout em lugar nenhum.
**Impacto:** Impossível trocar de utilizador sem fechar a aplicação.
**Solução:** Adicionar botão de logout no sidebar ou status bar.

### 3. **Eliminar Assiduidade Lança Exceção** ❌
**Problema:** `AssiduidadeService.eliminar()` lança `UnsupportedOperationException`.
**Impacto:** Botão "Eliminar" no painel de assiduidade sempre falha.
**Solução:** Implementar workflow de adjustment request ou remover botão.

### 4. **Device ID Hardcoded** ⚠️
**Problema:** Device ID `00000000-0000-0000-0000-000000000099` está fixo no properties.
**Impacto:** Backend pode rejeitar registos se device não existir.
**Solução:** Registar device automaticamente no primeiro arranque.

---

## ⚠️ Funcionalidades Incompletas (PRIORIDADE 2)

### 5. **Detecção Facial ≠ Reconhecimento Facial** 
**Atual:** Camera detecta rostos (rectângulos) mas não identifica funcionário.
**Falta:** Integração com `/biometric/verify` para matching.
**Backend disponível:** 
- `POST /biometric/enroll` - Registar template facial
- `POST /biometric/verify` - Verificar identidade

### 6. **Auto-Detecção da Camera Não Faz Nada**
**Atual:** Checkbox apenas faz log.
**Falta:** Detectar rosto e auto-preencher funcionário ou sugerir matching.

### 7. **Sem Gestão de Unidades/Departamentos**
**Backend tem:** `GET/POST /admin/units`
**Desktop:** Não tem UI para isto.
**Impacto:** Não é possível criar/editar unidades organizacionais.

### 8. **Sem Gestão de Dispositivos**
**Backend tem:** CRUD completo de devices
**Desktop:** Device ID hardcoded sem registo.
**Impacto:** Devices não aparecem no backend.

### 9. **Sem Painel de Ajustes de Horário**
**Backend tem:** 
- `POST /clock/adjustments` - Pedir ajuste
- `GET /admin/adjustments` - Ver pedidos
- `PATCH /admin/adjustments/{id}` - Aprovar/rejeitar
**Desktop:** Nenhum destes existe.

### 10. **Sem Gestão de Consentimento**
**Backend tem:** CRUD de consentimentos biometricos.
**Desktop:** Não pede nem mostra consentimento.
**Impacto:** Problemas legais de privacidade.

---

## 🔧 Melhorias de Arquitetura (PRIORIDADE 3)

### 11. **Controlo de Acesso Baseado em Roles**
**Problema:** Todos os utilizadores veem todas as funcionalidades.
**Backend roles:**
- `COLABORADOR` - Só deveria ver proprio registo
- `GESTOR_RH` - Deveria ver equipa
- `ADMIN_SISTEMA` - Acesso total
- `AUDITOR` - Só leitura

**Solução:** Esconder/mostrar painéis conforme role do utilizador.

### 12. **Modo Offline**
**Problema:** App não arranca se backend estiver em baixo.
**Solução:** 
- Login com cache local
- Queue de registos pendentes
- Sync quando backend voltar

### 13. **Retry Automático**
**Problema:** Falhas de rede causam erros imediatos.
**Solução:** 3 retries com backoff exponencial.

### 14. **Handler Global de Exceções**
**Problema:** Exceções em SwingWorkers não são apanhadas.
**Solução:** `Thread.setDefaultUncaughtExceptionHandler()`

---

## 🧹 Limpeza de Código (PRIORIDADE 4)

### 15. **Dependências Não Usadas**
| Dependência | Uso | Ação |
|-------------|-----|------|
| `jdatepicker` | Nenhuma classe importa | Remover |
| `spring-boot-starter-test` | Sem testes | Adicionar testes OU remover |
| `FlatSVGIcon` | Importado mas não usado | Remover import |

### 16. **Valores Hardcoded**
| Valor | Localização | Deveria Ser |
|-------|-------------|-------------|
| `http://localhost:8000` | application.properties | OK, mas precisa perfis |
| Resolução 640x480 | CameraService | Configurável |
| 10 FPS | CameraPanel | Configurável |
| Page sizes 100/200 | BackendApiClient | Configurável |
| Cores RGB | Todos os UI panels | Constantes centralizadas |

### 17. **CSV Export Reinventado**
**Problema:** Desktop constrói CSV manualmente.
**Backend já tem:** `GET /admin/reports/export.csv`
**Solução:** Usar endpoint do backend ou manter local mas melhorar.

---

## 📋 Componentes UI em Falta

### Essenciais
1. **Dashboard/Home Panel** - Visão geral com métricas
2. **Settings Panel** - Configurar backend URL, device ID, etc
3. **Logout Button** - Status bar ou sidebar
4. **User Profile Display** - Ver/editar perfil atual
5. **Session Timer** - Indicador de tempo restante da sessão

### Importantes
6. **Reports Panel** - Usar `/admin/reports/export.csv`
7. **Audit Log Viewer** - Ver `/audit/logs`
8. **Adjustment Request Panel** - Pedir correções
9. **Self-Service Panel** - `/clock/me` para colaborador ver próprio registo
10. **Notification System** - Toast notifications para ações

### Avançados
11. **Units Management Panel** - CRUD de unidades
12. **Devices Management Panel** - CRUD de dispositivos
13. **Biometric Enrollment Panel** - Registar template facial
14. **Consent Management Panel** - Gestão de consentimentos
15. **Adjustment Review Panel** - Admin aprovar/rejeitar ajustes

---

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

---

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

---

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

---

**Data da Análise:** 14 de Abril de 2026  
**Ficheiros Analisados:** 26 Java files  
**Linhas de Código:** ~4,500  
**Cobertura de Testes:** 0%  
**Pronto para Produção?** ❌ Não (bugs críticos)  
**Pronto para Demo?** ✅ Sim (funcionalidades básicas)
