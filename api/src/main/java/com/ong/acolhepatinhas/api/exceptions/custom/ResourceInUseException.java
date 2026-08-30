package com.ong.acolhepatinhas.api.exceptions.custom;

public class ResourceInUseException extends RuntimeException {
    public ResourceInUseException(String message) {
        super(message);
    }
}
