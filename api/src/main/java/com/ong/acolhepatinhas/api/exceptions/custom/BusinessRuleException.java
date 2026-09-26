package com.ong.acolhepatinhas.api.exceptions.custom;

public class BusinessRuleException extends RuntimeException {
    public BusinessRuleException(String message) {
        super(message);
    }
}
