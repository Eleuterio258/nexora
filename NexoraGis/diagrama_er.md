# Diagrama Entidade-Relacionamento

## Diagrama ER Simplificado (Mermaid)

```mermaid
erDiagram
    ORGANIZACAO ||--o{ UTILIZADOR : possui
    ORGANIZACAO ||--o{ PROJETO : executa
    ORGANIZACAO ||--o| DIVISAO_ADMINISTRATIVA : opera_em

    DIVISAO_ADMINISTRATIVA ||--o{ DIVISAO_ADMINISTRATIVA : pai_de
    DIVISAO_ADMINISTRATIVA ||--o{ PROJETO : referencia
    DIVISAO_ADMINISTRATIVA ||--o{ PARCELA : localiza

    PROJETO ||--o{ PROJETO_EQUIPA : tem
    UTILIZADOR ||--o{ PROJETO_EQUIPA : participa
    PROJETO ||--o{ PLANO : contem
    PROJETO ||--o{ PARCELA : cadastra
    PROJETO ||--o{ INFRAESTRUTURA : regista
    PROJETO ||--o{ EQUIPAMENTO : regista
    PROJETO ||--o{ LEVANTAMENTO : planeia
    PROJETO ||--o{ CONFLITO : deteta
    PROJETO ||--o{ FISCALIZACAO : monitoriza
    PROJETO ||--o{ APROVACAO : submete
    PROJETO ||--o{ DOCUMENTO : anexa

    PLANO ||--o{ ZONA : define

    PARCELA ||--o{ LOTE : subdivide
    PARCELA ||--o{ EDIFICACAO : contem
    PARCELA ||--o{ PARCELA_ENTIDADE : relaciona
    PARCELA ||--o{ FISCALIZACAO : fiscaliza
    PARCELA ||--o{ APROVACAO : passa_por

    ENTIDADE ||--o{ PARCELA_ENTIDADE : vincula

    LEVANTAMENTO ||--o{ PONTO_LEVANTAMENTO : recolhe

    UTILIZADOR ||--o{ APROVACAO : aprova
    UTILIZADOR ||--o{ FISCALIZACAO : fiscaliza
    UTILIZADOR ||--o{ LOG : registra

    ZONA ||--o{ CONFLITO : gera
    CONDICIONANTE ||--o{ CONFLITO : gera

    CAMADA ||--o| PROJETO : pertence
```

---

## Diagrama ER Detalhado por Domínio

### 1. Territorial — Organizações, Utilizadores e Projetos

```mermaid
erDiagram
    ORGANIZACAO {
        uuid id PK
        string codigo UK
        string designacao
        string tipo
        string nif
        string email
        string telefone
        text endereco
        uuid divisao_administrativa_id FK
        boolean ativo
    }

    UTILIZADOR {
        uuid id PK
        uuid organizacao_id FK
        string username UK
        string email UK
        string password_hash
        string nome_completo
        string perfil
        string telefone
        boolean ativo
        timestamp ultimo_acesso
    }

    PERMISSAO {
        uuid id PK
        string perfil
        string recurso
        string acao
        boolean ativo
    }

    PROJETO {
        uuid id PK
        uuid organizacao_id FK
        string codigo UK
        string designacao
        string tipo
        text descricao
        string cliente
        uuid divisao_administrativa_id FK
        geometry area_intervencao
        string sistema_referencia
        uuid responsavel_tecnico_id FK
        date data_inicio
        date data_prevista_conclusao
        enum status
    }

    PROJETO_EQUIPA {
        uuid id PK
        uuid projeto_id FK
        uuid utilizador_id FK
        string funcao
        boolean ativo
    }

    ORGANIZACAO ||--o{ UTILIZADOR : possui
    ORGANIZACAO ||--o{ PROJETO : executa
    PROJETO ||--o{ PROJETO_EQUIPA : tem
    UTILIZADOR ||--o{ PROJETO_EQUIPA : participa
```

