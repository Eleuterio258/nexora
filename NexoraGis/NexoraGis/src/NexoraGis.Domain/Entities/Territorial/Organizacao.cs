namespace NexoraGis.Domain.Entities.Territorial;

/// <summary>Tenant da plataforma (município, governo distrital, empresa, consultora, etc.).</summary>
public class Organizacao
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Codigo { get; set; } = string.Empty;
    public string Designacao { get; set; } = string.Empty;
    public string Tipo { get; set; } = string.Empty;
    public string? Nif { get; set; }
    public string? Email { get; set; }
    public string? Telefone { get; set; }
    public string? Endereco { get; set; }

    public Guid? DivisaoAdministrativaId { get; set; }
    public DivisaoAdministrativa? DivisaoAdministrativa { get; set; }

    public bool Ativo { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;

    public ICollection<Utilizador> Utilizadores { get; set; } = new List<Utilizador>();
    public ICollection<Projeto> Projetos { get; set; } = new List<Projeto>();
}
