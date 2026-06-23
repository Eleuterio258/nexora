package com.factpro.core.exception;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class BusinessExceptionTest {

    @Test
    void shouldCreateWithDefaultErrorCode() {
        BusinessException ex = new BusinessException("Test error");
        assertEquals("Test error", ex.getMessage());
        assertEquals("BUSINESS_ERROR", ex.getErrorCode());
    }

    @Test
    void shouldCreateWithCustomErrorCode() {
        BusinessException ex = new BusinessException("Test error", "CUSTOM_CODE");
        assertEquals("CUSTOM_CODE", ex.getErrorCode());
    }

    @Test
    void shouldCreateWithCause() {
        Throwable cause = new RuntimeException("Root cause");
        BusinessException ex = new BusinessException("Test error", cause);
        assertEquals("BUSINESS_ERROR", ex.getErrorCode());
        assertEquals(cause, ex.getCause());
    }
}
