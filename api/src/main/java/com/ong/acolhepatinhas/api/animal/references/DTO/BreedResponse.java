package com.ong.acolhepatinhas.api.animal.references.DTO;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalBreed;

import io.swagger.v3.oas.annotations.media.Schema;

public record BreedResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "1", description = "ID da espécie vinculada à raça")
    int specieId,

    @Schema(example = "Pitbull")
    String name
    
) {

    public BreedResponse(AnimalBreed data) {
        this(data.getId(), data.getSpecie().getId(), data.getName());
    }
}
