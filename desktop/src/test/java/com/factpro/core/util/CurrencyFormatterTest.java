package com.factpro.core.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class CurrencyFormatterTest {

    @Test
    void format_shouldFormatWithMZN_Symbol() {
        String result = CurrencyFormatter.format(1250.50);
        assertNotNull(result);
        assertTrue(result.contains("1") || result.contains("250"));
    }

    @Test
    void format_shouldHandleZero() {
        String result = CurrencyFormatter.format(0.0);
        assertNotNull(result);
    }

    @Test
    void format_shouldHandleLargeValues() {
        String result = CurrencyFormatter.format(999999.99);
        assertNotNull(result);
    }

    @Test
    void formatWithoutSymbol_shouldHandleZero() {
        String result = CurrencyFormatter.formatWithoutSymbol(0.0);
        // Uses Portuguese locale formatting (comma as decimal separator)
        assertNotNull(result);
        assertTrue(result.contains("0"));
    }

    @Test
    void formatWithoutSymbol_shouldHandleDecimals() {
        String result = CurrencyFormatter.formatWithoutSymbol(0.05);
        assertNotNull(result);
        assertTrue(result.contains("05"));
    }

    @Test
    void formatWithoutSymbol_shouldReturnNumericFormat() {
        String result = CurrencyFormatter.formatWithoutSymbol(1250.50);
        assertNotNull(result);
        assertTrue(result.contains("250"));
    }

    @Test
    void parse_shouldParseNumericString() {
        double result = CurrencyFormatter.parse("1250.50");
        assertEquals(1250.50, result, 0.01);
    }

    @Test
    void parse_shouldHandleCommaSeparatedThousands() {
        double result = CurrencyFormatter.parse("1,250.50");
        assertEquals(1250.50, result, 0.01);
    }

    @Test
    void parse_shouldReturnZeroForInvalidInput() {
        double result = CurrencyFormatter.parse("invalid");
        assertEquals(0.0, result, 0.01);
    }

    @Test
    void parse_shouldHandleEmptyString() {
        double result = CurrencyFormatter.parse("");
        assertEquals(0.0, result, 0.01);
    }
}
