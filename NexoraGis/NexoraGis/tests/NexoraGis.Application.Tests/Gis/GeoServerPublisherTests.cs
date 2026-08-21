using System.Net;
using System.Text.Json;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using NexoraGis.Infrastructure.Services;

namespace NexoraGis.Application.Tests.Gis;

/// <summary>
/// Guarda o contrato HTTP com o GeoServer. O publisher esteve partido em
/// produção porque os caminhos começavam por "/", o que num HttpClient com
/// BaseAddress .../geoserver/rest/ é tratado como caminho absoluto e apaga o
/// prefixo: todos os pedidos iam para a raiz do GeoServer e devolviam 404.
/// </summary>
public class GeoServerPublisherTests
{
    private const string BaseUrl = "http://geoserver.local:8090/geoserver/rest";

    private static (GeoServerPublisher Publisher, RecordingHandler Handler) CreatePublisher(
        Func<HttpRequestMessage, HttpResponseMessage>? responder = null)
    {
        var handler = new RecordingHandler(responder);
        var http = new HttpClient(handler) { BaseAddress = new Uri(BaseUrl.TrimEnd('/') + "/") };
        var options = Options.Create(new GeoServerOptions
        {
            BaseUrl = BaseUrl,
            Username = "admin",
            Password = "secreta",
            Workspace = "nexoragis",
            DataStore = "nexoragis_postgis",
            DbHost = "127.0.0.1",
            DbPort = 5432,
            DbName = "nexoragis",
            DbUser = "postgres",
            DbPassword = "pw",
            DbSchema = "cadastro"
        });

        return (new GeoServerPublisher(http, options, NullLogger<GeoServerPublisher>.Instance), handler);
    }

    [Fact]
    public async Task PublishLayerAsync_MantemOPrefixoGeoserverRestEmTodosOsPedidos()
    {
        var (publisher, handler) = CreatePublisher();

        var result = await publisher.PublishLayerAsync("parcela", "parcela", "EPSG:4326", corHex: null);

        Assert.True(result.IsSuccess);
        Assert.NotEmpty(handler.Requests);
        Assert.All(handler.Requests, r =>
            Assert.StartsWith("/geoserver/rest/", r.RequestUri!.AbsolutePath));
    }

    [Fact]
    public async Task PublishLayerAsync_UsaOSrsRecebidoEmVezDeUmFixo()
    {
        var (publisher, handler) = CreatePublisher();

        await publisher.PublishLayerAsync("zona", "zona", "EPSG:32737", corHex: null);

        var featureTypePost = handler.Requests.Single(r =>
            r.Method == HttpMethod.Post && r.RequestUri!.AbsolutePath.EndsWith("/featuretypes"));
        var body = JsonDocument.Parse(handler.Bodies[featureTypePost]);

        Assert.Equal("EPSG:32737", body.RootElement.GetProperty("featureType").GetProperty("srs").GetString());
    }

    [Fact]
    public async Task PublishLayerAsync_NaoRecriaOQueJaExiste()
    {
        // Tudo responde 200 ao GET => nada deve ser criado.
        var (publisher, handler) = CreatePublisher(_ => new HttpResponseMessage(HttpStatusCode.OK));

        var result = await publisher.PublishLayerAsync("parcela", "parcela", "EPSG:4326", corHex: null);

        Assert.True(result.IsSuccess);
        Assert.DoesNotContain(handler.Requests, r => r.Method == HttpMethod.Post);
    }

    [Fact]
    public async Task PublishLayerAsync_DevolveFailureQuandoOGeoServerRecusa()
    {
        var (publisher, _) = CreatePublisher(r => new HttpResponseMessage(
            r.Method == HttpMethod.Get ? HttpStatusCode.NotFound : HttpStatusCode.Unauthorized));

        var result = await publisher.PublishLayerAsync("parcela", "parcela", "EPSG:4326", corHex: null);

        Assert.True(result.IsFailure);
        Assert.Equal("GeoServer.WorkspaceFailed", result.Error.Code);
    }

