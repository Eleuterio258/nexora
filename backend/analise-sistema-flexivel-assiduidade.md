# Análise: Sistema Flexível de Controlo de Assiduidade (Nexora ERP)

## 1. Estado actual do backend

O módulo de Recursos Humanos (`internal/modules/recursos-humanos`) já possui esboços de assiduidade, mas a estrutura é **rígida e orientada a dias**:

| Aspecto | Implementação actual | Nível de flexibilidade |
|---|---|---|
| Tabela de horários | `rh.horarios_trabalho` com `hora_entrada`, `hora_saida`, `intervalo_inicio`, `intervalo_fim`, `dias_semana` | Baixo: apenas um turno fixo por dia, sem turnos rotativos, sem flexibilidade, sem trabalho nocturno |
| Tabela de registos | `rh.presencas` com `hora_entrada`, `hora_saida`, `horas_extra` por dia | Muito baixo: força um único par entrada/saída por dia; não suporta eventos intermédios, múltiplos turnos, remoto, etc. |
| Tipos de evento | Não existe catálogo de tipos de evento | Baixo: apenas entradas/saídas pré-definidas no código |
| Tipos de registo / origem | Hardware (FaceClock), QR Code, NFC, geofencing | Parcial: há integração com dispositivos e geofencing, mas ainda não existe uma tabela genérica de origens/métodos |
| Correcções | `rh.pedidos_correcao_ponto` (aprovado/rejeitado) | Parcial: apenas hora_entrada e hora_saida; sem auditoria completa e sem recálculo separado |
| Estados de registo | Coluna `tipo` adicionada como catchup | Parcial: não cobre o workflow completo pendente/aprovado/corrigido/etc. |
| Cálculo | Feito inline nas presenças (`horas_extra`) | Baixo: não separa normais/extra/nocturnas; não permite recalcular após mudança de política |
| Regras | Não existe motor de regras | Não existe |
| Auditoria | Apenas timestamps de criação/actualização | Insuficiente para requisitos de auditoria (quem, valor anterior, IP, dispositivo, localização) |

Ficheiros relevantes:
- `backend/migrations/20260629000018_rh_horarios.up.sql`
- `backend/migrations/20260629000023_rh_presencas.up.sql`
- `backend/migrations/20260712000122_rh_pedidos_correcao_ponto.up.sql`
- `backend/internal/modules/recursos-humanos/handlers/presencas.go`
- `backend/internal/modules/recursos-humanos/handlers/horarios.go`
- `backend/internal/modules/recursos-humanos/handlers/correcoes_ponto.go`
- `backend/internal/modules/recursos-humanos/handlers/assiduidade_qr.go`
- `backend/internal/modules/recursos-humanos/handlers/assiduidade_integracao.go`
- `backend/internal/modules/recursos-humanos/handlers/nfc_tags.go`

## 2. Gaps críticos face ao requisito

### 2.1 Modelo de dados ainda é diário, não eventos independentes
O requisito (secção 8) diz que cada marcação deve ser um **evento independente**. A tabela `rh.presencas` assume um par entrada/saída por dia (`uq_presencas_funcionario_data`), impossibilitando múltiplos eventos, intervalos, saídas temporárias, remoto, etc.

### 2.2 Horários não suportam os 9 cenários pedidos
A secção 1 pede suporte a horários fixos, flexíveis, turnos, rotativos, nocturno, remoto, escala, dias diferentes e sem horário fixo. A tabela actual tem uma única entrada/saída por dia da semana e não guarda janela flexível, carga mínima/máxima, nem turnos nocturnos que atravessam a meia-noite.

### 2.3 Tipos de registo limitados e hard-coded
A secção 2 lista 22 tipos de evento (entrada, saída, intervalo, remoto, missão, horas extra, férias, baixa, etc.). O administrador deve poder criar novos tipos sem alterar código. Hoje os tipos são campos fixos ou derivados de rotinas hard-coded.

### 2.4 Sequência rígida e bloqueios implícitos
A secção 4 exige que o sistema aceite sequências diferentes e não bloqueie quando falta um registo. A estrutura actual `hora_entrada`/`hora_saida` impede naturalmente múltiplas entradas e não tem um modo de registar ocorrências para análise sem destruir os restantes dados.

