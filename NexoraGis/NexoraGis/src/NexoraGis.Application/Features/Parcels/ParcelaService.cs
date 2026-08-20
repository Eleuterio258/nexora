using Microsoft.EntityFrameworkCore;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Parcels;

public class ParcelaService(
    IRepository<Parcela> parcelas,
    IRepository<Projeto> projetos,
    IRepository<DivisaoAdministrativa> divisoes,
    IRepository<GeometriaHistorico> geometriasHistorico,
    ICurrentUserService currentUser,
    IUnitOfWork unitOfWork)
{
    public async Task<Result<ParcelaDto>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var parcela = await parcelas.GetByIdAsync(id, ct);
        return parcela is null ? Result.Failure<ParcelaDto>(NotFound(id)) : ToDto(parcela);
    }

    public async Task<PagedResult<ParcelaDto>> ListAsync(
        Guid? projetoId, Guid? divisaoAdministrativaId, SituacaoParcela? situacao, UsoSolo? usoAtual,
        ApprovalStatus? estado, string? codigo, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = parcelas.Query();

        if (projetoId is not null) query = query.Where(p => p.ProjetoId == projetoId);
        if (divisaoAdministrativaId is not null) query = query.Where(p => p.DivisaoAdministrativaId == divisaoAdministrativaId);
        if (situacao is not null) query = query.Where(p => p.Situacao == situacao);
        if (usoAtual is not null) query = query.Where(p => p.UsoAtual == usoAtual);
        if (estado is not null) query = query.Where(p => p.Estado == estado);
        if (!string.IsNullOrWhiteSpace(codigo)) query = query.Where(p => p.CodigoCadastral.Contains(codigo));

        var totalCount = await query.CountAsync(ct);
        var items = await query
            .OrderByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return new PagedResult<ParcelaDto>(items.Select(ToDto).ToList(), page, pageSize, totalCount);
    }

    /// <summary>Pesquisa espacial: parcelas cuja geometria interseta a área pedida.</summary>
    public async Task<IReadOnlyList<ParcelaDto>> SearchAsync(ParcelaSearchRequest request, CancellationToken ct = default)
    {
        var query = parcelas.Query().Where(p => p.Geometria.Intersects(request.Area));
        if (request.ProjetoId is not null) query = query.Where(p => p.ProjetoId == request.ProjetoId);

        var items = await query.Take(500).ToListAsync(ct);
        return items.Select(ToDto).ToList();
    }

    public async Task<Result<ParcelaDto>> CreateAsync(CreateParcelaRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.CodigoCadastral))
            return Result.Failure<ParcelaDto>(Error.Validation("Parcela.Invalid", "Código cadastral é obrigatório."));

        if (!await projetos.ExistsAsync(request.ProjetoId, ct))
            return Result.Failure<ParcelaDto>(Error.Validation("Parcela.ProjetoNotFound", "Projeto indicado não existe."));

        if (request.DivisaoAdministrativaId is not null && !await divisoes.ExistsAsync(request.DivisaoAdministrativaId.Value, ct))
            return Result.Failure<ParcelaDto>(Error.Validation("Parcela.DivisaoNotFound", "Divisão administrativa indicada não existe."));

        if (await parcelas.Query().AnyAsync(p => p.CodigoCadastral == request.CodigoCadastral, ct))
            return Result.Failure<ParcelaDto>(Error.Conflict("Parcela.DuplicateCodigo", $"Já existe uma parcela com o código '{request.CodigoCadastral}'."));

        var geometriaError = ValidateGeometry(request.Geometria);
        if (geometriaError is not null)
            return Result.Failure<ParcelaDto>(geometriaError);

        var multiPolygon = ToMultiPolygon(request.Geometria);

        var overlapError = await CheckOverlapAsync(request.ProjetoId, multiPolygon, excludeId: null, ct);
        if (overlapError is not null)
            return Result.Failure<ParcelaDto>(overlapError);

        var parcela = new Parcela
        {
            ProjetoId = request.ProjetoId,
            CodigoCadastral = request.CodigoCadastral,
            NumeroParcela = request.NumeroParcela,
            NumeroTalhao = request.NumeroTalhao,
            DivisaoAdministrativaId = request.DivisaoAdministrativaId,
            Geometria = multiPolygon,
            SistemaCoordenadas = string.IsNullOrWhiteSpace(request.SistemaCoordenadas) ? "EPSG:4326" : request.SistemaCoordenadas,
            PrecisaoLevantamento = request.PrecisaoLevantamento,
            Situacao = request.Situacao ?? SituacaoParcela.Desocupada,
            UsoAtual = request.UsoAtual,
            UsoPrevisto = request.UsoPrevisto,
            ClassificacaoPlano = request.ClassificacaoPlano,
            ParametrosUrbanisticos = request.ParametrosUrbanisticos,
            Restricoes = request.Restricoes,
            Condicionantes = request.Condicionantes,
            Estado = ApprovalStatus.Rascunho
        };

        await parcelas.AddAsync(parcela, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(parcela);
    }

    public async Task<Result<ParcelaDto>> UpdateAsync(Guid id, UpdateParcelaRequest request, CancellationToken ct = default)
    {
        var parcela = await parcelas.GetByIdAsync(id, ct);
        if (parcela is null)
            return Result.Failure<ParcelaDto>(NotFound(id));

        if (request.DivisaoAdministrativaId is not null && !await divisoes.ExistsAsync(request.DivisaoAdministrativaId.Value, ct))
            return Result.Failure<ParcelaDto>(Error.Validation("Parcela.DivisaoNotFound", "Divisão administrativa indicada não existe."));

        var geometriaError = ValidateGeometry(request.Geometria);
        if (geometriaError is not null)
            return Result.Failure<ParcelaDto>(geometriaError);

        var multiPolygon = ToMultiPolygon(request.Geometria);

        var overlapError = await CheckOverlapAsync(parcela.ProjetoId, multiPolygon, excludeId: parcela.Id, ct);
        if (overlapError is not null)
            return Result.Failure<ParcelaDto>(overlapError);

        if (!parcela.Geometria.EqualsExact(multiPolygon))
        {
            await geometriasHistorico.AddAsync(new GeometriaHistorico
            {
                EntidadeTipo = "parcela",
                EntidadeId = parcela.Id,
                ProjetoId = parcela.ProjetoId,
                GeometriaAnterior = parcela.Geometria,
                GeometriaNova = multiPolygon,
                UtilizadorId = currentUser.UtilizadorId,
                Motivo = request.Motivo,
                VersaoAnterior = parcela.Versao,
                VersaoNova = parcela.Versao + 1
            }, ct);
        }

        parcela.NumeroParcela = request.NumeroParcela;
        parcela.NumeroTalhao = request.NumeroTalhao;
        parcela.DivisaoAdministrativaId = request.DivisaoAdministrativaId;
        parcela.Geometria = multiPolygon;
        parcela.PrecisaoLevantamento = request.PrecisaoLevantamento;
        parcela.Situacao = request.Situacao;
        parcela.UsoAtual = request.UsoAtual;
        parcela.UsoPrevisto = request.UsoPrevisto;
        parcela.ClassificacaoPlano = request.ClassificacaoPlano;
        parcela.ParametrosUrbanisticos = request.ParametrosUrbanisticos;
        parcela.Restricoes = request.Restricoes;
        parcela.Condicionantes = request.Condicionantes;
        parcela.Versao += 1;
        parcela.UpdatedAt = DateTimeOffset.UtcNow;

        await parcelas.UpdateAsync(parcela, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(parcela);
    }

    private async Task<Error?> CheckOverlapAsync(Guid projetoId, NetTopologySuite.Geometries.MultiPolygon geometria, Guid? excludeId, CancellationToken ct)
    {
        var query = parcelas.Query().Where(p => p.ProjetoId == projetoId && p.Geometria.Overlaps(geometria));
        if (excludeId is not null) query = query.Where(p => p.Id != excludeId);

        var conflito = await query.Select(p => p.CodigoCadastral).FirstOrDefaultAsync(ct);
        return conflito is null
            ? null
            : Error.Conflict("Parcela.GeometryOverlap", $"A geometria sobrepõe-se à parcela '{conflito}'.");
    }

    private static Error? ValidateGeometry(NetTopologySuite.Geometries.Geometry geometria)
    {
        if (geometria is not NetTopologySuite.Geometries.Polygon and not NetTopologySuite.Geometries.MultiPolygon)
            return Error.Validation("Parcela.InvalidGeometryType", "A geometria da parcela tem de ser um polígono ou multi-polígono.");

        return geometria.IsValid
            ? null
            : Error.Validation("Parcela.InvalidGeometry", "Geometria inválida (auto-interseção ou anel malformado).");
    }

    private static NetTopologySuite.Geometries.MultiPolygon ToMultiPolygon(NetTopologySuite.Geometries.Geometry geometria) => geometria switch
    {
        NetTopologySuite.Geometries.MultiPolygon mp => mp,
        NetTopologySuite.Geometries.Polygon p => new NetTopologySuite.Geometries.MultiPolygon([p]) { SRID = p.SRID },
        _ => throw new InvalidOperationException("Geometria já validada como polígono/multi-polígono.")
    };

    private static Error NotFound(Guid id) => Error.NotFound("Parcela.NotFound", $"Parcela '{id}' não encontrada.");

    private static ParcelaDto ToDto(Parcela p) => new(
        p.Id, p.ProjetoId, p.CodigoCadastral, p.NumeroParcela, p.NumeroTalhao, p.DivisaoAdministrativaId,
        p.Geometria, p.Centroide, p.AreaCalculada, p.Perimetro, p.SistemaCoordenadas, p.PrecisaoLevantamento,
        p.Situacao, p.UsoAtual, p.UsoPrevisto, p.ClassificacaoPlano, p.ParametrosUrbanisticos, p.Restricoes,
        p.Condicionantes, p.Estado, p.Versao, p.CreatedAt, p.UpdatedAt);
}
