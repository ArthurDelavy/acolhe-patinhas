package com.ong.acolhepatinhas.api.user.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record EditNameRequest(

    @NotBlank @Size(min = 3, max = 100)
    @Schema(example = "Fulano de Tal")
    String name
) {
}

