import re

TERMOS = {
    # Entidades principais
    "users": "utilizadores registados no sistema",
    "user": "utilizador",
    "sessions": "sessões de autenticação ativas",
    "session": "sessão de autenticação",
    "roles": "perfis/papéis de acesso",
    "role": "perfil/papel",
    "permissions": "permissões de acesso a funcionalidades",
    "permission": "permissão",
    "cargos": "cargos/funções organizacionais",
    "cargo": "cargo/função",
    "memberships": "ligações entre utilizadores e tenants (acesso multi-empresa)",
    "login_history": "histórico de tentativas de autenticação",
    "audit_logs": "logs operacionais de auditoria",
    "audit_events": "eventos de auditoria com valor legal/compliance (imutáveis, com hash)",
    "schema_migrations": "controlo de versões/migrações da base de dados",
    "email_verifications": "tokens/códigos de verificação de email",
    "password_resets": "tokens/códigos de recuperação de password",
    "oauth_clients": "aplicações cliente registadas no OAuth2",
    "oauth_authorization_codes": "códigos de autorização OAuth2",
    "oauth_refresh_tokens": "tokens de refresh OAuth2",
    "oauth_access_token_revocations": "registo de revogação de tokens OAuth2",
    "superadmin_security_settings": "configurações de segurança globais do superadmin",
    "superadmin_ip_allowlist": "lista de IPs autorizados para acesso de superadmin",
    "user_auth_codes": "códigos/tokens de autenticação secundária (2FA/MFA/TOTP)",
    "permissoes_cargo": "permissões associadas a cada cargo",
    "permissoes_diretas": "permissões atribuídas diretamente a utilizadores",
    "permissoes_tipo": "tipos/categorias de permissões disponíveis",
    
    # Empresas / SaaS
    "companies": "empresas/tenants registados",
    "company": "empresa/tenant",
    "tenants": "tenants/clientes do SaaS",
    "tenant": "tenant",
    "company_branches": "filiais/sucursais das empresas",
    "company_addresses": "endereços das empresas",
    "company_banks": "contas bancárias das empresas",
    "company_contacts": "contactos das empresas",
    "company_documents": "documentos associados às empresas",
    "company_licenses": "licenças ativas das empresas",
    "company_settings": "configurações específicas de cada empresa",
    "company_tax_info": "informação fiscal das empresas",
    "company_users": "associação empresa ↔ utilizador",
    "subscriptions": "subscrições ativas de cada tenant",
    "subscription_plans": "planos de subscrição disponíveis",
    "subscription_invoices": "faturas emitidas pelas subscrições",
    "subscription_usage": "consumo de recursos das subscrições",
    
    # Pessoas
    "pessoas": "registo master de pessoas (funcionários, clientes, fornecedores)",
    "pessoa": "pessoa",
    "funcionarios": "funcionários/colaboradores",
    "funcionario": "funcionário",
    "candidatos": "candidatos a vagas de emprego",
    "encarregados": "encarregados de educação",
    "guardians": "encarregados de educação (guardiões)",
    "alunos": "alunos",
    "aluno": "aluno",
    "professores": "professores",
    "teachers": "professores",
    "students": "alunos",
    "docentes": "docentes",
    
    # Clientes
    "customers": "clientes",
    "customer": "cliente",
    "customer_addresses": "endereços dos clientes",
    "customer_contacts": "contactos dos clientes",
    "customer_balances": "saldos contabilísticos dos clientes",
    "customer_credit_limits": "limites de crédito dos clientes",
    "customer_discounts": "descontos configurados para clientes",
    "customer_documents": "documentos anexados aos clientes",
    "customer_groups": "grupos/categorias de clientes",
    "customer_history": "histórico de interações com clientes",
    "customer_notes": "notas/observações sobre clientes",
    "customer_payments": "pagamentos recebidos de clientes",
    "customer_tag_links": "associação cliente ↔ tag",
    "customer_tags": "tags/etiquetas de clientes",
    
    # Produtos / Stock
    "produtos": "produtos e serviços comercializados",
    "products": "produtos e serviços",
    "product": "produto/serviço",
    "categories": "categorias de produtos/serviços",
    "categorias": "categorias",
    "product_prices": "preços dos produtos ao longo do tempo",
    "product_units": "unidades de medida dos produtos",
    "warehouses": "armazéns/locais de armazenamento",
    "inventory_movements": "movimentos de entrada/saída de stock",
    "stock_levels": "saldos atuais de stock por armazém",
    "inventory_counts": "contagens de inventário físico",
    
    # Faturação / Vendas
    "invoices": "faturas de venda emitidas",
    "invoice": "fatura de venda",
    "invoice_items": "linhas de artigos/serviços das faturas",
    "invoice_taxes": "impostos aplicados nas faturas",
    "invoice_discounts": "descontos aplicados nas faturas",
    "invoice_receipts": "associação entre faturas e recibos de pagamento",
    "invoice_series": "séries de numeração de faturas",
    "credit_notes": "notas de crédito emitidas",
    "credit_note_items": "linhas das notas de crédito",
    "receipts": "recibos de pagamento",
    "recibos": "recibos de pagamento",
    "sales_orders": "encomendas de venda",
    "sales_order_items": "linhas de encomendas de venda",
    "sales_quotes": "cotações/orçamentos de venda",
    "sales_quote_items": "linhas de cotações/orçamentos",
    "sales_deliveries": "guias de remessa/entregas de venda",
    "sales_delivery_items": "linhas das guias de remessa",
    "sales_returns": "devoluções de venda",
    "sales_return_items": "linhas das devoluções de venda",
    
    # Compras
    "suppliers": "fornecedores",
    "supplier": "fornecedor",
    "supplier_addresses": "endereços dos fornecedores",
    "supplier_contacts": "contactos dos fornecedores",
    "supplier_groups": "grupos de fornecedores",
    "purchase_requests": "requisições internas de compra",
    "purchase_request_items": "linhas de requisições de compra",
    "purchase_orders": "ordens de compra a fornecedores",
    "purchase_order_items": "linhas de ordens de compra",
    "goods_receipts": "receções de mercadoria",
    "goods_receipt_items": "linhas das receções de mercadoria",
    "purchase_invoices": "faturas de compra recebidas",
    "purchase_invoice_items": "linhas das faturas de compra",
    "purchase_payments": "pagamentos efetuados a fornecedores",
    "purchase_payment_items": "linhas de pagamentos a fornecedores",
    "purchase_returns": "devoluções a fornecedores",
    "purchase_return_items": "linhas das devoluções a fornecedores",
    
    # Financeiro
    "accounts_payable": "contas a pagar (dívidas a fornecedores)",
    "accounts_receivable": "contas a receber (créditos de clientes)",
    "payments": "pagamentos registados no sistema",
    "payment_methods": "meios/formas de pagamento",
    "cash_flow_entries": "movimentos de fluxo de caixa",
    "financial_budgets": "orçamentos financeiros",
    "financial_categories": "categorias financeiras",
    "bank_accounts": "contas bancárias",
    "cash_accounts": "contas de caixa/tesouraria",
    "cash_movements": "movimentos de caixa/tesouraria",
    
    # Contabilidade
    "chart_of_accounts": "plano de contas contabilístico",
    "account_types": "tipos de contas contabilísticas",
    "journal_entries": "lançamentos contabilísticos",
    "journal_entry_lines": "linhas analíticas dos lançamentos contabilísticos",
    "journal_entry_sequences": "numeração/sequências de lançamentos",
    "accounting_journals": "diários contabilísticos",
    "fiscal_years": "anos fiscais",
    "fiscal_periods": "períodos fiscais/mensais",
    "period_closings": "fechos de período contabilístico",
    "period_closing_checks": "validações de fecho de período",
    "fixed_assets": "ativos fixos/imobilizado",
    "depreciation_entries": "lançamentos de depreciação",
    "accounting_budgets": "orçamentos contabilísticos",
    "accounting_reports": "relatórios contabilísticos gerados",
    
    # RH
    "contratos": "contratos de trabalho",
    "salarios": "processamento de salários/vencimentos",
    "faltas": "registo de faltas",
    "presencas": "registo de presenças/ponto",
    "ferias": "registo de férias",
    "beneficios": "benefícios atribuídos aos funcionários",
    "descontos": "descontos salariais",
    "horas_extra": "horas extraordinárias",
    "recibos_vencimento": "recibos de vencimento",
    "avaliacoes_desempenho": "avaliações de desempenho",
    "funcionario_beneficios": "benefícios por funcionário",
    "funcionario_descontos": "descontos por funcionário",
    "funcionario_documentos": "documentos dos funcionários",
    "departamentos": "departamentos da organização",
    "cargos_rh": "cargos no contexto de RH",
    
    # Escola
    "school_students": "alunos matriculados",
    "school_teachers": "professores/docentes",
    "school_guardians": "encarregados/guardiões",
    "school_classes": "turmas",
    "school_courses": "cursos",
    "school_subjects": "disciplinas",
    "school_course_subjects": "disciplinas associadas a cursos",
    "school_enrollments": "matrículas de alunos",
    "school_grades": "notas/avaliações",
    "school_grade_items": "itens/componentes de avaliação",
    "school_grade_formulas": "fórmulas de cálculo de notas",
    "school_attendance": "presenças/faltas dos alunos",
    "school_fees": "propinas/taxas escolares",
    "school_fee_plans": "planos de pagamento de propinas",
    "school_fee_generations": "gerações de propinas",
    "school_payments": "pagamentos escolares",
    "school_timetable_entries": "entradas de horário",
    "school_time_slots": "slots/periodos de horário",
    "school_calendar_events": "eventos do calendário escolar",
    "school_calendar_event_types": "tipos de eventos do calendário",
    "school_terms": "trimestres/períodos letivos",
    "school_levels": "níveis de ensino",
    "school_cycles": "ciclos de ensino",
    "school_series": "séries/turmas agrupadas",
    "school_library_loans": "empréstimos da biblioteca",
    "school_incident_types": "tipos de incidentes disciplinares",
    "school_student_incidents": "incidentes dos alunos",
    "school_sanction_types": "tipos de sanções",
    "school_student_sanctions": "sanções aplicadas aos alunos",
    "school_student_merits": "méritos/reconhecimentos dos alunos",
    "school_student_roles": "papéis/perfil dos alunos",
    "school_teacher_roles": "papéis dos professores",
    "school_teacher_assignments": "atribuições de professores a turmas/disciplinas",
    "school_academic_transcripts": "históricos académicos",
    "school_academic_config": "configuração académica",
    "school_financial_config": "configuração financeira escolar",
    "school_messages": "mensagens internas do portal escolar",
    "portal_sessions": "sessões do portal escolar",
    "guardian_portal_sessions": "sessões do portal dos encarregados",
    "school_books": "livros escolares/biblioteca",
    
    # Assinatura digital
    "documentos": "documentos a serem assinados digitalmente",
    "signatarios": "signatários dos documentos",
    "convites": "convites enviados para assinatura",
    "versoes_assinadas": "versões finais assinadas dos documentos",
    "validacoes": "validações de assinaturas digitais",
    "webhook_events": "eventos recebidos por webhook de providers de assinatura",
    "logs": "logs de atividades",
    
    # Outros
    "tarefas": "tarefas/afazeres",
    "tasks": "tarefas",
    "impostos": "impostos e taxas fiscais",
    "taxes": "impostos",
    "tax_rates": "taxas de imposto",
    "moedas": "moedas suportadas",
    "currencies": "moedas",
    "exchange_rates": "taxas de câmbio",
    "cost_centers": "centros de custo",
    "cost_center_allocations": "alocações de custos a centros de custo",
    "cost_center_budgets": "orçamentos por centro de custo",
    "crm_leads": "leads/oportunidades potenciais",
    "leads": "leads",
    "oportunidades": "oportunidades de negócio",
    "atividades": "atividades/interações comerciais",
    "hardware_devices": "dispositivos/equipamentos hardware",
    "devices": "dispositivos",
    "notifications": "notificações enviadas aos utilizadores",
    "notification_preferences": "preferências de notificação",
    "lgpd_consentimentos": "consentimentos de dados pessoais",
    "consentimentos": "consentimentos",
    "logistica_transportes": "transportes/logística",
    "parametros": "parâmetros/configurações do sistema",
    "settings": "configurações",
    "modules": "módulos do sistema",
    "module_permissions": "permissões por módulo",
}

