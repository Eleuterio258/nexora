package com.factpro.core.util;

public class StringUtil {
    public static boolean isEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }
    
    public static boolean isNotEmpty(String str) {
        return !isEmpty(str);
    }
    
    public static String sanitize(String str) {
        if (str == null) return "";
        return str.trim().replaceAll("[<>\"'&]", "");
    }
    
    public static String initials(String name) {
        if (isEmpty(name)) return "?";
        String[] parts = name.trim().split("\\s+");
        if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
        return (parts[0].charAt(0) + "" + parts[parts.length - 1].charAt(0)).toUpperCase();
    }
    
    public static String limit(String str, int maxLength) {
        if (str == null) return "";
        return str.length() > maxLength ? str.substring(0, maxLength) + "..." : str;
    }
}
