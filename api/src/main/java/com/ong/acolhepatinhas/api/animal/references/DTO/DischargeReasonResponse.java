package com.ong.acolhepatinhas.api.animal.references.DTO;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalDischargeReason;

import io.swagger.v3.oas.annotations.media.Schema;

public record DischargeReasonResponse(
   
    @Schema(example = "1")
    int id,

    @Schema(example = "Doação")
    String name
) {

    public DischargeReasonResponse(AnimalDischargeReason data) {
        this(data.getId(), data.getName());
    }
}
