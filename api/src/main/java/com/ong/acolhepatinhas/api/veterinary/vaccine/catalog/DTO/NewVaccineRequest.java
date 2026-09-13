package com.ong.acolhepatinhas.api.veterinary.vaccine.catalog.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record NewVaccineRequest(

    @NotBlank @Size(min = 3, max = 30)
    @Schema(example = "Polivalente")
    String name
) {
}
