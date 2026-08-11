-- Dados bancários do funcionário, necessários para gerar o ficheiro de
-- exportação bancária (transferência salarial em lote) a partir da folha de
-- pagamento processada.
ALTER TABLE rh.funcionarios
    ADD COLUMN IF NOT EXISTS banco text,
    ADD COLUMN IF NOT EXISTS numero_conta text,
    ADD COLUMN IF NOT EXISTS nib text,
    ADD COLUMN IF NOT EXISTS iban text;
