using NetTopologySuite.Geometries;
using NexoraGis.Application.Common;
using NexoraGis.Application.Features.Reports;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace NexoraGis.Infrastructure.Services;

/// <summary>
/// Gera os PDFs do backlog 8.2 com QuestPDF. Os "mapas" aqui são esquemas
/// vectoriais simples (a geometria reescalada para caber na página, sem
/// projeção cartográfica nem base de satélite/rua) — não substituem uma
/// planta topográfica, servem para dar uma noção visual rápida da forma e
/// localização relativa das parcelas.
/// </summary>
public class QuestPdfReportGenerator : IReportGenerator
{
    static QuestPdfReportGenerator()
    {
        QuestPDF.Settings.License = LicenseType.Community;
    }

    public byte[] GenerateParcelaFicha(ParcelaFichaDto ficha)
    {
        var document = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(2, Unit.Centimetre);
                page.DefaultTextStyle(x => x.FontSize(10));

                page.Header().Column(col =>
                {
                    col.Item().Text("Ficha Cadastral").FontSize(18).Bold();
                    col.Item().Text($"Parcela {ficha.CodigoCadastral}").FontSize(12).FontColor(Colors.Grey.Darken2);
                    col.Item().PaddingTop(4).LineHorizontal(1).LineColor(Colors.Grey.Lighten1);
                });

                page.Content().PaddingTop(10).Column(col =>
                {
                    col.Spacing(12);

                    col.Item().Row(row =>
                    {
                        row.RelativeItem().Column(c =>
                        {
                            c.Item().Text("Dados da Parcela").Bold().FontSize(12);
                            c.Item().Text($"Código cadastral: {ficha.CodigoCadastral}");
                            c.Item().Text($"Número da parcela: {ficha.NumeroParcela ?? "—"}");
                            c.Item().Text($"Número do talhão: {ficha.NumeroTalhao ?? "—"}");
                            c.Item().Text($"Projecto: {ficha.ProjetoDesignacao}");
                            c.Item().Text($"Divisão administrativa: {ficha.DivisaoAdministrativaNome ?? "—"}");
                        });

                        row.RelativeItem().Column(c =>
                        {
                            c.Item().Text("Situação e Uso").Bold().FontSize(12);
                            c.Item().Text($"Situação: {ficha.Situacao}");
                            c.Item().Text($"Uso atual: {ficha.UsoAtual ?? "—"}");
                            c.Item().Text($"Uso previsto: {ficha.UsoPrevisto ?? "—"}");
                            c.Item().Text($"Estado (aprovação): {ficha.Estado}  ·  Versão: {ficha.Versao}");
                            c.Item().Text($"Área: {FormatArea(ficha.AreaCalculadaM2)}   Perímetro: {FormatMeters(ficha.Perimetro)}");
                        });
                    });

                    col.Item().Text("Esquema da Geometria").Bold().FontSize(12);
                    col.Item().Height(220).Border(1).BorderColor(Colors.Grey.Lighten1)
                        .Svg(size => GeometrySvg.RenderSingle(size.Width, size.Height, ficha.Geometria, Colors.Blue.Medium.ToString()));

                    if (ficha.Entidades.Count > 0)
                    {
                        col.Item().Text("Entidades Associadas").Bold().FontSize(12);
                        col.Item().Table(table =>
                        {
                            table.ColumnsDefinition(c => { c.RelativeColumn(3); c.RelativeColumn(2); });
                            table.Header(h =>
                            {
                                h.Cell().Element(HeaderCell).Text("Nome");
                                h.Cell().Element(HeaderCell).Text("Relação");
                            });
                            foreach (var e in ficha.Entidades)
                            {
                                table.Cell().Element(BodyCell).Text(e.Nome);
                                table.Cell().Element(BodyCell).Text(e.TipoRelacao);
                            }
                        });
                    }

                    if (ficha.Edificacoes.Count > 0)
                    {
                        col.Item().Text("Edificações").Bold().FontSize(12);
                        col.Item().Table(table =>
                        {
                            table.ColumnsDefinition(c => { c.RelativeColumn(2); c.RelativeColumn(2); c.RelativeColumn(2); });
                            table.Header(h =>
                            {
                                h.Cell().Element(HeaderCell).Text("Código");
                                h.Cell().Element(HeaderCell).Text("Área construída");
                                h.Cell().Element(HeaderCell).Text("Finalidade");
                            });
                            foreach (var e in ficha.Edificacoes)
                            {
                                table.Cell().Element(BodyCell).Text(e.Codigo);
                                table.Cell().Element(BodyCell).Text(FormatArea(e.AreaConstruida));
                                table.Cell().Element(BodyCell).Text(e.Finalidade ?? "—");
                            }
                        });
                    }
                });

                page.Footer().AlignCenter().Text(x =>
                {
                    x.Span($"Emitido em {ficha.GeradoEm:dd/MM/yyyy HH:mm} · NexoraGis").FontSize(8).FontColor(Colors.Grey.Medium);
                });
            });
        });

        return document.GeneratePdf();
    }

    public byte[] GenerateMapaTematico(MapaTematicoDto mapa)
    {
        var categorias = mapa.Parcelas.Select(p => p.Categoria).Distinct().OrderBy(c => c).ToList();
        var paleta = new[]
        {
            Colors.Blue.Medium, Colors.Green.Medium, Colors.Orange.Medium, Colors.Purple.Medium,
            Colors.Red.Medium, Colors.Teal.Medium, Colors.Brown.Medium, Colors.Grey.Medium
        };
        var corPorCategoria = categorias
            .Select((categoria, i) => (categoria, cor: paleta[i % paleta.Length]))
            .ToDictionary(x => x.categoria, x => x.cor);

        var document = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4.Landscape());
                page.Margin(2, Unit.Centimetre);
                page.DefaultTextStyle(x => x.FontSize(10));

                page.Header().Column(col =>
                {
                    col.Item().Text(mapa.Titulo).FontSize(18).Bold();
                    col.Item().Text(mapa.ProjetoDesignacao).FontSize(12).FontColor(Colors.Grey.Darken2);
                    col.Item().PaddingTop(4).LineHorizontal(1).LineColor(Colors.Grey.Lighten1);
                });

                page.Content().PaddingTop(10).Row(row =>
                {
                    row.RelativeItem(4).Border(1).BorderColor(Colors.Grey.Lighten1)
                        .Svg(size => GeometrySvg.RenderMany(
                            size.Width, size.Height,
                            mapa.Parcelas.Select(p => (p.Geometria, corPorCategoria[p.Categoria].ToString())).ToList()));

                    row.RelativeItem(1).PaddingLeft(10).Column(c =>
                    {
                        c.Item().Text("Legenda").Bold();
                        foreach (var categoria in categorias)
                        {
                            c.Item().PaddingTop(4).Row(r =>
                            {
                                r.ConstantItem(12).Height(12).Background(corPorCategoria[categoria]);
                                r.RelativeItem().PaddingLeft(6).Text(categoria);
                            });
                        }
                    });
                });

                page.Footer().AlignCenter().Text(x =>
                {
                    x.Span($"Esquema sem base cartográfica — Emitido em {mapa.GeradoEm:dd/MM/yyyy HH:mm} · NexoraGis").FontSize(8).FontColor(Colors.Grey.Medium);
                });
            });
        });

        return document.GeneratePdf();
    }

    private static string FormatArea(decimal? areaM2) => areaM2 is null ? "—" : $"{areaM2:N2} m²";
    private static string FormatMeters(decimal? metros) => metros is null ? "—" : $"{metros:N2} m";

    private static IContainer HeaderCell(IContainer c) => c.Background(Colors.Grey.Lighten3).Padding(4).DefaultTextStyle(x => x.Bold());
    private static IContainer BodyCell(IContainer c) => c.BorderBottom(1).BorderColor(Colors.Grey.Lighten2).Padding(4);
}
