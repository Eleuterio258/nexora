using NetTopologySuite.Geometries;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Features.AdministrativeDivisions;

public record DivisaoAdministrativaDto(
    Guid Id,
    Guid? ParentId,
    TipoDivisao Tipo,
    string Codigo,
    string Nome,
    string? NomeNormalizado,
    bool? ZonaUrbana,
    int NivelHierarquico,
    string? EntidadeResponsavel,
    string? CodigoIne,
    Geometry? Geometria,
    decimal? AreaCalculada,
    bool Ativo,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public record CreateDivisaoAdministrativaRequest(
    Guid? ParentId,
    TipoDivisao Tipo,
    string Codigo,
    string Nome,
    string? NomeNormalizado,
    bool? ZonaUrbana,
    int NivelHierarquico,
    string? EntidadeResponsavel,
    string? CodigoIne,
    Geometry? Geometria,
    string? Metadados);

public record UpdateDivisaoAdministrativaRequest(
    string Nome,
    string? NomeNormalizado,
    bool? ZonaUrbana,
    string? EntidadeResponsavel,
    string? CodigoIne,
    Geometry? Geometria,
    bool Ativo,
    string? Metadados);

/// <summary>Um nó do caminho hierárquico, da raiz até à divisão pedida (inclusive).</summary>
public record DivisaoAdministrativaPathNodeDto(Guid Id, TipoDivisao Tipo, string Codigo, string Nome);
