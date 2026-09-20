package com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.DTO;

import java.time.LocalDate;

import com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.enums.DiseaseStatus;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;

public record NewDiagnosisRequest(

    @Positive
    @Schema(example = "1")
    int diseaseId,

    @PastOrPresent
    @Schema(example = "2026-09-03")
    LocalDate diagnosedAt,

    @NotNull
    @Schema(example = "HEALED")
    DiseaseStatus status
) {
}
