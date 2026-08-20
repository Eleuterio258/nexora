using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Territorial;

public class Utilizador
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid OrganizacaoId { get; set; }
    public Organizacao Organizacao { get; set; } = null!;

    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string NomeCompleto { get; set; } = string.Empty;
    public PerfilUtilizador Perfil { get; set; }
    public string? Telefone { get; set; }
    public bool Ativo { get; set; } = true;
    public DateTimeOffset? UltimoAcesso { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
