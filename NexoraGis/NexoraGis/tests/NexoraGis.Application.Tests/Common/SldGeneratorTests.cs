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
        Assert.Contains("&quot;perigosa&quot;", sld);
    }

    [Theory]
    [InlineData("#3388ff")]
    [InlineData("#000000")]
    [InlineData("#FFFFFF")]
    public void SimplePolygonStyle_AcceptsValidHexColor(string hex)
    {
        var sld = SldGenerator.SimplePolygonStyle("zona", hex);
        Assert.Contains($">{hex}<", sld);
    }

    [Theory]
    [InlineData("javascript:alert(1)")]
    [InlineData("<script>")]
    [InlineData("#12345")]
    [InlineData("red")]
    [InlineData("")]
    public void SimplePolygonStyle_RejectsInvalidHexColor(string hex)
    {
        Assert.Throws<ArgumentException>(() => SldGenerator.SimplePolygonStyle("zona", hex));
    }
}
