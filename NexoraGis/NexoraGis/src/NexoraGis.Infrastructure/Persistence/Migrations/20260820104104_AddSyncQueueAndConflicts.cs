using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NexoraGis.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddSyncQueueAndConflicts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "sync_conflito",
                schema: "cadastro",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    levantamento_id = table.Column<Guid>(type: "uuid", nullable: false),
                    ponto_levantamento_id = table.Column<Guid>(type: "uuid", nullable: false),
                    dados_incoming = table.Column<string>(type: "jsonb", nullable: false),
                    status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    resolvido_por = table.Column<Guid>(type: "uuid", nullable: true),
                    data_resolucao = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_sync_conflito", x => x.id);
                    table.ForeignKey(
                        name: "fk_sync_conflito_levantamento_levantamento_id",
                        column: x => x.levantamento_id,
                        principalSchema: "cadastro",
                        principalTable: "levantamento",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_sync_conflito_ponto_levantamento_ponto_levantamento_id",
                        column: x => x.ponto_levantamento_id,
                        principalSchema: "cadastro",
                        principalTable: "ponto_levantamento",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "sync_job",
                schema: "cadastro",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    levantamento_id = table.Column<Guid>(type: "uuid", nullable: false),
                    status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    payload = table.Column<string>(type: "jsonb", nullable: false),
                    resultados = table.Column<string>(type: "jsonb", nullable: true),
                    total_pontos = table.Column<int>(type: "integer", nullable: false),
                    processados = table.Column<int>(type: "integer", nullable: false),
                    criados = table.Column<int>(type: "integer", nullable: false),
                    duplicados = table.Column<int>(type: "integer", nullable: false),
                    em_conflito = table.Column<int>(type: "integer", nullable: false),
                    rejeitados = table.Column<int>(type: "integer", nullable: false),
                    erro_mensagem = table.Column<string>(type: "text", nullable: true),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    started_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    completed_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_sync_job", x => x.id);
                    table.ForeignKey(
                        name: "fk_sync_job_levantamento_levantamento_id",
                        column: x => x.levantamento_id,
                        principalSchema: "cadastro",
                        principalTable: "levantamento",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_sync_conflito_levantamento_id",
                schema: "cadastro",
                table: "sync_conflito",
                column: "levantamento_id");

            migrationBuilder.CreateIndex(
                name: "ix_sync_conflito_ponto_levantamento_id",
                schema: "cadastro",
                table: "sync_conflito",
                column: "ponto_levantamento_id");

            migrationBuilder.CreateIndex(
                name: "ix_sync_conflito_status",
                schema: "cadastro",
                table: "sync_conflito",
                column: "status");

            migrationBuilder.CreateIndex(
                name: "ix_sync_job_levantamento_id",
                schema: "cadastro",
                table: "sync_job",
                column: "levantamento_id");

            migrationBuilder.CreateIndex(
                name: "ix_sync_job_status",
                schema: "cadastro",
                table: "sync_job",
                column: "status");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "sync_conflito",
                schema: "cadastro");

            migrationBuilder.DropTable(
                name: "sync_job",
                schema: "cadastro");
        }
    }
}
