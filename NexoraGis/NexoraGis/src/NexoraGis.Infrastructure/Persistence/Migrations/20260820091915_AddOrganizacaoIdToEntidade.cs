using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NexoraGis.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddOrganizacaoIdToEntidade : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Coluna nasce nullable para permitir backfill de linhas existentes
            // (dev/staging) antes de se tornar obrigatória — um DEFAULT fixo
            // violaria a FK para territorial.organizacao em qualquer BD que já
            // tenha dados.
            migrationBuilder.AddColumn<Guid>(
                name: "organizacao_id",
                schema: "cadastro",
                table: "entidade",
                type: "uuid",
                nullable: true);

            // 1) Entidades já ligadas a uma parcela herdam a organização do
            //    projeto dessa parcela.
            migrationBuilder.Sql("""
                UPDATE cadastro.entidade e
                SET organizacao_id = pr.organizacao_id
                FROM cadastro.parcela_entidade pe
                JOIN cadastro.parcela pa ON pa.id = pe.parcela_id
                JOIN territorial.projeto pr ON pr.id = pa.projeto_id
                WHERE pe.entidade_id = e.id
                  AND e.organizacao_id IS NULL;
                """);

            // 2) Entidades órfãs (sem nenhuma parcela associada ainda) ficam
            //    provisoriamente na primeira organização existente — só
            //    relevante em BDs de desenvolvimento com dados de teste
            //    anteriores a este isolamento multi-tenant.
            migrationBuilder.Sql("""
                UPDATE cadastro.entidade
                SET organizacao_id = (SELECT id FROM territorial.organizacao ORDER BY created_at LIMIT 1)
                WHERE organizacao_id IS NULL
                  AND EXISTS (SELECT 1 FROM territorial.organizacao);
                """);

            migrationBuilder.AlterColumn<Guid>(
                name: "organizacao_id",
                schema: "cadastro",
                table: "entidade",
                type: "uuid",
                nullable: false,
                oldClrType: typeof(Guid),
                oldType: "uuid",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "ix_entidade_organizacao_id",
                schema: "cadastro",
                table: "entidade",
                column: "organizacao_id");

            migrationBuilder.AddForeignKey(
                name: "fk_entidade_organizacoes_organizacao_id",
                schema: "cadastro",
                table: "entidade",
                column: "organizacao_id",
                principalSchema: "territorial",
                principalTable: "organizacao",
                principalColumn: "id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "fk_entidade_organizacoes_organizacao_id",
                schema: "cadastro",
                table: "entidade");

            migrationBuilder.DropIndex(
                name: "ix_entidade_organizacao_id",
                schema: "cadastro",
                table: "entidade");

            migrationBuilder.DropColumn(
                name: "organizacao_id",
                schema: "cadastro",
                table: "entidade");
        }
    }
}
