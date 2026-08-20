namespace NexoraGis.Domain.Enums;

public enum ProjectStatus
{
    Rascunho,
    Levantamento,
    Diagnostico,
    Proposta,
    EmRevisao,
    Aprovado,
    Publicado,
    EmImplementacao,
    Arquivado
}

public enum TipoDivisao
{
    Pais,
    Provincia,
    Cidade,
    Municipio,
    Distrito,
    DistritoMunicipal,
    DistritoUrbano,
    PostoAdministrativo,
    PostoAdministrativoUrbano,
    Localidade,
    Bairro,
    Quarteirao,
    Aldeia,
    Povoacao,
    Comunidade,
    UnidadePlaneamento,
    Outro
}

public enum TipoConflito
{
    UsoIncompativel,
    InfracaoCondicionante,
    Sobreposicao,
    ForaZoneamento,
    ConstrucaoIlegal,
    Outro
}

public enum PerfilUtilizador
{
    Administrador,
    GestorPlano,
    PlaneadorTerritorial,
    TecnicoGis,
    Topografo,
    TecnicoCampo,
    Fiscal,
    Consulta
}
