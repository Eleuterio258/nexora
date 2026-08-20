using NetTopologySuite.Geometries;
using NexoraGis.Application.Features.Surveys;
using NexoraGis.Application.Tests.TestSupport;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;
using NexoraGis.Infrastructure.Repositories;

namespace NexoraGis.Application.Tests.Surveys;

public class SyncServiceTests
{
    private readonly string _dbName = TestDb.NewDatabaseName();
    private readonly FakeCurrentUserService _user;
    private readonly Guid _levantamentoId;

    public SyncServiceTests()
    {
        var organizacaoId = Guid.NewGuid();
        _user = new FakeCurrentUserService(Guid.NewGuid(), organizacaoId);

        using var db = TestDb.Create(_dbName);
        var organizacao = new Organizacao { Id = organizacaoId, Codigo = "ORG", Designacao = "Organização Teste", Tipo = "instituicao" };
        var projeto = new Projeto { OrganizacaoId = organizacao.Id, Organizacao = organizacao, Codigo = "PROJ-1", Designacao = "Projeto Teste", Tipo = "plano_pormenor" };
        var levantamento = new Levantamento { ProjetoId = projeto.Id, Projeto = projeto, Codigo = "LEV-1", Tipo = TipoLevantamento.Gnss };
        db.Organizacoes.Add(organizacao);
        db.Projetos.Add(projeto);
        db.Levantamentos.Add(levantamento);
        db.SaveChanges();
        _levantamentoId = levantamento.Id;
    }

    /// <summary>
    /// Cada chamada devolve um serviço com um DbContext NOVO (mesma base de
    /// dados InMemory) — simula pedidos/ticks de worker separados, tal como
    /// acontece em produção com o DbContext scoped por DI.
    /// </summary>
    private SyncService NewService()
    {
        var db = TestDb.Create(_dbName, _user);
        return new SyncService(
            new EfRepository<PontoLevantamento>(db),
            new EfRepository<Levantamento>(db),
            new EfRepository<SyncJob>(db),
            new EfRepository<SyncConflito>(db),
            _user,
            new EfUnitOfWork(db));
    }

    private static SyncPontoItem Point(Guid clientId, double x, double y, string? codigo = "P1") =>
        new(clientId, codigo, new Point(new Coordinate(x, y)) { SRID = 4326 }, null, null, null, null, null, null, null, null);

    [Fact]
    public async Task EnqueueAsync_Fails_WhenBatchIsEmpty()
    {
        var result = await NewService().EnqueueAsync(new SyncPontosRequest(_levantamentoId, []));

        Assert.False(result.IsSuccess);
        Assert.Equal("Sync.EmptyBatch", result.Error.Code);
    }

    [Fact]
    public async Task EnqueueAsync_Fails_WhenLevantamentoDoesNotExist()
    {
        var result = await NewService().EnqueueAsync(new SyncPontosRequest(Guid.NewGuid(), [Point(Guid.NewGuid(), 32.5, -25.9)]));

        Assert.False(result.IsSuccess);
        Assert.Equal("Sync.LevantamentoNotFound", result.Error.Code);
    }

    [Fact]
    public async Task EnqueueAsync_CreatesPendingJob_WhenValid()
    {
        var result = await NewService().EnqueueAsync(new SyncPontosRequest(_levantamentoId, [Point(Guid.NewGuid(), 32.5, -25.9)]));

        Assert.True(result.IsSuccess);
        Assert.Equal(SyncJobStatus.Pendente, result.Value.Status);
        Assert.Equal(1, result.Value.TotalPontos);
    }

    [Fact]
    public async Task ProcessNextPendingJobAsync_CreatesPonto_AndMarksJobConcluido()
    {
        var enqueued = await NewService().EnqueueAsync(new SyncPontosRequest(_levantamentoId, [Point(Guid.NewGuid(), 32.5, -25.9)]));

        var processedAny = await NewService().ProcessNextPendingJobAsync();

        Assert.True(processedAny);
        var job = await NewService().GetJobAsync(enqueued.Value.Id);
        Assert.True(job.IsSuccess);
        Assert.Equal(SyncJobStatus.Concluido, job.Value.Status);
        Assert.Equal(1, job.Value.Criados);
        Assert.Equal(SyncPontoStatus.Created, Assert.Single(job.Value.Resultados!).Status);
    }

    [Fact]
    public async Task ProcessNextPendingJobAsync_FlagsDuplicate_WhenSameClientIdResentWithIdenticalData()
    {
        var clientId = Guid.NewGuid();

        await NewService().EnqueueAsync(new SyncPontosRequest(_levantamentoId, [Point(clientId, 32.5, -25.9)]));
        await NewService().ProcessNextPendingJobAsync();

        var secondJob = await NewService().EnqueueAsync(new SyncPontosRequest(_levantamentoId, [Point(clientId, 32.5, -25.9)]));
        await NewService().ProcessNextPendingJobAsync();

        var job = await NewService().GetJobAsync(secondJob.Value.Id);
        Assert.Equal(1, job.Value.Duplicados);
        Assert.Equal(0, job.Value.EmConflito);
    }

    [Fact]
    public async Task ProcessNextPendingJobAsync_FlagsConflict_WhenSameClientIdResentWithDifferentData()
    {
        var clientId = Guid.NewGuid();

        await NewService().EnqueueAsync(new SyncPontosRequest(_levantamentoId, [Point(clientId, 32.5, -25.9)]));
        await NewService().ProcessNextPendingJobAsync();

        var secondJob = await NewService().EnqueueAsync(new SyncPontosRequest(_levantamentoId, [Point(clientId, 32.6, -25.95, "P1-corrigido")]));
        await NewService().ProcessNextPendingJobAsync();

        var job = await NewService().GetJobAsync(secondJob.Value.Id);
        Assert.Equal(1, job.Value.EmConflito);
        Assert.Equal(0, job.Value.Duplicados);
    }

    [Fact]
    public async Task ProcessNextPendingJobAsync_RejectsPointWithLatitudeOutOfRange()
    {
        var enqueued = await NewService().EnqueueAsync(new SyncPontosRequest(_levantamentoId, [Point(Guid.NewGuid(), 32.5, 95.0)]));
        await NewService().ProcessNextPendingJobAsync();

        var result = await NewService().GetJobAsync(enqueued.Value.Id);
        Assert.Equal(1, result.Value.Rejeitados);
    }

    [Fact]
    public async Task ProcessNextPendingJobAsync_ReturnsFalse_WhenQueueIsEmpty()
    {
        Assert.False(await NewService().ProcessNextPendingJobAsync());
    }
}
