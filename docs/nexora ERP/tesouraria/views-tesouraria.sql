-- Views do modulo de Tesouraria

CREATE OR REPLACE VIEW vw_tesouraria_saldos AS
SELECT 'conta_bancaria' AS origem, id, banco AS nome, saldo_atual FROM contas_bancarias
UNION ALL
SELECT 'caixa' AS origem, id, nome, saldo_atual FROM caixas;
