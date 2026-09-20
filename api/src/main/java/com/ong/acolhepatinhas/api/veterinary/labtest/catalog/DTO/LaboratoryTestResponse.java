package com.ong.acolhepatinhas.api.veterinary.labtest.catalog.DTO;

import com.ong.acolhepatinhas.api.veterinary.labtest.catalog.LaboratoryTest;

import io.swagger.v3.oas.annotations.media.Schema;

public record LaboratoryTestResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "Hemograma")
    String name
) {

    public LaboratoryTestResponse(LaboratoryTest data) {
        this(data.getId(), data.getName());
    }
    
}
