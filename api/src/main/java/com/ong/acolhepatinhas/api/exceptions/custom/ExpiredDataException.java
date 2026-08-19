package com.ong.acolhepatinhas.api.exceptions.custom;

public class ExpiredDataException extends RuntimeException {
    public ExpiredDataException(String message) {
        super(message);
    }
}
