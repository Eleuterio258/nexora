# Análise: Endpoints de Sessões de Caixa POS

**Data:** 2026-08-12  
**Âmbito:** Endpoints REST para gestão de sessões de caixa POS (`/api/pos/sessions`)  
**Objetivo:** Mapear endpoints existentes, identificar gaps de segurança/funcionalidade e propor melhorias.

---

## 1. Resumo executivo

As sessões de caixa são o coração do fluxo POS. Atualmente existem endpoints para abrir, fechar, listar e obter o resumo de fecho, mas há **gaps de segurança e funcionalidade**:

- Falta `GET /api/pos/sessions/{id}` para obter uma sessão específica.
- `FecharSessao` não verifica se o utilizador é o dono da sessão.
- `ListarSessoes` está sob `operar_pos`, mas deveria ser acessível a supervisores/gerentes.
- `AbrirSessao` não impede que um operador tenha duas sessões abertas simultaneamente.
- Faltam filtros úteis no listar (data, terminal, operador, status).

Esta análise propõe corrigir esses gaps e alinhar as permissões com o modelo granular de POS.

---

## 2. Endpoints atuais

| Método | Endpoint | Handler | Descrição | Permissão |
|---|---|---|---|---|
| GET | `/api/pos/sessions` | `pos.ListarSessoes` | Listar sessões | `pos:operar_pos` |
| POST | `/api/pos/sessions` | `pos.AbrirSessao` | Abrir sessão | `pos:operar_pos` + humano |
| GET | `/api/pos/sessions/atual` | `pos.ObterSessaoAtual` | Obter sessão aberta do utilizador | `pos:operar_pos` |
| POST | `/api/pos/sessions/{id}/fechar` | `pos.FecharSessao` | Fechar sessão | `pos:operar_pos` + humano |
| GET | `/api/pos/sessions/{id}/fecho` | `pos.ObterFechoSessao` | Resumo de fecho | `pos:operar_pos` |
| GET | `/api/pos/sessions/{id}/movimentacoes` | `pos.ListarMovimentosCaixa` | Listar movimentos | `pos:operar_pos` |
| POST | `/api/pos/sessions/{id}/movimentacoes` | `pos.RegistarMovimentoCaixa` | Registar movimento | `pos:supervisionar_pos` + humano |

---

## 3. Gaps identificados

| Gap | Impacto | Proposta |
|---|---|---|
| `GET /api/pos/sessions/{id}` não existe | Médio | Adicionar endpoint para obter detalhe de uma sessão |
| `FecharSessao` não valida dono da sessão | **Alto** | Só o dono pode fechar; exigir `pos:supervisionar_pos` ou `pos:fechar_outra_sessao` para fechar de outro |
| `ListarSessoes` sob `operar_pos` | Médio | Permitir `pos:ver`, `pos:supervisionar` ou `pos:relatorios` |
| `AbrirSessao` permite múltiplas sessões abertas do mesmo operador | Médio | Impedir operador de abrir nova sessão se já tiver uma aberta |
| Filtros limitados no listar | Baixo | Adicionar filtros por data, terminal, operador, status |
| `ObterSessaoAtual` retorna erro 404 se não houver sessão | Baixo | Considerar 200 com `{sessao: null}` para facilitar o frontend |
| `ObterFechoSessao` está sob `operar_pos` | Médio | Deveria exigir `pos:ver` ou `pos:relatorios` |

---

## 4. Endpoints propostos

### 4.1 CRUD e operações

