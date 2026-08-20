using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Features.Entities;

/// <summary>
/// Vista completa (uso interno/autenticado). O WebGIS público nunca deve usar
/// este DTO diretamente — ver <see cref="EntidadePublicaDto"/>.
/// </summary>
public record EntidadeDto(
    Guid Id,
    TipoEntidade Tipo,
    string Nome,
    string? DocumentoIdentificacao,
    string? Nuit,
    string? Morada,
    string? Telefone,
    string? Email,
    bool DadosPessoais,
    bool AcessoPublico,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

/// <summary>Vista mascarada para consulta pública — nunca expõe contactos/documentos de identificação.</summary>
public record EntidadePublicaDto(Guid Id, TipoEntidade Tipo, string Nome);

public record UpsertEntidadeRequest(
    TipoEntidade Tipo,
    string Nome,
    string? DocumentoIdentificacao,
    string? Nuit,
    string? Morada,
    string? Telefone,
    string? Email,
    bool DadosPessoais,
    bool AcessoPublico);

public record ParcelaEntidadeDto(Guid Id, Guid ParcelaId, Guid EntidadeId, string NomeEntidade, TipoEntidade TipoRelacao, DateOnly? DataInicio, DateOnly? DataFim, bool Ativo);

public record LinkParcelaEntidadeRequest(Guid EntidadeId, TipoEntidade TipoRelacao, DateOnly? DataInicio, DateOnly? DataFim);
