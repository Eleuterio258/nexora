package com.factpro.core.util;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class DateFormatter {
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter DATETIME_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");
    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("HH:mm:ss");
    private static final DateTimeFormatter FILE_FMT = DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss");
    
    public static String formatDate(LocalDateTime date) {
        return date != null ? date.format(DATE_FMT) : "-";
    }
    
    public static String formatDateTime(LocalDateTime date) {
        return date != null ? date.format(DATETIME_FMT) : "-";
    }
    
    public static String formatTime(LocalDateTime date) {
        return date != null ? date.format(TIME_FMT) : "-";
    }
    
    public static String formatForFile(LocalDateTime date) {
        return date != null ? date.format(FILE_FMT) : "unknown";
    }
    
    public static String formatNow() {
        return formatDateTime(LocalDateTime.now());
    }
    
    public static LocalDateTime now() {
        return LocalDateTime.now();
    }
}
