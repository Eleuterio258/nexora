using NexoraGis.Application.Features.Reports;

namespace NexoraGis.Application.Common;

/// <summary>Geração de PDF (backlog 8.2). Implementado em Infrastructure para não trazer a dependência de renderização para a Application.</summary>
public interface IReportGenerator
{
    byte[] GenerateParcelaFicha(ParcelaFichaDto ficha);

    byte[] GenerateMapaTematico(MapaTematicoDto mapa);
}
