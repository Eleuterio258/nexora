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
    Task<Result> PublishLayerAsync(string layerName, string tableName, string? sld, CancellationToken ct = default);

    Task<Result> UnpublishLayerAsync(string layerName, CancellationToken ct = default);
}
