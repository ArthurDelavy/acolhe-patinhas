package com.ong.acolhepatinhas.api.veterinary.medicine.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record NewMedicineRequest(

    @NotBlank @Size(min = 3, max = 50)
    @Schema(example = "Maxicam")
    String name
) {
}
