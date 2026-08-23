package com.ong.acolhepatinhas.api.auth.DTO;

import java.util.UUID;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

public record RefreshSessionRequest(

    @NotNull
    @Schema(example = "HRI4959D...")
    UUID refreshToken
) {
}
