package com.ong.acolhepatinhas.api.exceptions.custom;

public class DuplicatedValueException extends RuntimeException {
    public DuplicatedValueException(String message) {
        super(message);
    }
}
