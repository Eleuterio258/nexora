using NexoraGis.Domain.Entities.Territorial;
using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Entities.Cadastro;

/// <summary>Pessoa/entidade relacionável com parcelas (proprietário, ocupante, empresa, etc.).</summary>
public class Entidade
{
    public Guid Id { get; set; } = Guid.NewGuid();

    /// <summary>
    /// Entidade não deriva de Projeto (pode não estar ligada a nenhuma parcela
    /// ainda), por isso guarda a organização diretamente para permitir
    /// isolamento multi-tenant.
    /// </summary>
    public Guid OrganizacaoId { get; set; }
    public Organizacao Organizacao { get; set; } = null!;

    public TipoEntidade Tipo { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? DocumentoIdentificacao { get; set; }
    public string? Nuit { get; set; }
    public string? Morada { get; set; }
    public string? Telefone { get; set; }
    public string? Email { get; set; }

    /// <summary>Marca a entidade como contendo dados pessoais — regras de acesso restritas.</summary>
    public bool DadosPessoais { get; set; }

    /// <summary>Se falso, esta entidade nunca é exposta no WebGIS público.</summary>
    public bool AcessoPublico { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;

    public ICollection<ParcelaEntidade> Parcelas { get; set; } = new List<ParcelaEntidade>();
}
