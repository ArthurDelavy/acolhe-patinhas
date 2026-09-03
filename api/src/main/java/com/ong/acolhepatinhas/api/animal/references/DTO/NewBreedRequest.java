package com.ong.acolhepatinhas.api.animal.references.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record NewBreedRequest(

    @Positive
    @Schema(example = "1")
    int specieId,

    @NotBlank @Size(max = 50)
    @Schema(example = "PitBull")
    String name

) {
}
