package com.ong.acolhepatinhas.api.auth.DTO;

import java.util.UUID;

import io.swagger.v3.oas.annotations.media.Schema;

public record TokenResponse(

    @Schema(example = "Yhue38493...", description = "Token JWT")
    String accessToken,

    @Schema(example = "HRI4959D...", description = "Refresh Token UUID")
    UUID refreshToken
) {
}
