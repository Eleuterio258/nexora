using NexoraGis.Application.Features.Versioning;
using NexoraGis.Application.Tests.TestSupport;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Infrastructure.Repositories;

namespace NexoraGis.Application.Tests.Versioning;

public class VersioningServiceTests
{
    [Fact]
    public async Task GetAtDateAsync_ReturnsNotFound_WhenNoHistoryExists()
    {
        var db = TestDb.Create();
        var service = new VersioningService(new EfRepository<GeometriaHistorico>(db));

        var result = await service.GetAtDateAsync("parcela", Guid.NewGuid(), DateTimeOffset.UtcNow);

        Assert.False(result.Encontrado);
        Assert.Null(result.Geometria);
    }

    [Fact]
    public async Task GetAtDateAsync_ReturnsGeometriaAnterior_WhenDateIsBeforeFirstChange()
    {
        var db = TestDb.Create();
        var entidadeId = Guid.NewGuid();
        var t0 = DateTimeOffset.Parse("2026-01-01T00:00:00Z");

        var original = GeometryTestHelper.Square(0, 0, 1, 1);
        var alterada = GeometryTestHelper.Square(0, 0, 2, 2);

        db.GeometriasHistorico.Add(new GeometriaHistorico
        {
            EntidadeTipo = "parcela",
            EntidadeId = entidadeId,
            GeometriaAnterior = original,
            GeometriaNova = alterada,
            DataAlteracao = t0,
            VersaoAnterior = 1,
            VersaoNova = 2
        });
        db.SaveChanges();

        var service = new VersioningService(new EfRepository<GeometriaHistorico>(db));
        var result = await service.GetAtDateAsync("parcela", entidadeId, t0.AddDays(-1));

        Assert.True(result.Encontrado);
        Assert.Null(result.VigenteDesde);
        Assert.True(original.EqualsExact(result.Geometria));
    }

    [Fact]
    public async Task GetAtDateAsync_ReturnsLatestApplicableVersion_AcrossMultipleChanges()
    {
        var db = TestDb.Create();
        var entidadeId = Guid.NewGuid();
        var t1 = DateTimeOffset.Parse("2026-01-01T00:00:00Z");
        var t2 = DateTimeOffset.Parse("2026-02-01T00:00:00Z");

        var v0 = GeometryTestHelper.Square(0, 0, 1, 1);
        var v1 = GeometryTestHelper.Square(0, 0, 2, 2);
        var v2 = GeometryTestHelper.Square(0, 0, 3, 3);

        db.GeometriasHistorico.AddRange(
            new GeometriaHistorico { EntidadeTipo = "parcela", EntidadeId = entidadeId, GeometriaAnterior = v0, GeometriaNova = v1, DataAlteracao = t1, VersaoAnterior = 1, VersaoNova = 2 },
            new GeometriaHistorico { EntidadeTipo = "parcela", EntidadeId = entidadeId, GeometriaAnterior = v1, GeometriaNova = v2, DataAlteracao = t2, VersaoAnterior = 2, VersaoNova = 3 });
        db.SaveChanges();

        var service = new VersioningService(new EfRepository<GeometriaHistorico>(db));

        // Entre as duas alterações: deve valer a versão criada em t1.
        var entre = await service.GetAtDateAsync("parcela", entidadeId, t1.AddDays(5));
        Assert.True(entre.Encontrado);
        Assert.True(v1.EqualsExact(entre.Geometria));
        Assert.Equal(t1, entre.VigenteDesde);

        // Depois da segunda alteração: deve valer a versão mais recente.
        var depois = await service.GetAtDateAsync("parcela", entidadeId, t2.AddDays(5));
        Assert.True(depois.Encontrado);
        Assert.True(v2.EqualsExact(depois.Geometria));
        Assert.Equal(t2, depois.VigenteDesde);
    }

    [Fact]
    public async Task GetHistoryAsync_ReturnsEntriesOrderedByDataAlteracao()
    {
        var db = TestDb.Create();
        var entidadeId = Guid.NewGuid();
        var t1 = DateTimeOffset.Parse("2026-02-01T00:00:00Z");
        var t2 = DateTimeOffset.Parse("2026-01-01T00:00:00Z");

        db.GeometriasHistorico.AddRange(
            new GeometriaHistorico { EntidadeTipo = "parcela", EntidadeId = entidadeId, DataAlteracao = t1, VersaoAnterior = 2, VersaoNova = 3 },
            new GeometriaHistorico { EntidadeTipo = "parcela", EntidadeId = entidadeId, DataAlteracao = t2, VersaoAnterior = 1, VersaoNova = 2 });
        db.SaveChanges();

        var service = new VersioningService(new EfRepository<GeometriaHistorico>(db));
        var history = await service.GetHistoryAsync("parcela", entidadeId);

        Assert.Equal(2, history.Count);
        Assert.Equal(t2, history[0].DataAlteracao);
        Assert.Equal(t1, history[1].DataAlteracao);
    }
}
