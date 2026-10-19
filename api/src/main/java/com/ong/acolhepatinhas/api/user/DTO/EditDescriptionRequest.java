package com.ong.acolhepatinhas.api.user.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Size;

public record EditDescriptionRequest(

    @Size(max = 500)
    @Schema(example = "Voluntário na Acolhe Patinhas")
    String description
) {
}