### 2.5 Cálculo acoplado aos registos
A secção 10 exige que o cálculo seja separado dos registos originais, permitindo recalcular após mudanças de política. Hoje as horas extra são colunas na própria presença.

### 2.6 Auditoria insuficiente
A secção 12 exige histórico completo: quem alterou, valor anterior, novo valor, motivo, IP, dispositivo, localização. A actualização de `presencas` não guarda versão anterior.

### 2.7 Regras configuráveis não existem
A secção 7 pede regras por empresa, filial, local, departamento, cargo, equipa, turno, funcionário e contrato. Não existe ainda tabela nem motor de regras.

## 3. Modelo de dados proposto (novo schema `rh`)

O modelo segue a separação recomendada na secção 13:

1. **Registo bruto** → `registos_brutos` (ou `eventos_assiduidade`)
2. **Evento interpretado** → `eventos_assiduidade` + `tipos_evento`
3. **Resultado calculado** → `resultados_assiduidade` (dia) e `periodos_assiduidade` (semana/mês)
4. **Ajuste** → `ajustes_assiduidade` e `correcoes_evento`
5. **Aprovação** → reaproveitar `aprovacoes` + `aprovacoes_workflow` ou tabela dedicada `aprovacoes_assiduidade`
6. **Auditoria** → `auditoria_assiduidade`

### 3.1 Catálogos configuráveis

```sql
-- Tipos de evento criáveis pelo administrador (sem alterar código)
CREATE TABLE rh.tipos_evento (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,           -- 'entrada', 'saida', 'intervalo_inicio', 'remoto_inicio', ...
    nome VARCHAR(100) NOT NULL,
    categoria VARCHAR(40) NOT NULL,        -- 'marcacao', 'ausencia', 'justificacao', 'tipo_presenca'
    sentido VARCHAR(20),                   -- 'inicio', 'fim', 'unico' (para casar pares)
    tipo_par VARCHAR(50),                  -- 'entrada' -> 'saida', 'intervalo_inicio' -> 'intervalo_fim'
    afeta_calculo VARCHAR(20),             -- 'trabalho', 'intervalo', 'ausencia', 'remoto', 'extra', 'nenhum'
    cor VARCHAR(10),
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, codigo)
);

-- Métodos de marcação (RFID, NFC, biometrico, app, selfie, manual, importacao, api...)
CREATE TABLE rh.metodos_marcacao (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,           -- 'biometria', 'rfid', 'app_web', 'manual', ...
    nome VARCHAR(100) NOT NULL,
    requer_dispositivo BOOLEAN DEFAULT FALSE,
    requer_localizacao BOOLEAN DEFAULT FALSE,
    requer_selfie BOOLEAN DEFAULT FALSE,
    ativo BOOLEAN DEFAULT TRUE,
    UNIQUE(tenant_id, codigo)
);

-- Tipos de regra para cálculo e validação
CREATE TABLE rh.tipos_regra (
    id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,    -- 'tolerancia_atraso', 'max_horas_extra', 'intervalo_obrigatorio', ...
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    parametros JSONB DEFAULT '{}',          -- schema dos parametros esperados
    tipo_valor VARCHAR(20)                 -- 'numero', 'hora', 'booleano', 'jsonb'
);
```

### 3.2 Horários flexíveis

