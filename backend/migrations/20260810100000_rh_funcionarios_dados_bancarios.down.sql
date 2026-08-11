ALTER TABLE rh.funcionarios
    DROP COLUMN IF EXISTS banco,
    DROP COLUMN IF EXISTS numero_conta,
    DROP COLUMN IF EXISTS nib,
    DROP COLUMN IF EXISTS iban;
