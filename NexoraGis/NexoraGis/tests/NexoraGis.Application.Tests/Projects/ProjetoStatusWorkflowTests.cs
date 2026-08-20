using NexoraGis.Application.Features.Projects;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Tests.Projects;

public class ProjetoStatusWorkflowTests
{
    [Theory]
    [InlineData(ProjectStatus.Rascunho, ProjectStatus.Levantamento, true)]
    [InlineData(ProjectStatus.Levantamento, ProjectStatus.Diagnostico, true)]
    [InlineData(ProjectStatus.Diagnostico, ProjectStatus.Proposta, true)]
    [InlineData(ProjectStatus.Proposta, ProjectStatus.EmRevisao, true)]
    [InlineData(ProjectStatus.EmRevisao, ProjectStatus.Aprovado, true)]
    [InlineData(ProjectStatus.EmRevisao, ProjectStatus.Proposta, true)]
    [InlineData(ProjectStatus.Aprovado, ProjectStatus.Publicado, true)]
    [InlineData(ProjectStatus.Publicado, ProjectStatus.EmImplementacao, true)]
    public void CanTransition_AllowsDocumentedPaths(ProjectStatus from, ProjectStatus to, bool expected)
    {
        Assert.Equal(expected, ProjetoStatusWorkflow.CanTransition(from, to));
    }

    [Theory]
    [InlineData(ProjectStatus.Rascunho, ProjectStatus.Aprovado)]
    [InlineData(ProjectStatus.Rascunho, ProjectStatus.Publicado)]
    [InlineData(ProjectStatus.Publicado, ProjectStatus.Rascunho)]
    [InlineData(ProjectStatus.Aprovado, ProjectStatus.Levantamento)]
    public void CanTransition_RejectsSkippedOrBackwardSteps(ProjectStatus from, ProjectStatus to)
    {
        Assert.False(ProjetoStatusWorkflow.CanTransition(from, to));
    }

    [Fact]
    public void CanTransition_ArquivadoReachableFromAnyNonTerminalStatus()
    {
        foreach (var status in Enum.GetValues<ProjectStatus>())
        {
            if (status == ProjectStatus.Arquivado) continue;
            Assert.True(ProjetoStatusWorkflow.CanTransition(status, ProjectStatus.Arquivado));
        }
    }

    [Fact]
    public void CanTransition_ArquivadoIsTerminal()
    {
        // from == to é sempre permitido por design (ver CanTransition_SameStatusIsAllowed);
        // "terminal" aqui significa que não há nenhuma transição para um estado DIFERENTE.
        foreach (var status in Enum.GetValues<ProjectStatus>().Where(s => s != ProjectStatus.Arquivado))
            Assert.False(ProjetoStatusWorkflow.CanTransition(ProjectStatus.Arquivado, status));
    }

    [Fact]
    public void CanTransition_SameStatusIsAllowed()
    {
        Assert.True(ProjetoStatusWorkflow.CanTransition(ProjectStatus.Proposta, ProjectStatus.Proposta));
    }
}
