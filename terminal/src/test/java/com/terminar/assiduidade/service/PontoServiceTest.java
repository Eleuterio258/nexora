package com.terminar.assiduidade.service;

import com.terminar.assiduidade.model.TipoMarcacao;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class PontoServiceTest {

    private final PontoService pontoService = new PontoService();

    @Test
    void semRegistoAnteriorSugereEntrada() {
        assertEquals(TipoMarcacao.ENTRADA, pontoService.proximoTipo(null));
    }

    @Test
    void aposEntradaSugereSaida() {
        assertEquals(TipoMarcacao.SAIDA, pontoService.proximoTipo(TipoMarcacao.ENTRADA));
    }

    @Test
    void aposInicioPausaSugereFimPausa() {
        assertEquals(TipoMarcacao.FIM_PAUSA, pontoService.proximoTipo(TipoMarcacao.INICIO_PAUSA));
    }

    @Test
    void aposFimPausaSugereEntrada() {
        assertEquals(TipoMarcacao.ENTRADA, pontoService.proximoTipo(TipoMarcacao.FIM_PAUSA));
    }

    @Test
    void aposSaidaSugereEntrada() {
        assertEquals(TipoMarcacao.ENTRADA, pontoService.proximoTipo(TipoMarcacao.SAIDA));
    }
}