SUFIXOS = {
    "_items": "linhas/detaihes de ",
    "_lines": "linhas analíticas de ",
    "_history": "histórico de ",
    "_addresses": "endereços de ",
    "_contacts": "contactos de ",
    "_payments": "pagamentos de ",
    "_discounts": "descontos de ",
    "_taxes": "impostos de ",
    "_documents": "documentos de ",
    "_tags": "tags/etiquetas de ",
    "_tag_links": "associações de tags com ",
    "_notes": "notas/observações de ",
    "_balances": "saldos de ",
    "_settings": "configurações de ",
    "_config": "configuração de ",
    "_sequences": "sequências/numeração de ",
    "_types": "tipos/categorias de ",
    "_events": "eventos de ",
    "_logs": "logs de ",
    "_codes": "códigos/tokens de ",
    "_tokens": "tokens de ",
    "_verifications": "verificações de ",
    "_resets": "recuperações/reinicializações de ",
    "_revocations": "revogações de ",
    "_allowlist": "lista de autorização de ",
    "_usage": "consumo/uso de ",
    "_invoices": "faturas de ",
    "_plans": "planos de ",
    "_fees": "taxas/propinas de ",
    "_grades": "notas/avaliações de ",
    "_attendance": "presenças/faltas de ",
    "_enrollments": "matrículas de ",
    "_assignments": "atribuições de ",
    "_transcripts": "históricos de ",
    "_loans": "empréstimos de ",
    "_incidents": "incidentes de ",
    "_sanctions": "sanções de ",
    "_merits": "méritos de ",
    "_roles": "papéis/perfil de ",
    "_permissions": "permissões de ",
    "_movements": "movimentos de ",
    "_levels": "níveis de ",
    "_cycles": "ciclos de ",
    "_series": "séries de ",
    "_terms": "períodos/trimestres de ",
    "_slots": "slots/períodos de ",
    "_entries": "entradas/registos de ",
    "_groups": "grupos de ",
    "_links": "ligações/associações de ",
    "_receipts": "recibos/comprovativos de ",
    "_returns": "devoluções de ",
    "_deliveries": "entregas/remessas de ",
    "_quotes": "cotações/orçamentos de ",
    "_orders": "encomendas/pedidos de ",
    "_requests": "requisições/pedidos de ",
    "_budgets": "orçamentos de ",
    "_categories": "categorias de ",
    "_methods": "métodos/meios de ",
    "_accounts": "contas de ",
    "_info": "informação de ",
    "_users": "utilizadores de ",
    "_banks": "contas bancárias de ",
    "_licenses": "licenças de ",
}