| Método | Endpoint | Descrição | Permissão |
|---|---|---|---|
| GET | `/api/pos/sessions` | Listar sessões (com filtros) | `pos:ver` / `pos:supervisionar` / `pos:relatorios` |
| POST | `/api/pos/sessions` | Abrir sessão | `pos:abrir_sessao` + humano |
| GET | `/api/pos/sessions/atual` | Obter sessão aberta do utilizador | `pos:operar_pos` |
| GET | `/api/pos/sessions/{id}` | Obter sessão por ID | `pos:ver` / `pos:supervisionar` |
| POST | `/api/pos/sessions/{id}/fechar` | Fechar sessão | `pos:fechar_sessao` (própria) ou `pos:fechar_outra_sessao` (de outro) |
| GET | `/api/pos/sessions/{id}/fecho` | Resumo de fecho | `pos:ver` / `pos:relatorios` |
| GET | `/api/pos/sessions/{id}/movimentacoes` | Listar movimentos | `pos:ver` / `pos:supervisionar` |
| POST | `/api/pos/sessions/{id}/movimentacoes` | Registar movimento | `pos:movimentar_caixa` + humano |

### 4.2 Filtros no listar

```http
GET /api/pos/sessions?status=aberta&terminal_id=1&user_id=5&data_inicio=2026-08-01&data_fim=2026-08-31&page=1&limit=20
```

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `status` | string | `aberta` ou `fechada` |
| `terminal_id` | int | Filtrar por terminal |
| `user_id` | int | Filtrar por operador |
| `funcionario_id` | int | Filtrar por funcionário |
| `data_inicio` | date | Sessões abertas/fechadas a partir de |
| `data_fim` | date | Sessões até |
| `page` | int | Página |
| `limit` | int | Tamanho da página |

---

## 5. Regras de segurança propostas

### 5.1 Abertura de sessão

- Requer `pos:abrir_sessao`.
- Apenas operadores humanos (`RequireHumanOperator`).
- Terminal deve estar ativo e não arquivado.
- Operador deve estar autorizado no terminal (já existe `funcionarioAutorizadoNoTerminal`).
- Não pode haver outra sessão aberta para o **mesmo terminal**.
- **Novo:** Operador não pode ter outra sessão aberta em outro terminal.

### 5.2 Fecho de sessão

- Requer `pos:fechar_sessao`.
- Apenas operadores humanos.
- Sessão deve existir e estar aberta.
- **Novo:** Se o utilizador não for o dono da sessão, requer `pos:supervisionar_pos` ou `pos:fechar_outra_sessao`.

### 5.3 Visualização

- `GET /api/pos/sessions/{id}` e `GET /api/pos/sessions/{id}/fecho`:
  - Dono da sessão pode sempre ver.
  - Outros utilizadores precisam de `pos:supervisionar` ou `pos:relatorios`.

### 5.4 Movimentos de caixa

- **Listar:** `pos:ver` ou `pos:supervisionar`.
- **Criar:** `pos:movimentar_caixa` (alteração da atual `supervisionar_pos`).

---

## 6. Implementação proposta

### 6.1 Novo handler `ObterSessaoPorID`

```go
func (h *Handler) ObterSessaoPorID(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	type Row struct {
		ID            int64      `json:"id"`
		TerminalID    int64      `json:"terminal_id"`
		TerminalNome  string     `json:"terminal_nome"`
		UserID        int64      `json:"user_id"`
		OperadorNome  string     `json:"operador_nome"`
		FuncionarioID *int64     `json:"funcionario_id"`
		OpenedAt      time.Time  `json:"opened_at"`
		ClosedAt      *time.Time `json:"closed_at"`
		OpeningAmount float64    `json:"opening_amount"`
		ClosingAmount *float64   `json:"closing_amount"`
		Status        string     `json:"status"`
		CreatedAt     time.Time  `json:"created_at"`
	}
	var s Row
	err := h.db.QueryRow(r.Context(), `
		SELECT s.id, s.terminal_id, COALESCE(t.nome,''), s.user_id, COALESCE(u.nome,''),
		       s.funcionario_id, s.opened_at, s.closed_at, s.opening_amount, s.closing_amount,
		       s.status, s.created_at
		  FROM pos_sessions s
		  LEFT JOIN pos_terminals t ON t.id = s.terminal_id AND t.tenant_id = s.tenant_id
		  LEFT JOIN auth.users u ON u.id = s.user_id
		 WHERE s.id=$1 AND s.tenant_id=$2`, id, user.TenantID).
		Scan(&s.ID, &s.TerminalID, &s.TerminalNome, &s.UserID, &s.OperadorNome,
			&s.FuncionarioID, &s.OpenedAt, &s.ClosedAt, &s.OpeningAmount, &s.ClosingAmount,
			&s.Status, &s.CreatedAt)
	if err == pgx.ErrNoRows {
		jsonErr(w, "Sessão não encontrada", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	// Dono pode sempre ver; outros precisam de permissão de supervisão/relatórios.
	if s.UserID != user.ID && !user.Can("pos", "supervisionar") && !user.Can("pos", "relatorios") {
		jsonErr(w, "Sem permissão para visualizar esta sessão", http.StatusForbidden)
		return
	}

	jsonOK(w, s, http.StatusOK)
}
```

