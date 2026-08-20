using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Features.Surveys;

public record LevantamentoDto(
    Guid Id, Guid ProjetoId, string Codigo, string? Designacao, Guid? ResponsavelId, TipoLevantamento Tipo,
    string? EquipamentoUtilizado, string? Metodo, DateTimeOffset? DataInicio, DateTimeOffset? DataFim,
    string Status, string? Observacoes, int TotalPontos, DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);

public record CreateLevantamentoRequest(
    Guid ProjetoId, string Codigo, string? Designacao, Guid? ResponsavelId, TipoLevantamento Tipo,
    string? EquipamentoUtilizado, string? Metodo, DateTimeOffset? DataInicio, string? Observacoes);

public record UpdateLevantamentoStatusRequest(string Status, DateTimeOffset? DataFim, string? Observacoes);
