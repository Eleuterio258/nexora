SET search_path TO auth, public;

BEGIN;

-- Remove as permissões granulares introduzidas na Fase 3.
-- Nota: não remove a função auxiliar para evitar quebrar dependências.

DELETE FROM auth.permissoes_cargo
 WHERE (modulo, acao) IN (
     ('crm', 'ver_atividades'),
     ('crm', 'eliminar_oportunidades'),
     ('faturacao', 'cancelar_documentos'),
     ('compras', 'receber_mercadoria'),
     ('compras', 'gerir_devolucoes'),
     ('compras', 'faturar_compras'),
     ('compras', 'gerir_pagamentos'),
     ('contabilidade', 'estornar_lancamentos'),
     ('contabilidade', 'reabrir_periodo'),
     ('contabilidade', 'fechar_ano_fiscal'),
     ('tesouraria', 'gerir_contas'),
     ('recursos-humanos', 'desligar_funcionarios')
 );

COMMIT;