    [Fact]
    public async Task PublishLayerAsync_EnviaAsCredenciaisEmBasicAuth()
    {
        var (publisher, handler) = CreatePublisher();

        await publisher.PublishLayerAsync("parcela", "parcela", "EPSG:4326", corHex: null);

        Assert.All(handler.Requests, r =>
        {
            Assert.Equal("Basic", r.Headers.Authorization?.Scheme);
            Assert.Equal("admin:secreta",
                System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(r.Headers.Authorization!.Parameter!)));
        });
    }


    [Fact]
    public async Task PublishLayerAsync_EscolheOSimbolizadorPelaGeometriaRealDaCamada()
    {
        // O featuretype já existe e a sua geometria é um ponto: o estilo enviado
        // tem de ser um PointSymbolizer. Escolher pelo TipoCamada não servia —
        // uma camada de pontos vectorial é `Vetorial` como as de polígonos.
        var (publisher, handler) = CreatePublisher(r => FeatureTypeWithGeometry(r, "coordenadas", "org.locationtech.jts.geom.Point"));

        await publisher.PublishLayerAsync("fiscalizacao", "fiscalizacao", "EPSG:4326", "#3388ff");

        var stylePost = handler.Requests.Single(r => r.RequestUri!.AbsolutePath.EndsWith("/styles"));
        var sld = handler.Bodies[stylePost];

        Assert.Contains("<PointSymbolizer>", sld);
        Assert.DoesNotContain("<PolygonSymbolizer>", sld);
    }

    [Fact]
    public async Task PublishLayerAsync_FixaAColunaDeGeometriaQueOGeoServerAnuncia()
    {
        // `parcela` tem duas colunas geométricas; o estilo tem de nomear a que o
        // GeoServer usa como omissão, não a que a aplicação assume.
        var (publisher, handler) = CreatePublisher(r => FeatureTypeWithGeometry(r, "geometria", "org.locationtech.jts.geom.MultiPolygon"));

        await publisher.PublishLayerAsync("parcela", "parcela", "EPSG:4326", "#3388ff");

        var stylePost = handler.Requests.Single(r => r.RequestUri!.AbsolutePath.EndsWith("/styles"));

        Assert.Contains("<ogc:PropertyName>geometria</ogc:PropertyName>", handler.Bodies[stylePost]);
    }

    [Fact]
    public async Task PublishLayerAsync_SemConseguirLerAGeometria_NaoEmiteElementoGeometry()
    {
        var (publisher, handler) = CreatePublisher();

        await publisher.PublishLayerAsync("parcela", "parcela", "EPSG:4326", "#3388ff");

        var stylePost = handler.Requests.Single(r => r.RequestUri!.AbsolutePath.EndsWith("/styles"));

        Assert.DoesNotContain("<Geometry>", handler.Bodies[stylePost]);
    }

    private static HttpResponseMessage FeatureTypeWithGeometry(HttpRequestMessage request, string column, string binding)
    {
        if (request.Method == HttpMethod.Get && request.RequestUri!.AbsolutePath.Contains("/featuretypes/"))
        {
            var json = JsonSerializer.Serialize(new
            {
                featureType = new
                {
                    name = "x",
                    attributes = new { attribute = new[] { new { name = column, binding } } }
                }
            });

            return new HttpResponseMessage(HttpStatusCode.OK) { Content = new StringContent(json) };
        }

        return new HttpResponseMessage(request.Method == HttpMethod.Get ? HttpStatusCode.NotFound : HttpStatusCode.Created);
    }

    /// <summary>GET devolve 404 (não existe) e POST/PUT devolvem 201, salvo responder próprio.</summary>
    private sealed class RecordingHandler(Func<HttpRequestMessage, HttpResponseMessage>? responder) : HttpMessageHandler
    {
        public List<HttpRequestMessage> Requests { get; } = [];
        public Dictionary<HttpRequestMessage, string> Bodies { get; } = [];

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Requests.Add(request);
            Bodies[request] = request.Content is null ? "" : await request.Content.ReadAsStringAsync(cancellationToken);

            return responder?.Invoke(request) ?? new HttpResponseMessage(
                request.Method == HttpMethod.Get ? HttpStatusCode.NotFound : HttpStatusCode.Created);
        }
    }
}
