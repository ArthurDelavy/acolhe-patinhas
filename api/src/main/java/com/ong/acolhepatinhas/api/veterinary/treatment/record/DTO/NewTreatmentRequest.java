package com.ong.acolhepatinhas.api.veterinary.treatment.record.DTO;

import java.time.LocalDate;

import com.ong.acolhepatinhas.api.veterinary.treatment.record.enums.TreatmentStatus;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Size;

public record NewTreatmentRequest(

    @Schema(example = "1")
    Integer diagnosisId,

    @PastOrPresent
    @Schema(example = "2026-09-03")
    LocalDate startDate,

    @Schema(example = "2026-11-09")
    LocalDate endDate,

    @NotNull
    @Schema(example = "FINISHED")
    TreatmentStatus status,

    @Size(max = 5000)
    @Schema(example = "[...]")
    String observations
) {
}
