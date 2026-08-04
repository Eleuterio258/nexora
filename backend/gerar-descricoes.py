import re

# Mapeamento de termos comuns para descrições em português
TERMOS = {
    # Gerais
    "users": "utilizadores do sistema",
    "user": "utilizador",
    "sessions": "sessões de login ativas",
    "session": "sessão",
    "roles": "perfis/papéis de utilizador",
    "permissions": "permissões de acesso",
    "role_permissions": "associação entre roles e permissões",
    "user_roles": "associação entre utilizadores e roles",
    "cargos": "cargos/funções organizacionais",
    "permissoes": "permissões",
    "memberships": "ligações utilizador-tenant (memberships)",
    "login_history": "histórico de tentativas de login",
    "audit_logs": "logs de auditoria operacional",
    "audit_events": "eventos de auditoria com valor legal",
    "schema_migrations": "controlo de migrações da base de dados",
    "settings": "configurações/parametrizações",
    "configuracoes": "configurações",
    "notifications": "notificações",
    "email_verifications": "verificações de email",
    "password_resets": "recuperações de password",
    "oauth_clients": "clientes OAuth",
    "oauth_refresh_tokens": "tokens de refresh OAuth",
    "oauth_authorization_codes": "códigos de autorização OAuth",
    "oauth_access_token_revocations": "revogações de tokens de acesso",
    "superadmin_security_settings": "configurações de segurança do superadmin",
    "superadmin_ip_allowlist": "lista de IPs permitidos para superadmin",
    "user_auth_codes": "códigos/tokens de autenticação de utilizador",
    # Empresas
    "empresas": "empresas/tenants",
    "empresa": "empresa",
    "tenants": "tenants/clientes do SaaS",
    "tenant": "tenant",
    "filiais": "filiais/sucursais",
    "company": "empresa",
    "companies": "empresas",
    # Pessoas
    "pessoas": "pessoas (entidade master)",
    "pessoa": "pessoa",
    "funcionarios": "funcionários",
    "funcionario": "funcionário",
    "candidatos": "candidatos a vagas",
    "candidato": "candidato",
    "encarregados": "encarregados de educação",
    "alunos": "alunos",
    "aluno": "aluno",
    "professores": "professores",
    "docentes": "docentes",
    # Clientes
    "customers": "clientes",
    "customer": "cliente",
    "customer_addresses": "endereços de clientes",
    "customer_contacts": "contactos de clientes",
    "customer_balances": "saldos de clientes",
    "customer_credit_limits": "limites de crédito de clientes",
    "customer_discounts": "descontos de clientes",
    "customer_documents": "documentos de clientes",
    "customer_groups": "grupos de clientes",
    # Produtos
    "produtos": "produtos/serviços",
    "products": "produtos",
    "product": "produto",
    "categories": "categorias",
    "categorias": "categorias",
    "stock": "movimentos/saldos de stock",
    "inventory": "inventário",
    # Faturação
    "faturas": "faturas",
    "fatura": "fatura",
    "invoices": "faturas",
    "invoice": "fatura",
    "recibos": "recibos",
    "recibo": "recibo",
    "receipts": "recibos",
    "notas_credito": "notas de crédito",
    "credit_notes": "notas de crédito",
    "series": "séries de documentação",
    # Financeiro
    "contas_bancarias": "contas bancárias",
    "bank_accounts": "contas bancárias",
    "movimentos": "movimentos financeiros",
    "transactions": "transações financeiras",
    "payments": "pagamentos",
    "pagamentos": "pagamentos",
    # Contabilidade
    "planos_contas": "plano de contas",
    "chart_of_accounts": "plano de contas",
    "movimentos_contabilisticos": "movimentos contabilísticos",
    "ledger": "livro razão",
    "balancetes": "balancetes",
    "trial_balance": "balancete",
    "diarios": "diários contabilísticos",
    # RH
    "contratos": "contratos de trabalho",
    "salarios": "processamento salarial",
    "faltas": "registo de faltas",
    "presencas": "registo de presenças",
    "ferias": "férias",
    "beneficios": "benefícios",
    "descontos": "descontos",
    "horas_extra": "horas extras",
    "recibos_vencimento": "recibos de vencimento",
    # Escola
    "turmas": "turmas",
    "matriculas": "matrículas",
    "disciplinas": "disciplinas",
    "notas": "notas/avaliações",
    "pautas": "pautas",
    "ano_letivo": "ano letivo",
    "trimestres": "trimestres",
    "cursos": "cursos",
    # Compras
    "fornecedores": "fornecedores",
    "suppliers": "fornecedores",
    "purchase_orders": "ordens de compra",
    "ordens_compra": "ordens de compra",
    "requisicoes": "requisições de compra",
    # Saúde
    "recrutamento": "processo de recrutamento",
    "vagas": "vagas de emprego",
    "entrevistas": "entrevistas",
    "avaliacoes": "avaliações",
    # Assinatura digital
    "documentos": "documentos",
    "signatarios": "signatários",
    "convites": "convites para assinatura",
    "versoes_assinadas": "versões assinadas dos documentos",
    "validacoes": "validações de assinaturas",
    "webhook_events": "eventos recebidos por webhook",
    # SaaS
    "subscriptions": "subscrições",
    "subscription_plans": "planos de subscrição",
    "subscription_invoices": "faturas de subscrição",
    "subscription_usage": "consumo/uso de subscrição",
    "plans": "planos",
    # Outros
    "tarefas": "tarefas",
    "tasks": "tarefas",
    "notifications": "notificações",
    "impostos": "impostos/taxas",
    "taxes": "impostos",
    "moedas": "moedas",
    "currencies": "moedas",
    "exchange_rates": "taxas de câmbio",
    "centros_custo": "centros de custo",
    "cost_centers": "centros de custo",
    "tesouraria": "movimentos de tesouraria/caixa",
    "cash": "caixa/tesouraria",
    "hardware": "equipamentos/hardware",
    "devices": "dispositivos",
    "crm": "CRM (leads/oportunidades)",
    "leads": "leads",
    "oportunidades": "oportunidades",
    "lgpd": "dados de privacidade/LGPD",
    "consentimentos": "consentimentos",
    "logistica": "logística/transporte",
    "public": "dados públicos/compartilhados",
    "sistema_configuracao": "configurações do sistema",
    "parametros": "parâmetros do sistema",
}


