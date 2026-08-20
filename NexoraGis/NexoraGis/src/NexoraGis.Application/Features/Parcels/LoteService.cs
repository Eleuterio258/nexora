using Microsoft.EntityFrameworkCore;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Parcels;

public class LoteService(IRepository<Lote> lotes, IRepository<Parcela> parcelas, IUnitOfWork unitOfWork)
{
    public async Task<Result<IReadOnlyList<LoteDto>>> ListAsync(Guid parcelaId, CancellationToken ct = default)
    {
        if (!await parcelas.ExistsAsync(parcelaId, ct))
            return Result.Failure<IReadOnlyList<LoteDto>>(ParcelaNotFound(parcelaId));

        var items = await lotes.Query().Where(l => l.ParcelaId == parcelaId).OrderBy(l => l.Codigo).ToListAsync(ct);
        return Result.Success<IReadOnlyList<LoteDto>>(items.Select(ToDto).ToList());
    }

    public async Task<Result<LoteDto>> CreateAsync(Guid parcelaId, CreateLoteRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Codigo))
            return Result.Failure<LoteDto>(Error.Validation("Lote.Invalid", "Código é obrigatório."));

        if (!await parcelas.ExistsAsync(parcelaId, ct))
            return Result.Failure<LoteDto>(ParcelaNotFound(parcelaId));

        if (!request.Geometria.IsValid)
            return Result.Failure<LoteDto>(Error.Validation("Lote.InvalidGeometry", "Geometria inválida."));

        if (await lotes.Query().AnyAsync(l => l.ParcelaId == parcelaId && l.Codigo == request.Codigo, ct))
            return Result.Failure<LoteDto>(Error.Conflict("Lote.DuplicateCodigo", $"Já existe um lote '{request.Codigo}' nesta parcela."));

        var geometria = request.Geometria as NetTopologySuite.Geometries.MultiPolygon
            ?? new NetTopologySuite.Geometries.MultiPolygon([(NetTopologySuite.Geometries.Polygon)request.Geometria]);

        var lote = new Lote { ParcelaId = parcelaId, Codigo = request.Codigo, Geometria = geometria };
        await lotes.AddAsync(lote, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(lote);
    }

    public async Task<Result> DeleteAsync(Guid parcelaId, Guid loteId, CancellationToken ct = default)
    {
        var lote = await lotes.GetByIdAsync(loteId, ct);
        if (lote is null || lote.ParcelaId != parcelaId)
            return Result.Failure(Error.NotFound("Lote.NotFound", $"Lote '{loteId}' não encontrado nesta parcela."));

        await lotes.DeleteAsync(lote, ct);
        await unitOfWork.SaveChangesAsync(ct);
        return Result.Success();
    }

    private static Error ParcelaNotFound(Guid id) => Error.NotFound("Parcela.NotFound", $"Parcela '{id}' não encontrada.");

    private static LoteDto ToDto(Lote l) => new(l.Id, l.ParcelaId, l.Codigo, l.Geometria, l.AreaCalculada, l.CreatedAt);
}
