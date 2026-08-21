using NexoraGis.Domain.Enums;

namespace NexoraGis.Domain.Tests.Enums;

/// <summary>
/// O claim "perfil" do JWT e a coluna territorial.permissao.perfil têm de usar
/// exatamente a mesma convenção: se divergirem, o
/// PermissionAuthorizationHandler deixa de encontrar qualquer regra e a API
/// devolve 403 em todos os endpoints, incluindo ao administrador.
/// </summary>
public class EnumWireFormatTests
{
    [Theory]
    [InlineData(PerfilUtilizador.Administrador, "administrador")]
    [InlineData(PerfilUtilizador.GestorPlano, "gestor_plano")]
    [InlineData(PerfilUtilizador.PlaneadorTerritorial, "planeador_territorial")]
    [InlineData(PerfilUtilizador.TecnicoGis, "tecnico_gis")]
    [InlineData(PerfilUtilizador.Topografo, "topografo")]
    [InlineData(PerfilUtilizador.TecnicoCampo, "tecnico_campo")]
    [InlineData(PerfilUtilizador.Fiscal, "fiscal")]
    [InlineData(PerfilUtilizador.Consulta, "consulta")]
    public void ToWireString_UsaSnakeCase(PerfilUtilizador perfil, string esperado)
    {
        Assert.Equal(esperado, perfil.ToWireString());
    }

    [Theory]
    [InlineData(PerfilUtilizador.Administrador)]
    [InlineData(PerfilUtilizador.PlaneadorTerritorial)]
    [InlineData(PerfilUtilizador.TecnicoGis)]
    public void FromSnakeCase_InverteToWireString(PerfilUtilizador perfil)
    {
        var wire = perfil.ToWireString();

        Assert.Equal(perfil.ToString(), EnumWireFormat.FromSnakeCase(wire));
    }

    [Fact]
    public void ToSnakeCase_NuncaDevolveMaiusculasNemEspacos()
    {
        foreach (var perfil in Enum.GetValues<PerfilUtilizador>())
        {
            var wire = perfil.ToWireString();

            Assert.Equal(wire.ToLowerInvariant(), wire);
            Assert.False(wire.Contains(' '));
            Assert.NotEmpty(wire);
        }
    }
}
