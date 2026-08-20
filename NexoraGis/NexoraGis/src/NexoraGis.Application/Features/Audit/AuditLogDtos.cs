using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Features.Audit;

public record AuditLogDto(
    Guid Id,
    Guid? UtilizadorId,
    string? UtilizadorNome,
    TipoOperacaoAuditoria Operacao,
    string EntidadeTipo,
    Guid? EntidadeId,
    Guid? ProjetoId,
    string? DadosAnteriores,
    string? DadosNovos,
    DateTimeOffset DataHora);
