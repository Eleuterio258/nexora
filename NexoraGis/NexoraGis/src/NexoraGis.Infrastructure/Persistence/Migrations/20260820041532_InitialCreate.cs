using System;
using System.Collections.Generic;
using System.Net;
using Microsoft.EntityFrameworkCore.Migrations;
using NetTopologySuite.Geometries;

#nullable disable

namespace NexoraGis.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "workflow");

            migrationBuilder.EnsureSchema(
                name: "gis");

            migrationBuilder.EnsureSchema(
                name: "cadastro");

            migrationBuilder.EnsureSchema(
                name: "territorial");

            migrationBuilder.EnsureSchema(
                name: "audit");

            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:PostgresExtension:pgcrypto", ",,")
                .Annotation("Npgsql:PostgresExtension:postgis", ",,")
                .Annotation("Npgsql:PostgresExtension:uuid-ossp", ",,");

            migrationBuilder.CreateTable(
                name: "divisao_administrativa",
                schema: "territorial",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    parent_id = table.Column<Guid>(type: "uuid", nullable: true),
                    tipo = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    codigo = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    nome = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    nome_normalizado = table.Column<string>(type: "text", nullable: true),
                    zona_urbana = table.Column<bool>(type: "boolean", nullable: true),
                    nivel_hierarquico = table.Column<int>(type: "integer", nullable: false),
                    entidade_responsavel = table.Column<string>(type: "text", nullable: true),
                    codigo_ine = table.Column<string>(type: "text", nullable: true),
                    geometria = table.Column<MultiPolygon>(type: "geometry(MultiPolygon, 4326)", nullable: true),
                    area_calculada = table.Column<decimal>(type: "numeric", nullable: true, computedColumnSql: "CASE WHEN geometria IS NOT NULL THEN ST_Area(geometria::geography) / 10000 ELSE NULL END", stored: true),
                    centroide = table.Column<Point>(type: "geometry(Point, 4326)", nullable: true, computedColumnSql: "CASE WHEN geometria IS NOT NULL THEN ST_Centroid(geometria) END", stored: true),
                    ativo = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    metadados = table.Column<string>(type: "jsonb", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_divisao_administrativa", x => x.id);
                    table.ForeignKey(
                        name: "fk_divisao_administrativa_divisao_administrativa_parent_id",
                        column: x => x.parent_id,
                        principalSchema: "territorial",
                        principalTable: "divisao_administrativa",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "entidade",
                schema: "cadastro",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    tipo = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    nome = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    documento_identificacao = table.Column<string>(type: "text", nullable: true),
                    nuit = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    morada = table.Column<string>(type: "text", nullable: true),
                    telefone = table.Column<string>(type: "text", nullable: true),
                    email = table.Column<string>(type: "text", nullable: true),
                    dados_pessoais = table.Column<bool>(type: "boolean", nullable: false),
                    acesso_publico = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_entidade", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "permissao",
                schema: "territorial",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    perfil = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    recurso = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    acao = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ativo = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_permissao", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "organizacao",
                schema: "territorial",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    codigo = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    designacao = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    tipo = table.Column<string>(type: "text", nullable: false),
                    nif = table.Column<string>(type: "text", nullable: true),
                    email = table.Column<string>(type: "text", nullable: true),
                    telefone = table.Column<string>(type: "text", nullable: true),
                    endereco = table.Column<string>(type: "text", nullable: true),
                    divisao_administrativa_id = table.Column<Guid>(type: "uuid", nullable: true),
                    ativo = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_organizacao", x => x.id);
                    table.ForeignKey(
                        name: "fk_organizacao_divisao_administrativa_divisao_administrativa_id",
                        column: x => x.divisao_administrativa_id,
                        principalSchema: "territorial",
                        principalTable: "divisao_administrativa",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "utilizador",
                schema: "territorial",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    organizacao_id = table.Column<Guid>(type: "uuid", nullable: false),
                    username = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    email = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    password_hash = table.Column<string>(type: "text", nullable: false),
                    nome_completo = table.Column<string>(type: "text", nullable: false),
                    perfil = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    telefone = table.Column<string>(type: "text", nullable: true),
                    ativo = table.Column<bool>(type: "boolean", nullable: false),
                    ultimo_acesso = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_utilizador", x => x.id);
                    table.ForeignKey(
                        name: "fk_utilizador_organizacao_organizacao_id",
                        column: x => x.organizacao_id,
                        principalSchema: "territorial",
                        principalTable: "organizacao",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "projeto",
                schema: "territorial",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    organizacao_id = table.Column<Guid>(type: "uuid", nullable: false),
                    codigo = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    designacao = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    descricao = table.Column<string>(type: "text", nullable: true),
                    cliente = table.Column<string>(type: "text", nullable: true),
                    tipo = table.Column<string>(type: "text", nullable: false),
                    localizacao = table.Column<string>(type: "text", nullable: true),
                    divisao_administrativa_id = table.Column<Guid>(type: "uuid", nullable: true),
                    area_intervencao = table.Column<MultiPolygon>(type: "geometry(MultiPolygon, 4326)", nullable: true),
                    sistema_referencia = table.Column<string>(type: "text", nullable: false),
                    responsavel_tecnico_id = table.Column<Guid>(type: "uuid", nullable: true),
                    data_inicio = table.Column<DateOnly>(type: "date", nullable: true),
                    data_prevista_conclusao = table.Column<DateOnly>(type: "date", nullable: true),
                    status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_projeto", x => x.id);
                    table.ForeignKey(
                        name: "fk_projeto_divisao_administrativa_divisao_administrativa_id",
                        column: x => x.divisao_administrativa_id,
                        principalSchema: "territorial",
                        principalTable: "divisao_administrativa",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_projeto_organizacao_organizacao_id",
                        column: x => x.organizacao_id,
                        principalSchema: "territorial",
                        principalTable: "organizacao",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_projeto_utilizadores_created_by",
                        column: x => x.created_by,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_projeto_utilizadores_responsavel_tecnico_id",
                        column: x => x.responsavel_tecnico_id,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "refresh_token",
                schema: "territorial",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    utilizador_id = table.Column<Guid>(type: "uuid", nullable: false),
                    token_hash = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    expires_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    revoked_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    replaced_by_token_hash = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_refresh_token", x => x.id);
                    table.ForeignKey(
                        name: "fk_refresh_token_utilizadores_utilizador_id",
                        column: x => x.utilizador_id,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "aprovacao",
                schema: "workflow",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    entidade_tipo = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    entidade_id = table.Column<Guid>(type: "uuid", nullable: false),
                    projeto_id = table.Column<Guid>(type: "uuid", nullable: false),
                    status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    requisitado_por = table.Column<Guid>(type: "uuid", nullable: true),
                    verificado_por = table.Column<Guid>(type: "uuid", nullable: true),
                    aprovado_por = table.Column<Guid>(type: "uuid", nullable: true),
                    data_submissao = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    data_analise = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    data_aprovacao = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    data_publicacao = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    motivo_rejeicao = table.Column<string>(type: "text", nullable: true),
                    observacoes = table.Column<string>(type: "text", nullable: true),
                    versao = table.Column<int>(type: "integer", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_aprovacao", x => x.id);
                    table.ForeignKey(
                        name: "fk_aprovacao_projetos_projeto_id",
                        column: x => x.projeto_id,
                        principalSchema: "territorial",
                        principalTable: "projeto",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_aprovacao_utilizadores_aprovado_por",
                        column: x => x.aprovado_por,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_aprovacao_utilizadores_requisitado_por",
                        column: x => x.requisitado_por,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_aprovacao_utilizadores_verificado_por",
                        column: x => x.verificado_por,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "camada",
                schema: "gis",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    projeto_id = table.Column<Guid>(type: "uuid", nullable: true),
                    nome = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    tipo = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    tabela_fonte = table.Column<string>(type: "text", nullable: true),
                    coluna_geometria = table.Column<string>(type: "text", nullable: false),
                    estilo = table.Column<string>(type: "jsonb", nullable: true),
                    metadados = table.Column<string>(type: "jsonb", nullable: true),
                    responsavel_id = table.Column<Guid>(type: "uuid", nullable: true),
                    fonte = table.Column<string>(type: "text", nullable: true),
                    data_atualizacao = table.Column<DateOnly>(type: "date", nullable: true),
                    sistema_coordenadas = table.Column<string>(type: "text", nullable: false),
                    versao = table.Column<string>(type: "text", nullable: false),
                    visivel = table.Column<bool>(type: "boolean", nullable: false),
                    publica = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_camada", x => x.id);
                    table.ForeignKey(
                        name: "fk_camada_projetos_projeto_id",
                        column: x => x.projeto_id,
                        principalSchema: "territorial",
                        principalTable: "projeto",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_camada_utilizadores_responsavel_id",
                        column: x => x.responsavel_id,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "condicionante",
                schema: "cadastro",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    projeto_id = table.Column<Guid>(type: "uuid", nullable: false),
                    tipo = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    designacao = table.Column<string>(type: "text", nullable: true),
                    descricao = table.Column<string>(type: "text", nullable: true),
                    geometria = table.Column<Geometry>(type: "geometry(Geometry, 4326)", nullable: true),
                    buffer_metros = table.Column<decimal>(type: "numeric", nullable: true),
                    restritivo = table.Column<bool>(type: "boolean", nullable: false),
                    atributos = table.Column<string>(type: "jsonb", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_condicionante", x => x.id);
                    table.ForeignKey(
                        name: "fk_condicionante_projetos_projeto_id",
                        column: x => x.projeto_id,
                        principalSchema: "territorial",
                        principalTable: "projeto",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "conflito",
                schema: "territorial",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    projeto_id = table.Column<Guid>(type: "uuid", nullable: false),
                    tipo = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    descricao = table.Column<string>(type: "text", nullable: false),
                    entidade_tipo = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    entidade_id = table.Column<Guid>(type: "uuid", nullable: true),
                    geometria = table.Column<Geometry>(type: "geometry(Geometry, 4326)", nullable: true),
                    detalhes = table.Column<string>(type: "jsonb", nullable: true),
                    resolvido = table.Column<bool>(type: "boolean", nullable: false),
                    data_detecao = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    data_resolucao = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    resolvido_por = table.Column<Guid>(type: "uuid", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_conflito", x => x.id);
                    table.ForeignKey(
                        name: "fk_conflito_projetos_projeto_id",
                        column: x => x.projeto_id,
                        principalSchema: "territorial",
                        principalTable: "projeto",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_conflito_utilizadores_resolvido_por",
                        column: x => x.resolvido_por,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "documento",
                schema: "cadastro",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    projeto_id = table.Column<Guid>(type: "uuid", nullable: true),
                    tipo = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    titulo = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    descricao = table.Column<string>(type: "text", nullable: true),
                    entidade_tipo = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    entidade_id = table.Column<Guid>(type: "uuid", nullable: true),
                    ficheiro_url = table.Column<string>(type: "text", nullable: true),
                    ficheiro_nome = table.Column<string>(type: "text", nullable: true),
                    ficheiro_tamanho = table.Column<long>(type: "bigint", nullable: true),
                    ficheiro_hash = table.Column<string>(type: "text", nullable: true),
                    mime_type = table.Column<string>(type: "text", nullable: true),
                    armazenamento_objeto = table.Column<bool>(type: "boolean", nullable: false),
                    acesso_publico = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_documento", x => x.id);
                    table.ForeignKey(
                        name: "fk_documento_projetos_projeto_id",
                        column: x => x.projeto_id,
                        principalSchema: "territorial",
                        principalTable: "projeto",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_documento_utilizadores_created_by",
                        column: x => x.created_by,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "equipamento",
                schema: "cadastro",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    projeto_id = table.Column<Guid>(type: "uuid", nullable: false),
                    tipo = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    codigo = table.Column<string>(type: "text", nullable: true),
                    nome = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    geometria = table.Column<Point>(type: "geometry(Point, 4326)", nullable: true),
                    morada = table.Column<string>(type: "text", nullable: true),
                    contacto = table.Column<string>(type: "text", nullable: true),
                    horario_funcionamento = table.Column<string>(type: "text", nullable: true),
                    capacidade = table.Column<int>(type: "integer", nullable: true),
                    atributos = table.Column<string>(type: "jsonb", nullable: true),
                    ativo = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_equipamento", x => x.id);
                    table.ForeignKey(
                        name: "fk_equipamento_projetos_projeto_id",
                        column: x => x.projeto_id,
                        principalSchema: "territorial",
                        principalTable: "projeto",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "infraestrutura",
                schema: "cadastro",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    projeto_id = table.Column<Guid>(type: "uuid", nullable: false),
                    tipo = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    subtipo = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    codigo = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    designacao = table.Column<string>(type: "text", nullable: true),
                    geometria = table.Column<Geometry>(type: "geometry(Geometry, 4326)", nullable: true),
                    atributos = table.Column<string>(type: "jsonb", nullable: true),
                    estado_conservacao = table.Column<string>(type: "text", nullable: true),
                    data_levantamento = table.Column<DateOnly>(type: "date", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_infraestrutura", x => x.id);
                    table.ForeignKey(
                        name: "fk_infraestrutura_projetos_projeto_id",
                        column: x => x.projeto_id,
                        principalSchema: "territorial",
                        principalTable: "projeto",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "levantamento",
                schema: "cadastro",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    projeto_id = table.Column<Guid>(type: "uuid", nullable: false),
                    codigo = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    designacao = table.Column<string>(type: "text", nullable: true),
                    responsavel_id = table.Column<Guid>(type: "uuid", nullable: true),
                    tipo = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    equipamento_utilizado = table.Column<string>(type: "text", nullable: true),
                    metodo = table.Column<string>(type: "text", nullable: true),
                    data_inicio = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    data_fim = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    status = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    observacoes = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_levantamento", x => x.id);
                    table.ForeignKey(
                        name: "fk_levantamento_projetos_projeto_id",
                        column: x => x.projeto_id,
                        principalSchema: "territorial",
                        principalTable: "projeto",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_levantamento_utilizadores_responsavel_id",
                        column: x => x.responsavel_id,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "log",
                schema: "audit",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    utilizador_id = table.Column<Guid>(type: "uuid", nullable: true),
                    utilizador_nome = table.Column<string>(type: "text", nullable: true),
                    operacao = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    entidade_tipo = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    entidade_id = table.Column<Guid>(type: "uuid", nullable: true),
                    projeto_id = table.Column<Guid>(type: "uuid", nullable: true),
                    dados_anteriores = table.Column<string>(type: "jsonb", nullable: true),
                    dados_novos = table.Column<string>(type: "jsonb", nullable: true),
                    ip_address = table.Column<IPAddress>(type: "inet", nullable: true),
                    data_hora = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_log", x => x.id);
                    table.ForeignKey(
                        name: "fk_log_projetos_projeto_id",
                        column: x => x.projeto_id,
                        principalSchema: "territorial",
                        principalTable: "projeto",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_log_utilizadores_utilizador_id",
                        column: x => x.utilizador_id,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "parcela",
                schema: "cadastro",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    projeto_id = table.Column<Guid>(type: "uuid", nullable: false),
                    codigo_cadastral = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    numero_parcela = table.Column<string>(type: "text", nullable: true),
                    numero_talhao = table.Column<string>(type: "text", nullable: true),
                    divisao_administrativa_id = table.Column<Guid>(type: "uuid", nullable: true),
                    geometria = table.Column<MultiPolygon>(type: "geometry(MultiPolygon, 4326)", nullable: false),
                    centroide = table.Column<Point>(type: "geometry(Point, 4326)", nullable: true, computedColumnSql: "ST_Centroid(geometria)", stored: true),
                    area_calculada = table.Column<decimal>(type: "numeric", nullable: true, computedColumnSql: "ST_Area(geometria::geography)", stored: true),
                    perimetro = table.Column<decimal>(type: "numeric", nullable: true, computedColumnSql: "ST_Perimeter(geometria::geography)", stored: true),
                    sistema_coordenadas = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    precisao_levantamento = table.Column<decimal>(type: "numeric", nullable: true),
                    situacao = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    uso_atual = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    uso_previsto = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    classificacao_plano = table.Column<string>(type: "text", nullable: true),
                    parametros_urbanisticos = table.Column<string>(type: "jsonb", nullable: true),
                    restricoes = table.Column<string>(type: "text", nullable: true),
                    condicionantes = table.Column<string>(type: "text", nullable: true),
                    estado = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    versao = table.Column<int>(type: "integer", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_parcela", x => x.id);
                    table.ForeignKey(
                        name: "fk_parcela_divisao_administrativa_divisao_administrativa_id",
                        column: x => x.divisao_administrativa_id,
                        principalSchema: "territorial",
                        principalTable: "divisao_administrativa",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_parcela_projetos_projeto_id",
                        column: x => x.projeto_id,
                        principalSchema: "territorial",
                        principalTable: "projeto",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_parcela_utilizadores_created_by",
                        column: x => x.created_by,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_parcela_utilizadores_updated_by",
                        column: x => x.updated_by,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "plano",
                schema: "territorial",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    projeto_id = table.Column<Guid>(type: "uuid", nullable: false),
                    codigo = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    designacao = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    versao = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    data_aprovacao = table.Column<DateOnly>(type: "date", nullable: true),
                    data_publicacao = table.Column<DateOnly>(type: "date", nullable: true),
                    ativo = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_plano", x => x.id);
                    table.ForeignKey(
                        name: "fk_plano_projetos_projeto_id",
                        column: x => x.projeto_id,
                        principalSchema: "territorial",
                        principalTable: "projeto",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "projeto_equipa",
                schema: "territorial",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    projeto_id = table.Column<Guid>(type: "uuid", nullable: false),
                    utilizador_id = table.Column<Guid>(type: "uuid", nullable: false),
                    funcao = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    ativo = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_projeto_equipa", x => x.id);
                    table.ForeignKey(
                        name: "fk_projeto_equipa_projeto_projeto_id",
                        column: x => x.projeto_id,
                        principalSchema: "territorial",
                        principalTable: "projeto",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_projeto_equipa_utilizadores_utilizador_id",
                        column: x => x.utilizador_id,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "geometria_historico",
                schema: "territorial",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    entidade_tipo = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    entidade_id = table.Column<Guid>(type: "uuid", nullable: false),
                    projeto_id = table.Column<Guid>(type: "uuid", nullable: true),
                    geometria_anterior = table.Column<Geometry>(type: "geometry(Geometry, 4326)", nullable: true),
                    geometria_nova = table.Column<Geometry>(type: "geometry(Geometry, 4326)", nullable: true),
                    utilizador_id = table.Column<Guid>(type: "uuid", nullable: true),
                    data_alteracao = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    motivo = table.Column<string>(type: "text", nullable: true),
                    versao_anterior = table.Column<int>(type: "integer", nullable: true),
                    versao_nova = table.Column<int>(type: "integer", nullable: true),
                    aprovacao_id = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_geometria_historico", x => x.id);
                    table.ForeignKey(
                        name: "fk_geometria_historico_aprovacao_aprovacao_id",
                        column: x => x.aprovacao_id,
                        principalSchema: "workflow",
                        principalTable: "aprovacao",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_geometria_historico_projetos_projeto_id",
                        column: x => x.projeto_id,
                        principalSchema: "territorial",
                        principalTable: "projeto",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_geometria_historico_utilizadores_utilizador_id",
                        column: x => x.utilizador_id,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ponto_levantamento",
                schema: "cadastro",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    levantamento_id = table.Column<Guid>(type: "uuid", nullable: false),
                    codigo = table.Column<string>(type: "text", nullable: true),
                    geometria = table.Column<Point>(type: "geometry(Point, 4326)", nullable: false),
                    altitude = table.Column<decimal>(type: "numeric", nullable: true),
                    precisao_horizontal = table.Column<decimal>(type: "numeric", nullable: true),
                    precisao_vertical = table.Column<decimal>(type: "numeric", nullable: true),
                    latitude = table.Column<decimal>(type: "numeric", nullable: true),
                    longitude = table.Column<decimal>(type: "numeric", nullable: true),
                    sistema_referencia = table.Column<string>(type: "text", nullable: true),
                    operador = table.Column<string>(type: "text", nullable: true),
                    data_hora = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    fotografias = table.Column<List<string>>(type: "text[]", nullable: false),
                    observacoes = table.Column<string>(type: "text", nullable: true),
                    sincronizado = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_ponto_levantamento", x => x.id);
                    table.ForeignKey(
                        name: "fk_ponto_levantamento_levantamento_levantamento_id",
                        column: x => x.levantamento_id,
                        principalSchema: "cadastro",
                        principalTable: "levantamento",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "edificacao",
                schema: "cadastro",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    parcela_id = table.Column<Guid>(type: "uuid", nullable: false),
                    codigo = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    localizacao = table.Column<string>(type: "text", nullable: true),
                    geometria = table.Column<MultiPolygon>(type: "geometry(MultiPolygon, 4326)", nullable: true),
                    area_construida = table.Column<decimal>(type: "numeric", nullable: true),
                    numero_pisos = table.Column<int>(type: "integer", nullable: true),
                    tipo_construcao = table.Column<string>(type: "text", nullable: true),
                    finalidade = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    material_predominante = table.Column<string>(type: "text", nullable: true),
                    estado_conservacao = table.Column<string>(type: "text", nullable: true),
                    situacao_ocupacao = table.Column<string>(type: "text", nullable: true),
                    fotografias = table.Column<List<string>>(type: "text[]", nullable: false),
                    coordenadas = table.Column<Point>(type: "geometry(Point, 4326)", nullable: true),
                    data_levantamento = table.Column<DateOnly>(type: "date", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_edificacao", x => x.id);
                    table.ForeignKey(
                        name: "fk_edificacao_parcelas_parcela_id",
                        column: x => x.parcela_id,
                        principalSchema: "cadastro",
                        principalTable: "parcela",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "fiscalizacao",
                schema: "territorial",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    projeto_id = table.Column<Guid>(type: "uuid", nullable: false),
                    parcela_id = table.Column<Guid>(type: "uuid", nullable: true),
                    fiscal_id = table.Column<Guid>(type: "uuid", nullable: true),
                    data_ocorrencia = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    coordenadas = table.Column<Point>(type: "geometry(Point, 4326)", nullable: true),
                    descricao = table.Column<string>(type: "text", nullable: false),
                    fotografias = table.Column<List<string>>(type: "text[]", nullable: false),
                    estado = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    acao_necessaria = table.Column<string>(type: "text", nullable: true),
                    responsavel = table.Column<Guid>(type: "uuid", nullable: true),
                    data_resolucao = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_fiscalizacao", x => x.id);
                    table.ForeignKey(
                        name: "fk_fiscalizacao_parcelas_parcela_id",
                        column: x => x.parcela_id,
                        principalSchema: "cadastro",
                        principalTable: "parcela",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "fk_fiscalizacao_projetos_projeto_id",
                        column: x => x.projeto_id,
                        principalSchema: "territorial",
                        principalTable: "projeto",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_fiscalizacao_utilizadores_fiscal_id",
                        column: x => x.fiscal_id,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_fiscalizacao_utilizadores_responsavel",
                        column: x => x.responsavel,
                        principalSchema: "territorial",
                        principalTable: "utilizador",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "lote",
                schema: "cadastro",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    parcela_id = table.Column<Guid>(type: "uuid", nullable: false),
                    codigo = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    geometria = table.Column<MultiPolygon>(type: "geometry(MultiPolygon, 4326)", nullable: false),
                    area_calculada = table.Column<decimal>(type: "numeric", nullable: true, computedColumnSql: "ST_Area(geometria::geography)", stored: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_lote", x => x.id);
                    table.ForeignKey(
                        name: "fk_lote_parcelas_parcela_id",
                        column: x => x.parcela_id,
                        principalSchema: "cadastro",
                        principalTable: "parcela",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "parcela_entidade",
                schema: "cadastro",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    parcela_id = table.Column<Guid>(type: "uuid", nullable: false),
                    entidade_id = table.Column<Guid>(type: "uuid", nullable: false),
                    tipo_relacao = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    data_inicio = table.Column<DateOnly>(type: "date", nullable: true),
                    data_fim = table.Column<DateOnly>(type: "date", nullable: true),
                    ativo = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_parcela_entidade", x => x.id);
                    table.ForeignKey(
                        name: "fk_parcela_entidade_entidade_entidade_id",
                        column: x => x.entidade_id,
                        principalSchema: "cadastro",
                        principalTable: "entidade",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_parcela_entidade_parcela_parcela_id",
                        column: x => x.parcela_id,
                        principalSchema: "cadastro",
                        principalTable: "parcela",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "zona",
                schema: "territorial",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    plano_id = table.Column<Guid>(type: "uuid", nullable: false),
                    codigo = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    designacao = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    cor = table.Column<string>(type: "character varying(7)", maxLength: 7, nullable: false),
                    geometria = table.Column<MultiPolygon>(type: "geometry(MultiPolygon, 4326)", nullable: true),
                    parametros = table.Column<string>(type: "jsonb", nullable: true),
                    atividades_permitidas = table.Column<List<string>>(type: "text[]", nullable: false),
                    atividades_condicionadas = table.Column<List<string>>(type: "text[]", nullable: false),
                    atividades_proibidas = table.Column<List<string>>(type: "text[]", nullable: false),
                    area_calculada = table.Column<decimal>(type: "numeric", nullable: true, computedColumnSql: "CASE WHEN geometria IS NOT NULL THEN ST_Area(geometria::geography) / 10000 ELSE NULL END", stored: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_zona", x => x.id);
                    table.ForeignKey(
                        name: "fk_zona_plano_plano_id",
                        column: x => x.plano_id,
                        principalSchema: "territorial",
                        principalTable: "plano",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_aprovacao_aprovado_por",
                schema: "workflow",
                table: "aprovacao",
                column: "aprovado_por");

            migrationBuilder.CreateIndex(
                name: "ix_aprovacao_entidade_tipo_entidade_id",
                schema: "workflow",
                table: "aprovacao",
                columns: new[] { "entidade_tipo", "entidade_id" });

            migrationBuilder.CreateIndex(
                name: "ix_aprovacao_projeto_id",
                schema: "workflow",
                table: "aprovacao",
                column: "projeto_id");

            migrationBuilder.CreateIndex(
                name: "ix_aprovacao_requisitado_por",
                schema: "workflow",
                table: "aprovacao",
                column: "requisitado_por");

            migrationBuilder.CreateIndex(
                name: "ix_aprovacao_verificado_por",
                schema: "workflow",
                table: "aprovacao",
                column: "verificado_por");

            migrationBuilder.CreateIndex(
                name: "ix_camada_projeto_id",
                schema: "gis",
                table: "camada",
                column: "projeto_id");

            migrationBuilder.CreateIndex(
                name: "ix_camada_responsavel_id",
                schema: "gis",
                table: "camada",
                column: "responsavel_id");

            migrationBuilder.CreateIndex(
                name: "ix_condicionante_geometria",
                schema: "cadastro",
                table: "condicionante",
                column: "geometria")
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "ix_condicionante_projeto_id",
                schema: "cadastro",
                table: "condicionante",
                column: "projeto_id");

            migrationBuilder.CreateIndex(
                name: "ix_conflito_geometria",
                schema: "territorial",
                table: "conflito",
                column: "geometria")
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "ix_conflito_projeto_id",
                schema: "territorial",
                table: "conflito",
                column: "projeto_id");

            migrationBuilder.CreateIndex(
                name: "ix_conflito_resolvido_por",
                schema: "territorial",
                table: "conflito",
                column: "resolvido_por");

            migrationBuilder.CreateIndex(
                name: "ix_divisao_administrativa_codigo",
                schema: "territorial",
                table: "divisao_administrativa",
                column: "codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_divisao_administrativa_codigo_ine",
                schema: "territorial",
                table: "divisao_administrativa",
                column: "codigo_ine");

            migrationBuilder.CreateIndex(
                name: "ix_divisao_administrativa_geometria",
                schema: "territorial",
                table: "divisao_administrativa",
                column: "geometria")
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "ix_divisao_administrativa_parent_id",
                schema: "territorial",
                table: "divisao_administrativa",
                column: "parent_id");

            migrationBuilder.CreateIndex(
                name: "ix_divisao_administrativa_tipo",
                schema: "territorial",
                table: "divisao_administrativa",
                column: "tipo");

            migrationBuilder.CreateIndex(
                name: "ix_divisao_administrativa_zona_urbana",
                schema: "territorial",
                table: "divisao_administrativa",
                column: "zona_urbana");

            migrationBuilder.CreateIndex(
                name: "ix_documento_created_by",
                schema: "cadastro",
                table: "documento",
                column: "created_by");

            migrationBuilder.CreateIndex(
                name: "ix_documento_entidade_tipo_entidade_id",
                schema: "cadastro",
                table: "documento",
                columns: new[] { "entidade_tipo", "entidade_id" });

            migrationBuilder.CreateIndex(
                name: "ix_documento_projeto_id",
                schema: "cadastro",
                table: "documento",
                column: "projeto_id");

            migrationBuilder.CreateIndex(
                name: "ix_edificacao_geometria",
                schema: "cadastro",
                table: "edificacao",
                column: "geometria")
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "ix_edificacao_parcela_id_codigo",
                schema: "cadastro",
                table: "edificacao",
                columns: new[] { "parcela_id", "codigo" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_equipamento_geometria",
                schema: "cadastro",
                table: "equipamento",
                column: "geometria")
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "ix_equipamento_projeto_id",
                schema: "cadastro",
                table: "equipamento",
                column: "projeto_id");

            migrationBuilder.CreateIndex(
                name: "ix_fiscalizacao_coordenadas",
                schema: "territorial",
                table: "fiscalizacao",
                column: "coordenadas")
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "ix_fiscalizacao_fiscal_id",
                schema: "territorial",
                table: "fiscalizacao",
                column: "fiscal_id");

            migrationBuilder.CreateIndex(
                name: "ix_fiscalizacao_parcela_id",
                schema: "territorial",
                table: "fiscalizacao",
                column: "parcela_id");

            migrationBuilder.CreateIndex(
                name: "ix_fiscalizacao_projeto_id",
                schema: "territorial",
                table: "fiscalizacao",
                column: "projeto_id");

            migrationBuilder.CreateIndex(
                name: "ix_fiscalizacao_responsavel",
                schema: "territorial",
                table: "fiscalizacao",
                column: "responsavel");

            migrationBuilder.CreateIndex(
                name: "ix_geometria_historico_aprovacao_id",
                schema: "territorial",
                table: "geometria_historico",
                column: "aprovacao_id");

            migrationBuilder.CreateIndex(
                name: "ix_geometria_historico_entidade_tipo_entidade_id",
                schema: "territorial",
                table: "geometria_historico",
                columns: new[] { "entidade_tipo", "entidade_id" });

            migrationBuilder.CreateIndex(
                name: "ix_geometria_historico_projeto_id",
                schema: "territorial",
                table: "geometria_historico",
                column: "projeto_id");

            migrationBuilder.CreateIndex(
                name: "ix_geometria_historico_utilizador_id",
                schema: "territorial",
                table: "geometria_historico",
                column: "utilizador_id");

            migrationBuilder.CreateIndex(
                name: "ix_infraestrutura_geometria",
                schema: "cadastro",
                table: "infraestrutura",
                column: "geometria")
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "ix_infraestrutura_projeto_id_tipo",
                schema: "cadastro",
                table: "infraestrutura",
                columns: new[] { "projeto_id", "tipo" });

            migrationBuilder.CreateIndex(
                name: "ix_levantamento_codigo",
                schema: "cadastro",
                table: "levantamento",
                column: "codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_levantamento_projeto_id",
                schema: "cadastro",
                table: "levantamento",
                column: "projeto_id");

            migrationBuilder.CreateIndex(
                name: "ix_levantamento_responsavel_id",
                schema: "cadastro",
                table: "levantamento",
                column: "responsavel_id");

            migrationBuilder.CreateIndex(
                name: "ix_log_data_hora",
                schema: "audit",
                table: "log",
                column: "data_hora");

            migrationBuilder.CreateIndex(
                name: "ix_log_entidade_tipo_entidade_id",
                schema: "audit",
                table: "log",
                columns: new[] { "entidade_tipo", "entidade_id" });

            migrationBuilder.CreateIndex(
                name: "ix_log_projeto_id",
                schema: "audit",
                table: "log",
                column: "projeto_id");

            migrationBuilder.CreateIndex(
                name: "ix_log_utilizador_id",
                schema: "audit",
                table: "log",
                column: "utilizador_id");

            migrationBuilder.CreateIndex(
                name: "ix_lote_geometria",
                schema: "cadastro",
                table: "lote",
                column: "geometria")
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "ix_lote_parcela_id_codigo",
                schema: "cadastro",
                table: "lote",
                columns: new[] { "parcela_id", "codigo" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_organizacao_codigo",
                schema: "territorial",
                table: "organizacao",
                column: "codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_organizacao_divisao_administrativa_id",
                schema: "territorial",
                table: "organizacao",
                column: "divisao_administrativa_id");

            migrationBuilder.CreateIndex(
                name: "ix_parcela_codigo_cadastral",
                schema: "cadastro",
                table: "parcela",
                column: "codigo_cadastral",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_parcela_created_by",
                schema: "cadastro",
                table: "parcela",
                column: "created_by");

            migrationBuilder.CreateIndex(
                name: "ix_parcela_divisao_administrativa_id",
                schema: "cadastro",
                table: "parcela",
                column: "divisao_administrativa_id");

            migrationBuilder.CreateIndex(
                name: "ix_parcela_geometria",
                schema: "cadastro",
                table: "parcela",
                column: "geometria")
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "ix_parcela_projeto_id",
                schema: "cadastro",
                table: "parcela",
                column: "projeto_id");

            migrationBuilder.CreateIndex(
                name: "ix_parcela_updated_by",
                schema: "cadastro",
                table: "parcela",
                column: "updated_by");

            migrationBuilder.CreateIndex(
                name: "ix_parcela_entidade_entidade_id",
                schema: "cadastro",
                table: "parcela_entidade",
                column: "entidade_id");

            migrationBuilder.CreateIndex(
                name: "ix_parcela_entidade_parcela_id_entidade_id_tipo_relacao_ativo",
                schema: "cadastro",
                table: "parcela_entidade",
                columns: new[] { "parcela_id", "entidade_id", "tipo_relacao", "ativo" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_permissao_perfil_recurso_acao",
                schema: "territorial",
                table: "permissao",
                columns: new[] { "perfil", "recurso", "acao" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_plano_projeto_id_codigo_versao",
                schema: "territorial",
                table: "plano",
                columns: new[] { "projeto_id", "codigo", "versao" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_ponto_levantamento_geometria",
                schema: "cadastro",
                table: "ponto_levantamento",
                column: "geometria")
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "ix_ponto_levantamento_levantamento_id",
                schema: "cadastro",
                table: "ponto_levantamento",
                column: "levantamento_id");

            migrationBuilder.CreateIndex(
                name: "ix_projeto_area_intervencao",
                schema: "territorial",
                table: "projeto",
                column: "area_intervencao")
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "ix_projeto_codigo",
                schema: "territorial",
                table: "projeto",
                column: "codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_projeto_created_by",
                schema: "territorial",
                table: "projeto",
                column: "created_by");

            migrationBuilder.CreateIndex(
                name: "ix_projeto_divisao_administrativa_id",
                schema: "territorial",
                table: "projeto",
                column: "divisao_administrativa_id");

            migrationBuilder.CreateIndex(
                name: "ix_projeto_organizacao_id",
                schema: "territorial",
                table: "projeto",
                column: "organizacao_id");

            migrationBuilder.CreateIndex(
                name: "ix_projeto_responsavel_tecnico_id",
                schema: "territorial",
                table: "projeto",
                column: "responsavel_tecnico_id");

            migrationBuilder.CreateIndex(
                name: "ix_projeto_equipa_projeto_id_utilizador_id",
                schema: "territorial",
                table: "projeto_equipa",
                columns: new[] { "projeto_id", "utilizador_id" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_projeto_equipa_utilizador_id",
                schema: "territorial",
                table: "projeto_equipa",
                column: "utilizador_id");

            migrationBuilder.CreateIndex(
                name: "ix_refresh_token_token_hash",
                schema: "territorial",
                table: "refresh_token",
                column: "token_hash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_refresh_token_utilizador_id",
                schema: "territorial",
                table: "refresh_token",
                column: "utilizador_id");

            migrationBuilder.CreateIndex(
                name: "ix_utilizador_email",
                schema: "territorial",
                table: "utilizador",
                column: "email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_utilizador_organizacao_id",
                schema: "territorial",
                table: "utilizador",
                column: "organizacao_id");

            migrationBuilder.CreateIndex(
                name: "ix_utilizador_username",
                schema: "territorial",
                table: "utilizador",
                column: "username",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_zona_geometria",
                schema: "territorial",
                table: "zona",
                column: "geometria")
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "ix_zona_plano_id_codigo",
                schema: "territorial",
                table: "zona",
                columns: new[] { "plano_id", "codigo" },
                unique: true);

            migrationBuilder.Sql("""
                -- View hierárquica completa da divisão administrativa
                CREATE OR REPLACE VIEW territorial.vw_divisao_hierarquia AS
                WITH RECURSIVE hierarquia AS (
                    SELECT
                        id, parent_id, tipo, codigo, nome, zona_urbana, nivel_hierarquico,
                        ARRAY[nome]::TEXT[] AS caminho,
                        ARRAY[tipo]::TEXT[] AS tipos_caminho,
                        id::TEXT AS caminho_ids
                    FROM territorial.divisao_administrativa
                    WHERE parent_id IS NULL
                    UNION ALL
                    SELECT
                        d.id, d.parent_id, d.tipo, d.codigo, d.nome, d.zona_urbana, d.nivel_hierarquico,
                        h.caminho || d.nome,
                        h.tipos_caminho || d.tipo,
                        h.caminho_ids || ' > ' || d.id::TEXT
                    FROM territorial.divisao_administrativa d
                    INNER JOIN hierarquia h ON d.parent_id = h.id
                )
                SELECT id, parent_id, tipo, codigo, nome, zona_urbana, nivel_hierarquico,
                    array_to_string(caminho, ' > ') AS hierarquia_nomes,
                    array_to_string(tipos_caminho, ' > ') AS hierarquia_tipos,
                    caminho_ids
                FROM hierarquia;

                -- Divisões filhas de um determinado tipo dentro de um território
                CREATE OR REPLACE FUNCTION territorial.filhos_por_tipo(pai_id UUID, p_tipo TEXT)
                RETURNS TABLE(id UUID, codigo VARCHAR, nome VARCHAR, tipo VARCHAR) AS $$
                BEGIN
                    RETURN QUERY
                    WITH RECURSIVE arvore AS (
                        SELECT d.id, d.parent_id, d.codigo, d.nome, d.tipo
                        FROM territorial.divisao_administrativa d
                        WHERE d.id = pai_id
                        UNION ALL
                        SELECT d.id, d.parent_id, d.codigo, d.nome, d.tipo
                        FROM territorial.divisao_administrativa d
                        INNER JOIN arvore a ON d.parent_id = a.id
                    )
                    SELECT a.id, a.codigo, a.nome, a.tipo
                    FROM arvore a
                    WHERE a.tipo = p_tipo AND a.id <> pai_id;
                END;
                $$ LANGUAGE plpgsql STABLE;

                -- Área em hectares a partir de uma geometria
                CREATE OR REPLACE FUNCTION territorial.area_hectares(geom GEOMETRY)
                RETURNS NUMERIC AS $$
                BEGIN
                    RETURN ROUND((ST_Area(geom::geography) / 10000)::NUMERIC, 4);
                END;
                $$ LANGUAGE plpgsql IMMUTABLE;

                -- Caminho hierárquico textual de uma divisão administrativa
                CREATE OR REPLACE FUNCTION territorial.hierarquia_divisao(p_id UUID)
                RETURNS TEXT AS $$
                DECLARE
                    v_nome TEXT;
                    v_pai UUID;
                    v_tipo TEXT;
                    v_caminho TEXT;
                BEGIN
                    SELECT nome, parent_id, tipo INTO v_nome, v_pai, v_tipo
                    FROM territorial.divisao_administrativa WHERE id = p_id;

                    v_caminho := v_tipo || ':' || v_nome;

                    WHILE v_pai IS NOT NULL LOOP
                        SELECT nome, parent_id, tipo INTO v_nome, v_pai, v_tipo
                        FROM territorial.divisao_administrativa WHERE id = v_pai;
                        v_caminho := v_tipo || ':' || v_nome || ' > ' || v_caminho;
                    END LOOP;

                    RETURN v_caminho;
                END;
                $$ LANGUAGE plpgsql STABLE;

                -- Deteção simples de conflito de uso (atual vs. previsto) numa parcela
                CREATE OR REPLACE FUNCTION territorial.detectar_conflito_uso(parcela_uuid UUID)
                RETURNS TABLE(tipo TEXT, descricao TEXT) AS $$
                DECLARE
                    p_uso_atual TEXT;
                    p_uso_previsto TEXT;
                    p_geom GEOMETRY;
                    p_codigo VARCHAR;
                BEGIN
                    SELECT uso_atual, uso_previsto, geometria, codigo_cadastral
                    INTO p_uso_atual, p_uso_previsto, p_geom, p_codigo
                    FROM cadastro.parcela WHERE id = parcela_uuid;

                    IF p_uso_atual IS DISTINCT FROM p_uso_previsto AND p_uso_previsto IS NOT NULL THEN
                        RETURN QUERY SELECT 'uso_incompativel'::TEXT,
                            format('Parcela %s: uso atual (%s) difere do previsto (%s)', p_codigo, p_uso_atual, p_uso_previsto)::TEXT;
                    END IF;

                    RETURN;
                END;
                $$ LANGUAGE plpgsql STABLE;

                -- Auditoria automática por trigger nas tabelas mais sensíveis
                CREATE OR REPLACE FUNCTION audit.log_changes()
                RETURNS TRIGGER AS $$
                DECLARE
                    v_dados_anteriores JSONB;
                    v_dados_novos JSONB;
                    v_operacao TEXT;
                BEGIN
                    IF TG_OP = 'INSERT' THEN
                        v_operacao := 'create';
                        v_dados_novos := to_jsonb(NEW);
                    ELSIF TG_OP = 'UPDATE' THEN
                        v_operacao := 'update';
                        v_dados_anteriores := to_jsonb(OLD);
                        v_dados_novos := to_jsonb(NEW);
                        IF OLD.geometria IS DISTINCT FROM NEW.geometria THEN
                            v_operacao := 'alteracao_geometria';
                        END IF;
                    ELSIF TG_OP = 'DELETE' THEN
                        v_operacao := 'delete';
                        v_dados_anteriores := to_jsonb(OLD);
                    END IF;

                    INSERT INTO audit.log (operacao, entidade_tipo, entidade_id, dados_anteriores, dados_novos)
                    VALUES (v_operacao, TG_TABLE_NAME, COALESCE(NEW.id, OLD.id), v_dados_anteriores, v_dados_novos);

                    IF TG_OP = 'DELETE' THEN
                        RETURN OLD;
                    ELSE
                        RETURN NEW;
                    END IF;
                END;
                $$ LANGUAGE plpgsql;

                CREATE TRIGGER trg_audit_parcela
                AFTER INSERT OR UPDATE OR DELETE ON cadastro.parcela
                FOR EACH ROW EXECUTE FUNCTION audit.log_changes();

                CREATE TRIGGER trg_audit_edificacao
                AFTER INSERT OR UPDATE OR DELETE ON cadastro.edificacao
                FOR EACH ROW EXECUTE FUNCTION audit.log_changes();

                CREATE TRIGGER trg_audit_zona
                AFTER INSERT OR UPDATE OR DELETE ON territorial.zona
                FOR EACH ROW EXECUTE FUNCTION audit.log_changes();

                CREATE TRIGGER trg_audit_infraestrutura
                AFTER INSERT OR UPDATE OR DELETE ON cadastro.infraestrutura
                FOR EACH ROW EXECUTE FUNCTION audit.log_changes();

                CREATE TRIGGER trg_audit_divisao_administrativa
                AFTER INSERT OR UPDATE OR DELETE ON territorial.divisao_administrativa
                FOR EACH ROW EXECUTE FUNCTION audit.log_changes();

                -- Views utilitárias
                CREATE OR REPLACE VIEW cadastro.vw_parcela_completa AS
                SELECT
                    p.id, p.codigo_cadastral, p.numero_parcela, p.numero_talhao,
                    p.divisao_administrativa_id, d.tipo AS tipo_divisao, d.nome AS nome_divisao, d.codigo AS codigo_divisao,
                    territorial.hierarquia_divisao(d.id) AS hierarquia_completa,
                    p.geometria, p.area_calculada, p.perimetro, p.centroide,
                    p.situacao, p.uso_atual, p.uso_previsto, p.estado, p.versao, p.created_at, p.updated_at
                FROM cadastro.parcela p
                LEFT JOIN territorial.divisao_administrativa d ON p.divisao_administrativa_id = d.id;

                CREATE OR REPLACE VIEW territorial.vw_divisoes_urbanas AS
                SELECT * FROM territorial.divisao_administrativa WHERE zona_urbana = TRUE;

                CREATE OR REPLACE VIEW territorial.vw_divisoes_rurais AS
                SELECT * FROM territorial.divisao_administrativa WHERE zona_urbana = FALSE;

                CREATE OR REPLACE VIEW territorial.vw_conflitos_ativos AS
                SELECT c.id, c.projeto_id, c.tipo, c.descricao, c.entidade_tipo, c.entidade_id, c.data_detecao, c.resolvido
                FROM territorial.conflito c
                WHERE c.resolvido = FALSE;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DROP VIEW IF EXISTS territorial.vw_conflitos_ativos;
                DROP VIEW IF EXISTS territorial.vw_divisoes_rurais;
                DROP VIEW IF EXISTS territorial.vw_divisoes_urbanas;
                DROP VIEW IF EXISTS cadastro.vw_parcela_completa;
                DROP TRIGGER IF EXISTS trg_audit_divisao_administrativa ON territorial.divisao_administrativa;
                DROP TRIGGER IF EXISTS trg_audit_infraestrutura ON cadastro.infraestrutura;
                DROP TRIGGER IF EXISTS trg_audit_zona ON territorial.zona;
                DROP TRIGGER IF EXISTS trg_audit_edificacao ON cadastro.edificacao;
                DROP TRIGGER IF EXISTS trg_audit_parcela ON cadastro.parcela;
                DROP FUNCTION IF EXISTS audit.log_changes();
                DROP FUNCTION IF EXISTS territorial.detectar_conflito_uso(UUID);
                DROP FUNCTION IF EXISTS territorial.hierarquia_divisao(UUID);
                DROP FUNCTION IF EXISTS territorial.area_hectares(GEOMETRY);
                DROP FUNCTION IF EXISTS territorial.filhos_por_tipo(UUID, TEXT);
                DROP VIEW IF EXISTS territorial.vw_divisao_hierarquia;
                """);

            migrationBuilder.DropTable(
                name: "camada",
                schema: "gis");

            migrationBuilder.DropTable(
                name: "condicionante",
                schema: "cadastro");

            migrationBuilder.DropTable(
                name: "conflito",
                schema: "territorial");

            migrationBuilder.DropTable(
                name: "documento",
                schema: "cadastro");

            migrationBuilder.DropTable(
                name: "edificacao",
                schema: "cadastro");

            migrationBuilder.DropTable(
                name: "equipamento",
                schema: "cadastro");

            migrationBuilder.DropTable(
                name: "fiscalizacao",
                schema: "territorial");

            migrationBuilder.DropTable(
                name: "geometria_historico",
                schema: "territorial");

            migrationBuilder.DropTable(
                name: "infraestrutura",
                schema: "cadastro");

            migrationBuilder.DropTable(
                name: "log",
                schema: "audit");

            migrationBuilder.DropTable(
                name: "lote",
                schema: "cadastro");

            migrationBuilder.DropTable(
                name: "parcela_entidade",
                schema: "cadastro");

            migrationBuilder.DropTable(
                name: "permissao",
                schema: "territorial");

            migrationBuilder.DropTable(
                name: "ponto_levantamento",
                schema: "cadastro");

            migrationBuilder.DropTable(
                name: "projeto_equipa",
                schema: "territorial");

            migrationBuilder.DropTable(
                name: "refresh_token",
                schema: "territorial");

            migrationBuilder.DropTable(
                name: "zona",
                schema: "territorial");

            migrationBuilder.DropTable(
                name: "aprovacao",
                schema: "workflow");

            migrationBuilder.DropTable(
                name: "entidade",
                schema: "cadastro");

            migrationBuilder.DropTable(
                name: "parcela",
                schema: "cadastro");

            migrationBuilder.DropTable(
                name: "levantamento",
                schema: "cadastro");

            migrationBuilder.DropTable(
                name: "plano",
                schema: "territorial");

            migrationBuilder.DropTable(
                name: "projeto",
                schema: "territorial");

            migrationBuilder.DropTable(
                name: "utilizador",
                schema: "territorial");

            migrationBuilder.DropTable(
                name: "organizacao",
                schema: "territorial");

            migrationBuilder.DropTable(
                name: "divisao_administrativa",
                schema: "territorial");
        }
    }
}
