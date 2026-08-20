using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Cadastro;

/// <summary>
/// Metadados de um documento associável a qualquer entidade (parcela, edificação,
/// projeto, plano, ...) via EntidadeTipo/EntidadeId. O ficheiro em si vive em
/// armazenamento de objetos (MinIO/S3) — aqui fica só a referência.
/// </summary>
public class Documento
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid? ProjetoId { get; set; }
    public Projeto? Projeto { get; set; }

    public TipoDocumento Tipo { get; set; }
    public string Titulo { get; set; } = string.Empty;
    public string? Descricao { get; set; }

    public string? EntidadeTipo { get; set; }
    public Guid? EntidadeId { get; set; }

    public string? FicheiroUrl { get; set; }
    public string? FicheiroNome { get; set; }
    public long? FicheiroTamanho { get; set; }
    public string? FicheiroHash { get; set; }
    public string? MimeType { get; set; }
    public bool ArmazenamentoObjeto { get; set; }
    public bool AcessoPublico { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;

    public Guid? CreatedBy { get; set; }
    public Utilizador? CreatedByUtilizador { get; set; }
}
