using NetTopologySuite.Geometries;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Features.Conflicts;

public record ConflitoDto(
    Guid Id,
    Guid ProjetoId,
    TipoConflito Tipo,
    string Descricao,
    string? EntidadeTipo,
    Guid? EntidadeId,
    Geometry? Geometria,
    bool Resolvido,
    DateTimeOffset DataDetecao,
    DateTimeOffset? DataResolucao,
    Guid? ResolvidoPor);

/// <summary>Registo manual de um conflito (ex: observado em fiscalização de campo).</summary>
public record CreateConflitoRequest(
    Guid ProjetoId,
    TipoConflito Tipo,
    string Descricao,
    string? EntidadeTipo,
    Guid? EntidadeId,
    string? Detalhes);
