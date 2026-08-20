using NetTopologySuite.Geometries;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Features.Parcels;

public record ParcelaDto(
    Guid Id,
    Guid ProjetoId,
    string CodigoCadastral,
    string? NumeroParcela,
    string? NumeroTalhao,
    Guid? DivisaoAdministrativaId,
    Geometry Geometria,
    Point? Centroide,
    decimal? AreaCalculada,
    decimal? Perimetro,
    string SistemaCoordenadas,
    decimal? PrecisaoLevantamento,
    SituacaoParcela Situacao,
    UsoSolo? UsoAtual,
    UsoSolo? UsoPrevisto,
    string? ClassificacaoPlano,
    string? ParametrosUrbanisticos,
    string? Restricoes,
    string? Condicionantes,
    ApprovalStatus Estado,
    int Versao,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public record CreateParcelaRequest(
    Guid ProjetoId,
    string CodigoCadastral,
    string? NumeroParcela,
    string? NumeroTalhao,
    Guid? DivisaoAdministrativaId,
    Geometry Geometria,
    string? SistemaCoordenadas,
    decimal? PrecisaoLevantamento,
    SituacaoParcela? Situacao,
    UsoSolo? UsoAtual,
    UsoSolo? UsoPrevisto,
    string? ClassificacaoPlano,
    string? ParametrosUrbanisticos,
    string? Restricoes,
    string? Condicionantes);

public record UpdateParcelaRequest(
    string? NumeroParcela,
    string? NumeroTalhao,
    Guid? DivisaoAdministrativaId,
    Geometry Geometria,
    decimal? PrecisaoLevantamento,
    SituacaoParcela Situacao,
    UsoSolo? UsoAtual,
    UsoSolo? UsoPrevisto,
    string? ClassificacaoPlano,
    string? ParametrosUrbanisticos,
    string? Restricoes,
    string? Condicionantes,
    /// <summary>Motivo da alteração de geometria (backlog 6.2.1) — guardado no histórico só se a geometria mudar.</summary>
    string? Motivo = null);

public record ParcelaSearchRequest(Geometry Area, Guid? ProjetoId);
