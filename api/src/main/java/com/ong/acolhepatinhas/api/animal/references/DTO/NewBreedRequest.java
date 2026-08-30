package com.ong.acolhepatinhas.api.animal.references.DTO;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record NewBreedRequest(

    @Positive
    int specieId,

    @NotBlank @Size(max = 50)
    String name

) {
}
