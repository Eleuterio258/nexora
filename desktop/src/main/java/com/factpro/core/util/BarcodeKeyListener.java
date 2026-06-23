package com.factpro.core.util;

import javax.swing.*;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.util.function.Consumer;

/**
 * KeyListener for barcode scanners.
 * Detects fast barcode input and triggers a callback when ENTER is pressed.
 */
public class BarcodeKeyListener implements KeyListener {

    private static final long TIMEOUT = 100;

    private final StringBuilder buffer = new StringBuilder();
    private long lastKeyTime = 0;
    private final Consumer<String> onBarcodeScanned;

    public BarcodeKeyListener(Consumer<String> callback) {
        this.onBarcodeScanned = callback;
    }

    @Override
    public void keyTyped(KeyEvent e) {
        // Not used
    }

    @Override
    public void keyPressed(KeyEvent e) {
        long currentTime = System.currentTimeMillis();
        if (currentTime - lastKeyTime > TIMEOUT) {
            buffer.setLength(0);
        }
        lastKeyTime = currentTime;

        if (e.getKeyCode() == KeyEvent.VK_ENTER) {
            String barcode = buffer.toString().trim();
            if (!barcode.isEmpty() && onBarcodeScanned != null) {
                onBarcodeScanned.accept(barcode);
                buffer.setLength(0);
            }
            e.consume();
        } else if (e.getKeyChar() != KeyEvent.CHAR_UNDEFINED) {
            buffer.append(e.getKeyChar());
        }
    }

    @Override
    public void keyReleased(KeyEvent e) {
        // Not used
    }

    /**
     * Installs a BarcodeKeyListener on a JTextField with the given callback.
     *
     * @param field    the text field to listen to
     * @param callback the callback invoked when a barcode is scanned
     */
    public static void install(JTextField field, Consumer<String> callback) {
        field.addKeyListener(new BarcodeKeyListener(callback));
    }
}
