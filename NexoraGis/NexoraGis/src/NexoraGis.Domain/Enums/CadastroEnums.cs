namespace NexoraGis.Domain.Enums;

public enum SituacaoParcela
{
    Ocupada,
    Desocupada,
    ParcialmenteOcupada,
    EmConstrucao,
    Abandonada,
    EmConflito,
    Reservada
}

public enum UsoSolo
{
    Habitacional,
    Comercial,
    Servicos,
    Industrial,
    Agricola,
    Institucional,
    Recreativo,
    Misto,
    Outros
}

public enum TipoEntidade
{
    Proprietario,
    Ocupante,
    Requerente,
    Empresa,
    InstituicaoPublica,
    Associacao,
    Concessionario
}

public enum TipoInfraestrutura
{
    RedeViaria,
    Agua,
    SaneamentoDrenagem,
    Energia,
    Telecomunicacoes
}

public enum TipoLevantamento
{
    Gnss,
    GnssRtk,
    EstacaoTotal,
    GpsPortatil,
    AplicacaoMovel,
    EquipamentoExterno,
    Drone,
    Satelite
}

public enum TipoDocumento
{
    Planta,
    Requerimento,
    Relatorio,
    Fotografia,
    Parecer,
    Autorizacao,
    Levantamento,
    Anexo,
    Outro
}

/// <summary>Estado de um lote de sincronização processado em segundo plano (backlog 4.2.4).</summary>
public enum SyncJobStatus
{
    Pendente,
    EmProcessamento,
    Concluido,
    Falhou
}

/// <summary>
/// Estado de um conflito de sincronização (backlog 4.2.3): ponto recebido com
/// o mesmo ClientId de um já sincronizado, mas com dados diferentes.
/// </summary>
public enum SyncConflitoStatus
{
    Pendente,
    ResolvidoManterExistente,
    ResolvidoAplicarNovo
}
