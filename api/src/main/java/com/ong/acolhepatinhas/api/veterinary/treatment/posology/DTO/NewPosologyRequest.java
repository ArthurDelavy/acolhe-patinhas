package com.ong.acolhepatinhas.api.veterinary.treatment.posology.DTO;

import java.time.LocalDate;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public record NewPosologyRequest(

    @PositiveOrZero @NotNull
    @Schema(example = "1")
    int treatmentId,

    @PositiveOrZero @NotNull
    @Schema(example = "1")
    int medicineId,

    @NotBlank @Size(max = 30)
    @Schema(example = "1cp")
    String dosage,

    @NotBlank @Size(max = 30)
    @Schema(example = "1cp")
    String frequency,

    @PositiveOrZero @NotNull
    @Schema(example = "7")
    int durationDays,

    @PastOrPresent @NotNull
    LocalDate starDate
) {
}
