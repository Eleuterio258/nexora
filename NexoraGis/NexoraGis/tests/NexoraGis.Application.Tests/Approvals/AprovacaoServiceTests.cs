using NexoraGis.Application.Features.Approvals;
using NexoraGis.Application.Tests.TestSupport;
using NexoraGis.Domain.Entities.Audit;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Entities.Workflow;
using NexoraGis.Domain.Enums;
using NexoraGis.Infrastructure.Persistence;
using NexoraGis.Infrastructure.Repositories;

namespace NexoraGis.Application.Tests.Approvals;

public class AprovacaoServiceTests
{
    private static (AprovacaoService Service, AppDbContext Db, Guid ProjetoId, Guid ParcelaId) CreateSut()
    {
        var db = TestDb.Create();

        var organizacao = new Organizacao { Codigo = "ORG", Designacao = "Organização Teste", Tipo = "instituicao" };
        var projeto = new Projeto { OrganizacaoId = organizacao.Id, Organizacao = organizacao, Codigo = "PROJ-1", Designacao = "Projeto Teste", Tipo = "plano_pormenor" };
        var parcela = new Parcela { ProjetoId = projeto.Id, Projeto = projeto, CodigoCadastral = "PAR-1", Geometria = GeometryTestHelper.Square(0, 0, 10, 10) };
        db.Organizacoes.Add(organizacao);
        db.Projetos.Add(projeto);
        db.Parcelas.Add(parcela);
        db.SaveChanges();

        var service = new AprovacaoService(
            new EfRepository<Aprovacao>(db),
            new EfRepository<Projeto>(db),
            new EfRepository<Parcela>(db),
            new EfRepository<Plano>(db),
            new EfRepository<AuditLog>(db),
            new FakeCurrentUserService(Guid.NewGuid(), organizacao.Id),
            new EfUnitOfWork(db));

        return (service, db, projeto.Id, parcela.Id);
    }

    [Fact]
    public async Task CreateAsync_Fails_WhenEntidadeTipoIsUnsupported()
    {
        var (service, _, projetoId, _) = CreateSut();

        var result = await service.CreateAsync(new CreateAprovacaoRequest("zona", Guid.NewGuid(), projetoId));

        Assert.False(result.IsSuccess);
        Assert.Equal("Aprovacao.UnsupportedEntidadeTipo", result.Error.Code);
    }

    [Fact]
    public async Task CreateAsync_Fails_WhenAnotherWorkflowAlreadyInProgress()
    {
        var (service, _, projetoId, parcelaId) = CreateSut();

        var first = await service.CreateAsync(new CreateAprovacaoRequest("parcela", parcelaId, projetoId));
        Assert.True(first.IsSuccess);

        var second = await service.CreateAsync(new CreateAprovacaoRequest("parcela", parcelaId, projetoId));

        Assert.False(second.IsSuccess);
        Assert.Equal("Aprovacao.AlreadyInProgress", second.Error.Code);
    }

    [Fact]
    public async Task PublicarAsync_Fails_WhenCalledBeforeAprovado()
    {
        var (service, _, projetoId, parcelaId) = CreateSut();
        var created = await service.CreateAsync(new CreateAprovacaoRequest("parcela", parcelaId, projetoId));

        var result = await service.PublicarAsync(created.Value.Id);

        Assert.False(result.IsSuccess);
        Assert.Equal("Aprovacao.InvalidTransition", result.Error.Code);
    }

    [Fact]
    public async Task FullFlow_SyncsParcelaEstado_AndWritesAuditTrail()
    {
        var (service, db, projetoId, parcelaId) = CreateSut();
        var created = await service.CreateAsync(new CreateAprovacaoRequest("parcela", parcelaId, projetoId));
        var id = created.Value.Id;

        Assert.True((await service.SubmeterAsync(id)).IsSuccess);
        Assert.True((await service.IniciarAnaliseAsync(id)).IsSuccess);
        var aprovado = await service.AprovarAsync(id);
        Assert.True(aprovado.IsSuccess);
        Assert.Equal(ApprovalStatus.Aprovado, aprovado.Value.Status);

        var parcela = await db.Parcelas.FindAsync(parcelaId);
        Assert.Equal(ApprovalStatus.Aprovado, parcela!.Estado);

        var publicado = await service.PublicarAsync(id);
        Assert.True(publicado.IsSuccess);
        Assert.Equal(ApprovalStatus.Publicado, publicado.Value.Status);

        var parcelaFinal = await db.Parcelas.FindAsync(parcelaId);
        Assert.Equal(ApprovalStatus.Publicado, parcelaFinal!.Estado);

        var logs = db.AuditLogs.Where(l => l.EntidadeId == parcelaId).ToList();
        Assert.Equal(4, logs.Count);
        Assert.Contains(logs, l => l.Operacao == TipoOperacaoAuditoria.Aprovacao);
        Assert.Contains(logs, l => l.Operacao == TipoOperacaoAuditoria.Publicacao);
    }

    [Fact]
    public async Task RejeitarAsync_SetsMotivo_AndAllowsReopen()
    {
        var (service, _, projetoId, parcelaId) = CreateSut();
        var created = await service.CreateAsync(new CreateAprovacaoRequest("parcela", parcelaId, projetoId));
        var id = created.Value.Id;

        await service.SubmeterAsync(id);
        await service.IniciarAnaliseAsync(id);

        var rejeitado = await service.RejeitarAsync(id, new RejeitarRequest("Geometria com auto-interseção"));
        Assert.True(rejeitado.IsSuccess);
        Assert.Equal(ApprovalStatus.Rejeitado, rejeitado.Value.Status);
        Assert.Equal("Geometria com auto-interseção", rejeitado.Value.MotivoRejeicao);

        var reaberto = await service.ReabrirAsync(id);
        Assert.True(reaberto.IsSuccess);
        Assert.Equal(ApprovalStatus.Rascunho, reaberto.Value.Status);
        Assert.Null(reaberto.Value.MotivoRejeicao);
    }
}