```sql
CREATE TABLE rh.horarios_trabalho (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(40) NOT NULL,             -- 'fixo', 'flexivel', 'turno', 'rotativo', 'escala', 'remoto', 'sem_horario'
    contagem VARCHAR(20) DEFAULT 'diaria',   -- 'diaria', 'semanal', 'mensal'
    carga_diaria_minima INTERVAL,
    carga_diaria_maxima INTERVAL,
    carga_semanal INTERVAL,
    janela_entrada_inicio INTERVAL,         -- para flexível: 07:00
    janela_entrada_fim INTERVAL,            -- para flexível: 10:00
    ativo BOOLEAN DEFAULT TRUE,
    UNIQUE(tenant_id, codigo)
);

-- Horário por dia (permite dias diferentes e múltiplos turnos no mesmo dia)
CREATE TABLE rh.horarios_dias (
    id BIGSERIAL PRIMARY KEY,
    horario_id BIGINT NOT NULL REFERENCES rh.horarios_trabalho(id) ON DELETE CASCADE,
    dia_semana SMALLINT CHECK (dia_semana BETWEEN 1 AND 7),
    data_especifica DATE,                   -- para escalas ou feriados pontuais
    ordem SMALLINT DEFAULT 1,               -- ordem dos turnos no mesmo dia
    hora_entrada INTERVAL NOT NULL,
    hora_saida INTERVAL NOT NULL,
    intervalo_inicio INTERVAL,
    intervalo_fim INTERVAL,
    tolerancia_atraso INTERVAL DEFAULT '0',
    tolerancia_saida_antecipada INTERVAL DEFAULT '0',
    eh_nocturno BOOLEAN DEFAULT FALSE,      -- turno atravessa meia-noite
    UNIQUE(horario_id, dia_semana, data_especifica, ordem)
);

-- Associar funcionários a horários com vigência (permite mudanças de horário no tempo)
CREATE TABLE rh.funcionario_horarios (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES rh.funcionarios(id) ON DELETE CASCADE,
    horario_id BIGINT NOT NULL REFERENCES rh.horarios_trabalho(id),
    data_inicio DATE NOT NULL,
    data_fim DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, funcionario_id, data_inicio)
);
```

### 3.3 Eventos de assiduidade (registos independentes)

```sql
CREATE TABLE rh.eventos_assiduidade (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES rh.funcionarios(id) ON DELETE CASCADE,
    tipo_evento_id BIGINT NOT NULL REFERENCES rh.tipos_evento(id),
    metodo_id BIGINT REFERENCES rh.metodos_marcacao(id),
    
    -- momento exacto do evento (timestamp com timezone, para remoto e fronteiras)
    ocorrido_em TIMESTAMPTZ NOT NULL,
    data_referencia DATE NOT NULL,          -- dia de referência (pode ser anterior se turno nocturno)
    
    -- origem do registo
    origem VARCHAR(40) NOT NULL,            -- 'biometria', 'app', 'web', 'manual', 'api', 'importacao'
    dispositivo_id BIGINT,                  -- referência a hardware.devices quando aplicável
    qr_token_id BIGINT,                     -- referência a rh.qr_tokens quando aplicável
    nfc_tag_id BIGINT,                      -- referência a rh.nfc_tags quando aplicável
    
    -- localização
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    localidade_id BIGINT,                   -- unidade organizacional / filial / local de trabalho
    dentro_geofence BOOLEAN,
    
    -- selfie / comprovativo
    foto_url TEXT,
    documento_url TEXT,
    
    -- estado do workflow
    estado VARCHAR(30) NOT NULL DEFAULT 'valido', -- 'valido','pendente','aprovado','rejeitado','corrigido','duplicado','incompleto','fora_horario','fora_localizacao','manual','importado','em_analise'
    
    -- metadados
    registado_por BIGINT REFERENCES auth.users(id), -- NULL para marcação automática
    motivo TEXT,
    observacoes TEXT,
    
    -- duplicados / agrupamento
    evento_pai_id BIGINT REFERENCES rh.eventos_assiduidade(id),
    duplicado_de_id BIGINT REFERENCES rh.eventos_assiduidade(id),
    
    -- rastreabilidade
    ip_origem INET,
    user_agent TEXT,
    hash_digital TEXT,                      -- hash do payload original para auditoria
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_eventos_assiduidade_func_data ON rh.eventos_assiduidade(funcionario_id, data_referencia, ocorrido_em);
CREATE INDEX idx_eventos_assiduidade_tenant_data ON rh.eventos_assiduidade(tenant_id, data_referencia);
CREATE INDEX idx_eventos_assiduidade_estado ON rh.eventos_assiduidade(estado);
```

### 3.4 Resultados calculados (separados dos eventos)

