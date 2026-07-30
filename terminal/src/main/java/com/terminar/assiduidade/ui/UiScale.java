package com.terminar.assiduidade.ui;

import com.terminar.assiduidade.config.AppConfig;

/**
 * Escala todos os tamanhos (fontes, células, ícones) proporcionalmente ao ecrã configurado
 * (`screen.width`/`screen.height`), tomando como referência o desenho original feito para um
 * painel de 200x200. Evita ter de reajustar cada painel manualmente sempre que o tamanho do
 * ecrã físico do terminal muda.
 */
public final class UiScale {

    private static final float BASE_SIZE = 200f;

    private UiScale() {
    }

    /** Escala um tamanho de fonte (aceita fracionário, como usado em Font#deriveFont). */
    public static float f(float base) {
        return base * factor();
    }

    /** Escala um tamanho em pixels (célula, ícone, margem) para uso em layouts/ícones. */
    public static int px(int base) {
        return Math.max(1, Math.round(base * factor()));
    }

    private static float factor() {
        return Math.min(AppConfig.getScreenWidth(), AppConfig.getScreenHeight()) / BASE_SIZE;
    }
}
