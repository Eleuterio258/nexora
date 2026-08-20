using NetTopologySuite.Geometries;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Features.Projects;

public record ProjetoDto(
    Guid Id,
    Guid OrganizacaoId,
    string Codigo,
    string Designacao,
    string? Descricao,
    string? Cliente,
    string Tipo,
    string? Localizacao,
    Guid? DivisaoAdministrativaId,
    Geometry? AreaIntervencao,
    string SistemaReferencia,
    Guid? ResponsavelTecnicoId,
    DateOnly? DataInicio,
    DateOnly? DataPrevistaConclusao,
    ProjectStatus Status,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public record CreateProjetoRequest(
    string Codigo,
    string Designacao,
    string? Descricao,
    string? Cliente,
    string Tipo,
    string? Localizacao,
    Guid? DivisaoAdministrativaId,
    Geometry? AreaIntervencao,
    string? SistemaReferencia,
    Guid? ResponsavelTecnicoId,
    DateOnly? DataInicio,
    DateOnly? DataPrevistaConclusao);

public record UpdateProjetoRequest(
    string Designacao,
    string? Descricao,
    string? Cliente,
    string? Localizacao,
    Guid? DivisaoAdministrativaId,
    Geometry? AreaIntervencao,
    Guid? ResponsavelTecnicoId,
    DateOnly? DataInicio,
    DateOnly? DataPrevistaConclusao);

public record ChangeProjetoStatusRequest(ProjectStatus NovoStatus);

public record ProjetoEquipaDto(Guid Id, Guid UtilizadorId, string NomeCompleto, string? Funcao, bool Ativo, DateTimeOffset CreatedAt);

public record AddTeamMemberRequest(Guid UtilizadorId, string? Funcao);
