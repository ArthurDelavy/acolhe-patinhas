package com.ong.acolhepatinhas.api.veterinary.surgery.procedure.DTO;

import java.time.LocalDate;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record NewSurgeryRequest(

    @Positive
    @Schema(example = "1")
    int procedureId,

    @PastOrPresent @NotNull
    @Schema(example = "2028-09-03")
    LocalDate procedureDate,

    @Size(max = 5000)
    @Schema(example = "...")
    String observations
) {
}
