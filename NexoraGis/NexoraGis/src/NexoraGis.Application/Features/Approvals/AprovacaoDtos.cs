using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Features.Approvals;

public record AprovacaoDto(
    Guid Id,
    string EntidadeTipo,
    Guid EntidadeId,
    Guid ProjetoId,
    ApprovalStatus Status,
    Guid? RequisitadoPor,
    Guid? VerificadoPor,
    Guid? AprovadoPor,
    DateTimeOffset? DataSubmissao,
    DateTimeOffset? DataAnalise,
    DateTimeOffset? DataAprovacao,
    DateTimeOffset? DataPublicacao,
    string? MotivoRejeicao,
    string? Observacoes,
    int Versao,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

/// <summary>Abre um novo workflow de aprovação para uma entidade (parcela, plano, ...). Entidades sem workflow em curso.</summary>
public record CreateAprovacaoRequest(string EntidadeTipo, Guid EntidadeId, Guid ProjetoId);

public record PedirCorrecaoRequest(string Observacoes);

public record RejeitarRequest(string MotivoRejeicao);
