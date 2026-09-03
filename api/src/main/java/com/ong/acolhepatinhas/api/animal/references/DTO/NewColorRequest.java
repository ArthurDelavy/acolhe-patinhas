package com.ong.acolhepatinhas.api.animal.references.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record NewColorRequest(

    @NotBlank @Size(max = 20)
    @Schema(example = "Preto")
    String name
) {
}
