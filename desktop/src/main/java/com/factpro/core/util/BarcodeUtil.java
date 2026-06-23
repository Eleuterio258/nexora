package com.factpro.core.util;

public class BarcodeUtil {
    private static final int EAN13_LENGTH = 13;
    private static final int EAN8_LENGTH = 8;
    private static final int CODE128_MIN = 1;
    
    public static boolean isValidEAN13(String barcode) {
        if (barcode == null || barcode.length() != EAN13_LENGTH) return false;
        try {
            Long.parseLong(barcode);
        } catch (NumberFormatException e) {
            return false;
        }
        return true;
    }
    
    public static boolean isValidBarcode(String barcode) {
        return barcode != null && !barcode.trim().isEmpty();
    }
    
    public static String normalize(String barcode) {
        return barcode != null ? barcode.trim() : "";
    }
}
