# API — Modulo Assinaturas SaaS / Licencas

## Gateways de Pagamento

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/assinaturas/gateways | Listar gateways configurados |
| POST | /api/assinaturas/gateways | Criar gateway (M-Pesa, E-Mola, Stripe, etc.) |
| GET | /api/assinaturas/gateways/{id} | Obter gateway |
| PUT | /api/assinaturas/gateways/{id} | Actualizar gateway |
| POST | /api/assinaturas/gateways/{id}/activar | Activar gateway |
| POST | /api/assinaturas/gateways/{id}/desactivar | Desactivar gateway |

---

## Planos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/assinaturas/planos | Listar planos activos |
| POST | /api/assinaturas/planos | Criar plano (preco, ciclo, trial, limites) |
| GET | /api/assinaturas/planos/{id} | Obter plano com funcionalidades e limites |
| PUT | /api/assinaturas/planos/{id} | Actualizar plano |
| POST | /api/assinaturas/planos/{id}/activar | Activar plano |
| POST | /api/assinaturas/planos/{id}/desactivar | Desactivar plano |

### Funcionalidades do Plano

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/assinaturas/planos/{id}/features | Listar funcionalidades |
| POST | /api/assinaturas/planos/{id}/features | Adicionar funcionalidade |
| PUT | /api/assinaturas/planos/{id}/features/{feat_id} | Actualizar funcionalidade |
| DELETE | /api/assinaturas/planos/{id}/features/{feat_id} | Remover funcionalidade |

---

## Assinaturas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/assinaturas | Listar assinaturas (filtros: status, customer_id, plan_id) |
| POST | /api/assinaturas | Criar assinatura (inicia trial ou activa imediatamente) |
| GET | /api/assinaturas/{id} | Obter assinatura com estado actual e limites |
| POST | /api/assinaturas/{id}/upgrade | Mudar para plano superior (ajuste pro-rata) |
| POST | /api/assinaturas/{id}/downgrade | Mudar para plano inferior (efectivo no proximo ciclo) |
| POST | /api/assinaturas/{id}/pausar | Pausar assinatura (suspende faturacao) |
| POST | /api/assinaturas/{id}/retomar | Retomar assinatura pausada |
| POST | /api/assinaturas/{id}/suspender | Suspender por inadimplencia (sistema) |
| POST | /api/assinaturas/{id}/reactivar | Reactivar assinatura suspensa apos pagamento |
| POST | /api/assinaturas/{id}/cancelar | Cancelar (imediato ou no fim do periodo) |

---

## Ciclos de Faturacao

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/assinaturas/{id}/ciclos | Listar ciclos de faturacao (filtros: status) |
| POST | /api/assinaturas/{id}/ciclos/faturar | Gerar fatura para o ciclo pendente |
| GET | /api/assinaturas/{id}/ciclos/{ciclo_id} | Obter ciclo especifico |

---

## Pagamentos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/assinaturas/{id}/pagamentos | Listar pagamentos da assinatura |
| POST | /api/assinaturas/{id}/pagamentos | Registar pagamento (manual ou via gateway) |
| GET | /api/assinaturas/{id}/pagamentos/{pag_id} | Obter pagamento |
| POST | /api/assinaturas/{id}/pagamentos/{pag_id}/confirmar | Confirmar pagamento e reactivar se suspensa |
| POST | /api/assinaturas/{id}/pagamentos/{pag_id}/estornar | Estornar pagamento |

---

## Registo de Uso

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/assinaturas/{id}/uso | Uso do periodo actual por metrica |
| POST | /api/assinaturas/{id}/uso | Registar consumo de metrica |

---

## Eventos (Audit Trail)

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/assinaturas/{id}/eventos | Historico de eventos da assinatura |

---

## Relatorios

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/assinaturas/reports/mrr | MRR actual (Monthly Recurring Revenue) |
| GET | /api/assinaturas/reports/arr | ARR actual (Annual Recurring Revenue) |
| GET | /api/assinaturas/reports/churn | Taxa de churn por periodo |
| GET | /api/assinaturas/reports/por-plano | Distribuicao de assinaturas activas por plano |
| GET | /api/assinaturas/reports/inadimplentes | Assinaturas com pagamentos em atraso |
| GET | /api/assinaturas/reports/a-renovar | Assinaturas a renovar nos proximos N dias |
