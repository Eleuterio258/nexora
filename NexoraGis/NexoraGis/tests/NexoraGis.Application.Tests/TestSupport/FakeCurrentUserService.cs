using NexoraGis.Application.Common;

namespace NexoraGis.Application.Tests.TestSupport;

public class FakeCurrentUserService(Guid? utilizadorId = null, Guid? organizacaoId = null, string? perfil = null) : ICurrentUserService
{
    public bool IsAuthenticated => UtilizadorId is not null;
    public Guid? UtilizadorId { get; } = utilizadorId;
    public Guid? OrganizacaoId { get; } = organizacaoId;
    public string? Perfil { get; } = perfil;
}
