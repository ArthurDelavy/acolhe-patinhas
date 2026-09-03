package com.ong.acolhepatinhas.api.auth.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ResendVerificationRequest(

    @Email @NotBlank @Size(max = 150)
    @Schema(example = "email@dominio.com")
    String email
) {
}
