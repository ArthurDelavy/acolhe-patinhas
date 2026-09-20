package com.ong.acolhepatinhas.api.veterinary.disease.catalog.DTO;

import com.ong.acolhepatinhas.api.veterinary.disease.catalog.Disease;

import io.swagger.v3.oas.annotations.media.Schema;

public record DiseaseResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "Dermatite")
    String name
) {

    public DiseaseResponse(Disease data) {
        this(data.getId(), data.getName());
    }
}
