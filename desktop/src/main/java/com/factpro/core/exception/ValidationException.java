package com.factpro.core.exception;

public class ValidationException extends BusinessException {
    private final String field;
    
    public ValidationException(String field, String message) {
        super(message, "VALIDATION_ERROR");
        this.field = field;
    }
    
    public String getField() { return field; }
}
