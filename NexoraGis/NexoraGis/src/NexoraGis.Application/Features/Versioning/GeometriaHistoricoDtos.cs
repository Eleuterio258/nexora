using NetTopologySuite.Geometries;

namespace NexoraGis.Application.Features.Versioning;

public record GeometriaHistoricoDto(
    Guid Id,
    string EntidadeTipo,
    Guid EntidadeId,
    Guid? ProjetoId,
    Geometry? GeometriaAnterior,
    Geometry? GeometriaNova,
    Guid? UtilizadorId,
    DateTimeOffset DataAlteracao,
    string? Motivo,
    int? VersaoAnterior,
    int? VersaoNova);

/// <summary>Geometria reconstruída para uma data (backlog 6.2.2). Encontrado=false quando não há histórico para a entidade.</summary>
public record GeometryAtDateDto(bool Encontrado, DateTimeOffset DataConsultada, Geometry? Geometria, DateTimeOffset? VigenteDesde);
