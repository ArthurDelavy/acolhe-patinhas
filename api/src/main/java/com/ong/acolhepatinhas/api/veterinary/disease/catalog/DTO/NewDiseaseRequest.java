package com.ong.acolhepatinhas.api.veterinary.disease.catalog.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

public record NewDiseaseRequest(

    @NotBlank
    @Schema(example = "Dermatite")
    String name
) {
}