```sql
CREATE TABLE rh.resultados_diarios (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES rh.funcionarios(id) ON DELETE CASCADE,
    data_referencia DATE NOT NULL,
    horario_id BIGINT REFERENCES rh.horarios_trabalho(id),
    
    -- tempos calculados
    horas_trabalhadas INTERVAL,
    horas_normais INTERVAL,
    horas_extra INTERVAL,
    horas_nocturnas INTERVAL,
    horas_remoto INTERVAL,
    horas_missao INTERVAL,
    horas_formacao INTERVAL,
    horas_intervalo INTERVAL,
    horas_nao_contabilizadas INTERVAL,
    
    -- ocorrências
    atraso_minutos INTEGER DEFAULT 0,
    saida_antecipada_minutos INTEGER DEFAULT 0,
    ausencia BOOLEAN DEFAULT FALSE,
    falta_justificada BOOLEAN DEFAULT FALSE,
    falta_injustificada BOOLEAN DEFAULT FALSE,
    
    -- saldos
    saldo_diario INTERVAL,
    saldo_semanal INTERVAL,                 -- acumulado até domingo da semana
    saldo_mensal INTERVAL,                  -- acumulado até ao mês
    banco_horas INTERVAL,
    
    -- metadados de cálculo
    versao_regra INT DEFAULT 1,             -- permite saber qual a versão das regras aplicadas
    recalculado_em TIMESTAMPTZ,
    
    UNIQUE(tenant_id, funcionario_id, data_referencia)
);

CREATE TABLE rh.resultados_periodos (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES rh.funcionarios(id) ON DELETE CASCADE,
    tipo_periodo VARCHAR(20) NOT NULL,      -- 'semana', 'mes'
    ano SMALLINT NOT NULL,
    numero SMALLINT NOT NULL,               -- semana ou mês
    horas_normais INTERVAL,
    horas_extra INTERVAL,
    horas_nocturnas INTERVAL,
    horas_remoto INTERVAL,
    horas_missao INTERVAL,
    atrasos_minutos INTEGER DEFAULT 0,
    faltas INTEGER DEFAULT 0,
    saldo INTERVAL,
    UNIQUE(tenant_id, funcionario_id, tipo_periodo, ano, numero)
);
```

### 3.5 Regras configuráveis e aplicação

```sql
-- Regras com herança de âmbito e prioridade
CREATE TABLE rh.regras_assiduidade (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    tipo_regra_id BIGINT NOT NULL REFERENCES rh.tipos_regra(id),
    
    -- âmbito (do mais específico para o mais genérico)
    ambito VARCHAR(20) NOT NULL,            -- 'empresa','filial','local','departamento','cargo','equipa','turno','funcionario','contrato'
    entidade_id BIGINT,                     -- id da entidade no âmbito respectivo; NULL = default da empresa
    
    -- vigência
    data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim DATE,
    
    -- valor / parâmetros
    valor JSONB NOT NULL,
    
    prioridade SMALLINT DEFAULT 0,          -- maior número = ganha
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(tenant_id, tipo_regra_id, ambito, entidade_id, data_inicio)
);

-- Exemplos de regras em valor JSONB:
-- tolerancia_atraso: { "minutos": 10 }
-- max_horas_extra: { "horas": 2, "periodo": "dia" }
-- intervalo_obrigatorio: { "apos_horas": 5, "duracao_minima": 30 }
-- marcacao_somente_empresa: { "ativo": true }
-- trabalho_nocturno: { "inicio_noite": "22:00", "fim_noite": "06:00", "fator": 1.25 }
```

### 3.6 Correcções e ajustes

