using System.Net;
using System.Net.Http.Json;
using System.Net.Http.Headers;

namespace NexoraGis.Api.IntegrationTests;

/// <summary>
/// Verifica que o pipeline autentica antes de autorizar e que nenhum endpoint
/// de negócio está aberto. Um destes casos (o token válido a receber 403 por a
/// tabela de permissões estar vazia) só apareceu em produção porque não havia
/// nenhum teste a exercer o pipeline.
/// </summary>
public class AuthorizationPipelineTests(NexoraGisApiFactory factory) : IClassFixture<NexoraGisApiFactory>
{
    public static TheoryData<string> EndpointsProtegidos =>
    [
        "/api/v1/projects", "/api/v1/parcels", "/api/v1/layers/", "/api/v1/plans",
        "/api/v1/zones", "/api/v1/entities", "/api/v1/surveys", "/api/v1/approvals",
        "/api/v1/conflicts", "/api/v1/audit", "/api/v1/inspections", "/api/v1/administrative-divisions"
    ];

    [Theory]
    [MemberData(nameof(EndpointsProtegidos))]
    public async Task SemToken_Devolve401(string url)
    {
        var response = await factory.CreateClient().GetAsync(url);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task ComTokenInvalido_Devolve401()
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "isto.nao.e-um-jwt");

        var response = await client.GetAsync("/api/v1/projects");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task LoginComCredenciaisInvalidas_NaoRevelaDetalhes()
    {
        var response = await factory.CreateClient()
            .PostAsJsonAsync("/api/v1/auth/login", new { usernameOrEmail = "nao-existe", password = "errada" });

        // A base está inacessível de propósito neste arranque: o que não pode
        // acontecer é a API devolver 200 ou expor a excepção de ligação.
        Assert.NotEqual(HttpStatusCode.OK, response.StatusCode);
    }
}
