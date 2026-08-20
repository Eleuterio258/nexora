using NetTopologySuite.Geometries;

namespace NexoraGis.Application.Features.Inspections;

public record FiscalizacaoDto(
    Guid Id,
    Guid ProjetoId,
    Guid? ParcelaId,
    Guid? FiscalId,
    DateTimeOffset DataOcorrencia,
    Point? Coordenadas,
    string Descricao,
    IReadOnlyList<string> Fotografias,
    string Estado,
    string? AcaoNecessaria,
    Guid? Responsavel,
    DateTimeOffset? DataResolucao,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public record CreateFiscalizacaoRequest(
    Guid ProjetoId,
    Guid? ParcelaId,
    Point? Coordenadas,
    string Descricao,
    List<string>? Fotografias,
    string? AcaoNecessaria);

/// <summary>Estados livres (backlog 8.3.4): aberto → em_analise → resolvido.</summary>
public record UpdateFiscalizacaoEstadoRequest(string Estado, string? AcaoNecessaria);
