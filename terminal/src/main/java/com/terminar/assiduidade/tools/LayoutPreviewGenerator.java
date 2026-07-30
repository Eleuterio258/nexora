package com.terminar.assiduidade.tools;

import com.formdev.flatlaf.FlatDarkLaf;
import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.ui.AssiduidadeFrame;
import com.terminar.assiduidade.util.DatabaseManager;

import javax.imageio.ImageIO;
import javax.swing.SwingUtilities;
import javax.swing.UIManager;
import java.awt.Component;
import java.awt.Container;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;

/**
 * Gera imagens PNG dos ecrãs reais da aplicação para documentação.
 * Uso: mvn exec:java -Dexec.mainClass=com.terminar.assiduidade.tools.LayoutPreviewGenerator
 */
public final class LayoutPreviewGenerator {

    private LayoutPreviewGenerator() {
    }

    public static void main(String[] args) throws Exception {
        Path outputDir = Path.of(args.length > 0 ? args[0] : "assets")
            .toAbsolutePath().normalize();
        Files.createDirectories(outputDir);

        System.setProperty("db.url", "jdbc:sqlite:target/layout-preview.db");
        AppConfig.load();
        DatabaseManager.initialize();
        FlatDarkLaf.setup();
        UIManager.setLookAndFeel(new FlatDarkLaf());

        Map<String, java.util.function.Consumer<AssiduidadeFrame>> cards = Map.of(
            "final_layout_400x200.png", frame -> frame.goHome(),
            "final_pin_400x200.png", AssiduidadeFrame::goToPin,
            "final_digital_400x200.png", AssiduidadeFrame::goToFingerprint,
            "final_nfc_400x200.png", AssiduidadeFrame::goToNfc
        );

        SwingUtilities.invokeAndWait(() -> {
            try {
                AssiduidadeFrame frame = new AssiduidadeFrame();
                frame.getContentPane().setPreferredSize(
                    new java.awt.Dimension(AppConfig.getScreenWidth(), AppConfig.getScreenHeight()));
                frame.pack();
                frame.setVisible(true);

                int width = AppConfig.getScreenWidth();
                int height = AppConfig.getScreenHeight();
                for (Map.Entry<String, java.util.function.Consumer<AssiduidadeFrame>> entry : cards.entrySet()) {
                    entry.getValue().accept(frame);
                    layoutRecursively(frame.getContentPane());

                    BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
                    Graphics2D graphics = image.createGraphics();
                    frame.getContentPane().setSize(width, height);
                    frame.getContentPane().printAll(graphics);
                    graphics.dispose();

                    Path output = outputDir.resolve(entry.getKey());
                    ImageIO.write(image, "png", output.toFile());
                    System.out.println("Gerado: " + output);
                }

                frame.setVisible(false);
                frame.dispose();
            } catch (Exception e) {
                throw new IllegalStateException("Não foi possível gerar as imagens do layout", e);
            }
        });
        DatabaseManager.shutdown();
        System.exit(0);
    }

    private static void layoutRecursively(Container container) {
        container.doLayout();
        for (Component component : container.getComponents()) {
            if (component instanceof Container child) {
                layoutRecursively(child);
            }
        }
    }
}
