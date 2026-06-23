package com.factpro.core.util;

import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.util.Locale;

public class CurrencyFormatter {
    private static final NumberFormat FORMAT = NumberFormat.getCurrencyInstance(new Locale("pt", "MZ"));
    private static final DecimalFormat DECIMAL = new DecimalFormat("#,##0.00");
    
    public static String format(double value) {
        return FORMAT.format(value);
    }
    
    public static String formatWithoutSymbol(double value) {
        return DECIMAL.format(value);
    }
    
    public static double parse(String value) {
        try {
            return FORMAT.parse(value).doubleValue();
        } catch (Exception e) {
            try {
                return Double.parseDouble(value.replace(",", "").replace(" ", ""));
            } catch (NumberFormatException ex) {
                return 0.0;
            }
        }
    }
}
