package com.ong.acolhepatinhas.api.exceptions.custom;

public class EmailSendingException extends RuntimeException {
    public EmailSendingException(String message) {
        super(message);
    }
}
