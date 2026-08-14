package com.ong.acolhepatinhas.api.exceptions;

import java.time.OffsetDateTime;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ErrorResponse(

    int status,
    String message,
    OffsetDateTime timestamp,
    Map<String, String> errors
) {

    public ErrorResponse(int status, String message, OffsetDateTime timestamp) {
        this(status, message, timestamp, null);
    }
}
