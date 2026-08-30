package com.ong.acolhepatinhas.api.animal.DTO;

import java.time.Instant;
import java.time.LocalDate;

import com.ong.acolhepatinhas.api.animal.enums.Genders;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record EditAnimalRequest(

    @NotBlank @Size(max = 45)
    String name,

    @Size(min = 15, max = 15)
    String microchipNumber,

    @Positive
    int breedId,

    @Positive
    int colorId,

    @NotBlank
    Genders gender,

    @PastOrPresent
    LocalDate birthDate,
    
    @PastOrPresent
    Instant intakeDate,

    @PastOrPresent
    Instant dischargeDate,

    @Positive
    Integer dischargeReasonId,

    boolean toAdoption
) {
}
