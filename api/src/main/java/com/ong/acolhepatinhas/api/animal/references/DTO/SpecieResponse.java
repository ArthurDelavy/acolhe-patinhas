package com.ong.acolhepatinhas.api.animal.references.DTO;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalSpecie;

import io.swagger.v3.oas.annotations.media.Schema;

public record SpecieResponse(
    
    @Schema(example = "1")
    int id,

    @Schema(example = "Cachorro")
    String name
) {

    public SpecieResponse(AnimalSpecie data) {
        this(data.getId(), data.getName());
    }
}