### 6.2 Proteção no `FecharSessao`

Antes de processar o fecho, verificar:

```go
var sessaoUserID int64
if err := h.db.QueryRow(r.Context(), `
    SELECT user_id FROM pos_sessions WHERE id=$1 AND tenant_id=$2 AND status='aberta'`,
    id, user.TenantID).Scan(&sessaoUserID); err != nil {
    jsonErr(w, "Sessão de caixa não encontrada ou já fechada", http.StatusNotFound)
    return
}

if sessaoUserID != user.ID && !user.Can("pos", "supervisionar_pos") && !user.Can("pos", "fechar_outra_sessao") {
    jsonErr(w, "Sem permissão para fechar sessão de outro operador", http.StatusForbidden)
    return
}
```

### 6.3 Proteção no `AbrirSessao`

Adicionar verificação de sessão aberta do próprio utilizador:

```go
var sessaoUsuarioAberta int64
if err := h.db.QueryRow(r.Context(), `
    SELECT id FROM pos_sessions WHERE tenant_id=$1 AND user_id=$2 AND status='aberta'`,
    user.TenantID, user.ID).Scan(&sessaoUsuarioAberta); err == nil {
    jsonErr(w, fmt.Sprintf("Operador já tem uma sessão de caixa aberta (#%d)", sessaoUsuarioAberta), http.StatusConflict)
    return
}
```

### 6.4 Melhorias no `ListarSessoes`

Adicionar filtros e usar permissões corretas:

```go
q := r.URL.Query()
where := "tenant_id=$1"
args := []any{user.TenantID}

if v := q.Get("status"); v != "" {
    args = append(args, v)
    where += " AND status=$" + strconv.Itoa(len(args))
}
if v := q.Get("terminal_id"); v != "" {
    if tid, err := strconv.ParseInt(v, 10, 64); err == nil {
        args = append(args, tid)
        where += " AND terminal_id=$" + strconv.Itoa(len(args))
    }
}
if v := q.Get("user_id"); v != "" {
    if uid, err := strconv.ParseInt(v, 10, 64); err == nil {
        args = append(args, uid)
        where += " AND user_id=$" + strconv.Itoa(len(args))
    }
}
if v := q.Get("funcionario_id"); v != "" {
    if fid, err := strconv.ParseInt(v, 10, 64); err == nil {
        args = append(args, fid)
        where += " AND funcionario_id=$" + strconv.Itoa(len(args))
    }
}
if v := q.Get("data_inicio"); v != "" {
    args = append(args, v)
    where += " AND opened_at >= $" + strconv.Itoa(len(args))
}
if v := q.Get("data_fim"); v != "" {
    args = append(args, v+" 23:59:59")
    where += " AND opened_at <= $" + strconv.Itoa(len(args))
}

// Se não for supervisor, limitar às próprias sessões.
if !user.Can("pos", "supervisionar") && !user.Can("pos", "relatorios") {
    args = append(args, user.ID)
    where += " AND user_id=$" + strconv.Itoa(len(args))
}
```

