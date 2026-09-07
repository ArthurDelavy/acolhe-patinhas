package com.ong.acolhepatinhas.api.veterinary.vaccine.vaccination.DTO;

import java.time.LocalDate;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record NewVaccinationRequest(

    @Positive
    @Schema(example = "1")
    int vaccineId,

    @NotBlank @Size(max = 10)
    @Schema(example = "Única, reforço, anual, 1ª, 2ª, 3...")
    String dose,

    @NotBlank @Size(max = 50)
    @Schema(example = "Laboratório xyz")
    String manufacturer,

    @NotBlank @Size(max = 50)
    @Schema(example = "3746GHE92K3H8XV23")
    String batchNumer,

    @PastOrPresent
    @Schema(example = "2026-09-03T00:34:29.186Z")
    LocalDate vaccinationDate,

    @Future
    @Schema(example = "2028-09-03T00:34:29.186Z")
    LocalDate nextDoseDate
) {
}
