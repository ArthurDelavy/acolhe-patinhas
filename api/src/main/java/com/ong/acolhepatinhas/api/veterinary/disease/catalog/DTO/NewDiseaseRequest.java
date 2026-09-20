package com.ong.acolhepatinhas.api.veterinary.disease.catalog.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record NewDiseaseRequest(

    @NotBlank @Size(min = 3, max = 50)
    @Schema(example = "Dermatite")
    String name
) {
}
