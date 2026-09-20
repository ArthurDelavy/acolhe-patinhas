package com.ong.acolhepatinhas.api.veterinary.preventive.procedure.DTO;

import java.time.LocalDate;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record NewPreventiveCareRequest(

    @Positive 
    @Schema(example = "1")
    int procedureId,

    @Positive 
    @Schema(example = "1")
    Integer medicineId,

    @PastOrPresent
    @Schema(example = "2026-09-03T00:34:29.186Z")
    LocalDate procedureDate,

    @FutureOrPresent
    @Schema(example = "2028-09-03T00:34:29.186Z")
    LocalDate nextProcedureDate,

    @Size(max = 5000)
    @Schema(example = "...")
    String observations

) {
}
