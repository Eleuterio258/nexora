using NexoraGis.Application.Features.Conflicts;
using NexoraGis.Application.Tests.TestSupport;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;
using NexoraGis.Infrastructure.Persistence;
using NexoraGis.Infrastructure.Repositories;

namespace NexoraGis.Application.Tests.Conflicts;

public class ConflitoServiceTests
{
    private static (ConflitoService Service, AppDbContext Db, Guid ProjetoId) CreateSut()
    {
        var db = TestDb.Create();

        var organizacao = new Organizacao { Codigo = "ORG", Designacao = "Organização Teste", Tipo = "instituicao" };
        var projeto = new Projeto { OrganizacaoId = organizacao.Id, Organizacao = organizacao, Codigo = "PROJ-1", Designacao = "Projeto Teste", Tipo = "plano_pormenor" };
        db.Organizacoes.Add(organizacao);
        db.Projetos.Add(projeto);
        db.SaveChanges();

        var service = new ConflitoService(
            new EfRepository<Conflito>(db),
            new EfRepository<Parcela>(db),
            new EfRepository<Edificacao>(db),
            new EfRepository<Condicionante>(db),
            new EfRepository<Projeto>(db),
            new FakeCurrentUserService(Guid.NewGuid(), organizacao.Id),
            new EfUnitOfWork(db));

        return (service, db, projeto.Id);
    }

    [Fact]
    public async Task DetectAllAsync_CreatesUsoIncompativelConflict_WhenUsoAtualDiffersFromPrevisto()
    {
        var (service, db, projetoId) = CreateSut();

        var parcela = new Parcela
        {
            ProjetoId = projetoId,
            CodigoCadastral = "PAR-1",
            Geometria = GeometryTestHelper.Square(0, 0, 10, 10),
            UsoAtual = UsoSolo.Agricola,
            UsoPrevisto = UsoSolo.Habitacional
        };
        db.Parcelas.Add(parcela);
        db.SaveChanges();

        var result = await service.DetectAllAsync(projetoId);

        Assert.True(result.IsSuccess);
        var conflito = Assert.Single(result.Value, c => c.Tipo == TipoConflito.UsoIncompativel);
        Assert.Equal("parcela", conflito.EntidadeTipo);
        Assert.Equal(parcela.Id, conflito.EntidadeId);
        Assert.False(conflito.Resolvido);
    }

    [Fact]
    public async Task DetectAllAsync_DoesNotFlagParcela_WhenUsoAtualMatchesPrevisto()
    {
        var (service, db, projetoId) = CreateSut();

        db.Parcelas.Add(new Parcela
        {
            ProjetoId = projetoId,
            CodigoCadastral = "PAR-1",
            Geometria = GeometryTestHelper.Square(0, 0, 10, 10),
            UsoAtual = UsoSolo.Habitacional,
            UsoPrevisto = UsoSolo.Habitacional
        });
        db.SaveChanges();

        var result = await service.DetectAllAsync(projetoId);

        Assert.True(result.IsSuccess);
        Assert.Empty(result.Value);
    }

    [Fact]
    public async Task DetectAllAsync_CreatesInfracaoConflict_WhenEdificacaoIntersectsRestrictiveCondicionante()
    {
        var (service, db, projetoId) = CreateSut();

        var parcela = new Parcela { ProjetoId = projetoId, CodigoCadastral = "PAR-1", Geometria = GeometryTestHelper.Square(0, 0, 10, 10) };
        var edificacao = new Edificacao { ParcelaId = parcela.Id, Parcela = parcela, Codigo = "E1", Geometria = GeometryTestHelper.Square(2, 2, 4, 4) };
        var condicionante = new Condicionante
        {
            ProjetoId = projetoId,
            Tipo = "linha_agua",
            Restritivo = true,
            Geometria = GeometryTestHelper.Square(1, 1, 5, 5)
        };
        db.Parcelas.Add(parcela);
        db.Edificacoes.Add(edificacao);
        db.Condicionantes.Add(condicionante);
        db.SaveChanges();

        var result = await service.DetectAllAsync(projetoId);

        Assert.True(result.IsSuccess);
        var conflito = Assert.Single(result.Value, c => c.Tipo == TipoConflito.InfracaoCondicionante);
        Assert.Equal("edificacao", conflito.EntidadeTipo);
        Assert.Equal(edificacao.Id, conflito.EntidadeId);
    }

    [Fact]
    public async Task DetectAllAsync_IgnoresNonRestritivaCondicionante()
    {
        var (service, db, projetoId) = CreateSut();

        var parcela = new Parcela { ProjetoId = projetoId, CodigoCadastral = "PAR-1", Geometria = GeometryTestHelper.Square(0, 0, 10, 10) };
        var edificacao = new Edificacao { ParcelaId = parcela.Id, Parcela = parcela, Codigo = "E1", Geometria = GeometryTestHelper.Square(2, 2, 4, 4) };
        var condicionante = new Condicionante
        {
            ProjetoId = projetoId,
            Tipo = "servidao",
            Restritivo = false,
            Geometria = GeometryTestHelper.Square(1, 1, 5, 5)
        };
        db.Parcelas.Add(parcela);
        db.Edificacoes.Add(edificacao);
        db.Condicionantes.Add(condicionante);
        db.SaveChanges();

        var result = await service.DetectAllAsync(projetoId);

        Assert.True(result.IsSuccess);
        Assert.Empty(result.Value);
    }

    [Fact]
    public async Task DetectAllAsync_DoesNotDuplicate_WhenRunTwiceWithoutResolution()
    {
        var (service, db, projetoId) = CreateSut();

        db.Parcelas.Add(new Parcela
        {
            ProjetoId = projetoId,
            CodigoCadastral = "PAR-1",
            Geometria = GeometryTestHelper.Square(0, 0, 10, 10),
            UsoAtual = UsoSolo.Agricola,
            UsoPrevisto = UsoSolo.Habitacional
        });
        db.SaveChanges();

        var first = await service.DetectAllAsync(projetoId);
        var second = await service.DetectAllAsync(projetoId);

        Assert.Single(first.Value);
        Assert.Empty(second.Value);
    }

    [Fact]
    public async Task ResolveAsync_MarksResolved_AndRejectsSecondResolve()
    {
        var (service, db, projetoId) = CreateSut();

        var created = await service.CreateAsync(new CreateConflitoRequest(projetoId, TipoConflito.Outro, "Conflito manual", null, null, null));
        Assert.True(created.IsSuccess);

        var resolved = await service.ResolveAsync(created.Value.Id);
        Assert.True(resolved.IsSuccess);
        Assert.True(resolved.Value.Resolvido);

        var secondAttempt = await service.ResolveAsync(created.Value.Id);
        Assert.False(secondAttempt.IsSuccess);
        Assert.Equal("Conflito.AlreadyResolved", secondAttempt.Error.Code);
    }
}
