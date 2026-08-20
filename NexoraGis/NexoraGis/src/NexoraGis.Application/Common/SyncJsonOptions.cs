using System.Text.Json;
using System.Text.Json.Serialization;
using NetTopologySuite.IO.Converters;

namespace NexoraGis.Application.Common;

/// <summary>
/// Opções de serialização usadas para guardar/reler payloads de sincronização
/// (SyncPontosRequest, SyncPontoItem) em colunas jsonb — precisam do mesmo
/// conversor GeoJSON usado pela API para os tipos de geometria do NTS.
/// </summary>
public static class SyncJsonOptions
{
    public static readonly JsonSerializerOptions Default = Create();

    private static JsonSerializerOptions Create()
    {
        var options = new JsonSerializerOptions();
        options.Converters.Add(new GeoJsonConverterFactory());
        options.Converters.Add(new JsonStringEnumConverter());
        return options;
    }
}
