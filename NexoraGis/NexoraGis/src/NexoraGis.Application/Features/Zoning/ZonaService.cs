using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;
using NexoraGis.Domain.Entities.Cadastro;
using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Repositories;

namespace NexoraGis.Application.Features.Zoning;

public class ZonaService(
    IRepository<Zona> zonas,
    IRepository<Plano> planos,
    IRepository<Parcela> parcelas,
    IUnitOfWork unitOfWork)
{
    public async Task<Result<ZonaDto>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var zona = await zonas.GetByIdAsync(id, ct);
        return zona is null ? Result.Failure<ZonaDto>(NotFound(id)) : ToDto(zona);
    }

    public async Task<PagedResult<ZonaDto>> ListAsync(Guid? planoId, string? codigo, int page, int pageSize, CancellationToken ct = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 200 ? 50 : pageSize;

        var query = zonas.Query();
        if (planoId is not null) query = query.Where(z => z.PlanoId == planoId);
        if (!string.IsNullOrWhiteSpace(codigo)) query = query.Where(z => z.Codigo == codigo);

        var totalCount = await query.CountAsync(ct);
        var items = await query.OrderBy(z => z.Codigo).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return new PagedResult<ZonaDto>(items.Select(ToDto).ToList(), page, pageSize, totalCount);
    }

    public async Task<Result<ZonaDto>> CreateAsync(UpsertZonaRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Codigo) || string.IsNullOrWhiteSpace(request.Designacao))
            return Result.Failure<ZonaDto>(Error.Validation("Zona.Invalid", "Código e designação são obrigatórios."));

        if (!await planos.ExistsAsync(request.PlanoId, ct))
            return Result.Failure<ZonaDto>(Error.Validation("Zona.PlanoNotFound", "Plano indicado não existe."));

        if (await zonas.Query().AnyAsync(z => z.PlanoId == request.PlanoId && z.Codigo == request.Codigo, ct))
            return Result.Failure<ZonaDto>(Error.Conflict("Zona.DuplicateCodigo", $"Já existe uma zona com o código '{request.Codigo}' neste plano."));

        var geometriaError = ValidateGeometry(request.Geometria);
        if (geometriaError is not null)
            return Result.Failure<ZonaDto>(geometriaError);

        var zona = new Zona { PlanoId = request.PlanoId };
        Apply(zona, request);

        await zonas.AddAsync(zona, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(zona);
    }

    public async Task<Result<ZonaDto>> UpdateAsync(Guid id, UpsertZonaRequest request, CancellationToken ct = default)
    {
        var zona = await zonas.GetByIdAsync(id, ct);
        if (zona is null)
            return Result.Failure<ZonaDto>(NotFound(id));

        if (string.IsNullOrWhiteSpace(request.Codigo) || string.IsNullOrWhiteSpace(request.Designacao))
            return Result.Failure<ZonaDto>(Error.Validation("Zona.Invalid", "Código e designação são obrigatórios."));

        if (await zonas.Query().AnyAsync(z => z.PlanoId == zona.PlanoId && z.Codigo == request.Codigo && z.Id != id, ct))
            return Result.Failure<ZonaDto>(Error.Conflict("Zona.DuplicateCodigo", $"Já existe uma zona com o código '{request.Codigo}' neste plano."));

        var geometriaError = ValidateGeometry(request.Geometria);
        if (geometriaError is not null)
            return Result.Failure<ZonaDto>(geometriaError);

        Apply(zona, request);
        zona.UpdatedAt = DateTimeOffset.UtcNow;

        await zonas.UpdateAsync(zona, ct);
        await unitOfWork.SaveChangesAsync(ct);

        return ToDto(zona);
    }

    public async Task<Result> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var zona = await zonas.GetByIdAsync(id, ct);
        if (zona is null)
            return Result.Failure(NotFound(id));

        await zonas.DeleteAsync(zona, ct);
        await unitOfWork.SaveChangesAsync(ct);
        return Result.Success();
    }

    /// <summary>Parcelas cuja geometria interseta a zona — associação espacial (backlog 5.2.4 / 5.3.3).</summary>
    public async Task<Result<IReadOnlyList<ParcelaAfetadaDto>>> ListParcelasAfetadasAsync(Guid id, CancellationToken ct = default)
    {
        var zona = await zonas.GetByIdAsync(id, ct);
        if (zona is null)
            return Result.Failure<IReadOnlyList<ParcelaAfetadaDto>>(NotFound(id));

        if (zona.Geometria is null)
            return Result.Success<IReadOnlyList<ParcelaAfetadaDto>>([]);

        var afetadas = await parcelas.Query()
            .Where(p => p.Geometria.Intersects(zona.Geometria))
            .Select(p => new ParcelaAfetadaDto(p.Id, p.CodigoCadastral))
            .ToListAsync(ct);

        return Result.Success<IReadOnlyList<ParcelaAfetadaDto>>(afetadas);
    }

    private static void Apply(Zona zona, UpsertZonaRequest request)
    {
        zona.Codigo = request.Codigo;
        zona.Designacao = request.Designacao;
        if (!string.IsNullOrWhiteSpace(request.Cor)) zona.Cor = request.Cor;
        zona.Geometria = ToMultiPolygon(request.Geometria);
        zona.Parametros = request.Parametros;
        zona.AtividadesPermitidas = request.AtividadesPermitidas?.ToList() ?? [];
        zona.AtividadesCondicionadas = request.AtividadesCondicionadas?.ToList() ?? [];
        zona.AtividadesProibidas = request.AtividadesProibidas?.ToList() ?? [];
    }

    private static Error? ValidateGeometry(Geometry? geometria)
    {
        if (geometria is null)
            return null;

        if (geometria is not Polygon and not MultiPolygon)
            return Error.Validation("Zona.InvalidGeometryType", "A geometria da zona tem de ser um polígono ou multi-polígono.");

        return geometria.IsValid
            ? null
            : Error.Validation("Zona.InvalidGeometry", "Geometria inválida (auto-interseção ou anel malformado).");
    }

    private static MultiPolygon? ToMultiPolygon(Geometry? geometria) => geometria switch
    {
        null => null,
        MultiPolygon mp => mp,
        Polygon p => new MultiPolygon([p]) { SRID = p.SRID },
        _ => throw new InvalidOperationException("Geometria já validada como polígono/multi-polígono.")
    };

    private static Error NotFound(Guid id) => Error.NotFound("Zona.NotFound", $"Zona '{id}' não encontrada.");

    private static ZonaDto ToDto(Zona z) => new(
        z.Id, z.PlanoId, z.Codigo, z.Designacao, z.Cor, z.Geometria, z.Parametros,
        z.AtividadesPermitidas, z.AtividadesCondicionadas, z.AtividadesProibidas, z.AreaCalculada, z.CreatedAt, z.UpdatedAt);
}
