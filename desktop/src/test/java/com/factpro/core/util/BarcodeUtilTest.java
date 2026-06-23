package com.factpro.core.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class BarcodeUtilTest {

    @Test
    void isValidEAN13_shouldReturnTrueForValidBarcode() {
        assertTrue(BarcodeUtil.isValidEAN13("5901234123457"));
    }

    @Test
    void isValidEAN13_shouldReturnFalseForWrongLength() {
        assertFalse(BarcodeUtil.isValidEAN13("123456"));
    }

    @Test
    void isValidEAN13_shouldReturnFalseForNull() {
        assertFalse(BarcodeUtil.isValidEAN13(null));
    }

    @Test
    void isValidEAN13_shouldReturnFalseForNonNumeric() {
        assertFalse(BarcodeUtil.isValidEAN13("590123412345A"));
    }

    @Test
    void isValidBarcode_shouldReturnTrueForValidBarcode() {
        assertTrue(BarcodeUtil.isValidBarcode("7890123456789"));
    }

    @Test
    void isValidBarcode_shouldReturnFalseForNull() {
        assertFalse(BarcodeUtil.isValidBarcode(null));
    }

    @Test
    void isValidBarcode_shouldReturnFalseForEmptyString() {
        assertFalse(BarcodeUtil.isValidBarcode(""));
    }

    @Test
    void isValidBarcode_shouldReturnFalseForWhitespaceOnly() {
        assertFalse(BarcodeUtil.isValidBarcode("  "));
    }

    @Test
    void normalize_shouldTrimWhitespace() {
        assertEquals("7890123456789", BarcodeUtil.normalize("  7890123456789  "));
    }

    @Test
    void normalize_shouldReturnEmptyForNull() {
        assertEquals("", BarcodeUtil.normalize(null));
    }

    @Test
    void normalize_shouldReturnSameForValidBarcode() {
        assertEquals("5901234123457", BarcodeUtil.normalize("5901234123457"));
    }
}
