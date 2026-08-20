using NetTopologySuite.Geometries;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Features.Infrastructure;

public record InfraestruturaDto(
    Guid Id, Guid ProjetoId, TipoInfraestrutura Tipo, string Subtipo, string? Codigo, string? Designacao,
    Geometry? Geometria, string? Atributos, string? EstadoConservacao, DateOnly? DataLevantamento,
    DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);

public record UpsertInfraestruturaRequest(
    Guid ProjetoId, TipoInfraestrutura Tipo, string Subtipo, string? Codigo, string? Designacao,
    Geometry? Geometria, string? Atributos, string? EstadoConservacao, DateOnly? DataLevantamento);

public record EquipamentoDto(
    Guid Id, Guid ProjetoId, string Tipo, string? Codigo, string Nome, Point? Geometria, string? Morada,
    string? Contacto, string? HorarioFuncionamento, int? Capacidade, string? Atributos, bool Ativo,
    DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);

public record UpsertEquipamentoRequest(
    Guid ProjetoId, string Tipo, string? Codigo, string Nome, Point? Geometria, string? Morada,
    string? Contacto, string? HorarioFuncionamento, int? Capacidade, string? Atributos, bool Ativo);
