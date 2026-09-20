package com.ong.acolhepatinhas.api.veterinary.labtest.result.DTO;

import java.time.LocalDate;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record NewLaboratoryTestResultRequest(

    @Positive 
    @Schema(example = "1")
    int labTestId,

    @NotNull @PastOrPresent
    @Schema(example = "2026-09-03T00:34:29.186Z")
    LocalDate testDate,

    @Size(max = 10000)
    @Schema(example = "...")
    String results,

    @Size(max = 5000)
    @Schema(example = "...")
    String observations
) {
}
