using NexoraGis.Domain.Common;

namespace NexoraGis.Application.Common;

/// <summary>
/// Publicação de camadas no GeoServer via REST API (backlog 7.1.2). Uma vez
/// publicada, a camada fica automaticamente disponível como WMS/WFS/WMTS —
/// não há código nosso para esses protocolos, é o próprio GeoServer que os
/// serve (backlog 7.1.3).
/// </summary>
public interface IGeoServerPublisher
{
    /// <param name="srs">Sistema de referência da camada (ex: "EPSG:4326"). Vem da
    /// <c>Camada</c>; fixá-lo em 4326 partia qualquer camada projectada.</param>
    /// <param name="corHex">Cor do estilo gerado (hex de 6 dígitos). O SLD é
    /// construído pelo publisher, depois de saber qual é mesmo a geometria da
    /// camada — quem chama não tem essa informação.</param>
    Task<Result> PublishLayerAsync(string layerName, string tableName, string srs, string? corHex, CancellationToken ct = default);

    Task<Result> UnpublishLayerAsync(string layerName, CancellationToken ct = default);
}
