package com.ong.acolhepatinhas.api.veterinary.preventive.catalog.DTO;

import com.ong.acolhepatinhas.api.veterinary.preventive.catalog.PreventiveProcedure;

import io.swagger.v3.oas.annotations.media.Schema;

public record PreventiveProcedureResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "Vermifugação")
    String name,

    @Schema(example = "180")
    Integer defaultFrequencyDays
) {

    public PreventiveProcedureResponse(PreventiveProcedure data) {
        this(data.getId(), data.getName(), data.getDefaultFrequencyDays());
    }
}
