using NexoraGis.Application.Features.Approvals;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Tests.Approvals;

public class AprovacaoStatusWorkflowTests
{
    [Theory]
    [InlineData(ApprovalStatus.Rascunho, ApprovalStatus.Submetido, true)]
    [InlineData(ApprovalStatus.Submetido, ApprovalStatus.EmAnalise, true)]
    [InlineData(ApprovalStatus.EmAnalise, ApprovalStatus.CorrecaoSolicitada, true)]
    [InlineData(ApprovalStatus.EmAnalise, ApprovalStatus.Aprovado, true)]
    [InlineData(ApprovalStatus.EmAnalise, ApprovalStatus.Rejeitado, true)]
    [InlineData(ApprovalStatus.CorrecaoSolicitada, ApprovalStatus.Submetido, true)]
    [InlineData(ApprovalStatus.Aprovado, ApprovalStatus.Publicado, true)]
    [InlineData(ApprovalStatus.Rejeitado, ApprovalStatus.Rascunho, true)]
    public void CanTransition_AllowsDocumentedPaths(ApprovalStatus from, ApprovalStatus to, bool expected)
    {
        Assert.Equal(expected, AprovacaoStatusWorkflow.CanTransition(from, to));
    }

    [Theory]
    [InlineData(ApprovalStatus.Rascunho, ApprovalStatus.Aprovado)]
    [InlineData(ApprovalStatus.Rascunho, ApprovalStatus.Publicado)]
    [InlineData(ApprovalStatus.EmAnalise, ApprovalStatus.Publicado)]
    [InlineData(ApprovalStatus.Aprovado, ApprovalStatus.Rejeitado)]
    [InlineData(ApprovalStatus.Publicado, ApprovalStatus.Rascunho)]
    [InlineData(ApprovalStatus.Publicado, ApprovalStatus.Aprovado)]
    public void CanTransition_RejectsSkippedOrBackwardSteps(ApprovalStatus from, ApprovalStatus to)
    {
        Assert.False(AprovacaoStatusWorkflow.CanTransition(from, to));
    }

    [Fact]
    public void CanTransition_PublicadoIsTerminal()
    {
        foreach (var status in Enum.GetValues<ApprovalStatus>())
            Assert.False(AprovacaoStatusWorkflow.CanTransition(ApprovalStatus.Publicado, status));
    }

    [Fact]
    public void CanTransition_SameStatusIsNotATransition()
    {
        Assert.False(AprovacaoStatusWorkflow.CanTransition(ApprovalStatus.Rascunho, ApprovalStatus.Rascunho));
    }
}
