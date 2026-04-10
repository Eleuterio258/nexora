# API — Modulo Gestao de Clientes

## Grupos de Clientes

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/clientes/grupos | Listar grupos |
| POST | /api/clientes/grupos | Criar grupo |
| GET | /api/clientes/grupos/{id} | Obter grupo |
| PUT | /api/clientes/grupos/{id} | Actualizar grupo |

---

## Clientes

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/clientes | Listar clientes (filtros: grupo_id, status, search) |
| POST | /api/clientes | Criar cliente |
| GET | /api/clientes/{id} | Obter cliente |
| PUT | /api/clientes/{id} | Actualizar cliente |
| POST | /api/clientes/{id}/activar | Activar cliente |
| POST | /api/clientes/{id}/bloquear | Bloquear cliente (com motivo) |
| POST | /api/clientes/{id}/desbloquear | Desbloquear cliente |

---

## Contactos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/clientes/{id}/contactos | Listar contactos do cliente |
| POST | /api/clientes/{id}/contactos | Adicionar contacto |
| PUT | /api/clientes/{id}/contactos/{contacto_id} | Actualizar contacto |
| DELETE | /api/clientes/{id}/contactos/{contacto_id} | Remover contacto |

---

## Enderecos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/clientes/{id}/enderecos | Listar enderecos |
| POST | /api/clientes/{id}/enderecos | Adicionar endereco |
| PUT | /api/clientes/{id}/enderecos/{end_id} | Actualizar endereco |
| DELETE | /api/clientes/{id}/enderecos/{end_id} | Remover endereco |

---

## Documentos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/clientes/{id}/documentos | Listar documentos do cliente |
| POST | /api/clientes/{id}/documentos | Anexar documento |
| DELETE | /api/clientes/{id}/documentos/{doc_id} | Remover documento |

---

## Limite de Credito

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/clientes/{id}/limite-credito | Obter limite de credito actual |
| POST | /api/clientes/{id}/limite-credito | Definir ou actualizar limite de credito |

---

## Saldo e Pagamentos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/clientes/{id}/saldo | Obter saldo devedor actual |
| GET | /api/clientes/{id}/pagamentos | Listar pagamentos recebidos (filtros: data) |
| POST | /api/clientes/{id}/pagamentos | Registar pagamento manual |

---

## Notas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/clientes/{id}/notas | Listar notas do cliente |
| POST | /api/clientes/{id}/notas | Adicionar nota |

---

## Historico

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/clientes/{id}/historico | Historico de acoes sobre o cliente |

---

## Tags

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/clientes/tags | Listar todas as tags |
| POST | /api/clientes/tags | Criar tag |
| POST | /api/clientes/{id}/tags | Associar tag ao cliente |
| DELETE | /api/clientes/{id}/tags/{tag_id} | Remover tag do cliente |

---

## Descontos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/clientes/{id}/descontos | Listar descontos do cliente |
| POST | /api/clientes/{id}/descontos | Criar desconto para o cliente |
| PUT | /api/clientes/{id}/descontos/{desc_id} | Actualizar desconto |
| DELETE | /api/clientes/{id}/descontos/{desc_id} | Remover desconto |

---

## Relatorios

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/clientes/reports/top-clientes | Clientes com maior volume de compras |
| GET | /api/clientes/reports/saldos-devedores | Resumo de saldos em divida por cliente |
| GET | /api/clientes/reports/credito-utilizado | Clientes com limite de credito utilizado |
| GET | /api/clientes/reports/sem-actividade | Clientes sem compras nos ultimos N dias |
