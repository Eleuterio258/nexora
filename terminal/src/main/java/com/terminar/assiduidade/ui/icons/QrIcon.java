package com.terminar.assiduidade.ui.icons;

import javax.swing.Icon;
import java.awt.Color;
import java.awt.Component;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.BasicStroke;

/** Ícone desenhado (sem assets externos): cantos de enquadramento tipo QR. */
public class QrIcon implements Icon {

    private final int size;
    private final Color color;

    public QrIcon(int size, Color color) {
        this.size = size;
        this.color = color;
    }

    @Override
    public void paintIcon(Component c, Graphics g, int x, int y) {
        Graphics2D g2 = (Graphics2D) g.create();
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g2.setColor(color);
        g2.setStroke(new BasicStroke(Math.max(2f, size / 12f)));
        int corner = size / 3;
        // canto superior esquerdo
        g2.drawLine(x, y, x + corner, y);
        g2.drawLine(x, y, x, y + corner);
        // canto superior direito
        g2.drawLine(x + size - corner, y, x + size, y);
        g2.drawLine(x + size, y, x + size, y + corner);
        // canto inferior esquerdo
        g2.drawLine(x, y + size - corner, x, y + size);
        g2.drawLine(x, y + size, x + corner, y + size);
        // canto inferior direito
        g2.drawLine(x + size - corner, y + size, x + size, y + size);
        g2.drawLine(x + size, y + size - corner, x + size, y + size);
        // quadrado central
        int mid = size / 3;
        int midX = x + (size - mid) / 2;
        int midY = y + (size - mid) / 2;
        g2.fillRect(midX, midY, mid, mid);
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
