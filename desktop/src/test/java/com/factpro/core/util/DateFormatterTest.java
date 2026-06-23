package com.factpro.core.util;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

class DateFormatterTest {

    @Test
    void formatDate_shouldReturnFormattedDate() {
        LocalDateTime date = LocalDateTime.of(2026, 4, 11, 10, 30, 0);
        assertEquals("11/04/2026", DateFormatter.formatDate(date));
    }

    @Test
    void formatDate_shouldReturnDashForNull() {
        assertEquals("-", DateFormatter.formatDate(null));
    }

    @Test
    void formatDateTime_shouldReturnFormattedDateTime() {
        LocalDateTime date = LocalDateTime.of(2026, 4, 11, 10, 30, 45);
        assertEquals("11/04/2026 10:30:45", DateFormatter.formatDateTime(date));
    }

    @Test
    void formatDateTime_shouldReturnDashForNull() {
        assertEquals("-", DateFormatter.formatDateTime(null));
    }

    @Test
    void formatTime_shouldReturnFormattedTime() {
        LocalDateTime date = LocalDateTime.of(2026, 4, 11, 14, 30, 45);
        assertEquals("14:30:45", DateFormatter.formatTime(date));
    }

    @Test
    void formatTime_shouldReturnDashForNull() {
        assertEquals("-", DateFormatter.formatTime(null));
    }

    @Test
    void formatForFile_shouldReturnFileSafeFormat() {
        LocalDateTime date = LocalDateTime.of(2026, 4, 11, 10, 30, 45);
        assertEquals("20260411_103045", DateFormatter.formatForFile(date));
    }

    @Test
    void formatForFile_shouldReturnUnknownForNull() {
        assertEquals("unknown", DateFormatter.formatForFile(null));
    }

    @Test
    void formatNow_shouldReturnCurrentDateTime() {
        String result = DateFormatter.formatNow();
        assertNotNull(result);
        assertFalse(result.isEmpty());
        assertTrue(result.contains("/"));
    }

    @Test
    void now_shouldReturnCurrentLocalDateTime() {
        LocalDateTime result = DateFormatter.now();
        assertNotNull(result);
    }
}
