using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace NexoraGis.Api.IntegrationTests;

public class HealthEndpointsTests(NexoraGisApiFactory factory) : IClassFixture<NexoraGisApiFactory>
{
    [Fact]
    public async Task Health_RespondeSemTocarNaBase()
    {
        var response = await factory.CreateClient().GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("ok", body.GetProperty("status").GetString());
    }

    [Fact]
    public async Task HealthReady_Devolve503QuandoABaseEstaInacessivel()
    {
        // É esta a diferença que interessa: com a base em baixo o /health
        // continua 200 (o processo está vivo) mas o /health/ready tem de falhar,
        // senão o container fica "healthy" e o Traefik continua a encaminhar.
        var response = await factory.CreateClient().GetAsync("/health/ready");

        Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("unreachable", body.GetProperty("database").GetString());
    }
}