```sql
-- Correcções solicitadas por funcionários ou criadas por RH
CREATE TABLE rh.correcoes_evento (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES rh.funcionarios(id) ON DELETE CASCADE,
    evento_id BIGINT REFERENCES rh.eventos_assiduidade(id),   -- evento original quando existe
    data_referencia DATE NOT NULL,
    
    -- tipo de correcção
    tipo VARCHAR(40) NOT NULL,              -- 'entrada_esquecida', 'saida_esquecida', 'hora_errada', 'tipo_errado', 'duplicado', 'fora_local', 'falha_equipamento', 'trabalho_fora', ...
    
    -- valores solicitados
    tipo_evento_id BIGINT REFERENCES rh.tipos_evento(id),
    ocorrido_em_solicitado TIMESTAMPTZ,
    localidade_id_solicitada BIGINT,
    motivo TEXT NOT NULL,
    documento_url TEXT,
    
    -- workflow
    estado VARCHAR(20) NOT NULL DEFAULT 'pendente', -- 'pendente','aprovado','rejeitado'
    solicitado_por BIGINT NOT NULL REFERENCES auth.users(id),
    solicitado_em TIMESTAMPTZ DEFAULT NOW(),
    decidido_por BIGINT REFERENCES auth.users(id),
    decidido_em TIMESTAMPTZ,
    justificacao_decisao TEXT,
    
    -- criação do evento resultante
    evento_gerado_id BIGINT REFERENCES rh.eventos_assiduidade(id),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.7 Auditoria completa

```sql
CREATE TABLE rh.auditoria_assiduidade (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    tabela VARCHAR(50) NOT NULL,           -- 'eventos_assiduidade', 'correcoes_evento', 'resultados_diarios', ...
    registo_id BIGINT NOT NULL,
    operacao VARCHAR(10) NOT NULL,           -- 'INSERT', 'UPDATE', 'DELETE'
    campo VARCHAR(100),                     -- nome do campo alterado
    valor_anterior JSONB,
    valor_novo JSONB,
    alterado_por BIGINT REFERENCES auth.users(id),
    motivo TEXT,
    ip_origem INET,
    dispositivo TEXT,
    localizacao VARCHAR(200),               -- textual ou coordenadas
    estado_anterior VARCHAR(30),
    estado_novo VARCHAR(30),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 4. Arquitectura proposta

```
┌────────────────────────────────────────────────────────────────────┐
│                        Interfaces de marcação                     │
│  Biometria / RFID / NFC / QR / App / Web / GPS / Selfie / Manual  │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│                    Recepção de eventos (API)                        │
│  - validação de autenticação (JWT, device key, API key)           │
│  - validação geofence / localização                               │
│  - detecção de duplicados                                         │
│  - gravação em rh.eventos_assiduidade (estado = 'valido/pendente')│
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│                    Motor de interpretação                         │
│  - classifica o tipo de evento (catálogo configurável)            │
│  - agrupa pares: entrada/saída, intervalo, remoto, etc.           │
│  - detecta registos em falta, duplicados, fora de sequência       │
│  - gera ocorrências para análise (não bloqueia)                   │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│                      Motor de regras configurável                  │
│  - aplica tolerâncias, limites, obrigatoriedades                    │
│  - resolve conflitos por prioridade (funcionário > turno > cargo)   │
│  - determina horas normais / extra / nocturnas / remoto             │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│                      Cálculo de resultados                         │
│  - resultados_diarios (reaproveitável / recalculável)              │
│  - resultados_semanais / mensais                                   │
│  - saldo, banco de horas, ausências, faltas                         │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│              Ajustes, aprovações e auditoria                        │
│  - correcoes_evento + workflow de aprovação                         │
│  - auditoria_assiduidade (não elimina registos originais)           │
└────────────────────────────────────────────────────────────────────┘
```

### 4.1 Separação de responsabilidades (clean arch dentro do módulo RH)

Sugestão de estrutura de packages dentro de `internal/modules/recursos-humanos`:

```
recursos-humanos/
├── handlers/               # HTTP handlers (já existente)
├── domain/
│   ├── evento.go            # entidade Evento, estados, validações
│   ├── horario.go           # entidades Horario, Turno, Jornada
│   ├── regra.go             # entidade Regra, prioridade, aplicação
│   └── resultado.go         # entidades ResultadoDiario, ResultadoPeriodo
├── application/
│   ├── eventos_service.go   # caso de uso: receber eventos, detectar duplicados
│   ├── correcoes_service.go # caso de uso: correcões e aprovações
│   ├── calculo_service.go   # caso de uso: interpretar e calcular resultados
│   └── regras_service.go    # caso de uso: CRUD e resolução de regras
├── ports/
│   ├── repository.go        # interfaces para persistência
│   └── service.go           # interfaces para serviços externos (geofence, etc.)
├── infra/
│   ├── pg_eventos_repo.go   # implementação PostgreSQL
│   ├── pg_calculo_repo.go
│   └── regras_engine.go     # motor de regras
└── handlers_assiduidade.go  # rotas específicas do novo módulo
```

## 5. Estratégia de migração

### 5.1 Preservação dos dados actuais
Os dados de `rh.presencas` e `rh.pedidos_correcao_ponto` devem ser migrados para as novas tabelas, não eliminados. Sugestão:

1. Criar as novas tabelas em migrations novas.
2. Migrar os dados existentes:
   - Cada linha `presencas` vira até dois eventos (`entrada` e `saída`) em `eventos_assiduidade`.
   - `horas_extra` vira um evento de `horas_extra_inicio`/`horas_extra_fim` com base na saída ou num cálculo à parte.
   - Os pedidos de correcção vão para `correcoes_evento`.
3. Manter `rh.presencas` como view ou tabela somente-leitura para compatibilidade durante a transição.

```sql
-- Exemplo de view de compatibilidade
CREATE OR REPLACE VIEW rh.presencas_compat AS
SELECT 
    funcionario_id,
    data_referencia AS data,
    MIN(ocorrido_em) FILTER (WHERE te.codigo = 'entrada')::time AS hora_entrada,
    MAX(ocorrido_em) FILTER (WHERE te.codigo = 'saida')::time AS hora_saida,
    ...
FROM rh.eventos_assiduidade e
JOIN rh.tipos_evento te ON te.id = e.tipo_evento_id
WHERE e.estado IN ('valido', 'aprovado', 'corrigido')
GROUP BY funcionario_id, data_referencia;
```

### 5.2 Ordem de implementação sugerida

1. **Catálogos**: `tipos_evento`, `metodos_marcacao`, `tipos_regra`.
2. **Eventos**: `eventos_assiduidade` e adaptação de todos os endpoints de marcação para inserir eventos.
3. **Horários**: remodelar `horarios_trabalho` + criar `horarios_dias` e `funcionario_horarios`.
4. **Regras**: `regras_assiduidade` + motor de resolução.
5. **Cálculo**: `resultados_diarios`, `resultados_periodos` + job diário de recálculo.
6. **Correcções**: `correcoes_evento` + workflow.
7. **Auditoria**: `auditoria_assiduidade` + triggers ou service layer.
8. **Migrar dados**: `presencas` → `eventos_assiduidade`.
9. **Depreciar**: transformar `presencas` em view de compatibilidade (ou após ciclo de release).

## 6. Endpoints HTTP propostos (exemplos)

| Método | Endpoint | Descrição |
|---|---|---|
| GET | `/api/rh/tipos-evento` | CRUD de tipos de evento |
| POST | `/api/rh/eventos` | Registar evento (web, app, manual) |
| GET | `/api/rh/funcionarios/{id}/eventos` | Listar eventos de um funcionário |
| POST | `/api/hardware/assiduidade/eventos` | Registar evento vindo de dispositivo/hardware |
| GET | `/api/rh/funcionarios/{id}/resultados` | Resultados diários/semanais/mensais |
| POST | `/api/rh/funcionarios/{id}/recalcular` | Forçar recálculo dos resultados |
| GET/POST | `/api/rh/regras` | CRUD de regras configuráveis |
| POST | `/api/rh/correcoes` | Submeter pedido de correcção |
| POST | `/api/rh/correcoes/{id}/aprovar` | Aprovar/rejeitar correcção |
| GET | `/api/rh/funcionarios/{id}/auditoria` | Histórico de auditoria |

## 7. Recomendações técnicas imediatas

1. **Não expandir `rh.presencas`**: a tabela actual é uma armadilha de dados rígidos. Usar eventos independentes desde o início.
2. **Timestamps com timezone**: `ocorrido_em` deve ser `TIMESTAMPTZ` para remoto, dispositivos móveis e turnos nocturnos.
3. **Data de referência separada**: um turno que começa às 22:00 de segunda e termina às 06:00 de terça deve ter `data_referencia = segunda` para ambos os eventos, ou usar uma regra definida por empresa.
4. **Não eliminar eventos**: nunca apagar; usar estados (`rejeitado`, `duplicado`, `corrigido`) e manter o original.
5. **Recálculo assíncrono**: o cálculo de resultados deve ser idempotente e poder correr em job diário ou on-demand. Usar `resultados_diarios.versao_regra` para saber quando é preciso recalcular.
6. **Geofencing reutilizável**: já existe `rh.unidades_organizacionais` com `latitude`, `longitude`, `raio_metros`. Usar a mesma lógica de `haversineMeters` para validar eventos.
7. **Aprovações reutilizáveis**: avaliar se se pode usar o módulo `aprovacoes` existente (`internal/modules/aprovacoes`) em vez de reinventar workflow.
8. **Testes**: o projecto usa `pgxmock`. Criar testes para o motor de cálculo e para o motor de regras com cenários de turno nocturno, flexível, múltiplos turnos, etc.

## 8. Exemplos de cenários suportados

### Cenário 1: Funcionário flexível
```
Horário: flexível, janela 07:00-10:00, carga 8h.
Eventos: 07:55 entrada, 12:10 intervalo_inicio, 13:05 intervalo_fim, 17:20 saida.
Resultado: 8h05 trabalhadas, 0 atraso, 0 saída antecipada, 55m intervalo.
```

### Cenário 2: Turno nocturno
```
Horário: 22:00-06:00, nocturno.
Eventos: 22:00 entrada (data_ref=2026-07-20), 02:00 intervalo_inicio, 02:30 intervalo_fim, 06:00 saida (data_ref=2026-07-20).
Resultado: 8h trabalhadas, 8h nocturnas (ou aplicação da regra de fator nocturno).
```

### Cenário 3: Múltiplos turnos num dia
```
Eventos: 08:00 entrada, 12:00 saida, 14:00 entrada, 18:00 saida.
Horário: dois turnos (08:00-12:00, 14:00-18:00) ou acumulação de 8h.
Resultado: 8h trabalhadas, normais.
```

### Cenário 4: Saída temporária e regresso
```
Eventos: 08:00 entrada, 10:00 saida_temporaria, 10:45 regresso_temporaria, 12:30 saida.
Resultado: 3h45 trabalhadas, 45m não contabilizadas (ou contabilizadas conforme regra).
```

### Cenário 5: Remoto e presencial no mesmo dia
```
Eventos: 08:00 entrada, 10:00 remoto_inicio, 12:00 remoto_fim, 17:00 saida.
Resultado: 9h trabalhadas, 2h remoto, 7h presencial.
```

### Cenário 6: Entrada esquecida (registo em falta)
```
Eventos: 12:00 intervalo_inicio, 13:00 intervalo_fim, 17:00 saida.
Ocorrência: entrada em falta → estado 'incompleto', gera correcao pendente.
```

## 9. Conclusão

O backend Nexora já tem bases sólidas (autenticação multi-tenant, geofencing, QR/NFC, hardware integration), mas o núcleo de assiduidade é ainda uma **tabela rígida por dia**. A transição para o modelo proposto — **eventos independentes + horários flexíveis + motor de regras + resultados desacoplados + auditoria completa** — satisfaz todos os 13 pontos do requisito e permite que cada empresa configure o seu próprio funcionamento sem alterar código.

O investimento prioritário deve ser:
1. Modelo de eventos (`eventos_assiduidade`, `tipos_evento`, `metodos_marcacao`).
2. Modelo de horários flexíveis (`horarios_dias`, `funcionario_horarios`).
3. Motor de regras e cálculo de resultados.
4. Correcções com workflow e auditoria.

Com estas quatro bases, o resto das funcionalidades (formas de registo, excepções, relatórios) torna-se implementação de interfaces sobre um domínio estável.
