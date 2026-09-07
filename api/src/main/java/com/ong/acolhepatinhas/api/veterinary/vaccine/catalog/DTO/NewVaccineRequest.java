package com.ong.acolhepatinhas.api.veterinary.vaccine.catalog.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

public record NewVaccineRequest(

    @NotBlank
    @Schema(example = "Polivalente")
    String name
) {
}
