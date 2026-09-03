package com.ong.acolhepatinhas.api.animal.references.DTO;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalBreed;

public record BreedResponse(

    int id,
    int specieId,
    String name
    
) {

    public BreedResponse(AnimalBreed data) {
        this(data.getId(), data.getSpecie().getId(), data.getName());
    }
}