### 6.5 Atualização do router

```go
r.Route("/sessoes", func(r chi.Router) {
    r.With(mw.RequirePermissionAny(db, []authModels.Permission{
        {Modulo: "pos", Acao: "ver"},
        {Modulo: "pos", Acao: "supervisionar"},
        {Modulo: "pos", Acao: "relatorios"},
    })).Get("/", pos.ListarSessoes)

    r.With(mw.RequirePermission(db, "pos", "abrir_sessao"), mw.RequireHumanOperator()).
        Post("/", pos.AbrirSessao)

    r.With(mw.RequirePermission(db, "pos", "operar_pos")).
        Get("/atual", pos.ObterSessaoAtual)

    r.With(mw.RequirePermissionAny(db, []authModels.Permission{
        {Modulo: "pos", Acao: "ver"},
        {Modulo: "pos", Acao: "supervisionar"},
        {Modulo: "pos", Acao: "relatorios"},
    })).Get("/{id}", pos.ObterSessaoPorID)

    r.With(mw.RequirePermissionAny(db, []authModels.Permission{
        {Modulo: "pos", Acao: "fechar_sessao"},
        {Modulo: "pos", Acao: "supervisionar_pos"},
        {Modulo: "pos", Acao: "fechar_outra_sessao"},
    }), mw.RequireHumanOperator()).
        Post("/{id}/fechar", pos.FecharSessao)

    r.With(mw.RequirePermissionAny(db, []authModels.Permission{
        {Modulo: "pos", Acao: "ver"},
        {Modulo: "pos", Acao: "relatorios"},
    })).Get("/{id}/fecho", pos.ObterFechoSessao)

    r.With(mw.RequirePermissionAny(db, []authModels.Permission{
        {Modulo: "pos", Acao: "ver"},
        {Modulo: "pos", Acao: "supervisionar"},
    })).Get("/{id}/movimentacoes", pos.ListarMovimentosCaixa)

    r.With(mw.RequirePermission(db, "pos", "movimentar_caixa"), mw.RequireHumanOperator()).
        Post("/{id}/movimentacoes", pos.RegistarMovimentoCaixa)
})
```

---

## 7. Permissões por endpoint

| Endpoint | Permissão(s) |
|---|---|
| `GET /api/pos/sessions` | `pos:ver` ou `pos:supervisionar` ou `pos:relatorios` |
| `POST /api/pos/sessions` | `pos:abrir_sessao` + humano |
| `GET /api/pos/sessions/atual` | `pos:operar_pos` |
| `GET /api/pos/sessions/{id}` | `pos:ver` / `pos:supervisionar` / `pos:relatorios` (dono sempre pode) |
| `POST /api/pos/sessions/{id}/fechar` | `pos:fechar_sessao` (própria) ou `pos:supervisionar_pos` / `pos:fechar_outra_sessao` (de outro) + humano |
| `GET /api/pos/sessions/{id}/fecho` | `pos:ver` / `pos:relatorios` (dono sempre pode) |
| `GET /api/pos/sessions/{id}/movimentacoes` | `pos:ver` / `pos:supervisionar` |
| `POST /api/pos/sessions/{id}/movimentacoes` | `pos:movimentar_caixa` + humano |

---

## 8. Conclusão

As sessões de caixa precisam de:

1. Endpoint de detalhe (`GET /api/pos/sessions/{id}`).
2. Proteção do fecho para evitar que operadores fechem sessões alheias.
3. Prevenção de múltiplas sessões abertas pelo mesmo operador.
4. Melhores filtros no listar.
5. Alinhamento das permissões com o modelo granular de POS.

A implementação proposta mantém a compatibilidade com os fluxos existentes e reforça a segurança do módulo.
