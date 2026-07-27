# Roles / Cargos Recomendados — Nexora ERP

> Esta tabela sugere permissões por cargo. Ajusta conforme as necessidades reais de cada organização.

---

## Legenda

- ✅ — deve ter
- ➕ — recomendado (opcional)
- ❌ — não precisa

---

## 1. Super Admin

> Bypassa todas as permissões. Não precisa de roles.

---

## 2. CEO / Administrador Geral

| Módulo | Permissões |
|--------|-----------|
| Todos | Todas as permissões de todos os módulos |

---

## 3. Gestor de Recursos Humanos

| Módulo | Permissões |
|--------|-----------|
| `recursos-humanos` | `ver_funcionarios`, `gerir_funcionarios`, `ver_recibos`, `ver_salarios`, `ver_beneficios`, `gerir_beneficios`, `gerir_formacoes`, `gerir_contratos`, `gerir_avaliacoes`, `gerir_horarios`, `aprovar_ausencias`, `ver_processos_disciplinares` |
| `assiduidade` | `ver_configuracao`, `gerir_configuracao`, `aprovar_correcao` |
| `pedido-ferias` | `ver_pedidos`, `submeter_pedido` |
| `perfil` | `ver_perfil`, `editar_perfil` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## 4. Técnico de Payroll

| Módulo | Permissões |
|--------|-----------|
| `recursos-humanos` | `ver_funcionarios`, `ver_salarios`, `processar_salarios`, `ver_recibos`, `ver_beneficios` |
| `assiduidade` | `ver_assiduidade`, `ver_configuracao` |
| `perfil` | `ver_perfil`, `editar_perfil` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## 5. Gestor de Stock

| Módulo | Permissões |
|--------|-----------|
| `stock` | `ver_stock`, `gerir_categorias`, `gerir_produtos`, `gerir_movimentos`, `eliminar_produtos` |
| `compras` | `ver_compras`, `criar_pedidos`, `aprovar_pedidos` |
| `logistica` | `ver_logistica`, `gerir_entregas` |
| `centros-custo` | `ver_centros` |
| `perfil` | `ver_perfil`, `editar_perfil` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## 6. Gestor de Vendas / Comercial

| Módulo | Permissões |
|--------|-----------|
| `clientes` | `ver_clientes`, `gerir_clientes`, `gerir_grupos`, `gerir_credito` |
| `crm` | `ver_leads`, `gerir_leads`, `mover_leads`, `converter_leads`, `gerir_oportunidades`, `ver_oportunidades`, `gerir_atividades` |
| `faturacao` | `ver_documentos`, `emitir_orcamentos`, `emitir_encomendas`, `emitir_faturas`, `emitir_notas_credito`, `configurar_series` |
| `pos` | `operar_pos` |
| `perfil` | `ver_perfil`, `editar_perfil` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## 7. Operador de POS / Caixa

| Módulo | Permissões |
|--------|-----------|
| `pos` | `operar_pos` |
| `perfil` | `ver_perfil`, `editar_perfil` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## 8. Gestor Financeiro

| Módulo | Permissões |
|--------|-----------|
| `financeiro` | `ver_financeiro`, `gerir_categorias`, `gerir_contas_receber`, `gerir_contas_pagar` |
| `tesouraria` | `ver_tesouraria`, `gerir_movimentos`, `gerir_reconciliacao` |
| `multi-moeda` | `ver_moedas`, `gerir_moedas` |
| `faturacao` | `ver_documentos` |
| `perfil` | `ver_perfil`, `editar_perfil` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## 9. Contabilista

| Módulo | Permissões |
|--------|-----------|
| `contabilidade` | `ver_contabilidade`, `gerir_plano_contas`, `gerir_lancamentos`, `gerir_periodos`, `gerir_ativos_fixos`, `gerir_orcamentos`, `fechar_periodo`, `ver_relatorios` |
| `impostos` | `ver_impostos`, `gerir_impostos` |
| `centros-custo` | `ver_centros`, `gerir_centros` |
| `financeiro` | `ver_financeiro` |
| `faturacao` | `ver_documentos` |
| `perfil` | `ver_perfil`, `editar_perfil` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## 10. Gestor Escolar

| Módulo | Permissões |
|--------|-----------|
| `gestao-escolar` | `ver`, `gerir_turmas`, `gerir_alunos`, `gerir_matriculas`, `gerir_horarios`, `gerir_presencas`, `lancar_notas`, `gerir_propinas`, `gerir_comunicacao`, `gerir_calendario`, `gerir_ocorrencias`, `gerir_biblioteca` |
| `perfil` | `ver_perfil`, `editar_perfil` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## 11. Professor / Educador

