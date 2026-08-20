using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Gis;

/// <summary>Entrada no catálogo central de camadas (publicáveis via GeoServer).</summary>
public class Camada
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid? ProjetoId { get; set; }
    public Projeto? Projeto { get; set; }

    public string Nome { get; set; } = string.Empty;
    public TipoCamada Tipo { get; set; }
    public string? TabelaFonte { get; set; }
    public string ColunaGeometria { get; set; } = "geometria";
    public string? Estilo { get; set; }
    public string? Metadados { get; set; }

    public Guid? ResponsavelId { get; set; }
    public Utilizador? Responsavel { get; set; }

    public string? Fonte { get; set; }
    public DateOnly? DataAtualizacao { get; set; }
    public string SistemaCoordenadas { get; set; } = "EPSG:4326";
    public string Versao { get; set; } = "1.0";
    public bool Visivel { get; set; } = true;
    public bool Publica { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
