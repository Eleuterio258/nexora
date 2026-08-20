using NetTopologySuite.Geometries;

namespace NexoraGis.Application.Features.Reports;

/// <summary>Ficha cadastral de uma parcela (backlog 8.2.1) — dados + esquema da geometria.</summary>
public record ParcelaFichaDto(
    string CodigoCadastral,
    string? NumeroParcela,
    string? NumeroTalhao,
    string ProjetoDesignacao,
    string? DivisaoAdministrativaNome,
    string Situacao,
    string? UsoAtual,
    string? UsoPrevisto,
    string Estado,
    int Versao,
    decimal? AreaCalculadaM2,
    decimal? Perimetro,
    Geometry Geometria,
    IReadOnlyList<ParcelaFichaEntidadeDto> Entidades,
    IReadOnlyList<ParcelaFichaEdificacaoDto> Edificacoes,
    DateTimeOffset GeradoEm);

public record ParcelaFichaEntidadeDto(string Nome, string TipoRelacao);

public record ParcelaFichaEdificacaoDto(string Codigo, decimal? AreaConstruida, string? Finalidade);

/// <summary>Mapa temático esquemático de uso do solo por projecto (backlog 8.2.3) — sem base cartográfica georreferenciada.</summary>
public record MapaTematicoDto(
    string ProjetoDesignacao,
    string Titulo,
    IReadOnlyList<MapaTematicoParcelaDto> Parcelas,
    DateTimeOffset GeradoEm);

public record MapaTematicoParcelaDto(string CodigoCadastral, string Categoria, Geometry Geometria);
