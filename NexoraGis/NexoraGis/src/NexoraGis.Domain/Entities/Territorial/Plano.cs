namespace NexoraGis.Domain.Entities.Territorial;

public class Plano
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ProjetoId { get; set; }
    public Projeto Projeto { get; set; } = null!;

    public string Codigo { get; set; } = string.Empty;
    public string Designacao { get; set; } = string.Empty;
    public string Versao { get; set; } = "1.0";
    public DateOnly? DataAprovacao { get; set; }
    public DateOnly? DataPublicacao { get; set; }
    public bool Ativo { get; set; } = true;

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;

    public ICollection<Zona> Zonas { get; set; } = new List<Zona>();
}
