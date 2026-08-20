using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Features.Approvals;

/// <summary>
/// Transições válidas do workflow de aprovação (backlog 6.1.1): Rascunho →
/// Submetido → Em Análise → Aprovado/Rejeitado/Correção solicitada →
/// Publicado. Rejeitado pode ser reaberto para uma nova ronda.
/// </summary>
public static class AprovacaoStatusWorkflow
{
    private static readonly Dictionary<ApprovalStatus, ApprovalStatus[]> Transitions = new()
    {
        [ApprovalStatus.Rascunho] = [ApprovalStatus.Submetido],
        [ApprovalStatus.Submetido] = [ApprovalStatus.EmAnalise],
        [ApprovalStatus.EmAnalise] = [ApprovalStatus.CorrecaoSolicitada, ApprovalStatus.Aprovado, ApprovalStatus.Rejeitado],
        [ApprovalStatus.CorrecaoSolicitada] = [ApprovalStatus.Submetido],
        [ApprovalStatus.Aprovado] = [ApprovalStatus.Publicado],
        [ApprovalStatus.Rejeitado] = [ApprovalStatus.Rascunho],
        [ApprovalStatus.Publicado] = []
    };

    public static bool CanTransition(ApprovalStatus from, ApprovalStatus to) =>
        Transitions.TryGetValue(from, out var allowed) && allowed.Contains(to);
}
