using System.Security;
using System.Text.RegularExpressions;

namespace NexoraGis.Application.Common;

/// <summary>
/// Gera SLDs 1.0 mínimos de uma só cor (backlog 5.2.3 / 7.1.4). Há um
/// simbolizador por família de geometria: um PolygonSymbolizer aplicado a uma
/// camada de pontos não desenha nada, por isso quem publica tem de escolher o
/// estilo certo para o tipo de camada.
/// </summary>
public static partial class SldGenerator
{
    public static bool IsValidHexColor(string hexColor) => HexColorRegex().IsMatch(hexColor);

    /// <summary>
    /// Escolhe o simbolizador a partir do binding JTS da coluna de geometria
    /// (ex: org.locationtech.jts.geom.MultiPolygon). É o único critério fiável:
    /// o <c>TipoCamada</c> distingue produtos de drone, não famílias de
    /// geometria, e uma camada de pontos vectorial é `Vetorial` como as outras.
    /// </summary>
    public static string StyleForGeometry(string layerName, string hexColor, string? geometryBinding, string? geometryColumn = null)
    {
        var binding = geometryBinding ?? string.Empty;

        if (binding.Contains("Point", StringComparison.OrdinalIgnoreCase))
            return SimplePointStyle(layerName, hexColor, geometryColumn);

        if (binding.Contains("Line", StringComparison.OrdinalIgnoreCase))
            return SimpleLineStyle(layerName, hexColor, geometryColumn);

        return SimplePolygonStyle(layerName, hexColor, geometryColumn);
    }

    public static string SimplePolygonStyle(string layerName, string hexColor, string? geometryColumn = null) =>
        Build(layerName, hexColor, geometryColumn, (color, geometry) => $"""
                      <PolygonSymbolizer>
            {geometry}            <Fill>
                          <CssParameter name="fill">{color}</CssParameter>
                          <CssParameter name="fill-opacity">0.5</CssParameter>
                        </Fill>
                        <Stroke>
                          <CssParameter name="stroke">{color}</CssParameter>
                          <CssParameter name="stroke-width">1</CssParameter>
                        </Stroke>
                      </PolygonSymbolizer>
            """);

    public static string SimplePointStyle(string layerName, string hexColor, string? geometryColumn = null) =>
        Build(layerName, hexColor, geometryColumn, (color, geometry) => $"""
                      <PointSymbolizer>
            {geometry}            <Graphic>
                          <Mark>
                            <WellKnownName>circle</WellKnownName>
                            <Fill>
                              <CssParameter name="fill">{color}</CssParameter>
                            </Fill>
                            <Stroke>
                              <CssParameter name="stroke">{color}</CssParameter>
                              <CssParameter name="stroke-width">1</CssParameter>
                            </Stroke>
                          </Mark>
                          <Size>8</Size>
                        </Graphic>
                      </PointSymbolizer>
            """);

    public static string SimpleLineStyle(string layerName, string hexColor, string? geometryColumn = null) =>
        Build(layerName, hexColor, geometryColumn, (color, geometry) => $"""
                      <LineSymbolizer>
            {geometry}            <Stroke>
                          <CssParameter name="stroke">{color}</CssParameter>
                          <CssParameter name="stroke-width">2</CssParameter>
                        </Stroke>
                      </LineSymbolizer>
            """);

    private static string Build(string layerName, string hexColor, string? geometryColumn, Func<string, string, string> symbolizer)
    {
        if (!HexColorRegex().IsMatch(hexColor))
            throw new ArgumentException($"Cor inválida: '{hexColor}'. Tem de ser um hex de 6 dígitos (ex: #3388ff).", nameof(hexColor));

        // layerName e geometryColumn entram em nomes/títulos de elementos XML —
        // nunca confiar em texto livre sem escaping ao construir o SLD.
        var safeLayerName = SecurityElement.Escape(layerName);

        // Sem <Geometry> o simbolizador usa a geometria por omissão da camada,
        // que numa tabela com duas colunas geométricas (ex: parcela tem
        // `geometria` e `centroide`) é decidida pela ordem das colunas.
        var geometry = string.IsNullOrWhiteSpace(geometryColumn)
            ? string.Empty
            : $"""
                            <Geometry><ogc:PropertyName>{SecurityElement.Escape(geometryColumn)}</ogc:PropertyName></Geometry>

              """;

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
            {symbolizer(hexColor, geometry)}
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
