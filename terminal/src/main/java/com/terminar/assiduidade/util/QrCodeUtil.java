package com.terminar.assiduidade.util;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.MultiFormatWriter;
import com.google.zxing.NotFoundException;
import com.google.zxing.Result;
import com.google.zxing.client.j2se.BufferedImageLuminanceSource;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.common.HybridBinarizer;
import com.terminar.assiduidade.exception.AssiduidadeException;

import java.awt.image.BufferedImage;

public class QrCodeUtil {

    private static final MultiFormatReader READER = new MultiFormatReader();

    public BufferedImage gerar(String conteudo, int tamanho) {
        try {
            BitMatrix matrix = new MultiFormatWriter().encode(conteudo, BarcodeFormat.QR_CODE, tamanho, tamanho);
            return MatrixToImageWriter.toBufferedImage(matrix);
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao gerar QR Code", e);
        }
    }

    /** Devolve o texto descodificado, ou null se a imagem não contém um QR legível. */
    public String descodificar(BufferedImage frame) {
        try {
            BinaryBitmap bitmap = new BinaryBitmap(
                new HybridBinarizer(new BufferedImageLuminanceSource(frame)));
            Result result = READER.decodeWithState(bitmap);
            return result.getText();
        } catch (NotFoundException e) {
            return null;
        } catch (Exception e) {
            return null;
        } finally {
            READER.reset();
        }
    }
}
