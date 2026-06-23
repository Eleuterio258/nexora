# Fatura e Fatura Proforma

A fatura e o documento final que liga cliente e produtos vendidos.

## Dados da fatura

- Numero da fatura
- Cliente
- Data
- Estado (pago, pendente)
- Tipo (fatura ou proforma)
- Total
- IVA
- Desconto

## Tabela

```text
faturas
---------
id
numero
cliente_id
tipo (fatura ou proforma)
subtotal
iva
total
status
created_at
```

