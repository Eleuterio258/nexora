using NetTopologySuite.Geometries;

namespace NexoraGis.Application.Features.Zoning;

public record ZonaDto(
    Guid Id,
    Guid PlanoId,
    string Codigo,
    string Designacao,
    string Cor,
    Geometry? Geometria,
    string? Parametros,
    IReadOnlyList<string> AtividadesPermitidas,
    IReadOnlyList<string> AtividadesCondicionadas,
    IReadOnlyList<string> AtividadesProibidas,
    decimal? AreaCalculada,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public record UpsertZonaRequest(
    Guid PlanoId,
    string Codigo,
    string Designacao,
    string? Cor,
    Geometry? Geometria,
    string? Parametros,
    IReadOnlyList<string>? AtividadesPermitidas,
    IReadOnlyList<string>? AtividadesCondicionadas,
    IReadOnlyList<string>? AtividadesProibidas);

/// <summary>Parcela cuja geometria interseta a zona — associação espacial (backlog 5.2.4 / 5.3.3).</summary>
public record ParcelaAfetadaDto(Guid ParcelaId, string CodigoCadastral);