### 2. Territorial — Divisão Administrativa

```mermaid
erDiagram
    DIVISAO_ADMINISTRATIVA {
        uuid id PK
        uuid parent_id FK
        enum tipo
        string codigo UK
        string nome
        string nome_normalizado
        boolean zona_urbana
        int nivel_hierarquico
        string entidade_responsavel
        string codigo_ine
        geometry geometria
        numeric area_calculada
        geometry centroide
        boolean ativo
        jsonb metadados
    }

    DIVISAO_ADMINISTRATIVA ||--o{ DIVISAO_ADMINISTRATIVA : pai_de
```

### 3. Cadastro — Parcelas, Edificações e Entidades

```mermaid
erDiagram
    PARCELA {
        uuid id PK
        uuid projeto_id FK
        string codigo_cadastral UK
        string numero_parcela
        string numero_talhao
        uuid divisao_administrativa_id FK
        geometry geometria
        geometry centroide
        numeric area_calculada
        numeric perimetro
        string sistema_coordenadas
        numeric precisao_levantamento
        enum situacao
        enum uso_atual
        enum uso_previsto
        string classificacao_plano
        jsonb parametros_urbanisticos
        enum estado
        int versao
    }

    LOTE {
        uuid id PK
        uuid parcela_id FK
        string codigo
        geometry geometria
        numeric area_calculada
    }

    EDIFICACAO {
        uuid id PK
        uuid parcela_id FK
        string codigo
        geometry geometria
        numeric area_construida
        int numero_pisos
        string tipo_construcao
        enum finalidade
        string material_predominante
        string estado_conservacao
        text fotografias
        geometry coordenadas
    }

    ENTIDADE {
        uuid id PK
        enum tipo
        string nome
        string documento_identificacao
        string nuit
        text morada
        string telefone
        string email
        boolean dados_pessoais
        boolean acesso_publico
    }

    PARCELA_ENTIDADE {
        uuid id PK
        uuid parcela_id FK
        uuid entidade_id FK
        enum tipo_relacao
        date data_inicio
        date data_fim
        boolean ativo
    }

    PARCELA ||--o{ LOTE : subdivide
    PARCELA ||--o{ EDIFICACAO : contem
    PARCELA ||--o{ PARCELA_ENTIDADE : relaciona
    ENTIDADE ||--o{ PARCELA_ENTIDADE : vincula
```

### 4. Cadastro — Infraestruturas, Equipamentos e Levantamentos

```mermaid
erDiagram
    INFRAESTRUTURA {
        uuid id PK
        uuid projeto_id FK
        enum tipo
        string subtipo
        string codigo
        string designacao
        geometry geometria
        jsonb atributos
        string estado_conservacao
        date data_levantamento
    }

    EQUIPAMENTO {
        uuid id PK
        uuid projeto_id FK
        string tipo
        string codigo
        string nome
        geometry geometria
        text morada
        string contacto
        int capacidade
        jsonb atributos
        boolean ativo
    }

    LEVANTAMENTO {
        uuid id PK
        uuid projeto_id FK
        string codigo UK
        string designacao
        uuid responsavel_id FK
        enum tipo
        string equipamento_utilizado
        string metodo
        timestamp data_inicio
        timestamp data_fim
        string status
    }

    PONTO_LEVANTAMENTO {
        uuid id PK
        uuid levantamento_id FK
        string codigo
        geometry geometria
        numeric altitude
        numeric precisao_horizontal
        numeric precisao_vertical
        numeric latitude
        numeric longitude
        text fotografias
        boolean sincronizado
    }

    PROJETO ||--o{ INFRAESTRUTURA : regista
    PROJETO ||--o{ EQUIPAMENTO : regista
    PROJETO ||--o{ LEVANTAMENTO : planeia
    LEVANTAMENTO ||--o{ PONTO_LEVANTAMENTO : recolhe
```

### 5. Territorial — Plano, Zoneamento, Conflitos e Fiscalização

