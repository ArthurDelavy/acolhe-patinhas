package com.ong.acolhepatinhas.api.auth.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

public record TokenResponse(

    @NotBlank
    @Schema(example = "Yhue38493...", description = "Token JWT")
    String accessToken
) {
}
