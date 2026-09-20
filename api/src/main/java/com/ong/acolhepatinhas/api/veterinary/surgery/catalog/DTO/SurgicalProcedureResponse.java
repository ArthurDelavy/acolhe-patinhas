package com.ong.acolhepatinhas.api.veterinary.surgery.catalog.DTO;

import com.ong.acolhepatinhas.api.veterinary.surgery.catalog.SurgicalProcedure;

import io.swagger.v3.oas.annotations.media.Schema;

public record SurgicalProcedureResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "orquiectomia")
    String name
) {

    public SurgicalProcedureResponse(SurgicalProcedure data) {
        this(data.getId(), data.getName());
    }
}