| Módulo | Permissões |
|--------|-----------|
| `gestao-escolar` | `ver`, `gerir_presencas`, `lancar_notas`, `gerir_ocorrencias`, `gerir_comunicacao` |
| `perfil` | `ver_perfil`, `editar_perfil` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## 12. Funcionário / Colaborador (Self-Service)

| Módulo | Permissões |
|--------|-----------|
| `perfil` | `ver_perfil`, `editar_perfil` |
| `assiduidade` | `ver_assiduidade`, `justificar`, `corrigir_ponto` |
| `pedido-ferias` | `ver_pedidos`, `submeter_pedido` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## 13. Técnico de Hardware / Assiduidade

| Módulo | Permissões |
|--------|-----------|
| `hardware` | `ver_dispositivos`, `gerir_dispositivos`, `ver_eventos` |
| `assiduidade` | `ver_configuracao`, `gerir_configuracao`, `ver_assiduidade` |
| `recursos-humanos` | `ver_funcionarios` |
| `perfil` | `ver_perfil`, `editar_perfil` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## 14. Gestor de Tarefas / Projetos

| Módulo | Permissões |
|--------|-----------|
| `tarefas` | `ver_quadros`, `gerir_quadros`, `gerir_listas`, `gerir_cartoes`, `mover_cartoes`, `eliminar_cartoes` |
| `perfil` | `ver_perfil`, `editar_perfil` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## 15. Gestor de Recrutamento

| Módulo | Permissões |
|--------|-----------|
| `recrutamento` | `ver_vagas`, `gerir_vagas`, `ver_candidaturas`, `gerir_candidaturas`, `configurar_recrutamento` |
| `recursos-humanos` | `ver_funcionarios` |
| `perfil` | `ver_perfil`, `editar_perfil` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## 16. Administrador de Segurança

| Módulo | Permissões |
|--------|-----------|
| `seguranca` | `ver_seguranca`, `gerir_politicas`, `gerir_allowlist` |
| `auditoria` | `ver_logs`, `gerir_logs` |
| `autorizacao` | `gerir_utilizadores`, `gerir_perfis` |
| `auth` | `pin_admin` |
| `sistema-configuracao` | `ver_configuracoes`, `editar_configuracoes`, `gerir_templates` |
| `perfil` | `ver_perfil`, `editar_perfil` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## 17. Gestor de Empresa / Filiais

| Módulo | Permissões |
|--------|-----------|
| `empresa` | `ver_empresa`, `editar_empresa`, `gerir_filiais`, `gerir_licencas` |
| `sistema-configuracao` | `ver_configuracoes`, `editar_configuracoes` |
| `perfil` | `ver_perfil`, `editar_perfil` |
| `chat` | `ver_conversas`, `enviar_mensagem` |
| `notificacoes` | `ver_notificacoes` |

---

## Como criar um role no banco de dados

### 1. Criar o role

```sql
INSERT INTO autorizacao.roles (tenant_id, codigo, nome, descricao, ativo)
VALUES (7, 'gestor_rh', 'Gestor de RH', 'Gestão completa de RH e assiduidade', true)
RETURNING id;
```

### 2. Associar permissões ao role

```sql
INSERT INTO autorizacao.role_permissions (role_id, permission_id)
SELECT 1, p.id
FROM autorizacao.permissions p
WHERE p.recurso = 'recursos-humanos' AND p.acao IN (
    'ver_funcionarios', 'gerir_funcionarios', 'ver_recibos', 'ver_salarios',
    'ver_beneficios', 'gerir_beneficios', 'gerir_formacoes', 'gerir_contratos',
    'gerir_avaliacoes', 'gerir_horarios', 'aprovar_ausencias', 'ver_processos_disciplinares'
);
```

### 3. Atribuir role ao utilizador

```sql
INSERT INTO autorizacao.user_roles (user_id, role_id)
VALUES (129, 1);
```

---

## Referências

- [Permissões por Módulo](./permissoes-por-modulo.md)
- [Permissões do Módulo Recursos Humanos](./permissoes-modulo-recursos-humanos.md)
- [Permissões de Assiduidade: ERP vs FaceClock](./permissoes-assiduidade-erp-faceclock.md)
