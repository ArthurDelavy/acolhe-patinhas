package com.ong.acolhepatinhas.api.veterinary.record.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Positive;

public record NewVetRecordRequest(

    @Positive
    @Schema(example = "90", description = "Valor em cm")
    Integer size,

    @Schema(example = "1.5", description = "Valor em kg")
    Double weight,

    boolean neutered

) {
    
}
