package com.terminar.assiduidade.ui.icons;

import javax.swing.Icon;
import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Component;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.geom.Arc2D;

/** Ícone desenhado (sem assets externos): arcos concêntricos tipo impressão digital. */
public class FingerprintIcon implements Icon {

    private final int size;
    private final Color color;

    public FingerprintIcon(int size, Color color) {
        this.size = size;
        this.color = color;
    }

    @Override
    public void paintIcon(Component c, Graphics g, int x, int y) {
        Graphics2D g2 = (Graphics2D) g.create();
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g2.setColor(color);
        g2.setStroke(new BasicStroke(Math.max(2f, size / 14f), BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        int arcs = 4;
        for (int i = 0; i < arcs; i++) {
            int inset = i * (size / (arcs * 2));
            Arc2D.Double arc = new Arc2D.Double(x + inset, y + inset,
                size - inset * 2, size - inset * 2, 200, 220, Arc2D.OPEN);
            g2.draw(arc);
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
