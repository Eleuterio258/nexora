using NexoraGis.Application.Common;

namespace NexoraGis.Application.Tests.Common;

public class SldGeneratorTests
{
    [Fact]
    public void SimplePolygonStyle_EscapesXmlSpecialCharacters_InLayerName()
    {
        var sld = SldGenerator.SimplePolygonStyle("Camada <malévola> & \"perigosa\"", "#3388ff");

        Assert.DoesNotContain("<malévola>", sld);
        Assert.Contains("&lt;malévola&gt;", sld);
        Assert.Contains("&amp;", sld);
    }

    [Theory]
    [InlineData("#3388ff")]
    [InlineData("#ABCDEF")]
    [InlineData("#000000")]
    public void SimplePolygonStyle_AcceptsValidHexColor(string hex)
    {
        var sld = SldGenerator.SimplePolygonStyle("zona", hex);

        Assert.Contains(hex, sld);
    }

    [Theory]
    [InlineData("3388ff")]
    [InlineData("#38f")]
    [InlineData("azul")]
    [InlineData("")]
    public void SimplePolygonStyle_RejectsInvalidHexColor(string hex)
    {
        Assert.Throws<ArgumentException>(() => SldGenerator.SimplePolygonStyle("zona", hex));
    }

    [Fact]
    public void SimplePointStyle_UsaPointSymbolizer()
    {
        var sld = SldGenerator.SimplePointStyle("equipamento", "#3388ff");

        Assert.Contains("<PointSymbolizer>", sld);
        Assert.DoesNotContain("<PolygonSymbolizer>", sld);
    }

    [Fact]
    public void SimpleLineStyle_UsaLineSymbolizer()
    {
        var sld = SldGenerator.SimpleLineStyle("infraestrutura", "#3388ff");

        Assert.Contains("<LineSymbolizer>", sld);
        Assert.DoesNotContain("<PolygonSymbolizer>", sld);
    }

    [Fact]
    public void EstiloComColunaDeGeometria_FixaAPropriedadeUsada()
    {
        // parcela tem duas colunas geométricas (geometria e centroide); sem
        // <Geometry> o simbolizador usa a que vier primeiro na tabela.
        var sld = SldGenerator.SimplePolygonStyle("parcela", "#3388ff", "geometria");

        Assert.Contains("<ogc:PropertyName>geometria</ogc:PropertyName>", sld);
    }

    [Fact]
    public void EstiloSemColunaDeGeometria_NaoEmiteElementoGeometry()
    {
        var sld = SldGenerator.SimplePolygonStyle("parcela", "#3388ff");

        Assert.DoesNotContain("<Geometry>", sld);
    }

    [Fact]
    public void ColunaDeGeometria_TambemEEscapada()
    {
        var sld = SldGenerator.SimplePointStyle("x", "#3388ff", "geo<hack>");

        Assert.DoesNotContain("<hack>", sld);
        Assert.Contains("&lt;hack&gt;", sld);
    }
}
