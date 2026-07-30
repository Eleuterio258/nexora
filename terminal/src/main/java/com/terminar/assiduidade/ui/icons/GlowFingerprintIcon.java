package com.terminar.assiduidade.ui.icons;

import javax.swing.Icon;
import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Component;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RadialGradientPaint;
import java.awt.RenderingHints;
import java.awt.geom.Arc2D;
import java.awt.geom.Point2D;

/** Ícone de impressão digital com brilho (glow) suave, para o ecrã de leitura. */
public class GlowFingerprintIcon implements Icon {

    private final int coreSize;
    private final int totalSize;
    private final Color color;

    public GlowFingerprintIcon(int size, Color color) {
        this.coreSize = size;
        this.totalSize = Math.round(size * 1.5f);
        this.color = color;
    }

    @Override
    public void paintIcon(Component c, Graphics g, int x, int y) {
        Graphics2D g2 = (Graphics2D) g.create();
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

        int offset = (totalSize - coreSize) / 2;
        float cx = x + totalSize / 2f;
        float cy = y + totalSize / 2f;
        float haloRadius = coreSize * 0.75f;
        RadialGradientPaint halo = new RadialGradientPaint(
            new Point2D.Float(cx, cy), haloRadius,
            new float[]{0f, 0.6f, 1f},
            new Color[]{
                withAlpha(color, 0.35f),
                withAlpha(color, 0.12f),
                withAlpha(color, 0f)
            });
        g2.setPaint(halo);
        g2.fillOval(Math.round(cx - haloRadius), Math.round(cy - haloRadius),
            Math.round(haloRadius * 2), Math.round(haloRadius * 2));

        g2.setStroke(new BasicStroke(Math.max(2.5f, coreSize / 12f), BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        int arcs = 5;
        for (int i = 0; i < arcs; i++) {
            int inset = i * (coreSize / (arcs * 2));
            g2.setColor(withAlpha(color, 1f - i * 0.12f));
            Arc2D.Double arc = new Arc2D.Double(x + offset + inset, y + offset + inset,
                coreSize - inset * 2, coreSize - inset * 2, 200, 220, Arc2D.OPEN);
            g2.draw(arc);
        }
        g2.dispose();
    }

    private Color withAlpha(Color base, float alpha) {
        int a = Math.max(0, Math.min(255, Math.round(255 * alpha)));
        return new Color(base.getRed(), base.getGreen(), base.getBlue(), a);
    }

    @Override
    public int getIconWidth() {
        return totalSize;
    }

    @Override
    public int getIconHeight() {
        return totalSize;
    }
}
