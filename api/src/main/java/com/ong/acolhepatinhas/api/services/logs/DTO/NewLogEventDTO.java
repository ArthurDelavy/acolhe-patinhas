package com.ong.acolhepatinhas.api.services.logs.DTO;

import java.time.Instant;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record NewLogEventDTO(

    @NotBlank @Email
    String actor,

    @NotBlank
    String action,
    
    String resource,
    String details,

    String ip,

    @NotBlank
    String agent,

    @NotNull
    Instant timestamp

) {
}
