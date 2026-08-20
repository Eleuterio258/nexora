using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;
using NexoraGis.Infrastructure.Persistence.Conversions;

namespace NexoraGis.Infrastructure.Persistence.Configurations;

public class ParcelaConfiguration : IEntityTypeConfiguration<Parcela>
{
    public void Configure(EntityTypeBuilder<Parcela> builder)
    {
        builder.ToTable("parcela", "cadastro");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.CodigoCadastral).HasMaxLength(50);
        builder.HasIndex(x => x.CodigoCadastral).IsUnique();
        builder.Property(x => x.SistemaCoordenadas).HasMaxLength(50);
        builder.Property(x => x.ParametrosUrbanisticos).HasColumnType("jsonb");
        builder.Property(x => x.Situacao).HasConversion(new SnakeCaseEnumConverter<SituacaoParcela>()).HasMaxLength(40);
        builder.Property(x => x.UsoAtual).HasConversion(new SnakeCaseEnumConverter<UsoSolo>()).HasMaxLength(40);
        builder.Property(x => x.UsoPrevisto).HasConversion(new SnakeCaseEnumConverter<UsoSolo>()).HasMaxLength(40);
        builder.Property(x => x.Estado).HasConversion(new SnakeCaseEnumConverter<ApprovalStatus>()).HasMaxLength(40);

        builder.Property(x => x.Geometria).HasColumnType("geometry(MultiPolygon, 4326)").IsRequired();
        builder.Property(x => x.Centroide)
            .HasColumnType("geometry(Point, 4326)")
            .HasComputedColumnSql("ST_Centroid(geometria)", stored: true);
        builder.Property(x => x.AreaCalculada)
            .HasComputedColumnSql("ST_Area(geometria::geography)", stored: true);
        builder.Property(x => x.Perimetro)
            .HasComputedColumnSql("ST_Perimeter(geometria::geography)", stored: true);

        builder.HasIndex(x => x.Geometria).HasMethod("gist");
        builder.HasIndex(x => x.ProjetoId);
        builder.HasIndex(x => x.DivisaoAdministrativaId);

        builder.HasOne(x => x.Projeto)
            .WithMany()
            .HasForeignKey(x => x.ProjetoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.DivisaoAdministrativa)
            .WithMany()
            .HasForeignKey(x => x.DivisaoAdministrativaId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne<Utilizador>()
            .WithMany()
            .HasForeignKey(x => x.CreatedBy)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne<Utilizador>()
            .WithMany()
            .HasForeignKey(x => x.UpdatedBy)
            .OnDelete(DeleteBehavior.Restrict);
    }
}

public class LoteConfiguration : IEntityTypeConfiguration<Lote>
{
    public void Configure(EntityTypeBuilder<Lote> builder)
    {
        builder.ToTable("lote", "cadastro");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Codigo).HasMaxLength(50);
        builder.HasIndex(x => new { x.ParcelaId, x.Codigo }).IsUnique();

        builder.Property(x => x.Geometria).HasColumnType("geometry(MultiPolygon, 4326)").IsRequired();
        builder.HasIndex(x => x.Geometria).HasMethod("gist");
        builder.Property(x => x.AreaCalculada)
            .HasComputedColumnSql("ST_Area(geometria::geography)", stored: true);

