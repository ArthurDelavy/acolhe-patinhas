package com.ong.acolhepatinhas.api.exceptions;

import java.time.OffsetDateTime;

public record ErrorResponse(

    int status,
    String message,
    OffsetDateTime dateTime
) {
}
