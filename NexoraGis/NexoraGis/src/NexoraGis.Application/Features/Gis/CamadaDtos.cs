using NexoraGis.Domain.Enums;

namespace NexoraGis.Application.Features.Gis;

public record CamadaDto(
    Guid Id, Guid? ProjetoId, string Nome, TipoCamada Tipo, string? TabelaFonte, string ColunaGeometria,
    string? Estilo, string? Metadados, Guid? ResponsavelId, string? Fonte, DateOnly? DataAtualizacao,
    string SistemaCoordenadas, string Versao, bool Visivel, bool Publica, DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt);

public record UpsertCamadaRequest(
    Guid? ProjetoId, string Nome, TipoCamada Tipo, string? TabelaFonte, string? Estilo, string? Metadados,
    Guid? ResponsavelId, string? Fonte, DateOnly? DataAtualizacao, string? SistemaCoordenadas, string? Versao,
    bool Visivel, bool Publica);

/// <summary>
/// Registo de um produto de drone (§11): ortofoto, MDT, MDS ou nuvem de
/// pontos. É apenas metadados — o ficheiro em si fica em armazenamento de
/// objetos e é referenciado à parte (documento), não é feito upload aqui.
/// </summary>
public record RegisterDroneProductRequest(
    Guid ProjetoId, string Nome, TipoCamada Tipo, string? Fonte, DateOnly DataAtualizacao, string? SistemaCoordenadas);
