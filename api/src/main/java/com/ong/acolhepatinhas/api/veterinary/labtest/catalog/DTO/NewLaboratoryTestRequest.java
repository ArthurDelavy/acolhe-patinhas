package com.ong.acolhepatinhas.api.veterinary.labtest.catalog.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record NewLaboratoryTestRequest(

    @NotBlank @Size(max = 50)
    @Schema(example = "Hemograma")
    String name
) {
}
