using System.Security;
using System.Text.RegularExpressions;

namespace NexoraGis.Application.Common;

/// <summary>Gera um SLD 1.0 mínimo de polígono com uma única cor (backlog 5.2.3 / 7.1.4).</summary>
public static partial class SldGenerator
{
    public static string SimplePolygonStyle(string layerName, string hexColor)
    {
        if (!HexColorRegex().IsMatch(hexColor))
            throw new ArgumentException($"Cor inválida: '{hexColor}'. Tem de ser um hex de 6 dígitos (ex: #3388ff).", nameof(hexColor));

        // layerName entra em nomes/títulos de elementos XML — nunca confiar em texto livre
        // (nome da camada) sem escaping ao construir o SLD.
        var safeLayerName = SecurityElement.Escape(layerName);

        return $"""
            <?xml version="1.0" encoding="UTF-8"?>
            <StyledLayerDescriptor version="1.0.0"
                xmlns="http://www.opengis.net/sld" xmlns:ogc="http://www.opengis.net/ogc"
                xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
              <NamedLayer>
                <Name>{safeLayerName}</Name>
                <UserStyle>
                  <Title>{safeLayerName}</Title>
                  <FeatureTypeStyle>
                    <Rule>
                      <PolygonSymbolizer>
                        <Fill>
                          <CssParameter name="fill">{hexColor}</CssParameter>
                          <CssParameter name="fill-opacity">0.5</CssParameter>
                        </Fill>
                        <Stroke>
                          <CssParameter name="stroke">{hexColor}</CssParameter>
                          <CssParameter name="stroke-width">1</CssParameter>
                        </Stroke>
                      </PolygonSymbolizer>
                    </Rule>
                  </FeatureTypeStyle>
                </UserStyle>
              </NamedLayer>
            </StyledLayerDescriptor>
            """;
    }

    [GeneratedRegex("^#[0-9A-Fa-f]{6}$")]
    private static partial Regex HexColorRegex();
}