PREFIXOS = {
    "school_": "escolar: ",
    "customer_": "de clientes: ",
    "supplier_": "de fornecedores: ",
    "company_": "da empresa: ",
    "product_": "de produtos: ",
    "invoice_": "de faturas: ",
    "purchase_": "de compras: ",
    "sales_": "de vendas: ",
    "journal_": "contabilístico: ",
    "accounting_": "contabilístico: ",
    "financial_": "financeiro: ",
    "cost_center_": "de centros de custo: ",
    "subscription_": "de subscrição: ",
    "oauth_": "OAuth: ",
    "superadmin_": "de superadmin: ",
    "user_": "de utilizador: ",
    "cash_": "de caixa: ",
    "tax_": "fiscal: ",
    "credit_": "de crédito: ",
    "goods_": "de receção de mercadoria: ",
    "fixed_": "de imobilizado: ",
    "fiscal_": "fiscal: ",
    "period_": "de período: ",
    "module_": "de módulo: ",
    "notification_": "de notificação: ",
    "exchange_": "de câmbio: ",
}


def descrever_tabela(schema, tabela):
    nome = tabela.replace(schema + ".", "")
    
    # Tenta termo exato
    if nome in TERMOS:
        return TERMOS[nome]
    
    # Tenta por prefixo
    for prefixo, desc_prefixo in PREFIXOS.items():
        if nome.startswith(prefixo):
            resto = nome[len(prefixo):]
            if resto in TERMOS:
                return desc_prefixo + TERMOS[resto]
    
    # Tenta por sufixo
    for sufixo, desc_sufixo in SUFIXOS.items():
        if nome.endswith(sufixo):
            base = nome[:-len(sufixo)]
            base_desc = None
            if base in TERMOS:
                base_desc = TERMOS[base]
            else:
                # tenta pluralizar/despluralizar simples
                if base.endswith('s') and base[:-1] in TERMOS:
                    base_desc = TERMOS[base[:-1]]
                elif base + 's' in TERMOS:
                    base_desc = TERMOS[base + 's']
            if base_desc:
                return desc_sufixo + base_desc
    
    # Busca termos dentro do nome
    descricoes = []
    for termo, desc in sorted(TERMOS.items(), key=lambda x: -len(x[0])):
        if termo in nome and termo not in descricoes:
            descricoes.append(desc)
            if len(descricoes) >= 2:
                break
    
    if descricoes:
        return "Registo/gestão de " + " e ".join(descricoes[:2]) + "."
    
    # Fallback
    partes = [p for p in nome.split("_") if p]
    if partes:
        return "Tabela auxiliar relacionada com " + "/".join(partes[:3]) + "."
    return f"Tabela do schema `{schema}`."