        builder.HasOne(x => x.Parcela)
            .WithMany(x => x.Lotes)
            .HasForeignKey(x => x.ParcelaId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class EntidadeConfiguration : IEntityTypeConfiguration<Entidade>
{
    public void Configure(EntityTypeBuilder<Entidade> builder)
    {
        builder.ToTable("entidade", "cadastro");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Nome).HasMaxLength(300);
        builder.Property(x => x.Nuit).HasMaxLength(50);
        builder.Property(x => x.Tipo).HasConversion(new SnakeCaseEnumConverter<TipoEntidade>()).HasMaxLength(40);

        builder.HasIndex(x => x.OrganizacaoId);

        builder.HasOne(x => x.Organizacao)
            .WithMany()
            .HasForeignKey(x => x.OrganizacaoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class ParcelaEntidadeConfiguration : IEntityTypeConfiguration<ParcelaEntidade>
{
    public void Configure(EntityTypeBuilder<ParcelaEntidade> builder)
    {
        builder.ToTable("parcela_entidade", "cadastro");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.TipoRelacao).HasConversion(new SnakeCaseEnumConverter<TipoEntidade>()).HasMaxLength(40);
        builder.HasIndex(x => new { x.ParcelaId, x.EntidadeId, x.TipoRelacao, x.Ativo }).IsUnique();

        builder.HasOne(x => x.Parcela)
            .WithMany(x => x.Entidades)
            .HasForeignKey(x => x.ParcelaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Entidade)
            .WithMany(x => x.Parcelas)
            .HasForeignKey(x => x.EntidadeId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class EdificacaoConfiguration : IEntityTypeConfiguration<Edificacao>
{
    public void Configure(EntityTypeBuilder<Edificacao> builder)
    {
        builder.ToTable("edificacao", "cadastro");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Codigo).HasMaxLength(50);
        builder.HasIndex(x => new { x.ParcelaId, x.Codigo }).IsUnique();

        builder.Property(x => x.Geometria).HasColumnType("geometry(MultiPolygon, 4326)");
        builder.Property(x => x.Coordenadas).HasColumnType("geometry(Point, 4326)");
        builder.Property(x => x.Finalidade).HasConversion(new SnakeCaseEnumConverter<UsoSolo>()).HasMaxLength(40);
        builder.HasIndex(x => x.Geometria).HasMethod("gist");

        builder.HasOne(x => x.Parcela)
            .WithMany(x => x.Edificacoes)
            .HasForeignKey(x => x.ParcelaId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class InfraestruturaConfiguration : IEntityTypeConfiguration<Infraestrutura>
{
    public void Configure(EntityTypeBuilder<Infraestrutura> builder)
    {
        builder.ToTable("infraestrutura", "cadastro");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Subtipo).HasMaxLength(100);
        builder.Property(x => x.Codigo).HasMaxLength(50);
        builder.Property(x => x.Atributos).HasColumnType("jsonb");
        builder.Property(x => x.Tipo).HasConversion(new SnakeCaseEnumConverter<TipoInfraestrutura>()).HasMaxLength(40);

        builder.Property(x => x.Geometria).HasColumnType("geometry(Geometry, 4326)");
        builder.HasIndex(x => x.Geometria).HasMethod("gist");
        builder.HasIndex(x => new { x.ProjetoId, x.Tipo });

        builder.HasOne(x => x.Projeto)
            .WithMany()
            .HasForeignKey(x => x.ProjetoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class EquipamentoConfiguration : IEntityTypeConfiguration<Equipamento>
{
    public void Configure(EntityTypeBuilder<Equipamento> builder)
    {
        builder.ToTable("equipamento", "cadastro");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Tipo).HasMaxLength(100);
        builder.Property(x => x.Nome).HasMaxLength(200);
        builder.Property(x => x.Atributos).HasColumnType("jsonb");

        builder.Property(x => x.Geometria).HasColumnType("geometry(Point, 4326)");
        builder.HasIndex(x => x.Geometria).HasMethod("gist");

        builder.HasOne(x => x.Projeto)
            .WithMany()
            .HasForeignKey(x => x.ProjetoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class CondicionanteConfiguration : IEntityTypeConfiguration<Condicionante>
{
    public void Configure(EntityTypeBuilder<Condicionante> builder)
    {
        builder.ToTable("condicionante", "cadastro");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Tipo).HasMaxLength(100);
        builder.Property(x => x.Atributos).HasColumnType("jsonb");

        builder.Property(x => x.Geometria).HasColumnType("geometry(Geometry, 4326)");
        builder.HasIndex(x => x.Geometria).HasMethod("gist");

        builder.HasOne(x => x.Projeto)
            .WithMany()
            .HasForeignKey(x => x.ProjetoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class LevantamentoConfiguration : IEntityTypeConfiguration<Levantamento>
{
    public void Configure(EntityTypeBuilder<Levantamento> builder)
    {
        builder.ToTable("levantamento", "cadastro");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Codigo).HasMaxLength(50);
        builder.HasIndex(x => x.Codigo).IsUnique();
        builder.Property(x => x.Status).HasMaxLength(50);
        builder.Property(x => x.Tipo).HasConversion(new SnakeCaseEnumConverter<TipoLevantamento>()).HasMaxLength(40);

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

public class PontoLevantamentoConfiguration : IEntityTypeConfiguration<PontoLevantamento>
{
    public void Configure(EntityTypeBuilder<PontoLevantamento> builder)
    {
        builder.ToTable("ponto_levantamento", "cadastro");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.Property(x => x.Geometria).HasColumnType("geometry(Point, 4326)").IsRequired();
        builder.HasIndex(x => x.Geometria).HasMethod("gist");

        builder.HasOne(x => x.Levantamento)
            .WithMany(x => x.Pontos)
            .HasForeignKey(x => x.LevantamentoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class SyncJobConfiguration : IEntityTypeConfiguration<SyncJob>
{
    public void Configure(EntityTypeBuilder<SyncJob> builder)
    {
        builder.ToTable("sync_job", "cadastro");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Payload).HasColumnType("jsonb");
        builder.Property(x => x.Resultados).HasColumnType("jsonb");
        builder.Property(x => x.Status).HasConversion(new SnakeCaseEnumConverter<SyncJobStatus>()).HasMaxLength(40);

        builder.HasIndex(x => x.Status);
        builder.HasIndex(x => x.LevantamentoId);

        builder.HasOne(x => x.Levantamento)
            .WithMany()
            .HasForeignKey(x => x.LevantamentoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class SyncConflitoConfiguration : IEntityTypeConfiguration<SyncConflito>
{
    public void Configure(EntityTypeBuilder<SyncConflito> builder)
    {
        builder.ToTable("sync_conflito", "cadastro");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.DadosIncoming).HasColumnType("jsonb");
        builder.Property(x => x.Status).HasConversion(new SnakeCaseEnumConverter<SyncConflitoStatus>()).HasMaxLength(40);

        builder.HasIndex(x => x.Status);
        builder.HasIndex(x => x.LevantamentoId);
        builder.HasIndex(x => x.PontoLevantamentoId);

        builder.HasOne(x => x.Levantamento)
            .WithMany()
            .HasForeignKey(x => x.LevantamentoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.PontoLevantamento)
            .WithMany()
            .HasForeignKey(x => x.PontoLevantamentoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class DocumentoConfiguration : IEntityTypeConfiguration<Documento>
{
    public void Configure(EntityTypeBuilder<Documento> builder)
    {
        builder.ToTable("documento", "cadastro");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Titulo).HasMaxLength(300);
        builder.Property(x => x.EntidadeTipo).HasMaxLength(100);
        builder.Property(x => x.Tipo).HasConversion(new SnakeCaseEnumConverter<TipoDocumento>()).HasMaxLength(40);
        builder.HasIndex(x => new { x.EntidadeTipo, x.EntidadeId });

        builder.HasOne(x => x.Projeto)
            .WithMany()
            .HasForeignKey(x => x.ProjetoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.CreatedByUtilizador)
            .WithMany()
            .HasForeignKey(x => x.CreatedBy)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
