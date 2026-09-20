package com.ong.acolhepatinhas.api.veterinary.preventive.catalog.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record NewPreventiveProcedureRequest(

    @NotBlank @Size(max = 50)
    @Schema(example = "Vermifugação")
    String name,

    @Positive
    @Schema(example = "180")
    short defaultFrequencyDays
) {
}
