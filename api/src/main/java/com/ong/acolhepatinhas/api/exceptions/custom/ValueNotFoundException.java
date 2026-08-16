package com.ong.acolhepatinhas.api.exceptions.custom;

public class ValueNotFoundException extends RuntimeException{
    public ValueNotFoundException(String message) {
        super(message);
    }
}
