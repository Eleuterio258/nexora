using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Entities.Workflow;
using NexoraGis.Domain.Enums;
using NexoraGis.Infrastructure.Persistence.Conversions;

namespace NexoraGis.Infrastructure.Persistence.Configurations;

public class DivisaoAdministrativaConfiguration : IEntityTypeConfiguration<DivisaoAdministrativa>
{
    public void Configure(EntityTypeBuilder<DivisaoAdministrativa> builder)
    {
        builder.ToTable("divisao_administrativa", "territorial");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.Property(x => x.Codigo).HasMaxLength(30);
        builder.HasIndex(x => x.Codigo).IsUnique();
        builder.Property(x => x.Nome).HasMaxLength(200);
        builder.Property(x => x.Metadados).HasColumnType("jsonb");
        builder.Property(x => x.Tipo).HasConversion(new SnakeCaseEnumConverter<TipoDivisao>()).HasMaxLength(40);
        // Defaults ao nível da BD: o seed de divisões administrativas (secção
        // territorial.divisao_administrativa) é populado via script SQL puro,
        // que não passa pelos inicializadores de propriedade do C#.
        builder.Property(x => x.Ativo).HasDefaultValue(true);
        builder.Property(x => x.CreatedAt).HasDefaultValueSql("now()");
        builder.Property(x => x.UpdatedAt).HasDefaultValueSql("now()");

        builder.Property(x => x.Geometria).HasColumnType("geometry(MultiPolygon, 4326)");
        builder.Property(x => x.Centroide)
            .HasColumnType("geometry(Point, 4326)")
            .HasComputedColumnSql("CASE WHEN geometria IS NOT NULL THEN ST_Centroid(geometria) END", stored: true);
        builder.Property(x => x.AreaCalculada)
            .HasComputedColumnSql("CASE WHEN geometria IS NOT NULL THEN ST_Area(geometria::geography) / 10000 ELSE NULL END", stored: true);

        builder.HasIndex(x => x.ParentId);
        builder.HasIndex(x => x.Tipo);
        builder.HasIndex(x => x.ZonaUrbana);
        builder.HasIndex(x => x.CodigoIne);
        builder.HasIndex(x => x.Geometria).HasMethod("gist");

        builder.HasOne(x => x.Parent)
            .WithMany(x => x.Filhos)
            .HasForeignKey(x => x.ParentId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class OrganizacaoConfiguration : IEntityTypeConfiguration<Organizacao>
{
    public void Configure(EntityTypeBuilder<Organizacao> builder)
    {
        builder.ToTable("organizacao", "territorial");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Codigo).HasMaxLength(50);
        builder.HasIndex(x => x.Codigo).IsUnique();
        builder.Property(x => x.Designacao).HasMaxLength(200);

        builder.HasOne(x => x.DivisaoAdministrativa)
            .WithMany()
            .HasForeignKey(x => x.DivisaoAdministrativaId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}

public class UtilizadorConfiguration : IEntityTypeConfiguration<Utilizador>
{
    public void Configure(EntityTypeBuilder<Utilizador> builder)
    {
        builder.ToTable("utilizador", "territorial");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Username).HasMaxLength(100);
        builder.HasIndex(x => x.Username).IsUnique();
        builder.Property(x => x.Email).HasMaxLength(200);
        builder.HasIndex(x => x.Email).IsUnique();
        builder.Property(x => x.Perfil).HasConversion(new SnakeCaseEnumConverter<PerfilUtilizador>()).HasMaxLength(40);

        builder.HasOne(x => x.Organizacao)
            .WithMany(x => x.Utilizadores)
            .HasForeignKey(x => x.OrganizacaoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
{
    public void Configure(EntityTypeBuilder<RefreshToken> builder)
    {
        builder.ToTable("refresh_token", "territorial");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.TokenHash).HasMaxLength(128);
        builder.HasIndex(x => x.TokenHash).IsUnique();
        builder.HasIndex(x => x.UtilizadorId);
        builder.Ignore(x => x.IsActive);

        builder.HasOne(x => x.Utilizador)
            .WithMany()
            .HasForeignKey(x => x.UtilizadorId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class PermissaoConfiguration : IEntityTypeConfiguration<Permissao>
{
    public void Configure(EntityTypeBuilder<Permissao> builder)
    {
        builder.ToTable("permissao", "territorial");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Perfil).HasMaxLength(100);
        builder.Property(x => x.Recurso).HasMaxLength(100);
        builder.Property(x => x.Acao).HasMaxLength(50);
        builder.Property(x => x.Ativo).HasDefaultValue(true);
        builder.HasIndex(x => new { x.Perfil, x.Recurso, x.Acao }).IsUnique();
    }
}

public class ProjetoConfiguration : IEntityTypeConfiguration<Projeto>
{
    public void Configure(EntityTypeBuilder<Projeto> builder)
    {
        builder.ToTable("projeto", "territorial");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Codigo).HasMaxLength(50);
        builder.HasIndex(x => x.Codigo).IsUnique();
        builder.Property(x => x.Designacao).HasMaxLength(300);
        builder.Property(x => x.Status).HasConversion(new SnakeCaseEnumConverter<ProjectStatus>()).HasMaxLength(40);

        builder.Property(x => x.AreaIntervencao).HasColumnType("geometry(MultiPolygon, 4326)");
        builder.HasIndex(x => x.AreaIntervencao).HasMethod("gist");
        builder.HasIndex(x => x.DivisaoAdministrativaId);

        builder.HasOne(x => x.Organizacao)
            .WithMany(x => x.Projetos)
            .HasForeignKey(x => x.OrganizacaoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.DivisaoAdministrativa)
            .WithMany()
            .HasForeignKey(x => x.DivisaoAdministrativaId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.ResponsavelTecnico)
            .WithMany()
            .HasForeignKey(x => x.ResponsavelTecnicoId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.CreatedByUtilizador)
            .WithMany()
            .HasForeignKey(x => x.CreatedBy)
            .OnDelete(DeleteBehavior.Restrict);
    }
}

public class ProjetoEquipaConfiguration : IEntityTypeConfiguration<ProjetoEquipa>
{
    public void Configure(EntityTypeBuilder<ProjetoEquipa> builder)
    {
        builder.ToTable("projeto_equipa", "territorial");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Funcao).HasMaxLength(100);
        builder.HasIndex(x => new { x.ProjetoId, x.UtilizadorId }).IsUnique();

        builder.HasOne(x => x.Projeto)
            .WithMany(x => x.Equipa)
            .HasForeignKey(x => x.ProjetoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Utilizador)
            .WithMany()
            .HasForeignKey(x => x.UtilizadorId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class PlanoConfiguration : IEntityTypeConfiguration<Plano>
{
    public void Configure(EntityTypeBuilder<Plano> builder)
    {
        builder.ToTable("plano", "territorial");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Codigo).HasMaxLength(50);
        builder.Property(x => x.Designacao).HasMaxLength(300);
        builder.Property(x => x.Versao).HasMaxLength(20);
        builder.HasIndex(x => new { x.ProjetoId, x.Codigo, x.Versao }).IsUnique();

        builder.HasOne(x => x.Projeto)
            .WithMany(x => x.Planos)
            .HasForeignKey(x => x.ProjetoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class ZonaConfiguration : IEntityTypeConfiguration<Zona>
{
    public void Configure(EntityTypeBuilder<Zona> builder)
    {
        builder.ToTable("zona", "territorial");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Codigo).HasMaxLength(20);
        builder.Property(x => x.Designacao).HasMaxLength(200);
        builder.Property(x => x.Cor).HasMaxLength(7);
        builder.Property(x => x.Parametros).HasColumnType("jsonb");
        builder.HasIndex(x => new { x.PlanoId, x.Codigo }).IsUnique();

        builder.Property(x => x.Geometria).HasColumnType("geometry(MultiPolygon, 4326)");
        builder.HasIndex(x => x.Geometria).HasMethod("gist");
        builder.Property(x => x.AreaCalculada)
            .HasComputedColumnSql("CASE WHEN geometria IS NOT NULL THEN ST_Area(geometria::geography) / 10000 ELSE NULL END", stored: true);

        builder.HasOne(x => x.Plano)
            .WithMany(x => x.Zonas)
            .HasForeignKey(x => x.PlanoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class GeometriaHistoricoConfiguration : IEntityTypeConfiguration<GeometriaHistorico>
{
    public void Configure(EntityTypeBuilder<GeometriaHistorico> builder)
    {
        builder.ToTable("geometria_historico", "territorial");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.EntidadeTipo).HasMaxLength(100);
        builder.HasIndex(x => new { x.EntidadeTipo, x.EntidadeId });

        builder.Property(x => x.GeometriaAnterior).HasColumnType("geometry(Geometry, 4326)");
        builder.Property(x => x.GeometriaNova).HasColumnType("geometry(Geometry, 4326)");

        builder.HasOne(x => x.Projeto)
            .WithMany()
            .HasForeignKey(x => x.ProjetoId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Utilizador)
            .WithMany()
            .HasForeignKey(x => x.UtilizadorId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Aprovacao)
            .WithMany()
            .HasForeignKey(x => x.AprovacaoId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}

public class ConflitoConfiguration : IEntityTypeConfiguration<Conflito>
{
    public void Configure(EntityTypeBuilder<Conflito> builder)
    {
        builder.ToTable("conflito", "territorial");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.EntidadeTipo).HasMaxLength(100);
        builder.Property(x => x.Detalhes).HasColumnType("jsonb");
        builder.Property(x => x.Tipo).HasConversion(new SnakeCaseEnumConverter<TipoConflito>()).HasMaxLength(40);

        builder.Property(x => x.Geometria).HasColumnType("geometry(Geometry, 4326)");
        builder.HasIndex(x => x.Geometria).HasMethod("gist");

        builder.HasOne(x => x.Projeto)
            .WithMany()
            .HasForeignKey(x => x.ProjetoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.ResolvidoPorUtilizador)
            .WithMany()
            .HasForeignKey(x => x.ResolvidoPor)
            .OnDelete(DeleteBehavior.Restrict);
    }
}

public class FiscalizacaoConfiguration : IEntityTypeConfiguration<Fiscalizacao>
{
    public void Configure(EntityTypeBuilder<Fiscalizacao> builder)
    {
        builder.ToTable("fiscalizacao", "territorial");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Estado).HasMaxLength(50);

        builder.Property(x => x.Coordenadas).HasColumnType("geometry(Point, 4326)");
        builder.HasIndex(x => x.Coordenadas).HasMethod("gist");

        builder.HasOne(x => x.Projeto)
            .WithMany()
            .HasForeignKey(x => x.ProjetoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Parcela)
            .WithMany()
            .HasForeignKey(x => x.ParcelaId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(x => x.Fiscal)
            .WithMany()
            .HasForeignKey(x => x.FiscalId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.ResponsavelUtilizador)
            .WithMany()
            .HasForeignKey(x => x.Responsavel)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
