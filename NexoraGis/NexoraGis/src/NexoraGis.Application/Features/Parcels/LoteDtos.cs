using NetTopologySuite.Geometries;

namespace NexoraGis.Application.Features.Parcels;

public record LoteDto(Guid Id, Guid ParcelaId, string Codigo, Geometry Geometria, decimal? AreaCalculada, DateTimeOffset CreatedAt);

public record CreateLoteRequest(string Codigo, Geometry Geometria);
