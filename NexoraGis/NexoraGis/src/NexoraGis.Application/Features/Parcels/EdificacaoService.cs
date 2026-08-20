using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Parcels;

public class EdificacaoService(IRepository<Edificacao> edificacoes, IRepository<Parcela> parcelas, IUnitOfWork unitOfWork)
{
    public async Task<Result<IReadOnlyList<EdificacaoDto>>> ListAsync(Guid parcelaId, CancellationToken ct = default)
    {
        if (!await parcelas.ExistsAsync(parcelaId, ct))
            return Result.Failure<IReadOnlyList<EdificacaoDto>>(ParcelaNotFound(parcelaId));

        var items = await edificacoes.Query().Where(e => e.ParcelaId == parcelaId).OrderBy(e => e.Codigo).ToListAsync(ct);
        return Result.Success<IReadOnlyList<EdificacaoDto>>(items.Select(ToDto).ToList());
    }

    public async Task<Result<EdificacaoDto>> CreateAsync(Guid parcelaId, UpsertEdificacaoRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Codigo))
            return Result.Failure<EdificacaoDto>(Error.Validation("Edificacao.Invalid", "Código é obrigatório."));

        if (!await parcelas.ExistsAsync(parcelaId, ct))
            return Result.Failure<EdificacaoDto>(ParcelaNotFound(parcelaId));

        if (await edificacoes.Query().AnyAsync(e => e.ParcelaId == parcelaId && e.Codigo == request.Codigo, ct))
            return Result.Failure<EdificacaoDto>(Error.Conflict("Edificacao.DuplicateCodigo", $"Já existe uma edificação '{request.Codigo}' nesta parcela."));

        var geometriaError = ValidateGeometry(request.Geometria);
        if (geometriaError is not null)
            return Result.Failure<EdificacaoDto>(geometriaError);

        var edificacao = new Edificacao { ParcelaId = parcelaId, Codigo = request.Codigo };
        Apply(edificacao, request);

        await edificacoes.AddAsync(edificacao, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(edificacao);
    }

    public async Task<Result<EdificacaoDto>> UpdateAsync(Guid parcelaId, Guid edificacaoId, UpsertEdificacaoRequest request, CancellationToken ct = default)
    {
        var edificacao = await edificacoes.GetByIdAsync(edificacaoId, ct);
        if (edificacao is null || edificacao.ParcelaId != parcelaId)
            return Result.Failure<EdificacaoDto>(NotFound(edificacaoId));

        var geometriaError = ValidateGeometry(request.Geometria);
        if (geometriaError is not null)
            return Result.Failure<EdificacaoDto>(geometriaError);

        Apply(edificacao, request);
        edificacao.UpdatedAt = DateTimeOffset.UtcNow;

        await edificacoes.UpdateAsync(edificacao, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(edificacao);
    }

    public async Task<Result> DeleteAsync(Guid parcelaId, Guid edificacaoId, CancellationToken ct = default)
    {
        var edificacao = await edificacoes.GetByIdAsync(edificacaoId, ct);
        if (edificacao is null || edificacao.ParcelaId != parcelaId)
            return Result.Failure(NotFound(edificacaoId));

        await edificacoes.DeleteAsync(edificacao, ct);
        await unitOfWork.SaveChangesAsync(ct);
        return Result.Success();
    }

    private static void Apply(Edificacao edificacao, UpsertEdificacaoRequest request)
    {
        edificacao.Localizacao = request.Localizacao;
        edificacao.Geometria = ToMultiPolygon(request.Geometria);
        edificacao.AreaConstruida = request.AreaConstruida;
        edificacao.NumeroPisos = request.NumeroPisos;
        edificacao.TipoConstrucao = request.TipoConstrucao;
        edificacao.Finalidade = request.Finalidade;
        edificacao.MaterialPredominante = request.MaterialPredominante;
        edificacao.EstadoConservacao = request.EstadoConservacao;
        edificacao.SituacaoOcupacao = request.SituacaoOcupacao;
        edificacao.Fotografias = request.Fotografias ?? [];
        edificacao.Coordenadas = request.Coordenadas;
        edificacao.DataLevantamento = request.DataLevantamento;
    }

    private static Error? ValidateGeometry(Geometry? geometria)
    {
        if (geometria is null)
            return null;

        if (geometria is not Polygon and not MultiPolygon)
            return Error.Validation("Edificacao.InvalidGeometryType", "A geometria da edificação tem de ser um polígono ou multi-polígono.");

        return geometria.IsValid
            ? null
            : Error.Validation("Edificacao.InvalidGeometry", "Geometria inválida (auto-interseção ou anel malformado).");
    }

    private static MultiPolygon? ToMultiPolygon(Geometry? geometria) => geometria switch
    {
        null => null,
        MultiPolygon mp => mp,
        Polygon p => new MultiPolygon([p]) { SRID = p.SRID },
        _ => throw new InvalidOperationException("Geometria já validada como polígono/multi-polígono.")
    };

    private static Error ParcelaNotFound(Guid id) => Error.NotFound("Parcela.NotFound", $"Parcela '{id}' não encontrada.");
    private static Error NotFound(Guid id) => Error.NotFound("Edificacao.NotFound", $"Edificação '{id}' não encontrada.");

    private static EdificacaoDto ToDto(Edificacao e) => new(
        e.Id, e.ParcelaId, e.Codigo, e.Localizacao, e.Geometria, e.AreaConstruida, e.NumeroPisos, e.TipoConstrucao,
        e.Finalidade, e.MaterialPredominante, e.EstadoConservacao, e.SituacaoOcupacao, e.Fotografias, e.Coordenadas,
        e.DataLevantamento, e.CreatedAt, e.UpdatedAt);
}