def descrever_schema(schema):
    # Termos específicos por schema
    mapa = {
        "assinatura_digital": "assinatura digital de documentos (documentos, signatários, convites, versões assinadas, validações, webhooks)",
        "assinaturas": "planos e subscrições SaaS dos tenants",
        "auditoria": "registo de eventos e logs de auditoria (operacional e legal/compliance)",
        "auth": "autenticação, autorização, sessões, utilizadores, OAuth e permissões",
        "autorizacao": "modelo de roles e permissões (RBAC) alternativo",
        "centros_custo": "centros de custo, orçamentos e alocações de custos",
        "clientes": "gestão de clientes, endereços, contactos, saldos e histórico",
        "compras": "ciclo de compras: fornecedores, requisições, ordens, receções, faturas e pagamentos",
        "contabilidade": "plano de contas, lançamentos, diários, períodos fiscais, ativos fixos e depreciações",
        "crm": "gestão de relacionamento com clientes: leads, oportunidades e atividades",
        "empresas": "dados das empresas/tenants, filiais, configurações, licenças e contactos",
        "faturacao": "faturação e documentos de venda: faturas, notas de crédito, recibos, encomendas e guias",
        "financeiro": "contas a pagar/receber, pagamentos, fluxo de caixa e orçamentos financeiros",
        "gestao_escolar": "gestão escolar completa: alunos, professores, turmas, notas, propinas, horários",
        "hardware": "equipamentos, dispositivos e terminais físicos",
        "impostos": "configuração de impostos, taxas e retenções fiscais",
        "lgpd": "dados de privacidade e consentimentos (LGPD)",
        "logistica": "operações logísticas, transportes e entregas",
        "multi_moeda": "moedas, taxas de câmbio e conversões",
        "notifications": "notificações do sistema e preferências",
        "pessoas": "entidade master de pessoas (funcionários, clientes, fornecedores)",
        "pos": "ponto de venda: vendas, terminais, sessões de caixa e pagamentos",
        "produtos": "catálogo de produtos/serviços, categorias, preços e unidades",
        "public": "tabelas públicas/compartilhadas do sistema",
        "recrutamento": "processo de recrutamento: vagas, candidaturas, entrevistas e avaliações",
        "rh": "recursos humanos: funcionários, contratos, salários, faltas, presenças e benefícios",
        "saas": "dados da plataforma SaaS: tenants, quotas, módulos e faturamento",
        "seguranca": "segurança: allowlists, políticas e logs de segurança",
        "sistema_configuracao": "configurações globais e parâmetros do sistema",
        "stock": "inventário, armazéns, movimentos de stock e contagens",
        "tarefas": "gestão de tarefas e atribuições",
        "tesouraria": "caixa/tesouraria: contas e movimentos de caixa",
        "utilizadores": "perfil e dados de utilizadores do ERP",
    }
    if schema in mapa:
        return mapa[schema]
    return f"domínio `{schema}`"


def main():
    with open("schema-tabelas-lista.txt", "r", encoding="utf-8") as f:
        linhas = f.readlines()
    
    schema_atual = ""
    saida = ["# Descrição Detalhada dos Schemas e Tabelas - nexora_erp\n"]
    
    for linha in linhas:
        linha = linha.strip()
        if not linha:
            continue
        if linha.startswith("## "):
            schema_atual = linha[3:].strip()
            saida.append(f"\n## Schema: `{schema_atual}`")
            saida.append(f"**Domínio:** {descrever_schema(schema_atual)}\n")
            saida.append("### Tabelas\n")
        elif linha.startswith("- "):
            tabela = linha[2:].strip()
            desc = descrever_tabela(schema_atual, tabela)
            saida.append(f"- **`{tabela}`** — {desc}")
    
    with open("descricao-detalhada-schemas-tabelas.md", "w", encoding="utf-8") as f:
        f.write("\n".join(saida))
    
    print("Arquivo descricao-detalhada-schemas-tabelas.md gerado com sucesso.")


if __name__ == "__main__":
    main()
