package com.terminar.assiduidade.ui.icons;

import javax.swing.Icon;
import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Component;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.geom.Arc2D;

/** Ícone desenhado (sem assets externos): símbolo contactless (arcos irradiando de um ponto). */
public class NfcIcon implements Icon {

    private final int size;
    private final Color color;
    private final boolean emCirculo;

    public NfcIcon(int size, Color color) {
        this(size, color, false);
    }

    /** @param emCirculo desenha o símbolo centrado dentro de um anel, para ecrãs de destaque. */
    public NfcIcon(int size, Color color, boolean emCirculo) {
        this.size = size;
        this.color = color;
        this.emCirculo = emCirculo;
    }

    @Override
    public void paintIcon(Component c, Graphics g, int x, int y) {
        Graphics2D g2 = (Graphics2D) g.create();
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g2.setColor(color);

        if (emCirculo) {
            int anelInset = Math.max(2, size / 16);
            g2.setStroke(new BasicStroke(Math.max(2f, size / 18f)));
            g2.drawOval(x + anelInset, y + anelInset, size - anelInset * 2, size - anelInset * 2);

            g2.setStroke(new BasicStroke(Math.max(2f, size / 14f), BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
            int dot = Math.max(4, size / 10);
            int cx = x + size * 2 / 5;
            int cy = y + size / 2;
            g2.fillOval(cx - dot / 2, cy - dot / 2, dot, dot);
            for (int i = 1; i <= 3; i++) {
                int raio = i * size / 7;
                Arc2D.Double arc = new Arc2D.Double(cx - raio, cy - raio, raio * 2, raio * 2, -45, 90, Arc2D.OPEN);
                g2.draw(arc);
            }
        } else {
            g2.setStroke(new BasicStroke(Math.max(2f, size / 12f), BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
            int dot = Math.max(6, size / 8);
            int cx = x + size / 5;
            int cy = y + size - size / 5;
            g2.fillOval(cx - dot / 2, cy - dot / 2, dot, dot);
            for (int i = 1; i <= 3; i++) {
                int raio = i * size / 4;
                Arc2D.Double arc = new Arc2D.Double(cx - raio, cy - raio, raio * 2, raio * 2, 30, 60, Arc2D.OPEN);
                g2.draw(arc);
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
