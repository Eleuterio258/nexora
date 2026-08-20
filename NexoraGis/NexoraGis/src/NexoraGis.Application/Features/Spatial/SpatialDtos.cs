using NetTopologySuite.Geometries;

namespace NexoraGis.Application.Features.Spatial;

public record AffectedParcelsRequest(Geometry Geometria, Guid? ProjetoId);

public record AffectedParcelDto(Guid ParcelaId, string CodigoCadastral);

/// <summary>
/// Sumário territorial de um projeto (backlog 5.3.4). As áreas reaproveitam
/// colunas geradas pelo Postgres (ST_Area sobre ::geography), não são
/// recalculadas em .NET.
/// </summary>
public record ProjectStatisticsDto(
    Guid ProjetoId,
    int TotalParcelas,
    decimal AreaTotalParcelasM2,
    int TotalEdificacoes,
    decimal AreaTotalEdificacoesM2,
    int TotalInfraestruturas,
    int TotalZonas,
    decimal AreaTotalZonasHectares,
    int ConflitosAtivos,
    int FiscalizacoesAbertas,
    int AprovacoesPendentes,
    IReadOnlyDictionary<string, int> ParcelasPorSituacao,
    IReadOnlyDictionary<string, int> ParcelasPorUsoAtual);
