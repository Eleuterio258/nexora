-- Permissão 'assiduidade:marcar_ponto'
--
-- ATENÇÃO: nesta data nenhuma rota verifica esta acção — o endpoint de
-- marcação de ponto por JWT para que foi criada (POST
-- /api/self-service/assiduidade/ponto, fase 1 de
-- docs/arquitetura-comunicacao-assiduidade.md §10) não chegou a entrar. A
-- permissão fica aplicada em produção e é registada aqui para o repo
-- descrever o schema real; passa a ter efeito quando esse endpoint for
-- reintroduzido.
--
-- Vai para auth.permissoes_tipo (e não para permissoes_cargo) porque marcar o
-- próprio ponto é uma capacidade de base de qualquer colaborador, tal como
-- ver_assiduidade / justificar / corrigir_ponto que já lá estão. O
-- LoadUserAccess funde permissoes_tipo por cima do cargo (rbac.go:180),
-- portanto isto abrange todos os tenants — presentes e futuros — sem backfill
-- por cargo. A identidade de quem marca vem sempre do JWT, nunca do corpo do
-- pedido, por isso a permissão não permite marcar ponto por outrem.

INSERT INTO auth.permissoes_tipo (tipo, modulo, acao) VALUES
    ('funcionario', 'assiduidade', 'marcar_ponto')
ON CONFLICT (tipo, modulo, acao) DO NOTHING;
