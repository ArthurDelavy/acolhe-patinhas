package com.ong.acolhepatinhas.api.exceptions;

import java.time.OffsetDateTime;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonInclude;

import io.swagger.v3.oas.annotations.media.Schema;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ErrorResponse(

    @Schema(example = "400")
    int status,

    @Schema(example = "Mensagem")
    String message,

    @Schema(example = "2026-08-16T18:18:35Z")
    OffsetDateTime timestamp,

    @Schema(nullable = true, requiredMode = Schema.RequiredMode.NOT_REQUIRED, example = "{\"password\": \"não deve estar em branco\", \"email\": \"deve ser um endereço de e-mail bem formado\"}")
    Map<String, String> errors
) {

    public ErrorResponse(int status, String message, OffsetDateTime timestamp) {
        this(status, message, timestamp, null);
    }
}
