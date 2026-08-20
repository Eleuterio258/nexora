namespace NexoraGis.Application.Common;

/// <summary>Identidade do pedido HTTP corrente, extraída dos claims do JWT.</summary>
public interface ICurrentUserService
{
    bool IsAuthenticated { get; }
    Guid? UtilizadorId { get; }
    Guid? OrganizacaoId { get; }
    string? Perfil { get; }
}