def descrever_tabela(schema, tabela):
    nome = tabela.replace(schema + ".", "")
    partes = re.split(r'[_\-]', nome)
    descricoes = []
    usado = set()
    
    for termo, desc in TERMOS.items():
        if termo in nome and termo not in usado:
            descricoes.append(desc)
            usado.add(termo)
    
    # Fallback: descrever por partes
    if not descricoes:
        descricoes = [p for p in partes if p not in ('de', 'da', 'do', 'dos', 'das')]
    
    if descricoes:
        return f"Registo/gestão de {', '.join(descricoes[:3])}."
    return f"Tabela auxiliar do schema `{schema}`."


def main():
    with open("schema-tabelas-lista.txt", "r", encoding="utf-8") as f:
        linhas = f.readlines()
    
    schema_atual = ""
    saida = ["# Descrição dos Schemas e Tabelas - nexora_erp\n"]
    
    for linha in linhas:
        linha = linha.strip()
        if not linha:
            continue
        if linha.startswith("## "):
            schema_atual = linha[3:].strip()
            saida.append(f"\n## Schema: `{schema_atual}`\n")
            # descrição do schema
            desc_schema = descrever_tabela("", schema_atual)
            saida.append(f"**Função:** {desc_schema}\n")
            saida.append("\n### Tabelas\n")
        elif linha.startswith("- "):
            tabela = linha[2:].strip()
            desc = descrever_tabela(schema_atual, tabela)
            saida.append(f"- **`{tabela}`** — {desc}")
    
    with open("descricao-schemas-tabelas.md", "w", encoding="utf-8") as f:
        f.write("\n".join(saida))
    
    print("Arquivo descricao-schemas-tabelas.md gerado com sucesso.")


if __name__ == "__main__":
    main()
