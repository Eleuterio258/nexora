using NetTopologySuite.Geometries;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Features.Parcels;

public record EdificacaoDto(
    Guid Id,
    Guid ParcelaId,
    string Codigo,
    string? Localizacao,
    Geometry? Geometria,
    decimal? AreaConstruida,
    int? NumeroPisos,
    string? TipoConstrucao,
    UsoSolo? Finalidade,
    string? MaterialPredominante,
    string? EstadoConservacao,
    string? SituacaoOcupacao,
    IReadOnlyList<string> Fotografias,
    Point? Coordenadas,
    DateOnly? DataLevantamento,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public record UpsertEdificacaoRequest(
    string Codigo,
    string? Localizacao,
    Geometry? Geometria,
    decimal? AreaConstruida,
    int? NumeroPisos,
    string? TipoConstrucao,
    UsoSolo? Finalidade,
    string? MaterialPredominante,
    string? EstadoConservacao,
    string? SituacaoOcupacao,
    List<string>? Fotografias,
    Point? Coordenadas,
    DateOnly? DataLevantamento);
