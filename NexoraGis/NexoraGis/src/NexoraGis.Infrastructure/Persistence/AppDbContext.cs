using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Entities.Audit;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Gis;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Entities.Workflow;

namespace NexoraGis.Infrastructure.Persistence;

/// <summary>
/// <paramref name="currentUser"/> é opcional para permitir a construção em
/// design-time (migrations); em runtime é resolvido pelo DI e usado para
/// aplicar o filtro global multi-tenant por organização.
/// </summary>
public class AppDbContext(DbContextOptions<AppDbContext> options, ICurrentUserService? currentUser = null) : DbContext(options)
{
    private readonly Guid? _tenantOrganizacaoId = currentUser?.OrganizacaoId;

    // territorial
    public DbSet<DivisaoAdministrativa> DivisoesAdministrativas => Set<DivisaoAdministrativa>();
    public DbSet<Organizacao> Organizacoes => Set<Organizacao>();
    public DbSet<Utilizador> Utilizadores => Set<Utilizador>();
    public DbSet<Permissao> Permissoes => Set<Permissao>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Projeto> Projetos => Set<Projeto>();
    public DbSet<ProjetoEquipa> ProjetoEquipas => Set<ProjetoEquipa>();
    public DbSet<Plano> Planos => Set<Plano>();
    public DbSet<Zona> Zonas => Set<Zona>();
    public DbSet<GeometriaHistorico> GeometriasHistorico => Set<GeometriaHistorico>();
    public DbSet<Conflito> Conflitos => Set<Conflito>();
    public DbSet<Fiscalizacao> Fiscalizacoes => Set<Fiscalizacao>();

    // cadastro
    public DbSet<Parcela> Parcelas => Set<Parcela>();
    public DbSet<Lote> Lotes => Set<Lote>();
    public DbSet<Entidade> Entidades => Set<Entidade>();
    public DbSet<ParcelaEntidade> ParcelaEntidades => Set<ParcelaEntidade>();
    public DbSet<Edificacao> Edificacoes => Set<Edificacao>();
    public DbSet<Infraestrutura> Infraestruturas => Set<Infraestrutura>();
    public DbSet<Equipamento> Equipamentos => Set<Equipamento>();
    public DbSet<Condicionante> Condicionantes => Set<Condicionante>();
    public DbSet<Levantamento> Levantamentos => Set<Levantamento>();
    public DbSet<PontoLevantamento> PontosLevantamento => Set<PontoLevantamento>();
    public DbSet<SyncJob> SyncJobs => Set<SyncJob>();
    public DbSet<SyncConflito> SyncConflitos => Set<SyncConflito>();
    public DbSet<Documento> Documentos => Set<Documento>();

    // workflow
    public DbSet<Aprovacao> Aprovacoes => Set<Aprovacao>();

    // gis
    public DbSet<Camada> Camadas => Set<Camada>();

    // audit
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasPostgresExtension("postgis");
        modelBuilder.HasPostgresExtension("uuid-ossp");
        modelBuilder.HasPostgresExtension("pgcrypto");

        // Nota: os enums do domínio são guardados como texto (HasConversion<string>()
        // em cada configuração), não como tipos ENUM nativos do PostgreSQL — a
        // combinação Npgsql.EntityFrameworkCore.PostgreSQL + EFCore.NamingConventions
        // não estava a aplicar o mapeamento nativo em runtime (INSERTs eram enviados
        // como integer), pelo que se optou pela abordagem mais simples e previsível.

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);

        // Isolamento multi-tenant: cada organização só vê os seus próprios
        // registos raiz. Sem tenant autenticado (ex: login), o filtro é
        // transparente — necessário para permitir localizar o utilizador antes
        // de emitir o JWT que identifica a organização.
        //
        // Nota: um filtro definido numa entidade NÃO é aplicado automaticamente
        // quando essa entidade é alcançada por navegação a partir de outra (ex:
        // Lote.Parcela não reaplica o filtro de Parcela) — por isso a condição
        // de tenant é repetida explicitamente em cada filtro abaixo, seguindo a
        // cadeia de navegação até Projeto.OrganizacaoId ou Utilizador.OrganizacaoId.
        modelBuilder.Entity<Utilizador>()
            .HasQueryFilter(u => _tenantOrganizacaoId == null || u.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<Projeto>()
            .HasQueryFilter(p => _tenantOrganizacaoId == null || p.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<RefreshToken>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Utilizador.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<ProjetoEquipa>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Projeto.OrganizacaoId == _tenantOrganizacaoId);

        // Entidade não deriva de Projeto (pode existir sem estar ligada a
        // nenhuma parcela ainda), por isso guarda OrganizacaoId diretamente.
        modelBuilder.Entity<Entidade>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.OrganizacaoId == _tenantOrganizacaoId);

        // Entidades com ProjetoId direto e obrigatório.
        modelBuilder.Entity<Parcela>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<Condicionante>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<Equipamento>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<Infraestrutura>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<Levantamento>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<Conflito>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<Fiscalizacao>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<Plano>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<Aprovacao>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Projeto.OrganizacaoId == _tenantOrganizacaoId);

        // Entidades com ProjetoId opcional (registo pode ser global/partilhado).
        modelBuilder.Entity<Documento>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Projeto == null || x.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        // GeometriaHistorico versiona entidades pertencentes a um projeto — ao
        // contrário de Documento/Camada, não faz sentido existir sem Projeto,
        // por isso o filtro nega (em vez de permitir) quando Projeto é nulo.
        modelBuilder.Entity<GeometriaHistorico>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || (x.Projeto != null && x.Projeto.OrganizacaoId == _tenantOrganizacaoId));
        modelBuilder.Entity<Camada>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Projeto == null || x.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        // AuditLog: os triggers de BD (audit.log_changes) nunca preenchem
        // Projeto/Utilizador — não há forma de propagar o tenant do pedido
        // HTTP para a sessão da BD que o trigger vê. Um filtro permissivo
        // quando ambos são nulos exporia auditoria de TODAS as organizações a
        // qualquer utilizador autenticado, por isso nega por omissão nesse
        // caso; só divisao_administrativa (dado partilhado, não multi-tenant)
        // fica deliberadamente visível sem Projeto/Utilizador resolvido.
        modelBuilder.Entity<AuditLog>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null
                || x.EntidadeTipo == "divisao_administrativa"
                || (x.Projeto != null && x.Projeto.OrganizacaoId == _tenantOrganizacaoId)
                || (x.Utilizador != null && x.Utilizador.OrganizacaoId == _tenantOrganizacaoId));

        // Entidades ligadas a Projeto indiretamente, através de outra entidade já filtrada.
        modelBuilder.Entity<Lote>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Parcela.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<Edificacao>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Parcela.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<ParcelaEntidade>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Parcela.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<PontoLevantamento>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Levantamento.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<SyncJob>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Levantamento.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<SyncConflito>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Levantamento.Projeto.OrganizacaoId == _tenantOrganizacaoId);
        modelBuilder.Entity<Zona>()
            .HasQueryFilter(x => _tenantOrganizacaoId == null || x.Plano.Projeto.OrganizacaoId == _tenantOrganizacaoId);
    }
}
