package com.terminar.assiduidade.exception;

public class AssiduidadeException extends RuntimeException {

    public AssiduidadeException(String message) {
        super(message);
    }

    public AssiduidadeException(String message, Throwable cause) {
        super(message, cause);
    }
}
