using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Features.Projects;

/// <summary>
/// Transições válidas do estado do projeto territorial (§4 do documento
/// funcional): fluxo principal sequencial, com retorno de "Em Revisão" para
/// "Proposta" para correções, e arquivamento possível a partir de qualquer
/// estado não terminal.
/// </summary>
public static class ProjetoStatusWorkflow
{
    private static readonly Dictionary<ProjectStatus, ProjectStatus[]> Transitions = new()
    {
        [ProjectStatus.Rascunho] = [ProjectStatus.Levantamento, ProjectStatus.Arquivado],
        [ProjectStatus.Levantamento] = [ProjectStatus.Diagnostico, ProjectStatus.Arquivado],
        [ProjectStatus.Diagnostico] = [ProjectStatus.Proposta, ProjectStatus.Arquivado],
        [ProjectStatus.Proposta] = [ProjectStatus.EmRevisao, ProjectStatus.Arquivado],
        [ProjectStatus.EmRevisao] = [ProjectStatus.Aprovado, ProjectStatus.Proposta, ProjectStatus.Arquivado],
        [ProjectStatus.Aprovado] = [ProjectStatus.Publicado, ProjectStatus.Arquivado],
        [ProjectStatus.Publicado] = [ProjectStatus.EmImplementacao, ProjectStatus.Arquivado],
        [ProjectStatus.EmImplementacao] = [ProjectStatus.Arquivado],
        [ProjectStatus.Arquivado] = []
    };

    public static bool CanTransition(ProjectStatus from, ProjectStatus to) =>
        from == to || (Transitions.TryGetValue(from, out var allowed) && allowed.Contains(to));
}
