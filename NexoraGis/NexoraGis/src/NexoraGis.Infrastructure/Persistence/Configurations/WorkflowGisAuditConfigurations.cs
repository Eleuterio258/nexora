using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using NexoraGis.Domain.Entities.Audit;
using NexoraGis.Domain.Entities.Gis;
using NexoraGis.Domain.Entities.Workflow;
using NexoraGis.Domain.Enums;
using NexoraGis.Infrastructure.Persistence.Conversions;

namespace NexoraGis.Infrastructure.Persistence.Configurations;

public class AprovacaoConfiguration : IEntityTypeConfiguration<Aprovacao>
{
    public void Configure(EntityTypeBuilder<Aprovacao> builder)
    {
        builder.ToTable("aprovacao", "workflow");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.EntidadeTipo).HasMaxLength(100);
        builder.Property(x => x.Status).HasConversion(new SnakeCaseEnumConverter<ApprovalStatus>()).HasMaxLength(40);
        builder.HasIndex(x => new { x.EntidadeTipo, x.EntidadeId });

        builder.HasOne(x => x.Projeto)
            .WithMany()
            .HasForeignKey(x => x.ProjetoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.RequisitadoPorUtilizador)
            .WithMany()
            .HasForeignKey(x => x.RequisitadoPor)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.VerificadoPorUtilizador)
            .WithMany()
            .HasForeignKey(x => x.VerificadoPor)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.AprovadoPorUtilizador)
            .WithMany()
            .HasForeignKey(x => x.AprovadoPor)
            .OnDelete(DeleteBehavior.Restrict);
    }
}

public class CamadaConfiguration : IEntityTypeConfiguration<Camada>
{
    public void Configure(EntityTypeBuilder<Camada> builder)
    {
        builder.ToTable("camada", "gis");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Nome).HasMaxLength(200);
        builder.Property(x => x.Estilo).HasColumnType("jsonb");
        builder.Property(x => x.Metadados).HasColumnType("jsonb");
        builder.Property(x => x.Tipo).HasConversion(new SnakeCaseEnumConverter<TipoCamada>()).HasMaxLength(40);

        builder.HasOne(x => x.Projeto)
            .WithMany()
            .HasForeignKey(x => x.ProjetoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Responsavel)
            .WithMany()
            .HasForeignKey(x => x.ResponsavelId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}

public class AuditLogConfiguration : IEntityTypeConfiguration<AuditLog>
{
    public void Configure(EntityTypeBuilder<AuditLog> builder)
    {
        builder.ToTable("log", "audit");
        builder.HasKey(x => x.Id);
        // As linhas de auditoria também são inseridas via trigger em SQL puro
        // (audit.log_changes), por isso o Id precisa de um default ao nível da BD.
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.EntidadeTipo).HasMaxLength(100);
        builder.Property(x => x.Operacao).HasConversion(new SnakeCaseEnumConverter<TipoOperacaoAuditoria>()).HasMaxLength(40);
        builder.Property(x => x.DataHora).HasDefaultValueSql("now()");
        builder.HasIndex(x => new { x.EntidadeTipo, x.EntidadeId });
        builder.HasIndex(x => x.DataHora);

        builder.Property(x => x.DadosAnteriores).HasColumnType("jsonb");
        builder.Property(x => x.DadosNovos).HasColumnType("jsonb");

        builder.HasOne(x => x.Utilizador)
            .WithMany()
            .HasForeignKey(x => x.UtilizadorId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Projeto)
            .WithMany()
            .HasForeignKey(x => x.ProjetoId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
