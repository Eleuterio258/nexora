package com.factpro.core.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class StringUtilTest {

    @Test
    void isEmpty_shouldReturnTrueForNull() {
        assertTrue(StringUtil.isEmpty(null));
    }

    @Test
    void isEmpty_shouldReturnTrueForEmptyString() {
        assertTrue(StringUtil.isEmpty(""));
    }

    @Test
    void isEmpty_shouldReturnTrueForWhitespaceOnly() {
        assertTrue(StringUtil.isEmpty("   "));
    }

    @Test
    void isEmpty_shouldReturnFalseForValidString() {
        assertFalse(StringUtil.isEmpty("hello"));
    }

    @Test
    void isNotEmpty_shouldReturnTrueForValidString() {
        assertTrue(StringUtil.isNotEmpty("hello"));
    }

    @Test
    void isNotEmpty_shouldReturnFalseForNull() {
        assertFalse(StringUtil.isNotEmpty(null));
    }

    @Test
    void sanitize_shouldReturnEmptyForNull() {
        assertEquals("", StringUtil.sanitize(null));
    }

    @Test
    void sanitize_shouldRemoveDangerousCharacters() {
        String input = "<script>alert('XSS')</script>";
        String result = StringUtil.sanitize(input);
        assertFalse(result.contains("<"));
        assertFalse(result.contains(">"));
        assertFalse(result.contains("'"));
    }

    @Test
    void sanitize_shouldTrimWhitespace() {
        String result = StringUtil.sanitize("  hello  ");
        assertEquals("hello", result);
    }

    @Test
    void initials_shouldHandleSingleWord() {
        assertEquals("J", StringUtil.initials("Joao"));
    }

    @Test
    void initials_shouldHandleFullName() {
        assertEquals("JS", StringUtil.initials("Joao Silva"));
    }

    @Test
    void initials_shouldHandleMultipleWords() {
        // "Joao da Silva" -> first char of first word (J) + first char of last word (S) = JS
        assertEquals("JS", StringUtil.initials("Joao da Silva"));
    }

    @Test
    void initials_shouldReturnQuestionMarkForNull() {
        assertEquals("?", StringUtil.initials(null));
    }

    @Test
    void initials_shouldReturnQuestionMarkForEmptyString() {
        assertEquals("?", StringUtil.initials(""));
    }

    @Test
    void limit_shouldTruncateLongString() {
        String result = StringUtil.limit("Hello World", 5);
        assertEquals("Hello...", result);
    }

    @Test
    void limit_shouldNotModifyShortString() {
        String result = StringUtil.limit("Hi", 10);
        assertEquals("Hi", result);
    }

    @Test
    void limit_shouldReturnEmptyForNull() {
        assertEquals("", StringUtil.limit(null, 5));
    }
}
