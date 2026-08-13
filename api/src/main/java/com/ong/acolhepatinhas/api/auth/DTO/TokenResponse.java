package com.ong.acolhepatinhas.api.auth.DTO;

import jakarta.validation.constraints.NotBlank;

public record TokenResponse(

    @NotBlank
    String token
) {
}
