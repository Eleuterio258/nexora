using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using NexoraGis.Application.Common;
using NexoraGis.Domain.Common;

namespace NexoraGis.Infrastructure.Services;

/// <summary>
/// Cliente REST do GeoServer (backlog 7.1.2). Cria workspace/datastore
/// PostGIS/featuretype de forma idempotente (confirma se já existem antes de
/// criar). Não verificado contra uma instância real do GeoServer nesta
/// sessão — se o GeoServer não estiver acessível, os métodos falham com
/// Result.Failure em vez de lançar exceção, para não derrubar o resto da API.
/// </summary>
public class GeoServerPublisher(HttpClient http, IOptions<GeoServerOptions> options, ILogger<GeoServerPublisher> logger) : IGeoServerPublisher
{
    private readonly GeoServerOptions _options = options.Value;

    public async Task<Result> PublishLayerAsync(string layerName, string tableName, string? sld, CancellationToken ct = default)
    {
        try
        {
            var wsResult = await EnsureWorkspaceAsync(ct);
            if (wsResult.IsFailure) return wsResult;

            var dsResult = await EnsureDataStoreAsync(ct);
            if (dsResult.IsFailure) return dsResult;

            var ftResult = await EnsureFeatureTypeAsync(layerName, tableName, ct);
            if (ftResult.IsFailure) return ftResult;

            if (!string.IsNullOrWhiteSpace(sld))
                await TryApplyStyleAsync(layerName, sld, ct);

            return Result.Success();
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Falha ao publicar camada '{Layer}' no GeoServer.", layerName);
            return Result.Failure(Error.Failure("GeoServer.PublishFailed", $"Não foi possível publicar a camada no GeoServer: {ex.Message}"));
        }
    }

    public async Task<Result> UnpublishLayerAsync(string layerName, CancellationToken ct = default)
    {
        try
        {
            var response = await SendAsync(HttpMethod.Delete,
                $"/workspaces/{_options.Workspace}/datastores/{_options.DataStore}/featuretypes/{layerName}?recurse=true", null, ct);

            return response.IsSuccessStatusCode || response.StatusCode == HttpStatusCode.NotFound
                ? Result.Success()
                : Result.Failure(Error.Failure("GeoServer.UnpublishFailed", $"GeoServer devolveu {(int)response.StatusCode}."));
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Falha ao remover a camada '{Layer}' do GeoServer.", layerName);
            return Result.Failure(Error.Failure("GeoServer.UnpublishFailed", $"Não foi possível remover a camada do GeoServer: {ex.Message}"));
        }
    }

    private async Task<Result> EnsureWorkspaceAsync(CancellationToken ct)
    {
        var exists = await SendAsync(HttpMethod.Get, $"/workspaces/{_options.Workspace}.json", null, ct);
        if (exists.IsSuccessStatusCode) return Result.Success();

        var body = JsonSerializer.Serialize(new { workspace = new { name = _options.Workspace } });
        var response = await SendAsync(HttpMethod.Post, "/workspaces", body, ct);
        return response.IsSuccessStatusCode
            ? Result.Success()
            : Result.Failure(Error.Failure("GeoServer.WorkspaceFailed", $"Não foi possível criar o workspace '{_options.Workspace}' (HTTP {(int)response.StatusCode})."));
    }

    private async Task<Result> EnsureDataStoreAsync(CancellationToken ct)
    {
        var exists = await SendAsync(HttpMethod.Get, $"/workspaces/{_options.Workspace}/datastores/{_options.DataStore}.json", null, ct);
        if (exists.IsSuccessStatusCode) return Result.Success();

        // GeoServer espera cada parâmetro de ligação como {"@key":"...","$":"..."} —
        // "$" não é um identificador C# válido, por isso a entrada é montada como
        // Dictionary<string, object> em vez de um tipo anónimo.
        static Dictionary<string, object> Entry(string key, string value) => new() { ["@key"] = key, ["$"] = value };

        var body = JsonSerializer.Serialize(new
        {
            dataStore = new
            {
                name = _options.DataStore,
                connectionParameters = new
                {
                    entry = new[]
                    {
                        Entry("host", _options.DbHost),
                        Entry("port", _options.DbPort.ToString()),
                        Entry("database", _options.DbName),
                        Entry("user", _options.DbUser),
                        Entry("passwd", _options.DbPassword),
                        Entry("dbtype", "postgis"),
                        Entry("schema", _options.DbSchema)
                    }
                }
            }
        });

        var response = await SendAsync(HttpMethod.Post, $"/workspaces/{_options.Workspace}/datastores", body, ct);
        return response.IsSuccessStatusCode
            ? Result.Success()
            : Result.Failure(Error.Failure("GeoServer.DataStoreFailed", $"Não foi possível criar o datastore '{_options.DataStore}' (HTTP {(int)response.StatusCode})."));
    }

    private async Task<Result> EnsureFeatureTypeAsync(string layerName, string tableName, CancellationToken ct)
    {
        var exists = await SendAsync(HttpMethod.Get,
            $"/workspaces/{_options.Workspace}/datastores/{_options.DataStore}/featuretypes/{layerName}.json", null, ct);
        if (exists.IsSuccessStatusCode) return Result.Success();

        var body = JsonSerializer.Serialize(new
        {
            featureType = new { name = layerName, nativeName = tableName, title = layerName, srs = "EPSG:4326" }
        });

        var response = await SendAsync(HttpMethod.Post, $"/workspaces/{_options.Workspace}/datastores/{_options.DataStore}/featuretypes", body, ct);
        return response.IsSuccessStatusCode
            ? Result.Success()
            : Result.Failure(Error.Failure("GeoServer.FeatureTypeFailed", $"Não foi possível publicar a camada '{layerName}' (HTTP {(int)response.StatusCode})."));
    }

    private async Task TryApplyStyleAsync(string layerName, string sld, CancellationToken ct)
    {
        try
        {
            var styleName = $"{layerName}_style";
            var createStyle = await SendAsync(HttpMethod.Post, "/styles?name=" + styleName, null, ct, sld, "application/vnd.ogc.sld+xml");
            if (!createStyle.IsSuccessStatusCode) return;

            var setDefault = JsonSerializer.Serialize(new { layer = new { defaultStyle = new { name = styleName } } });
            await SendAsync(HttpMethod.Put, $"/layers/{_options.Workspace}:{layerName}", setDefault, ct);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Não foi possível aplicar o estilo SLD à camada '{Layer}' — camada fica publicada com o estilo por omissão.", layerName);
        }
    }

    private async Task<HttpResponseMessage> SendAsync(
        HttpMethod method, string path, string? jsonBody, CancellationToken ct, string? rawBody = null, string? rawContentType = null)
    {
        var request = new HttpRequestMessage(method, path);
        request.Headers.Authorization = new AuthenticationHeaderValue(
            "Basic", Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_options.Username}:{_options.Password}")));

        if (rawBody is not null)
            request.Content = new StringContent(rawBody, Encoding.UTF8, rawContentType ?? "application/xml");
        else if (jsonBody is not null)
            request.Content = new StringContent(jsonBody, Encoding.UTF8, "application/json");

        return await http.SendAsync(request, ct);
    }
}