```mermaid
erDiagram
    PLANO {
        uuid id PK
        uuid projeto_id FK
        string codigo
        string designacao
        string versao
        date data_aprovacao
        date data_publicacao
        boolean ativo
    }

    ZONA {
        uuid id PK
        uuid plano_id FK
        string codigo
        string designacao
        string cor
        geometry geometria
        jsonb parametros
        text atividades_permitidas
        text atividades_condicionadas
        text atividades_proibidas
        numeric area_calculada
    }

    CONFLITO {
        uuid id PK
        uuid projeto_id FK
        enum tipo
        text descricao
        string entidade_tipo
        uuid entidade_id
        geometry geometria
        jsonb detalhes
        boolean resolvido
        timestamp data_detecao
    }

    FISCALIZACAO {
        uuid id PK
        uuid projeto_id FK
        uuid parcela_id FK
        uuid fiscal_id FK
        timestamp data_ocorrencia
        geometry coordenadas
        text descricao
        text fotografias
        string estado
        text acao_necessaria
    }

    CONDICIONANTE {
        uuid id PK
        uuid projeto_id FK
        string tipo
        string designacao
        geometry geometria
        numeric buffer_metros
        boolean restritivo
    }

    PROJETO ||--o{ PLANO : contem
    PLANO ||--o{ ZONA : define
    PROJETO ||--o{ CONFLITO : deteta
    PROJETO ||--o{ FISCALIZACAO : monitoriza
    PROJETO ||--o{ CONDICIONANTE : regista
```

### 6. Workflow, Auditoria e GIS

```mermaid
erDiagram
    APROVACAO {
        uuid id PK
        string entidade_tipo
        uuid entidade_id
        uuid projeto_id FK
        enum status
        uuid requisitado_por FK
        uuid verificado_por FK
        uuid aprovado_por FK
        timestamp data_submissao
        timestamp data_aprovacao
        text motivo_rejeicao
        int versao
    }

    GEOMETRIA_HISTORICO {
        uuid id PK
        string entidade_tipo
        uuid entidade_id
        uuid projeto_id FK
        geometry geometria_anterior
        geometry geometria_nova
        uuid utilizador_id FK
        timestamp data_alteracao
        text motivo
        int versao_anterior
        int versao_nova
    }

    LOG {
        uuid id PK
        uuid utilizador_id FK
        string utilizador_nome
        enum operacao
        string entidade_tipo
        uuid entidade_id
        uuid projeto_id FK
        jsonb dados_anteriores
        jsonb dados_novos
        inet ip_address
        timestamp data_hora
    }

    CAMADA {
        uuid id PK
        uuid projeto_id FK
        string nome
        enum tipo
        string tabela_fonte
        string coluna_geometria
        jsonb estilo
        jsonb metadados
        string fonte
        string sistema_coordenadas
        boolean publica
    }

    DOCUMENTO {
        uuid id PK
        uuid projeto_id FK
        enum tipo
        string titulo
        string entidade_tipo
        uuid entidade_id
        text ficheiro_url
        boolean armazenamento_objeto
        boolean acesso_publico
    }

    PROJETO ||--o{ APROVACAO : submete
    PROJETO ||--o{ DOCUMENTO : anexa
    UTILIZADOR ||--o{ APROVACAO : aprova
    UTILIZADOR ||--o{ LOG : registra
```

---

## Observações

- Todas as tabelas com geometria possuem índice espacial GIST no PostGIS.
- As tabelas `PARCELA`, `ZONA`, `DIVISAO_ADMINISTRATIVA` e outras utilizam campos gerados automaticamente para área, perímetro e centroide.
- O campo `tipo` da `DIVISAO_ADMINISTRATIVA` é um ENUM que permite representar tanto a estrutura urbana quanto a rural de Moçambique.
- A auditoria é feita por triggers nas tabelas principais, populando `audit.log`.
- O versionamento de geometrias é guardado em `territorial.geometria_historico`.
