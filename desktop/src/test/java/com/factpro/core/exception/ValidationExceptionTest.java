package com.factpro.core.exception;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class ValidationExceptionTest {

    @Test
    void shouldCreateWithFieldAndMessage() {
        ValidationException ex = new ValidationException("nome", "O campo nome e obrigatorio");
        assertEquals("nome", ex.getField());
        assertEquals("O campo nome e obrigatorio", ex.getMessage());
        assertEquals("VALIDATION_ERROR", ex.getErrorCode());
    }

    @Test
    void shouldInheritFromBusinessException() {
        ValidationException ex = new ValidationException("email", "Email invalido");
        assertInstanceOf(BusinessException.class, ex);
    }
}
