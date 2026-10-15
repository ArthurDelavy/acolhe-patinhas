package com.ong.acolhepatinhas.api.user.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ChangeEmailRequest(

    @Email @NotBlank @Size(max = 150)
    @Schema(example = "novo@dominio.com")
    String newEmail
) {
}
