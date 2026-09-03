package com.ong.acolhepatinhas.api.animal.DTO;

import java.time.Instant;
import java.time.LocalDate;

import com.ong.acolhepatinhas.api.animal.enums.Gender;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record NewAnimalRequest(
    
    @NotBlank @Size(max = 45)
    @Schema(example = "Max")
    String name,

    @Size(min = 15, max = 15)
    @Schema(example = "946578294037129")
    String microchipNumber,

    @Positive
    @Schema(example = "1")
    int breedId,

    @Positive
    @Schema(example = "1")
    int colorId,

    @NotNull
    @Schema(example = "M")
    Gender gender,

    @PastOrPresent
    @Schema(example = "2026-09-03T00:34:29.186Z")
    LocalDate birthDate,
    
    @PastOrPresent
    @Schema(example = "2029-09-27T00:34:29.186Z")
    Instant intakeDate,

    @Schema(example = "false")
    boolean toAdoption
) {
}
