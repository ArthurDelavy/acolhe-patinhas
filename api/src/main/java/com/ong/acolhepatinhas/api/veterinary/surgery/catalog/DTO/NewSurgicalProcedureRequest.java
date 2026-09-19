package com.ong.acolhepatinhas.api.veterinary.surgery.catalog.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record NewSurgicalProcedureRequest(

    @NotBlank @Size(max = 50)
    @Schema(example = "orquiectomia")
    String name
) {
}
