package com.terminar.assiduidade.ui.icons;

import javax.swing.Icon;
import java.awt.Color;
import java.awt.Component;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;

/** Ícone desenhado (sem assets externos): grelha de teclado numérico. */
public class PinIcon implements Icon {

    private final int size;
    private final Color color;

    public PinIcon(int size, Color color) {
        this.size = size;
        this.color = color;
    }

    @Override
    public void paintIcon(Component c, Graphics g, int x, int y) {
        Graphics2D g2 = (Graphics2D) g.create();
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g2.setColor(color);
        int cell = size / 4;
        int dot = Math.max(4, cell / 2);
        for (int row = 0; row < 3; row++) {
            for (int col = 0; col < 3; col++) {
                int cx = x + cell / 2 + col * cell + cell / 2;
                int cy = y + cell / 2 + row * cell + cell / 2;
                g2.fillOval(cx - dot / 2, cy - dot / 2, dot, dot);
            }
        }
        g2.dispose();
    }

    @Override
    public int getIconWidth() {
        return size;
    }

    @Override
    public int getIconHeight() {
        return size;
    }
}
